return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "mauve",
    },
  },
  { "yahddyyp/mauve.nvim", lazy = false, priority = 1000 },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = "mocha",
    },
  },
}
