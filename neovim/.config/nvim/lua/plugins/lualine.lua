return {
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            -- 1. Define the Git project-wide status function scoped to the current buffer
            local function git_project_status()
                -- Get the full path of the current buffer
                local buf_name = vim.api.nvim_buf_get_name(0)
                if buf_name == "" then
                    return ""
                end

                -- Extract the directory path of the current file
                local buf_dir = vim.fs.dirname(buf_name)
                if not buf_dir then
                    return ""
                end

                -- Check if the buffer's directory is inside a git repo using git -C
                local is_git = os.execute(
                    string.format(
                        "git -C %s rev-parse --is-inside-work-tree >/dev/null 2>&1",
                        vim.fn.shellescape(buf_dir)
                    )
                )
                if is_git ~= 0 then
                    return ""
                end

                -- Run git status from the buffer's directory and count lines
                local cmd =
                    string.format("git -C %s status --porcelain 2>/dev/null | wc -l", vim.fn.shellescape(buf_dir))
                local handle = io.popen(cmd)
                if not handle then
                    return ""
                end

                local result = handle:read("*a")
                handle:close()

                local count = tonumber(result:match("%d+"))
                if count and count > 0 then
                    -- This icon 󰊢 represents a Git branch/repo
                    return "󰊢 " .. count
                end
                return ""
            end

            -- 2. Add the Git counter to the left side (next to branch name)
            table.insert(opts.sections.lualine_b, {
                git_project_status,
                color = { fg = "#ff9e64", gui = "bold" }, -- Orange color similar to VSCode
                padding = { left = 1, right = 1 },
            })

            -- 3. Keep your existing encoding component on the right
            table.insert(opts.sections.lualine_x, "encoding")

            -- 4. Replace LazyVim's default `{ "filetype", icon_only = true }`
            --    statusline component (a mini.icons glyph) with the real-icons
            --    component. real-icons' own lualine integration is disabled in
            --    lua/plugins/icons.lua (it clobbers this section on every
            --    ColorScheme event), so we insert the icon ourselves. The
            --    `real_icons_lualine` marker key is kept as a guard: it makes
            --    real-icons.integrations.lualine.has_real_icon detect this
            --    component and skip auto-insertion, so exactly one icon is
            --    shown: a real terminal image on Ghostty/Kitty, or real-icons'
            --    glyph fallback elsewhere.
            local lualine_c = opts.sections.lualine_c
            for i, component in ipairs(lualine_c) do
                if type(component) == "table" and component[1] == "filetype" and component.icon_only then
                    table.remove(lualine_c, i)
                    table.insert(lualine_c, i, {
                        function()
                            local ok, integration = pcall(require, "real-icons.integrations.lualine")
                            if ok then
                                return integration.component()
                            end
                            return ""
                        end,
                        real_icons_lualine = true,
                        color = nil,
                        -- The real component already supplies its leading space.
                        padding = { left = 1, right = 0 },
                        separator = "",
                    })
                    break
                end
            end

        end,
    },
}
