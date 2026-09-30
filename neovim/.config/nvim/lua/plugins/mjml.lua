-- MJML (Mailjet Markup Language) support — https://mjml.io
--
-- Neovim ships no dedicated MJML treesitter parser and MJML publishes no
-- standalone language server, so `.mjml` files are made first-class by reusing
-- the Blade tooling LazyVim already provides:
--
--   * `vim.filetype.add` detects `.mjml` as its own `mjml` filetype, giving it
--     a dedicated statusline entry, file icon and autocmds.
--   * `vim.treesitter.language.register("blade", "mjml")` binds that filetype to
--     the `blade` parser, so highlighting, Blade directives, indentation,
--     folding and vim-matchup work out of the box.
--   * `ts-autotag` is taught about the filetype in `lua/plugins/autotag.lua`,
--     and `lua/config/autocmds.lua` sets the comment string.
--
-- Why Blade and not HTML? MJML templates used in Laravel are Blade files, and
-- the plain `html` grammar treats a bare `>` inside text as fatal: every Blade
-- arrow (`{{ $model->relation }}`) makes it wrap the whole document in a single
-- ERROR node, so no `tag_name`/`attribute` nodes survive and only the tag
-- delimiters keep a colour (the symptom: highlighting "stops" after the first
-- lines). The `blade` grammar is a superset that parses those expressions and
-- keeps the element tree intact. It inherits the `html` queries, so
-- `after/queries/html/injections.scm` (which highlights `<mj-style>` contents
-- as CSS) still applies.
--
-- Both registrations run at spec load (startup), before any buffer is opened,
-- so even the very first `.mjml` file is detected correctly.
vim.filetype.add({ extension = { mjml = "mjml" } })
vim.treesitter.language.register("blade", "mjml")

return {
    {
        -- The Blade parser is MJML's highlighting/indentation engine.
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, { "blade", "html" })
            end
        end,
    },
}
