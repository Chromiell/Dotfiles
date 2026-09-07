return {
    {
        "mfussenegger/nvim-dap",
        opts = function()
            local dap = require("dap")
            -- Automatically center the screen (zz) whenever the debugger stops on a line
            dap.listeners.after.event_stopped["center_view"] = function()
                vim.schedule(function()
                    vim.cmd("normal! zz")
                end)
            end
        end,
        keys = {
            -- F-key mappings
            {
                "<F5>",
                function()
                    require("dap").continue()
                end,
                desc = "Debug: Start/Continue",
            },
            {
                "<F9>",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "Debug: Toggle Breakpoint",
            },
            {
                "<F10>",
                function()
                    require("dap").step_over()
                    vim.cmd("normal! zz")
                end,
                desc = "Debug: Step Over",
            },
            {
                "<F11>",
                function()
                    require("dap").step_into()
                end,
                desc = "Debug: Step Into",
            },
            {
                "<F12>",
                function()
                    require("dap").step_out()
                end,
                desc = "Debug: Step Out",
            },

            -- Custom Toggle Mappings
            {
                "<leader>dW",
                function()
                    require("dap").set_exception_breakpoints({ "Warning" })
                    print("DAP: Breaking on Warnings & Errors")
                end,
                desc = "Debug: Break on Warnings",
            },
            {
                "<leader>dE",
                function()
                    require("dap").set_exception_breakpoints({ "Error" })
                    print("DAP: Breaking on Errors")
                end,
                desc = "Debug: Break on Errors",
            },
            {
                "<leader>dX",
                function()
                    require("dap").set_exception_breakpoints({ "Exception" })
                    print("DAP: Breaking on Exceptions")
                end,
                desc = "Debug: Break on Exceptions",
            },
            {
                "<leader>dN",
                function()
                    require("dap").set_exception_breakpoints({ "Notice" })
                    print("DAP: Breaking on Notices")
                end,
                desc = "Debug: Break on Notices",
            },
            {
                "<leader>dA",
                function()
                    require("dap").set_exception_breakpoints({ "Warning", "Error", "Exception", "Notice" })
                    print("DAP: Breaking on Everything")
                end,
                desc = "Debug: Break on All",
            },
            {
                "<leader>dZ",
                function()
                    require("dap").set_exception_breakpoints({})
                    print("DAP: Exception Breakpoints Off")
                end,
                desc = "Debug: Turn Off Exception Breaks",
            },
        },
    },

    -- Disable automatic DAP UI layout on debug start
    {
        "rcarriga/nvim-dap-ui",
        config = function(_, opts)
            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup(opts)

            -- Prevent dap-ui from opening automatically when debugging starts
            dap.listeners.after.event_initialized["dapui_config"] = function() end

            -- Automatically close DAP UI when debugging ends
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
    },
}
