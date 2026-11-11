return {
  {
    "folke/sidekick.nvim",
    opts = {
      -- CLI sessions only. Next-edit suggestions would start the Copilot language server.
      nes = { enabled = false },
    },
    keys = {
      -- Claude Code owns <leader>a. Sidekick is the picker for the other CLIs.
      { "<tab>", false },
      { "<leader>a", false, mode = { "n", "v" } },
      { "<leader>aa", false },
      { "<leader>as", false },
      { "<leader>ad", false },
      { "<leader>at", false, mode = { "n", "x" } },
      { "<leader>af", false },
      { "<leader>av", false, mode = "x" },
      { "<leader>ap", false, mode = { "n", "x" } },
      { "<leader>A", "", desc = "+agents", mode = { "n", "v" } },
      {
        "<leader>Aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Toggle CLI",
      },
      {
        "<leader>As",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Select CLI",
      },
      {
        "<leader>Ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach CLI",
      },
      {
        "<leader>At",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Send this",
      },
      {
        "<leader>Af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send file",
      },
      {
        "<leader>Av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = "x",
        desc = "Send selection",
      },
      {
        "<leader>Ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Select prompt",
      },
    },
  },
}
