return {
    {
        "akinsho/bufferline.nvim",
        opts = function(_, opts)
            -- LazyVim ships its own `options.get_element_icon`, which returns a
            -- plain mini.icons glyph keyed only on the buffer's filetype.
            -- real-icons' automatic bufferline integration *adds* its own
            -- `get_element_icon`, but it merges it with the user config as
            -- `vim.tbl_deep_extend("force", real_icons_opts, user_opts)` — the
            -- user config wins, so LazyVim's callback always shadows real-icons
            -- and the tabs keep the default LazyVim icons.
            --
            -- Point the option at real-icons' callback explicitly. It resolves
            -- the actual file (not just the filetype), renders a real terminal
            -- image when the terminal supports the Kitty Graphics Protocol
            -- (Ghostty/Kitty), and transparently falls back to the mini.icons
            -- glyph elsewhere — the same code path used by every other
            -- real-icons integration.
            local ok, integration = pcall(require, "real-icons.integrations.bufferline")
            if not ok then
                return
            end

            opts.options = opts.options or {}
            opts.options.color_icons = true
            opts.options.get_element_icon = integration.get_element_icon
        end,
    },
}
