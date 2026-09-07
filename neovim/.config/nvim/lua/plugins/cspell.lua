local cspell_config = {
    version = "0.2",
    import = {
        "https://cdn.jsdelivr.net/npm/@cspell/dict-it-it/cspell-ext.json",
    },
    language = "en,it",
    -- Note: Omitting an empty "words" array because Lua empty tables {}
    -- can sometimes encode as JSON objects instead of arrays.
    ignorePaths = { "node_modules/**", ".git/**", "vendor/**" },
}

-- Generate the JSON file on the fly inside Neovim's data directory
local config_path = vim.fn.stdpath("data") .. "/cspell_inline.json"
local file = io.open(config_path, "w")
if file then
    file:write(vim.json.encode(cspell_config))
    file:close()
end

return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                cspell_ls = {
                    cmd = {
                        "cspell-lsp",
                        "--stdio",
                        "--config",
                        config_path,
                    },
                    root_markers = { ".git", "cspell.json" },
                },
            },
        },
    },
}
