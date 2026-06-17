return {
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      widget_guides = { enabled = true },
      closing_tags = { enabled = true, prefix = "// " },
      dev_log = { enabled = true, open_cmd = "tabedit" },
    },
    keys = {
      { "<leader>Fr", "<cmd>FlutterRun<cr>", desc = "Flutter Run" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Flutter Quit" },
      { "<leader>Fh", "<cmd>FlutterReload<cr>", desc = "Hot Reload" },
      { "<leader>FH", "<cmd>FlutterRestart<cr>", desc = "Hot Restart" },
      { "<leader>Fd", "<cmd>FlutterDevices<cr>", desc = "Devices" },
      { "<leader>FD", "<cmd>FlutterDevTools<cr>", desc = "DevTools" },
      { "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Outline" },
      { "<leader>Fg", "<cmd>FlutterPubGet<cr>", desc = "Pub Get" },
      { "<leader>Fu", "<cmd>FlutterPubUpgrade<cr>", desc = "Pub Upgrade" },
    },
  },
}
