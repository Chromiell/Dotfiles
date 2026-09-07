return {
    "stevearc/conform.nvim",
    opts = {
        default_format_opts = {
            timeout_ms = 30000,
            lsp_format = "fallback",
        },
        formatters = {
            php_cs_fixer = {
                command = "php-cs-fixer",
                timeout_ms = 30000,
                args = {
                    "fix",
                    "--config=" .. vim.fn.expand("~/.config/php-cs-fixer/.php-cs-fixer.php"),
                    "--using-cache=no",
                    "$FILENAME",
                },
                stdin = false,
            },
        },
        formatters_by_ft = {
            php = { "php_cs_fixer" },
        },
    },
}
