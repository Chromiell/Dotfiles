-- Jump from a middleware alias string to the class that implements it.
--
-- laravel.nvim's built-in `gf` (lua/laravel/services/gf.lua) only resolves
-- view() / config() / env() / route() / inertia() arguments, so a line like
--     Route::middleware('elearning.reset-password')->group(...)
-- cannot be followed. This module fills that gap and is wired into the `gf`
-- keymap in lua/plugins/laravel.lua.
--
-- Resolution is runtime-authoritative, not source-parsed:
--   * the alias => class map is read from the booted app's router
--     (`app('router')->getMiddleware()`), so it matches exactly what Laravel
--     uses, including aliases registered in `bootstrap/app.php`;
--   * the class file/line is located with laravel.nvim's own `class_finder`
--     (PHP reflection), which also works for vendor middleware.
--
-- Requires the `nvim-treesitter` php parser for alias detection. When the
-- cursor is not on a middleware argument, detection returns nil and the caller
-- falls back to laravel.nvim's normal `gf`.

local M = {}

--- Return the middleware alias under the cursor, or nil.
--- The cursor must sit on a string argument of a `middleware(...)` call
--- (either `Route::middleware(...)` or `->middleware(...)`).
--- @return string|nil
function M.alias_under_cursor()
    local buf = vim.api.nvim_get_current_buf()

    -- `get_node` can return nil before a tree exists (e.g. when treesitter
    -- highlighting is disabled); parse lazily (no-op when already parsed).
    local pok, parser = pcall(vim.treesitter.get_parser, buf)
    if pok and parser then
        pcall(parser.parse, parser)
    end

    local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
    if not ok or not node or node:type() ~= "string_content" then
        return nil
    end

    local parent = node:parent()
    while parent do
        local ptype = parent:type()
        if
            ptype == "function_call_expression"
            or ptype == "scoped_call_expression"
            or ptype == "member_call_expression"
        then
            local name = parent:field("name")[1]
            if name and vim.treesitter.get_node_text(name, buf) == "middleware" then
                return vim.treesitter.get_node_text(node, buf)
            end
            return nil
        end
        parent = parent:parent()
    end

    return nil
end

--- Resolve `alias` to its middleware class and open it asynchronously.
--- @param alias string
function M.goto_alias(alias)
    local nio = require("nio")

    nio.run(function()
        local app = require("laravel.core.app")
        local notify = require("laravel.utils.notify")

        local res, err = app("laravel.services.code"):run([[
            echo json_encode([
                'aliases' => app('router')->getMiddleware(),
                'groups'  => array_keys(app('router')->getMiddlewareGroups()),
            ]);
        ]])

        if err then
            return notify.error("Laravel: could not read middleware aliases: " .. err:toString())
        end

        -- A middleware string may carry parameters, e.g. `auth:attendee,user`.
        local name = alias:match("^[^:]+") or alias

        local class = res and res.aliases and res.aliases[name]
        if not class then
            if res and res.groups and vim.tbl_contains(res.groups, name) then
                return notify.info(("Laravel: '%s' is a middleware group, not an alias"):format(name))
            end
            if name:find("\\", 1, true) then
                class = name -- already an FQCN, no alias indirection
            else
                return notify.warn(("Laravel: middleware alias '%s' not found"):format(name))
            end
        end

        local found, ferr = app("laravel.services.class_finder"):find(class)
        if ferr or not found or not found.file then
            return notify.error(("Laravel: could not locate class %s"):format(class))
        end

        nio.scheduler()
        if pcall(vim.cmd.edit, found.file) then
            pcall(vim.api.nvim_win_set_cursor, 0, { found.line or 1, 0 })
            pcall(vim.cmd.normal, "zt")
            -- Force a repaint: when the edit lands while Neovim is idle, the
            -- new buffer can otherwise stay unpainted until the next keypress.
            pcall(vim.cmd, "redraw")
        end
    end)
end

return M
