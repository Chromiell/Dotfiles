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
                args = function(ctx)
                    -- Search upward from the active file's directory for a project config
                    local local_config = vim.fs.find({ ".php-cs-fixer.php", ".php-cs-fixer.dist.php" }, {
                        upward = true,
                        path = ctx.dirname,
                    })[1]

                    local config_path = local_config or vim.fn.expand("~/.config/php-cs-fixer/.php-cs-fixer.php")

                    return {
                        "fix",
                        "--config=" .. config_path,
                        "--using-cache=no",
                        "$FILENAME",
                    }
                end,
                stdin = false,
            },
        },
        formatters_by_ft = {
            php = { "php_cs_fixer" },
        },
    },
}
