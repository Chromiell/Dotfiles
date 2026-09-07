return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                intelephense = {
                    enabled = true,
                    filetypes = { "php" },
                    on_attach = function(client, _)
                        client.server_capabilities.renameProvider = false
                    end,
                    settings = {
                        intelephense = {
                            diagnostics = {
                                enable = true,
                                pcreMetaUsage = false,
                                undefinedTypes = false,
                                undefinedFunctions = true,
                                undefinedConstants = true,
                                undefinedClassConstants = false,
                                undefinedMethods = true,
                                undefinedProperties = false,
                                unusedSymbols = true,
                            },
                            format = { enabled = false },
                            stubs = {
                                "Core",
                                "PDO",
                                "Phar",
                                "Reflection",
                                "SimpleXML",
                                "apache",
                                "bcmath",
                                "bz2",
                                "calendar",
                                "curl",
                                "date",
                                "dom",
                                "filter",
                                "gd",
                                "gettext",
                                "hash",
                                "iconv",
                                "imap",
                                "intl",
                                "json",
                                "libxml",
                                "mbstring",
                                "mcrypt",
                                "mysql",
                                "mysqli",
                                "openssl",
                                "password",
                                "pcntl",
                                "pcre",
                                "pdo_mysql",
                                "readline",
                                "recode",
                                "session",
                                "snmp",
                                "soap",
                                "sockets",
                                "standard",
                                "superglobals",
                                "tokenizer",
                                "xdebug",
                                "xml",
                                "xmlreader",
                                "xmlwriter",
                                "zip",
                                "zlib",
                            },
                            files = { maxSize = 5000000 },
                        },
                    },
                },

                -- Phpactor configured for Code Actions, CodeLens, and Rename ONLY
                phpactor = {
                    enabled = true,
                    cmd = { "phpactor", "language-server", "-q" },
                    handlers = {
                        -- Mute Phpactor diagnostics so they don't duplicate Intelephense
                        ["textDocument/publishDiagnostics"] = function() end,
                    },
                    on_attach = function(client, _)
                        local capabilities_to_disable = {
                            "completionProvider",
                            "hoverProvider",
                            "definitionProvider",
                            "signatureHelpProvider",
                            "referencesProvider",
                            "documentHighlightProvider",
                            "documentSymbolProvider",
                            "implementationProvider",
                            "typeDefinitionProvider",
                            "declarationProvider",
                        }

                        for _, cap in ipairs(capabilities_to_disable) do
                            client.server_capabilities[cap] = false
                        end
                    end,
                },
            },
        },
    },

    {
        "mfussenegger/nvim-lint",
        opts = { linters_by_ft = { php = {} } },
    },
    {
        "nvimtools/none-ls.nvim",
        optional = true,
        opts = function(_, opts)
            if opts.sources then
                opts.sources = vim.tbl_filter(function(source)
                    return source.name ~= "phpcs"
                end, opts.sources)
            end
        end,
    },
}
