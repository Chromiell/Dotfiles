return {
    "jake-stewart/multicursor.nvim",
    config = function()
        local mc = require("multicursor-nvim")
        mc.setup()

        local set = vim.keymap.set

        -- 1. Register the Which-Key group for BOTH Normal and Visual modes
        local wk = require("which-key")
        wk.add({
            {
                "<leader>m",
                group = "Multi-cursor / Marks",
                icon = { icon = "", color = "cyan" },
                mode = { "n", "v" },
            },
        })

        -- 2. The Keymap Layer
        -- This layer is ONLY active when multiple cursors exist.
        mc.addKeymapLayer(function(layerSet)
            -- Allow the leader key to pass through to Which-Key
            layerSet({ "n", "v" }, "<leader>", function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>", true, true, true), "m", true)
            end)

            -- Ensure Escape still clears cursors inside the layer
            layerSet("n", "<Esc>", mc.clearCursors)
        end)

        -- 3. Standard Mappings
        ---@section Add Cursors
        set({ "n", "v" }, "<leader>mj", function()
            mc.addCursor("j")
        end, { desc = "Add cursor below" })
        set({ "n", "v" }, "<leader>mk", function()
            mc.addCursor("k")
        end, { desc = "Add cursor above" })
        -- The "Selection to Cursors" key
        set("v", "<leader>mi", mc.addCursorOperator, { desc = "Add cursors to selection" })
        ---@section Word Matching
        -- This mimics the VSCode Ctrl+D behavior
        set({ "n", "v" }, "<C-n>", function()
            mc.matchAddCursor(1)
        end, { desc = "Select next occurrence" })

        -- Optional: Use Ctrl+Shift+D to skip the current match and move to the next
        set({ "n", "v" }, "<C-S-n>", function()
            mc.matchSkipCursor(1)
        end, { desc = "Skip and select next occurrence" })

        ---@section Word Matching
        set({ "n", "v" }, "<leader>mn", function()
            mc.matchAddCursor(1)
        end, { desc = "Match next word" })
        set({ "n", "v" }, "<leader>mN", function()
            mc.matchSkipCursor(1)
        end, { desc = "Skip next word" })
        set({ "n", "v" }, "<leader>ma", mc.matchAllAddCursors, { desc = "Match all occurrences" })

        ---@section Management
        set({ "n", "v" }, "<leader>mx", mc.clearCursors, { desc = "Delete all cursors" })
        set({ "n", "v" }, "<leader>mh", mc.nextCursor, { desc = "Focus next cursor" })
        set({ "n", "v" }, "<leader>ml", mc.prevCursor, { desc = "Focus prev cursor" })

        ---@section The Escape Hatch (For when only 1 cursor is active)
        set("n", "<Esc>", function()
            if not mc.cursorsEnabled() then
                mc.enableCursors()
            elseif mc.hasCursors() then
                mc.clearCursors()
            else
                vim.cmd("noh")
            end
        end, { desc = "Clear cursors / Escape" })
    end,
}
