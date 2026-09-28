return {
    {
        "Mirsmog/real-icons.nvim",
        -- Renders file/folder icons as real terminal images through the Kitty
        -- Graphics Protocol (Ghostty/Kitty). Other terminals (WezTerm,
        -- Neovide, Windows Terminal, ...) automatically fall back to the
        -- mini.icons glyph provider, so Lucide/Nerd Font icons keep working.
        --
        -- Icons come from the Flow Icons VS Code theme, which the lazy build
        -- step installs (once) into lazyvim's real-icons pack directory.
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
            integrations = {
                bufferline = true,
                lualine = true,
                snacks_picker = true,
                telescope = true,
            },
        },
    },
}
