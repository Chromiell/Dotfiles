return {
    {
        "folke/snacks.nvim",
        -- Defining `config` overrides LazyVim's own snacks config, so the
        -- `vim.notify` restore hack from LazyVim must be reproduced here.
        config = function(_, opts)
            local notify = vim.notify
            require("snacks").setup(opts)
            if LazyVim.has("noice.nvim") then
                vim.notify = notify
            end

            -- snacks' built-in tmux workaround for the TermResponse bug
            -- (folke/snacks.nvim#2332) only runs when a `tmux` binary exists
            -- *and* `extended-keys` is exactly `on` (that is the only value its
            -- guard matches). Neovim here runs inside the `arch-nvidia`
            -- distrobox container, which has no `tmux`, so the workaround never
            -- runs and the XTVERSION probe reply (e.g. "kitty(0.48.2)") leaks
            -- into the input buffer -- visible in the picker prompt. When the
            -- native workaround is unusable, pre-seed the detection with what
            -- it would have produced so no probe is ever sent. On the host (or
            -- if `tmux` is installed in the container with `extended-keys on`)
            -- this is skipped and snacks handles it natively.
            local snacks_tmux_ok = false
            if vim.fn.executable("tmux") == 1 then
                local ok, out = pcall(vim.fn.system, { "tmux", "show", "-g", "extended-keys" })
                snacks_tmux_ok = ok and vim.trim(out):find(" on$") ~= nil
            end
            if vim.env.TMUX and vim.env.KITTY_WINDOW_ID and not snacks_tmux_ok then
                local ok, term = pcall(require, "snacks.image.terminal")
                if ok then
                    term.transform = function(data)
                        return ("\27Ptmux;" .. data:gsub("\27", "\27\27")) .. "\27\\"
                    end
                    term._terminal = {
                        terminal = "kitty",
                        version = "unknown",
                        supported = true,
                        placeholders = true,
                    }
                end
            end
        end,
        opts = {
            dashboard = {
                preset = {
                    header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

[ by @chromiell ]
                    ]],
                },
            },
            picker = {
                -- 1. Register badge character 'c' in the top title bar
                toggles = {
                    case_sens = "c",
                },
                sources = {
                    explorer = {
                        hidden = true, -- Show hidden files (dotfiles)
                        ignored = true, -- Show files ignored by .gitignore
                        exclude = { ".git" },
                    },
                },
                -- 2. Define custom toggle action
                actions = {
                    ---@diagnostic disable-next-line: inject-field
                    toggle_live_case_sens = function(picker)
                        -- Toggle state flag for 'c' badge
                        picker.opts.case_sens = not picker.opts.case_sens
                        local is_case_sens = picker.opts.case_sens

                        if picker.opts.live then
                            -- GREP SEARCH: Modify ripgrep CLI arguments
                            picker.opts.args = picker.opts.args or {}
                            local case_sensitive, ignore_case = "--case-sensitive", "--ignore-case"

                            local new_args = {}
                            for _, arg in ipairs(picker.opts.args) do
                                if arg ~= case_sensitive and arg ~= ignore_case then
                                    table.insert(new_args, arg)
                                end
                            end

                            if is_case_sens then
                                table.insert(new_args, case_sensitive)
                            end

                            picker.opts.args = new_args
                            picker:find({ refresh = true })
                        else
                            -- FILE SEARCH: Simulate pressing <Ctrl+g> directly in Neovim
                            local ctrl_g = vim.api.nvim_replace_termcodes("<C-g>", true, false, true)
                            vim.api.nvim_feedkeys(ctrl_g, "m", false)

                            -- Update text with (?-i) and position cursor at the end after keypress processes
                            vim.schedule(function()
                                local buf = picker.input and picker.input.win and picker.input.win.buf
                                local win = picker.input and picker.input.win and picker.input.win.win

                                if buf and vim.api.nvim_buf_is_valid(buf) then
                                    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
                                    local prefix = "(?-i)"
                                    local new_line = line

                                    if is_case_sens then
                                        if line:sub(1, #prefix) ~= prefix then
                                            new_line = prefix .. line
                                        end
                                    else
                                        if line:sub(1, #prefix) == prefix then
                                            new_line = line:sub(#prefix + 1)
                                        end
                                    end

                                    -- Update input prompt line
                                    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { new_line })

                                    -- Position cursor at the very end of the search query
                                    if win and vim.api.nvim_win_is_valid(win) then
                                        vim.api.nvim_win_set_cursor(win, { 1, #new_line })
                                    end
                                end
                            end)
                        end
                    end,
                },
                win = {
                    input = {
                        keys = {
                            -- Scroll preview window with PageUp/PageDown
                            ["<PageDown>"] = { "preview_scroll_down", mode = { "i", "n" } },
                            ["<PageUp>"] = { "preview_scroll_up", mode = { "i", "n" } },

                            -- Bind Alt+c to toggle case sensitivity
                            ["<a-c>"] = {
                                "toggle_live_case_sens",
                                desc = "Toggle Case Sensitivity",
                                mode = { "i", "n" },
                            },
                        },
                    },
                },
            },
        },
    },
}
