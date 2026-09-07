return {
    {
        "mikevskater/nvim-xlsx",
        dependencies = { "hat0uma/csvview.nvim" },
        init = function()
            -- ===================================================
            -- 1. MODERN EXCEL (.xlsx) - Pure Lua Parsing
            -- ===================================================
            vim.api.nvim_create_autocmd("BufReadCmd", {
                pattern = "*.xlsx",
                callback = function(ev)
                    local filepath = ev.match
                    local buf = ev.buf
                    local xlsx = require("nvim-xlsx")
                    local success, data = pcall(xlsx.import_table, filepath)
                    if not success or not data then
                        return
                    end

                    local lines = {}
                    for _, row in ipairs(data) do
                        local row_str = {}
                        for _, cell in ipairs(row) do
                            local clean_cell = tostring(cell or ""):gsub("[\t\r\n]", " ")
                            table.insert(row_str, clean_cell)
                        end
                        table.insert(lines, table.concat(row_str, "\t"))
                    end

                    vim.bo[buf].modifiable = true
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                    vim.bo[buf].modifiable = false
                    vim.bo[buf].modified = false
                    vim.bo[buf].filetype = "tsv"
                    vim.opt_local.wrap = false

                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(buf) then
                            vim.cmd("CsvViewEnable")
                        end
                    end)
                end,
            })

            -- ===================================================
            -- 2. LEGACY EXCEL (.xls) - CLI Binary Stream
            -- ===================================================
            vim.api.nvim_create_autocmd("BufReadCmd", {
                pattern = "*.xls",
                callback = function(ev)
                    local filepath = ev.match
                    local buf = ev.buf

                    if vim.fn.executable("xls2csv") == 0 then
                        vim.notify(
                            "Missing system binary. Run 'brew install catdoc' or 'apt install catdoc' to read legacy .xls files.",
                            vim.log.levels.WARN
                        )
                        return
                    end

                    local cmd = string.format("xls2csv %s", vim.fn.shellescape(filepath))
                    local output = vim.fn.system(cmd)
                    local lines = vim.split(output, "\n", { trimempty = true })

                    vim.bo[buf].modifiable = true
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                    vim.bo[buf].modifiable = false
                    vim.bo[buf].modified = false
                    vim.bo[buf].filetype = "csv"
                    vim.opt_local.wrap = false

                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(buf) then
                            vim.cmd("CsvViewEnable")
                        end
                    end)
                end,
            })
        end,
    },

    {
        "hat0uma/csvview.nvim",
        opts = {
            view = { display_mode = "border" },
        },
    },
}
