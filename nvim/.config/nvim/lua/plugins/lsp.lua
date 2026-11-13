-- Whether any package.json in the repo mentions tailwindcss. Looked up once per repo.
local tailwind_repos = {}

local function repo_uses_tailwind(git_root)
  if tailwind_repos[git_root] == nil then
    local res = vim
      .system({
        "rg",
        "--files-with-matches",
        "--max-depth",
        "5",
        "--glob",
        "package.json",
        "--glob",
        "!**/node_modules/**",
        "tailwindcss",
        git_root,
      }, { text = true })
      :wait()
    tailwind_repos[git_root] = res.code == 0
  end
  return tailwind_repos[git_root]
end

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
        -- Upstream roots at any .git (for Tailwind v4, which needs no config file), so every
        -- repo starts ~350 MB of server. Start it only where the nearest package.json or a
        -- tailwind.config.* says so, or the repo uses Tailwind elsewhere (shared UI packages
        -- have no marker of their own).
        tailwindcss = {
          root_dir = function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local markers = require("lspconfig.util").insert_package_json({
              "tailwind.config.js",
              "tailwind.config.cjs",
              "tailwind.config.mjs",
              "tailwind.config.ts",
            }, "tailwindcss", fname)
            local found = vim.fs.find(markers, { path = fname, upward = true })[1]
            if found then
              return on_dir(vim.fs.dirname(found))
            end
            local git_root = vim.fs.root(fname, ".git")
            if git_root and repo_uses_tailwind(git_root) then
              on_dir(git_root)
            end
          end,
        },
      },
    },
  },
}
