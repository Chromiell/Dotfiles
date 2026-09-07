return {
    {
        "tronikelis/ts-autotag.nvim",
        opts = {
            auto_rename = {
                enabled = true, -- Enables live renaming of paired tags
            },
            -- Explicitly tell the plugin which filetypes to watch
            filetypes = {
                "html",
                "javascript",
                "typescript",
                "javascriptreact",
                "typescriptreact",
                "svelte",
                "vue",
                "xml",
                "php",
            },
        },
    },
    -- Explicitly kill the old plugin so Lazy stops auto-loading it
    { "windwp/nvim-ts-autotag", enabled = false },
}
