-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_picker = "fzf"

-- Git root first, so search and the file picker cover the whole monorepo instead of the
-- nearest package. The "lua" marker keeps this config editable as its own root.
vim.g.root_spec = { { ".git", "lua" }, "lsp", "cwd" }
