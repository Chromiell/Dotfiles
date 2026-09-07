return {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
        -- Ensure the nested tables exist
        opts.indent = opts.indent or {}
        opts.indent.enable = true

        -- Force the disable list to be a table and include "php"
        if type(opts.indent.disable) ~= "table" then
            opts.indent.disable = { "php" }
        else
            -- Only insert if it's not already there to prevent table bloating
            local found = false
            for _, lang in ipairs(opts.indent.disable) do
                if lang == "php" then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(opts.indent.disable, "php")
            end
        end
    end,
}
