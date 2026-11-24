local M = {}

--------------------------------------------------------------------------------
-- 1. FILE & TEXT UTILITIES
--------------------------------------------------------------------------------

function M.copy_project_path()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name == "" then
        vim.notify("No file in current buffer", vim.log.levels.WARN)
        return
    end

    -- Find the project root directory (e.g., where .git lives)
    local root = vim.fs.root(0, { ".git", "package.json", "Makefile" }) or vim.fn.getcwd()

    -- Calculate path relative to that root
    local path = vim.fs.relpath(root, buf_name) or buf_name

    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end

function M.trim_whitespace_file()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
        lines[i] = line:gsub("%s+$", "")
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    print("Trailing whitespace trimmed in file!")
end

function M.trim_whitespace_selection()
    -- Exit visual mode to force Neovim to update '< and '> marks
    vim.cmd("normal! \27")

    local start_line = vim.fn.line("'<") - 1
    local end_line = vim.fn.line("'>")

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
    for i, line in ipairs(lines) do
        lines[i] = line:gsub("%s+$", "")
    end

    vim.api.nvim_buf_set_lines(0, start_line, end_line, false, lines)
    print("Trailing whitespace trimmed in selection!")
end

function M.delete_all_marks()
    -- Delete local marks (a-z) across all loaded buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("delmarks!")
            end)
        end
    end

    -- Delete global marks (A-Z, 0-9)
    vim.cmd("delmarks A-Z0-9")

    vim.notify("Cleared all marks across all buffers", vim.log.levels.INFO)
end

function M.delete_line_marks()
    local cur_line = vim.fn.line(".")
    local marks = vim.fn.getmarklist()
    vim.list_extend(marks, vim.fn.getmarklist(vim.api.nvim_get_current_buf()))

    local deleted_count = 0
    for _, mark in ipairs(marks) do
        if mark.pos[2] == cur_line then
            -- Remove only the leading single quote
            local mark_name = mark.mark:sub(2)

            -- Only delete user-created marks (a-z, A-Z, 0-9)
            if mark_name:match("^[a-zA-Z0-9]$") then
                vim.cmd("delmarks " .. mark_name)
                deleted_count = deleted_count + 1
            end
        end
    end

    if deleted_count > 0 then
        vim.notify("Deleted " .. deleted_count .. " mark(s) from line " .. cur_line .. ".", vim.log.levels.INFO)
    else
        vim.notify("No user marks found on line " .. cur_line .. ".", vim.log.levels.WARN)
    end
end

--------------------------------------------------------------------------------
-- 2. SEARCH & PICKERS
--------------------------------------------------------------------------------

function M.grep_latin1()
    Snacks.picker.grep({
        cwd = LazyVim.root(),
        icon = { icon = "󱥰", hl = "SnacksIconCandy" },
        prompt = "Grep (Latin1)> ",
        args = { "--encoding", "latin1" },
        win = { preview = { wrap = true } },
        previewers = { file = { ft = nil } },
    })
end

--------------------------------------------------------------------------------
-- 3. GIT & DIFFING
--------------------------------------------------------------------------------

function M.diffview_compare_branches()
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    require("telescope.builtin").git_branches({
        prompt_title = "Select Base Branch",
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local base_branch = action_state.get_selected_entry().value
                actions.close(prompt_bufnr)

                require("telescope.builtin").git_branches({
                    prompt_title = "Compare " .. base_branch .. " with:",
                    attach_mappings = function(prompt_bufnr2, _)
                        actions.select_default:replace(function()
                            local target_branch = action_state.get_selected_entry().value
                            actions.close(prompt_bufnr2)
                            vim.cmd("DiffviewOpen " .. base_branch .. ".." .. target_branch)
                        end)
                        return true
                    end,
                })
            end)
            return true
        end,
    })
end

function M.diff_two_buffers()
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    require("telescope.builtin").buffers({
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selections = picker:get_multi_selection()

                if #selections ~= 2 then
                    actions.close(prompt_bufnr)
                    vim.notify("You must select exactly 2 buffers using <Tab>", vim.log.levels.ERROR)
                    return
                end

                actions.close(prompt_bufnr)
                vim.cmd("tabnew")
                vim.cmd("buffer " .. selections[1].bufnr)
                vim.cmd("diffthis")
                vim.cmd("vsplit")
                vim.cmd("buffer " .. selections[2].bufnr)
                vim.cmd("diffthis")
                vim.cmd("wincmd h")
            end)
            return true
        end,
    })
end

--------------------------------------------------------------------------------
-- 4. CONVERTERS & TRANSFORMATIONS
--------------------------------------------------------------------------------

function M.toggle_date_timestamp()
    vim.cmd('normal! "xy')
    local text = vim.fn.getreg("x"):gsub("^%s*(.-)%s*$", "%1")
    local new_text = ""

    if text:match("^%d+$") then
        new_text = os.date("%Y-%m-%d %H:%M:%S", tonumber(text))
        print("Converted Timestamp -> Date")
    else
        local y, m, d, hr, min, sec = text:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
        if y then
            new_text = tostring(os.time({ year = y, month = m, day = d, hour = hr, min = min, sec = sec }))
            print("Converted Date -> Timestamp")
        else
            print("Error: Selection is not a valid timestamp or YYYY-MM-DD HH:MM:SS string")
            return
        end
    end

    vim.cmd("normal! gvd")
    vim.api.nvim_put({ new_text }, "c", false, true)
end

local function hex_to_hsl(hex)
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max ~= min then
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    local function fmt(val)
        return (string.format("%.2f", val):gsub("%.?0+$", ""))
    end
    return string.format("hsl(%s, %s%%, %s%%)", fmt(h * 360), fmt(s * 100), fmt(l * 100))
end

local function hsl_to_hex(h, s, l)
    h, s, l = h / 360, s / 100, l / 100
    local function hue2rgb(p, q, t)
        if t < 0 then
            t = t + 1
        end
        if t > 1 then
            t = t - 1
        end
        if t < 1 / 6 then
            return p + (q - p) * 6 * t
        end
        if t < 1 / 2 then
            return q
        end
        if t < 2 / 3 then
            return p + (q - p) * (2 / 3 - t) * 6
        end
        return p
    end

    local r, g, b
    if s == 0 then
        r, g, b = l, l, l
    else
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r, g, b = hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3)
    end

    return string.format(
        "#%02x%02x%02x",
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5)
    )
end

function M.toggle_hex_hsl()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1

    for start_idx, hex_val, end_idx in line:gmatch("()#(%x%x%x%x%x%x)()") do
        if col >= start_idx and col <= end_idx - 1 then
            vim.api.nvim_set_current_line(line:sub(1, start_idx - 1) .. hex_to_hsl(hex_val) .. line:sub(end_idx))
            return
        end
    end

    for start_idx, h, s, l, end_idx in line:gmatch("()hsl%(([%d%.]+)%s*,%s*([%d%.]+)%%?%s*,%s*([%d%.]+)%%?%)()") do
        if col >= start_idx and col <= end_idx - 1 then
            vim.api.nvim_set_current_line(
                line:sub(1, start_idx - 1) .. hsl_to_hex(tonumber(h), tonumber(s), tonumber(l)) .. line:sub(end_idx)
            )
            return
        end
    end

    vim.notify("No Hex or HSL format found under cursor", vim.log.levels.WARN)
end

--------------------------------------------------------------------------------
-- 5. SPELLCHECK (CSPELL) INTEGRATION
--------------------------------------------------------------------------------

_G.cspell_active = true

function M.jump_to_typo(dir)
    return function()
        if not _G.cspell_active then
            vim.notify("Spell check is currently turned off!", vim.log.levels.WARN, { title = "Spell Checker" })
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local crow, ccol = cursor[1] - 1, cursor[2]
        local diagnostics = vim.diagnostic.get(bufnr)
        local typos = {}

        for _, d in ipairs(diagnostics) do
            if d.source and d.source:lower():match("cspell") then
                table.insert(typos, d)
            end
        end

        if #typos == 0 then
            vim.notify("No typos found in this file!", vim.log.levels.INFO, { title = "Spell Checker" })
            return
        end

        table.sort(typos, function(a, b)
            if a.lnum == b.lnum then
                return a.col < b.col
            end
            return a.lnum < b.lnum
        end)

        local target = nil
        if dir == "next" then
            for _, d in ipairs(typos) do
                if d.lnum > crow or (d.lnum == crow and d.col > ccol) then
                    target = d
                    break
                end
            end
            target = target or typos[1]
        else
            for i = #typos, 1, -1 do
                local d = typos[i]
                if d.lnum < crow or (d.lnum == crow and d.col < ccol) then
                    target = d
                    break
                end
            end
            target = target or typos[#typos]
        end

        if target then
            if vim.diagnostic.jump then
                vim.diagnostic.jump({ diagnostic = target })
            else
                vim.api.nvim_win_set_cursor(0, { target.lnum + 1, target.col })
            end
        end
    end
end

function M.toggle_cspell()
    _G.cspell_active = not _G.cspell_active

    for ns_id, ns in pairs(vim.diagnostic.get_namespaces()) do
        if ns.name:lower():match("cspell") then
            vim.diagnostic.config({
                underline = _G.cspell_active,
                virtual_text = _G.cspell_active,
                signs = _G.cspell_active,
            }, ns_id)
        end
    end

    if _G.cspell_active then
        vim.notify("CSpell Turned ON (Squiggles Visible)", vim.log.levels.INFO, { title = "Spell Checker" })
    else
        vim.notify("CSpell Turned OFF (Squiggles Hidden)", vim.log.levels.WARN, { title = "Spell Checker" })
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("CSpellWorkspaceToggle", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "cspell_ls" then
            local ns_id = vim.lsp.diagnostic.get_namespace(client.id)
            if not _G.cspell_active then
                vim.diagnostic.config({ underline = false, virtual_text = false, signs = false }, ns_id)
            end
        end
    end,
})

--------------------------------------------------------------------------------
-- 6. BROWSER INTEROP (WSL + DISTROBOX)
--------------------------------------------------------------------------------

-- `vim.ui.open`'s default handler on Linux is `xdg-open`. Inside a Distrobox
-- container that resolves to Distrobox's own host-delegating wrapper
-- (`/usr/local/bin/xdg-open` -> `distrobox-host-exec`), and the host process it
-- spawns runs with a sanitized PATH that drops the `/mnt/c/...` Windows interop
-- directories. On WSL, xdg-open only picks its WSL handler when `explorer.exe`
-- is reachable (xdg-utils 1.2.1: `/proc/version` contains "microsoft" AND
-- `command -v explorer.exe`), so inside the container detection fails and it
-- falls through to the generic method: no `BROWSER`, no GUI browser, only the
-- text-browser loop -> exits 3 "no method available", which Neovim reports as
-- `vim.ui.open: command failed (3): { "xdg-open", ... }` on `gx`.
--
-- Fix: when Neovim runs in a container on a WSL kernel with working interop,
-- open things directly with the Windows binaries by absolute path, mirroring
-- the host xdg-open's own WSL branch (rundll32 for URIs, explorer.exe for
-- files/directories). Native Linux (no WSL kernel) keeps the stock handler, so
-- the same config keeps working there unchanged.
do
    local rundll32 = "/mnt/c/Windows/System32/rundll32.exe"
    local explorer = "/mnt/c/Windows/explorer.exe"

    local is_wsl = vim.uv.os_uname().release:find("microsoft", 1, true) ~= nil
    local has_interop = vim.uv.fs_stat(rundll32) ~= nil and vim.uv.fs_stat(explorer) ~= nil
    local in_container = vim.uv.fs_stat("/run/.containerenv") ~= nil or vim.uv.fs_stat("/.dockerenv") ~= nil

    if is_wsl and has_interop and in_container then
        --- Convert a Linux path to a Windows-openable one: `/mnt/<drive>/...`
        --- becomes `<DRIVE>:/...` and everything else is addressed through the
        --- WSL UNC share (`\\wsl.localhost\<distro>\...`).
        local function windows_path(path)
            local p = vim.fs.normalize(path)
            local drive, rest = p:match("^/mnt/(%a)/?(.*)$")
            if drive then
                return drive:upper() .. ":/" .. rest
            end
            local distro = vim.env.WSL_DISTRO_NAME or "Ubuntu"
            return "\\\\wsl.localhost\\" .. distro .. "\\" .. (p:sub(2):gsub("/", "\\"))
        end

        local stock_open = vim.ui.open
        ---@param path string
        ---@param opt? vim.SystemOpenOpts
        vim.ui.open = function(path, opt)
            -- Explicit overrides are passed through untouched.
            if opt and opt.cmd then
                return stock_open(path, opt)
            end

            -- rundll32's FileProtocolHandler handles URIs and Windows paths
            -- alike (it is what the host xdg-open's WSL branch uses for URIs),
            -- and exits 0 on success. explorer.exe would also work for paths
            -- but exits 1 on success, which stock error reporting cannot tell
            -- apart from a failure, so it is avoided.
            local is_uri = path:match("^%w+:")
            local arg = is_uri and path or windows_path(path)

            local ok, out = pcall(vim.system, { rundll32, "url.dll,FileProtocolHandler", arg }, { detach = true })
            if not ok then
                return nil, out ---@cast out string
            end
            return out, nil
        end
    end
end

--------------------------------------------------------------------------------
-- 7. LARAVEL NAVIGATION (gd)
--------------------------------------------------------------------------------

-- Query the LSP for the definition of the symbol under the cursor and return
-- the first location found WITHOUT jumping to it, so the caller can decide
-- whether it is worth opening. Returns nil when no definition was found.
-- @return { item: table, encoding: string, filename: string, lnum: integer }|nil
local function first_definition_location()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local client = clients[1]
    local offset_encoding = client and client.offset_encoding or "utf-16"

    local params = vim.lsp.util.make_position_params(0, offset_encoding)
    local results = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 1000)
    if not results or vim.tbl_isempty(results) then
        return nil
    end

    for client_id, response in pairs(results) do
        local result = response.result
        if result and not vim.tbl_isempty(result) then
            local resp_client = vim.lsp.get_client_by_id(client_id)
            if resp_client then
                local item = (type(result) == "table" and result[1]) and result[1] or result
                local uri = item.uri or item.targetUri
                local range = item.range or item.targetSelectionRange or item.targetRange
                if uri then
                    return {
                        item = item,
                        encoding = resp_client.offset_encoding or "utf-16",
                        filename = vim.uri_to_fname(uri),
                        lnum = range and range.start.line or 0,
                    }
                end
            end
        end
    end
    return nil
end

-- Resolve a fully qualified PHP class name to its file through the PSR-4 maps
-- of the project (composer.json) and of the installed packages
-- (vendor/composer/autoload_psr4.php). This is what lets `gd` follow the
-- `@see` hints ide-helper writes, without booting PHP or searching the tree.
-- @return string|nil absolute path
local function php_class_file(fqcn)
    local root = vim.fs.root(0, { "composer.json", ".git" })
    if not root then
        return nil
    end

    ---@type { prefix: string, dir: string }[]
    local psr4 = {}
    local function add(prefix, dir)
        psr4[#psr4 + 1] = { prefix = prefix, dir = dir }
    end

    local ok, composer = pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(root .. "/composer.json"), "\n"))
    end)
    if ok and type(composer) == "table" then
        for _, section in ipairs({ "autoload", "autoload-dev" }) do
            local map = composer[section] and composer[section]["psr-4"]
            if type(map) == "table" then
                for prefix, dirs in pairs(map) do
                    if type(dirs) == "string" then
                        dirs = { dirs }
                    end
                    for _, dir in ipairs(dirs) do
                        add(prefix, root .. "/" .. dir)
                    end
                end
            end
        end
    end

    -- Composer's generated map covers vendor packages too; every entry reads
    -- `'Prefix\' => array($vendorDir . '/some/package/src')` (only the first
    -- directory is used: it is the only one Composer itself prefers).
    local vendor_ok, vendor_lines = pcall(vim.fn.readfile, root .. "/vendor/composer/autoload_psr4.php")
    if vendor_ok then
        for _, text in ipairs(vendor_lines) do
            local prefix, base, dir = text:match("^%s*'([%w_\\]+)'%s*=>%s*array%(%$(%a+)%s*%.%s*'([^']+)'")
            if prefix then
                add(prefix, (base == "baseDir" and root or root .. "/vendor") .. dir)
            end
        end
    end

    -- Longest namespace prefix wins: `Database\Factories\` beats `Database\`.
    table.sort(psr4, function(a, b)
        return #a.prefix > #b.prefix
    end)

    for _, entry in ipairs(psr4) do
        if vim.startswith(fqcn, entry.prefix) then
            local relative = fqcn:sub(#entry.prefix + 1):gsub("\\", "/")
            local path = entry.dir .. "/" .. relative .. ".php"
            if vim.uv.fs_stat(path) then
                return path
            end
        end
    end
    return nil
end

-- Namespace of a generated stub. `_ide_helper_models.php` groups its classes
-- in `namespace App\Models{...}` blocks, so the closest preceding declaration
-- gives the FQCN of the class a stub belongs to.
-- @return string|nil
local function php_namespace_at(lines, line)
    for i = line, 1, -1 do
        local namespace = lines[i]:match("^%s*namespace%s+([%w_\\]+)")
        if namespace then
            return namespace
        end
    end
    return nil
end

-- Locate the real file of a model class: prefer the project's PSR-4 map and
-- fall back to a path glob for models outside of it.
-- @return string|nil absolute path
local function model_file(class_name, fqcn)
    if fqcn then
        local path = php_class_file(fqcn)
        if path then
            return path
        end
    end

    local root = vim.fs.root(0, { "composer.json", ".git" }) or vim.fn.getcwd()
    local matches = vim.fn.glob(root .. "/app/**/" .. class_name .. ".php", false, true)
    if #matches == 0 then
        matches = vim.fn.glob(root .. "/**/" .. class_name .. ".php", false, true)
    end
    return matches[1]
end

-- Open the class declaration of a real PHP class and place the cursor on it.
-- This is where `gd` lands for a model stub that only declares the class.
local function open_class_definition(class_name, fqcn)
    local path = model_file(class_name, fqcn)
    if not path then
        vim.notify("Class file " .. class_name .. ".php not found", vim.log.levels.WARN)
        return false
    end

    vim.cmd("edit " .. vim.fn.fnameescape(path))

    local line = vim.fn.search("\\<class\\s\\+" .. vim.pesc(class_name) .. "\\>", "wn")
    if line > 0 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd("normal! zz")
    end
    return true
end

-- Read the `@see \Fully\Qualified\Class::method()` target from the docblock
-- directly above a generated stub. ide-helper adds that hint to the stubs it
-- generates for runtime macros (`Http::macro(...)`) and for methods it proxies,
-- pointing at the provider that registered them.
-- @return string|nil fqcn, string|nil method
local function stub_see_target(lines, stub_line)
    -- Stub locations point either at the method name (LocationLink) or at the
    -- start of the declaration (Location): normalise to the `function` line.
    local anchor = stub_line
    for i = stub_line, math.min(#lines, stub_line + 40) do
        if lines[i]:find("function%s+") then
            anchor = i
            break
        end
    end

    for i = anchor - 1, math.max(1, anchor - 60), -1 do
        if not lines[i]:find("^%s*%*") then
            return nil -- start of the docblock (or no docblock at all)
        end
        local class, method = lines[i]:match("@see%s+\\?([%w_\\]+)::(%w+)%(")
        if class then
            return class, method
        end
    end
    return nil
end

-- Follow the `@see` hint of a generated stub to the code that really defines
-- the symbol: the `macro('word', ...)` registration when the stub stands for a
-- runtime macro, otherwise the referenced method. Returns true when the cursor
-- was moved to a real file.
local function open_stub_reference(word, lines, stub_line)
    local class, method = stub_see_target(lines, stub_line)
    if not class or not method then
        return false
    end

    local path = php_class_file(class)
    if not path then
        return false
    end

    local ok, target_lines = pcall(vim.fn.readfile, path)
    if not ok or #target_lines == 0 then
        return false
    end

    local macro_pattern = word ~= "" and ("macro%s*%(%s*['\"]" .. vim.pesc(word) .. "['\"]") or nil
    local method_pattern = "function%s+" .. vim.pesc(method) .. "%s*%("
    local target = nil
    for i, text in ipairs(target_lines) do
        if macro_pattern and text:find(macro_pattern) then
            target = i
            break
        end
        if not target and text:find(method_pattern) then
            target = i
        end
    end
    if not target then
        return false
    end

    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_cursor(0, { target, 0 })
    vim.cmd("normal! zz")
    return true
end

-- Name of the stub's class when the definition points at the class declaration
-- itself (`class Customer extends \Eloquent {}`) rather than at a property or
-- method documented in the preceding docblock.
-- @return string|nil
local function stub_class_name(lines, stub_line, word)
    for i = stub_line, math.min(#lines, stub_line + 40) do
        local name = lines[i]:match("^%s*class%s+([%w_]+)")
        if name then
            return name == word and name or nil
        end
    end
    return nil
end

-- Nearest `class <Name>` after `stub_line`: model stubs are a `@property`
-- docblock immediately followed by the class declaration they document.
local function class_after(lines, stub_line)
    for i = stub_line, #lines do
        local name = lines[i]:match("class%s+ide_helper_([%w_]+)") or lines[i]:match("class%s+([%w_]+)")
        if name then
            return name
        end
    end
    return nil
end

-- Convert a snake_case attribute name to the StudlyCase suffix of its accessor:
-- `is_elearning` -> `IsElearning`.
local function studly(word)
    return (
        word:gsub("_(%l)", function(c)
            return c:upper()
        end):gsub("^%l", function(c)
            return c:upper()
        end)
    )
end

-- True when `path` declares a method named `needle`.
local function file_matches(path, needle)
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then
        return false
    end
    for _, text in ipairs(lines) do
        if text:find("function", 1, true) and text:find(needle, 1, true) then
            return true
        end
    end
    return false
end

-- Open `path` on the declaration of the method named `needle`.
local function open_at_match(path, needle)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    local line = vim.fn.search("function\\s\\+" .. needle, "wn")
    if line > 0 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd("normal! zz")
    end
    return true
end

-- Open the real model and place the cursor on the accessor implementing
-- `word`. This is the old `<leader>cj` behaviour. The ide-helper file is read
-- from disk with `readfile`, so it is never loaded into a buffer.
local function open_model_accessor(word, lines, stub_line)
    local class_name = class_after(lines, stub_line)
    if not class_name then
        vim.notify("Could not determine Model class from ide-helper", vim.log.levels.WARN)
        return false
    end

    -- Anchored at the project root so the lookup does not depend on the
    -- directory Neovim was started from.
    local path = model_file(class_name)
    if not path then
        vim.notify("Model file " .. class_name .. ".php not found", vim.log.levels.WARN)
        return false
    end

    vim.cmd("edit " .. vim.fn.fnameescape(path))

    local pascal = studly(word)
    local camel = pascal:sub(1, 1):lower() .. pascal:sub(2)
    local pattern = "\\(get" .. pascal .. "Attribute\\|function\\s\\+" .. camel .. "\\)"
    local line = vim.fn.search(pattern, "wn")

    if line > 0 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd("normal! zz")
        return true
    end

    -- The symbol is a plain column/relation, not an accessor: land on the
    -- model's class declaration instead of the generated stub.
    line = vim.fn.search("\\<class\\s\\+" .. vim.pesc(class_name) .. "\\>", "wn")
    if line > 0 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd("normal! zz")
    end
    return true
end

-- Intelephense resolves magic Eloquent attributes through the ide-helper stubs
-- only for typed receivers. For a chained call such as
-- `Product::find($id)?->is_elearning` it returns no definition at all, so look
-- up the `getIsElearningAttribute()` accessor directly. Returns true when the
-- cursor was moved.
local function open_magic_accessor(word)
    if word == "" or word:find("^%u") or word:find("\\") then
        return false
    end

    local needle = "get" .. studly(word) .. "Attribute"

    -- Prefer the class named on the current line (`Product::find(...)?->word`).
    local cursor = vim.api.nvim_win_get_cursor(0)
    local prefix = vim.api.nvim_get_current_line():sub(1, cursor[2])
    local receiver = prefix:match(".*([%u][%w_]*)%s*::")
    local preferred = receiver and model_file(receiver) or nil
    if preferred and file_matches(preferred, needle) then
        return open_at_match(preferred, needle)
    end

    local root = vim.fs.root(0, { "composer.json", ".git" }) or vim.fn.getcwd()
    local candidates = {}
    for _, path in ipairs(vim.fn.glob(root .. "/app/**/*.php", false, true)) do
        if file_matches(path, needle) then
            candidates[#candidates + 1] = path
        end
    end
    if #candidates ~= 1 then
        return false
    end
    return open_at_match(candidates[1], needle)
end

-- Given a definition the LSP resolved inside a generated `_ide_helper` file,
-- open the code that really defines the symbol. Macro/facade stubs are resolved
-- through ide-helper's own `@see` hint; model stubs (`_ide_helper_models.php`)
-- resolve to the real model class declaration or accessor. Returns true when
-- the cursor was moved.
local function open_stub_definition(word, ide_helper_file, ide_helper_line)
    local lines = vim.fn.readfile(ide_helper_file)
    if not lines or #lines == 0 then
        vim.notify("Could not read ide-helper file", vim.log.levels.WARN)
        return false
    end

    -- `ide_helper_line` is 0-based (from the LSP range).
    local stub_line = ide_helper_line + 1

    if open_stub_reference(word, lines, stub_line) then
        return true
    end

    if not ide_helper_file:find("_ide_helper_models%.php$") then
        return false
    end

    -- A class reference (`new Customer`) resolves to the stub that declares the
    -- class: open the real model instead of the docblock-only stub.
    local class_name = stub_class_name(lines, stub_line, word)
    if class_name then
        local namespace = php_namespace_at(lines, stub_line)
        local fqcn = namespace and (namespace .. "\\" .. class_name) or nil
        return open_class_definition(class_name, fqcn)
    end

    return open_model_accessor(word, lines, stub_line)
end

--- The old `<leader>cj` Laravel accessor jump, folded into `gd`.
---
--- Outside PHP this is LazyVim's stock definition jump. In a PHP buffer it first
--- performs the same LSP definition lookup, and only when that yields nothing (or
--- only a generated `_ide_helper` stub) does it resolve the real implementation:
--- the `@see` hint ide-helper writes for runtime macros, or the model class /
--- accessor, as the removed `<leader>cj` shortcut used to do. The ide-helper file
--- is only read from disk when it needs to be parsed, never loaded as a buffer.
function M.goto_definition()
    if vim.bo.filetype ~= "php" then
        return vim.lsp.buf.definition()
    end

    -- Capture the symbol before resolving: the definition points elsewhere.
    local word = vim.fn.expand("<cword>"):gsub("^%$", "")

    local def = first_definition_location()
    if not def then
        -- Fall back to the model accessor for magic attributes the LSP cannot
        -- resolve through a chained receiver.
        if open_magic_accessor(word) then
            return
        end
        if word ~= "" then
            vim.notify("LSP definition not found for: " .. word, vim.log.levels.WARN)
        end
        return
    end

    if not def.filename:match("_ide_helper") then
        -- A real definition: jump to it exactly like the stock `gd`.
        vim.lsp.util.show_document(def.item, def.encoding)
        return
    end

    -- The LSP only resolved a generated stub: prefer the real implementation.
    -- Model stubs are never opened, since they only repeat properties and
    -- methods documented in the real model; other stubs remain a last resort.
    if not open_stub_definition(word, def.filename, def.lnum) then
        if def.filename:find("_ide_helper_models%.php$") then
            vim.notify(
                "Definition only available in generated model stubs: " .. (word ~= "" and word or "symbol"),
                vim.log.levels.WARN
            )
            return
        end
        vim.lsp.util.show_document(def.item, def.encoding)
    end
end

return M
