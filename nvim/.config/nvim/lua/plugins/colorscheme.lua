-- Mauve sets Diff* as foreground only, and reapplies that from its own
-- ColorScheme hook. A background tint keeps syntax colors and makes hunks readable.
-- ponytail: mauve palette colors blended into its background by hand. Recompute if the palette changes.
local function apply_diff_hl()
  if vim.g.colors_name ~= "mauve" then
    return
  end
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#364143" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#242a3b" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#443244" })
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#385167" })
end

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "mauve",
    },
  },
  {
    "yahddyyp/mauve.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.schedule(apply_diff_hl)
        end,
      })
      if vim.g.colors_name == "mauve" then
        vim.schedule(apply_diff_hl)
      end
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = "mocha",
    },
  },
}
