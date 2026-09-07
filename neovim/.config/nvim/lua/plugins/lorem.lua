-- Lorem ipsum generator for Neovim
-- Usage:
-- * in Insert mode type `lorem<number of paragraphs>p<space>` to insert any number of lorem ipsum paragraphs
-- * in Insert mode type `lorem<number of words><space>` to insert any number of lorem ipsum words
return {
    {
        "derektata/lorem.nvim",
        event = "VeryLazy",
        opts = {
            sentence_length = "mixed", -- Can be "short", "medium", "long", or "mixed"
            comma_chance = 0.3, -- 30% chance to insert a comma after a word
            max_commas = 2, -- Max commas per sentence
        },
    },
}
