return {
  "xiyaowong/transparent.nvim",
  config = function()
    require("transparent").setup({
      clear_prefix = "transparent",
      groups = {
        "Normal",
        "NormalNC",
        "Comment",
        "Constant",
        "Special",
        "Identifier",
        "Statement",
        "PreProc",
        "Type",
        "Underlined",
        "Todo",
        "String",
        "Function",
        "Conditional",
        "Repeat",
        "Operator",
        "Structure",
        "LineNr",
        "NonText",
        "SignColumn",
        "CursorLine",
        "CursorLineNr",
        "StatusLine",
        "StatusLineNC",
        "EndOfBuffer",
        "CursorColumn",
        "CursorLineNr",
        "FoldBackground",
        "NeoTreeNormal",
        "NeoTreeNormalNC",
        "NeoTreeWinSeparator",
      },
      -- Plugin-specific and floating window groups
      extra_groups = {
        "NormalFloat", -- Essential for floating windows like Telescope
        "FloatBorder",

        -- Telescope
        "TelescopeNormal",
        "TelescopeBorder",
        "TelescopePromptBorder",
        "TelescopePromptNormal",
        "TelescopeResultsBorder",
        "TelescopeResultsNormal",
        "TelescopePreviewBorder",
        "TelescopePreviewNormal",
      },
      exclude_groups = {},
    })
    require("transparent").clear_prefix("transparent")
    require("transparent").clear_prefix("BufferLine")
    require("transparent").clear_prefix("Telescope")
    vim.g.transparent_enabled = true -- Enable for themes that check this
  end,
}
