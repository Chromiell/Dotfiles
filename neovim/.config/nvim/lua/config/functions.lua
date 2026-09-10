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

function M.jump_to_laravel_accessor()
    -- Extract word under cursor and remove leading $
    local word = vim.fn.expand("<cword>"):gsub("^%$", "")
    if word == "" then
        return
    end

    local current_buf = vim.api.nvim_buf_get_name(0)

    -- If currently inside an ide-helper generated file
    if current_buf:match("_ide_helper") then
        -- 1. Search for the class name around the current cursor location
        local class_line_num = vim.fn.search([[class\s\+\(ide_helper_\)\?\([A-Za-z0-9_]\+\)]], "nW")
        local class_name = nil

        if class_line_num > 0 then
            local line_text = vim.fn.getline(class_line_num)
            class_name = line_text:match("class%s+ide_helper_([%w_]+)") or line_text:match("class%s+([%w_]+)")
        end

        -- If not found downwards, search upwards
        if not class_name then
            class_line_num = vim.fn.search([[class\s\+\(ide_helper_\)\?\([A-Za-z0-9_]\+\)]], "bnW")
            if class_line_num > 0 then
                local line_text = vim.fn.getline(class_line_num)
                class_name = line_text:match("class%s+ide_helper_([%w_]+)") or line_text:match("class%s+([%w_]+)")
            end
        end

        if not class_name then
            vim.notify("Could not determine Model class from ide-helper", vim.log.levels.WARN)
            return
        end

        -- 2. Locate the actual Model file in the app directory
        local matches = vim.fn.glob("app/**/" .. class_name .. ".php", false, true)
        if #matches == 0 then
            matches = vim.fn.glob("**/" .. class_name .. ".php", false, true)
        end

        if #matches == 0 then
            vim.notify("Model file " .. class_name .. ".php not found", vim.log.levels.WARN)
            return
        end

        -- 3. Open the actual Model file buffer
        vim.cmd("edit " .. vim.fn.fnameescape(matches[1]))
    end

    -- Search for the accessor inside the active model buffer
    local pascal = word:gsub("_(%l)", function(c)
        return c:upper()
    end):gsub("^%l", function(c)
        return c:upper()
    end)

    local camel = pascal:sub(1, 1):lower() .. pascal:sub(2)
    local pattern = "\\(get" .. pascal .. "Attribute\\|function\\s\\+" .. camel .. "\\)"
    local line = vim.fn.search(pattern, "wn")

    if line > 0 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd("normal! zz")
    else
        vim.notify("No accessor method found for: " .. word .. " in " .. vim.fn.expand("%:t"), vim.log.levels.WARN)
    end
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

return M
