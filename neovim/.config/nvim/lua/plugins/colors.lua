-- This plugin highlights color codes in the text with their actual color
return {
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = {
            filetypes = { "*" },
            options = {
                parsers = {
                    hex = { default = true }, -- Enables #RGB, #RRGGBB, #RRGGBBAA, etc.
                    css = true, -- Enables CSS features & variable parsing
                    css_fn = true, -- Enables rgb(), hsl(), etc.
                    tailwind = { enable = true }, -- Enables Tailwind CSS utility classes
                    names = {
                        enable = true,
                        custom = {
                            -- Bootstrap 5 Default Colors
                            ["bg-primary"] = "#0d6efd",
                            ["text-primary"] = "#0d6efd",
                            ["bg-secondary"] = "#6c757d",
                            ["text-secondary"] = "#6c757d",
                            ["bg-success"] = "#198754",
                            ["text-success"] = "#198754",
                            ["bg-danger"] = "#dc3545",
                            ["text-danger"] = "#dc3545",
                            ["bg-warning"] = "#ffc107",
                            ["text-warning"] = "#ffc107",
                            ["bg-info"] = "#0dcaf0",
                            ["text-info"] = "#0dcaf0",
                            ["bg-light"] = "#f8f9fa",
                            ["text-light"] = "#f8f9fa",
                            ["bg-dark"] = "#212529",
                            ["text-dark"] = "#212529",
                        },
                    },
                },
                display = {
                    mode = "virtualtext", -- "foreground", "background", "underline" or "virtualtext"
                    virtualtext = {
                        char = "", -- character used for virtualtext
                        position = "before", -- "eol"|"before"|"after"
                        hl_mode = "foreground", -- "background"|"foreground"
                    },
                },
            },
        },
    },
}
