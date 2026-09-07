-- Implements the signature help for LSP which shows the signature of the function you are typing.
return {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
        require("lsp_signature").setup(opts)
    end,
}
