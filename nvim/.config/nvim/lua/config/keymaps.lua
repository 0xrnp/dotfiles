-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape insert mode" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zzzv'", { expr = true, desc = "Next match (centered)" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zzzv'", { expr = true, desc = "Previous match (centered)" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines" })
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

vim.keymap.set("n", "x", '"_x', { desc = "Delete character without copying" })
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without overwriting registry" })

vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

vim.keymap.set("n", "<C-q>", "<cmd>bdelete<CR>", { desc = "Close current tab" }) -- shift+Quit to close current tab
vim.keymap.set("n", "g1", "<cmd>BufferLineGoToBuffer 1<CR>", { desc = "Go to buffer 1" })
vim.keymap.set("n", "g2", "<cmd>BufferLineGoToBuffer 2<CR>", { desc = "Go to buffer 2" })
vim.keymap.set("n", "g3", "<cmd>BufferLineGoToBuffer 3<CR>", { desc = "Go to buffer 3" })
vim.keymap.set("n", "g4", "<cmd>BufferLineGoToBuffer 4<CR>", { desc = "Go to buffer 4" })
vim.keymap.set("n", "g5", "<cmd>BufferLineGoToBuffer 5<CR>", { desc = "Go to buffer 5" })
vim.keymap.set("n", "g6", "<cmd>BufferLineGoToBuffer 6<CR>", { desc = "Go to buffer 6" })
vim.keymap.set("n", "g7", "<cmd>BufferLineGoToBuffer 7<CR>", { desc = "Go to buffer 7" })
vim.keymap.set("n", "g8", "<cmd>BufferLineGoToBuffer 8<CR>", { desc = "Go to buffer 8" })
vim.keymap.set("n", "g9", "<cmd>BufferLineGoToBuffer 9<CR>", { desc = "Go to buffer 9" })
vim.keymap.set("n", "g0", "<cmd>BufferLineGoToBuffer 10<CR>", { desc = "Go to buffer 10" })
vim.keymap.set("n", "<M-J>", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer to the left" }) -- Alt+Shift+j grab to with you to left
vim.keymap.set("n", "<M-K>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer to the right" }) -- Alt+Shift+k grab to with you to right

vim.keymap.set("n", "<leader>un", function()
  Snacks.notifier.show_history()
end, { desc = "Notification History" })
