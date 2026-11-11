return {
  "xiyaowong/transparent.nvim",
  lazy = false, -- mauve loads first and would otherwise paint opaque groups
  config = function()
    require("transparent").setup({
      clear_prefix = "transparent",
      groups = {
        "Normal",
        "NormalNC",
        "SignColumn",
        "LineNr",
        "NonText",
        "EndOfBuffer",
        "NeoTreeNormal",
        "NeoTreeNormalNC",
        "NeoTreeWinSeparator",
      },
      extra_groups = {
        "NormalFloat",
        "FloatBorder",
      },
      exclude_groups = {},
    })
    require("transparent").clear_prefix("transparent")
    require("transparent").clear_prefix("BufferLine")
    vim.g.transparent_enabled = true -- Enable for themes that check this
  end,
}
