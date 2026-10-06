return {
    -- 1. Ensure Mason installs the tool
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                "sql-formatter",
                "xmlformatter",
                "djlint",
            },
        },
    },

    -- 2. Configure Conform to use it
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                bash = { "shfmt" },
                sh = { "shfmt" },
                zsh = { "shfmt" },
                json = { "prettier" },
                jsonc = { "prettier_jsonc" },
                sql = { "sql_formatter_custom" },
                html = { "prettier_html" },
                xml = { "xmlformatter" },
                yaml = { "prettier_yaml" },
                yml = { "prettier_yaml" },
                twig = { "djlint" },
            },
            formatters = {
                djlint = {
                    prepend_args = { "--indent", "4" },
                },
                sql_formatter_custom = {
                    command = "sql-formatter",
                    args = {
                        "-l",
                        "mariadb",
                        "-c",
                        '{"keywordCase": "upper", "tabWidth": 4, "useTabs": false}',
                    },
                    stdin = true,
                },
                shfmt = {
                    prepend_args = { "-i", "4", "-ci" },
                },
                prettier_html = {
                    command = "prettier",
                    args = {
                        "--print-width",
                        "9999",
                        "--html-whitespace-sensitivity",
                        "ignore",
                        "--bracket-same-line",
                        "--tab-width",
                        "4",
                        "--stdin-filepath",
                        "$FILENAME",
                    },
                },
                xmlformatter = {
                    prepend_args = { "--indent", "4" },
                },
                -- JSONC uses Prettier's dedicated `jsonc` parser (Prettier >= 3.2)
                -- so comments are preserved, unlike the strict `json` parser used
                -- for plain `.json` files. The jsonc parser also respects
                -- `trailingComma` (default "all"), so `--trailing-comma none`
                -- strips the trailing commas it would otherwise keep or insert.
                prettier_jsonc = {
                    command = "prettier",
                    args = {
                        "--parser",
                        "jsonc",
                        "--trailing-comma",
                        "none",
                        "--tab-width",
                        "4",
                        "--use-tabs",
                        "false",
                        "--stdin-filepath",
                        "$FILENAME",
                    },
                },
                -- General Prettier formatter (js/ts/css/html/markdown/json/...)
                prettier = {
                    prepend_args = { "--tab-width", "4", "--use-tabs", "false" },
                },
                -- Custom 2-space formatter specifically for YAML files
                prettier_yaml = {
                    command = "prettier",
                    args = {
                        "--tab-width",
                        "2",
                        "--stdin-filepath",
                        "$FILENAME",
                    },
                },
            },
        },
    },

    -- 3. Disable dadbod-ui
    { "kristijanhusak/vim-dadbod-ui", enabled = false },
}
