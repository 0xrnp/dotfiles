return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- mason-lspconfig enables every installed package not listed here. tsgo is a
        -- leftover that attaches next to vtsls and duplicates its diagnostics.
        tsgo = { enabled = false },
        -- Without a workspace, angularls starts in single-file mode on every TS file,
        -- including the Node API and React Native apps.
        angularls = { workspace_required = true },
      },
    },
  },
}
