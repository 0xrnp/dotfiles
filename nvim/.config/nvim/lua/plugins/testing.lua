return {
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-jest" },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          -- Local binary only, so it works with npm and pnpm workspaces alike.
          jestCommand = "npx --no-install jest",
          -- The adapter only looks for jest.config.js/.ts. Workspace packages use .cjs.
          jestConfigFile = function(file)
            return vim.fs.find(
              { "jest.config.ts", "jest.config.js", "jest.config.cjs", "jest.config.mjs" },
              { path = vim.fs.dirname(file), upward = true }
            )[1]
          end,
          -- Run from the package that owns the test, not the monorepo root.
          cwd = function(path)
            return vim.fs.root(path, "package.json")
          end,
        },
      },
    },
  },
}
