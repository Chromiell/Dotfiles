-- Checks whether a newer Flow Icons release exists on Open VSX and, if so,
-- runs the installer (which replaces the pack) in the background.
-- Silent by design: exits quietly on network failure or API errors and never
-- touches the UI unless a real update was applied.
local function get_pack_version()
    local file = vim.fn.expand("~/.local/share/nvim/real-icons/packs/flow-icons/package.json")
    if vim.fn.filereadable(file) == 0 then
        return nil
    end
    local content = table.concat(vim.fn.readfile(file), "\n")
    return (content:match('"version"%s*:%s*"(.-)"'))
end

-- Numeric semver-style compare; returns a<=b style -1/0/1. Tolerates
-- prerelease suffixes by comparing only dot-separated numeric components
-- ("2.1.0-rc1" compares as 2.1.0).
local function pack_version_compare(a, b)
    if a == b then
        return 0
    end
    if not (a and b) then
        return a and 1 or -1
    end
    local function split(v)
        local t = {}
        for part in v:gmatch("%d+") do
            t[#t + 1] = tonumber(part) -- only numeric components
        end
        return t
    end
    local pa, pb = split(a), split(b)
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then
            return x < y and -1 or 1
        end
    end
    return 0
end

local function notify_update(new_version)
    vim.notify(
        ("Flow Icons updated to v%s — restart Neovim to see the new icons."):format(new_version),
        vim.log.levels.INFO,
        { title = "real-icons.nvim" }
    )
end

local check_done = false
local function check_for_update()
    if check_done or vim.fn.executable("curl") == 0 then
        return
    end
    check_done = true

    vim.system(
        { "curl", "-fsSL", "--max-time", "15", "https://open-vsx.org/api/thang-nm/flow-icons/latest" },
        { text = true },
        function(result)
            vim.schedule(function()
                if result.code ~= 0 or not result.stdout or result.stdout == "" then
                    return -- offline or API error: stay silent, keep current pack
                end
                local latest = result.stdout:match('"version"%s*:%s*"(.-)"')
                if not latest then
                    return
                end
                local current = get_pack_version()
                if current and pack_version_compare(latest, current) <= 0 then
                    return -- up to date
                end
                -- Newer version available: run the installer in the background.
                local script = vim.fn.expand("~/.config/nvim/scripts/install-flow-icons.sh")
                vim.system({ "sh", script }, { text = true }, function(res)
                    vim.schedule(function()
                        if res.code == 0 then
                            notify_update(latest)
                        end
                        -- Non-zero exit codes mean the download failed; the
                        -- old pack is preserved, so staying silent is safe.
                    end)
                end)
            end)
        end
    )
end

-- Locate a tmux binary. Neovim runs inside the Arch Distrobox container, which
-- has no tmux of its own, but the host binary is executable there (distrobox
-- mounts the host filesystem under /run/host).
local function tmux_executable()
    if vim.fn.executable("tmux") == 1 then
        return "tmux"
    end
    for _, candidate in ipairs({ "/run/host/usr/bin/tmux", "/run/host/bin/tmux" }) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
end

-- real-icons can only query the tmux client term when a tmux binary is on
-- PATH. Inside the container there is none, so it falls back to environment
-- variables inherited from whichever terminal started the tmux server. That
-- makes a session started in Kitty keep claiming image support after the user
-- attaches from a terminal that cannot draw Kitty graphics (e.g. Windows
-- Terminal), leaving empty placeholder cells instead of glyph icons. Query the
-- attached client with the host binary and force the backend to match it.
local function tmux_opts(opts)
    if not vim.env.TMUX or vim.env.TMUX == "" then
        return opts
    end

    local tmux = tmux_executable()
    if not tmux then
        return opts
    end

    local ok, output = pcall(vim.fn.system, { tmux, "display-message", "-p", "#{client_termname}" })
    if not ok or vim.v.shell_error ~= 0 then
        return opts -- detached session or query failed: leave detection alone
    end

    local term = vim.trim(output):lower()
    if term == "" then
        return opts
    end

    local supported = term:find("kitty", 1, true) ~= nil or term:find("ghostty", 1, true) ~= nil
    return vim.tbl_deep_extend("force", opts, { backend = supported and "kitty" or false })
end

-- Kitty graphics belong to the alternate screen, so detaching a tmux client
-- makes the terminal drop the uploaded images, and tmux cannot replay Kitty
-- passthrough graphics on attach. real-icons.nvim caches uploaded image ids,
-- so it never notices. The tmux config signals `real-icons-reattach` from its
-- client-attached hook; wait on that channel, then re-run setup to clear the
-- upload cache, re-detect the attached client and retransmit the icons.
local function watch_tmux_reattach(opts)
    if not vim.env.TMUX or vim.env.TMUX == "" then
        return
    end

    local tmux = tmux_executable()
    if not tmux then
        return
    end

    local waiter
    local function arm()
        waiter = vim.system({ tmux, "wait-for", "real-icons-reattach" }, {}, function(result)
            if result.code ~= 0 then
                return -- tmux server gone: stop watching
            end
            vim.schedule(function()
                -- Let tmux finish painting the reattached client first.
                vim.defer_fn(function()
                    require("real-icons").setup(tmux_opts(opts))
                    arm()
                end, 100)
            end)
        end)
    end
    arm()

    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("RealIconsTmuxReattach", { clear = true }),
        callback = function()
            if waiter then
                pcall(waiter.kill, waiter)
            end
        end,
    })
end

return {
    {
        "Mirsmog/real-icons.nvim",
        -- Renders file/folder icons as real terminal images through the Kitty
        -- Graphics Protocol (Ghostty/Kitty). Other terminals (WezTerm,
        -- Neovide, Windows Terminal, ...) automatically fall back to the
        -- mini.icons glyph provider, so Nerd Font icons keep working.
        --
        -- Icons come from the Flow Icons VS Code theme, which the lazy build
        -- step installs into lazyvim's real-icons pack directory. The build
        -- script resolves the latest version, and a background check at
        -- startup upgrades the pack when a newer release is published.
        -- Run `:RealIcons packs` to preview and switch installed packs.
        build = "sh ~/.config/nvim/scripts/install-flow-icons.sh",
        opts = {
            -- Explicit pack wins over the :RealIcons packs saved selection.
            pack = "flow",
            packs = {
                flow = {
                    type = "vscode",
                    path = vim.fn.expand("~/.local/share/nvim/real-icons/packs/flow-icons"),
                    theme = "flow-deep", -- Flow Dim / Deep / Dawn / You
                },
            },
            -- Images are scaled to fill the reserved 2x1 cell area, so the
            -- visible glyph size is tuned with transparent padding (in PNG
            -- pixels, out of the 64px canvas), not with `pixels` (sharpness).
            -- Each padding point shrinks the icon ~3% per side; 2 is subtle.
            size = {
                padding = 7,
            },
            integrations = {
                bufferline = true,
                -- Disabled on purpose: real-icons' lualine integration patches
                -- `lualine.setup`, and lualine re-runs `setup()` with no
                -- arguments on every ColorScheme event. With no config passed,
                -- the integration injects its own default
                -- `{ icon, "filename" }` lualine_c section, clobbering ours
                -- (losing root_dir/diagnostics/pretty_path and turning the
                -- filename grey). We already insert the real-icons component
                -- manually in lua/plugins/lualine.lua, so the auto-integration
                -- is redundant; disabling it keeps our sections intact across
                -- colorscheme changes.
                lualine = false,
                snacks_picker = true,
                telescope = true,
            },
        },
        config = function(_, opts)
            require("real-icons").setup(tmux_opts(opts))
            watch_tmux_reattach(opts)

            -- Only check once per session, and only once the UI is up.
            vim.api.nvim_create_autocmd("UIEnter", {
                once = true,
                callback = function()
                    check_for_update()
                end,
            })
        end,
    },
}
