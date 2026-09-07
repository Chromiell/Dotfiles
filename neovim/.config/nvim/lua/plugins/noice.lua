-- This file is for customizing the noice plugin.
-- It adds a route to skip notifications with the message "No information available".
return {
    {
        "folke/noice.nvim",
        opts = function(_, opts)
            opts.routes = opts.routes or {}
            table.insert(opts.routes, {
                filter = {
                    event = "notify",
                    find = "No information available",
                },
                opts = { skip = true },
            })
        end,
    },
}
