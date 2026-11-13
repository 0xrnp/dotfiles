local M = {}

-- The project list is the union of three sources, minus anything hidden:
--   1. git checkouts (repo or worktree) found under `roots`. `.git` is a file in a worktree.
--   2. git roots this Neovim was opened in before, wherever they live.
--   3. folders added by hand with :ProjectAdd (for non-git folders).
-- A new project folder usually needs no configuration: the shallow `~` scan finds top-level
-- ones, and opening any repo once records it.
local roots = {
  { "~/workspace", depth = 5 },
  { "~/self", depth = 5 },
  {
    "~",
    depth = 3,
    exclude = {
      "workspace",
      "self",
      "Library",
      "Applications",
      "Downloads",
      "Documents",
      "Desktop",
      "Movies",
      "Music",
      "Pictures",
      "Public",
      "OrbStack",
      "go",
      "Postman",
      "bruno",
      ".cache",
      ".local",
      ".cargo",
      ".rustup",
      ".npm",
      ".pnpm-store",
      ".Trash",
      ".colima",
      ".docker",
      ".gradle",
      ".android",
      ".cocoapods",
      ".bun",
      ".mise",
      ".nvm",
    },
  },
}

-- Machine-local state: hand-added folders, hidden entries, and when each repo was last opened.
local state_path = vim.fn.stdpath("data") .. "/projects.json"

local function norm(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function tilde(path)
  return vim.fn.fnamemodify(path, ":~")
end

-- Dot-directories (~/.nvm, ~/.config/...) hold tool checkouts, not projects.
local function in_dot_dir(path)
  local home = norm("~")
  if not vim.startswith(path, home .. "/") then
    return false
  end
  return path:sub(#home + 2):find("^%.") ~= nil or path:sub(#home + 2):find("/%.") ~= nil
end

local function read_state()
  local state = {}
  local f = io.open(state_path, "r")
  if f then
    local ok, decoded = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(decoded) == "table" then
      state = decoded
    end
  end
  state.pinned = state.pinned or {}
  state.hidden = state.hidden or {}
  state.seen = state.seen or {}
  return state
end

-- Rename into place so a concurrent Neovim never reads a half-written file.
local function write_state(state)
  local tmp = state_path .. "." .. vim.uv.os_getpid()
  local f = assert(io.open(tmp, "w"))
  f:write(vim.json.encode(state))
  f:close()
  assert(vim.uv.fs_rename(tmp, state_path))
end

local function discover()
  local jobs = {}
  for _, root in ipairs(roots) do
    local dir = norm(root[1])
    if vim.uv.fs_stat(dir) then
      local cmd = {
        "fd",
        "--hidden",
        "--no-ignore",
        "--max-depth",
        tostring(root.depth),
        "--type",
        "d",
        "--type",
        "f",
        "--exclude",
        "node_modules",
        "--exclude",
        ".dart_tool",
        "--exclude",
        "Pods",
        "--exclude",
        ".terraform",
      }
      for _, name in ipairs(root.exclude or {}) do
        vim.list_extend(cmd, { "--exclude", name })
      end
      vim.list_extend(cmd, { "--format", "{//}", "^\\.git$", dir })
      jobs[#jobs + 1] = vim.system(cmd, { text = true })
    end
  end
  local found = {}
  for _, job in ipairs(jobs) do
    for _, line in ipairs(vim.split(job:wait().stdout or "", "\n", { trimempty = true })) do
      local path = norm(line)
      if not in_dot_dir(path) then
        found[#found + 1] = path
      end
    end
  end
  return found
end

-- Everything the list could show before hiding.
local function candidates(state)
  local list = discover()
  vim.list_extend(list, vim.tbl_keys(state.seen))
  vim.list_extend(list, vim.tbl_map(norm, state.pinned))
  return list
end

-- Most recently opened first, then alphabetical.
local function visible()
  local state = read_state()
  local hidden = {}
  for _, p in ipairs(state.hidden) do
    hidden[norm(p)] = true
  end
  local seen, list = {}, {}
  for _, p in ipairs(candidates(state)) do
    if not seen[p] and not hidden[p] and vim.uv.fs_stat(p) then
      seen[p] = true
      list[#list + 1] = p
    end
  end
  table.sort(list, function(a, b)
    local ta, tb = state.seen[a] or 0, state.seen[b] or 0
    if ta ~= tb then
      return ta > tb
    end
    return a < b
  end)
  return list
end

M.list = visible

local function record()
  local root = vim.fs.root(vim.fn.getcwd(), ".git")
  if not root then
    return
  end
  root = norm(root)
  if root == norm("~") or in_dot_dir(root) then
    return
  end
  local state = read_state()
  state.seen[root] = os.time()
  write_state(state)
end

-- Worktree folders are named after the branch, so keep the repo name for a readable tab.
local function label(path)
  local name = vim.fs.basename(path)
  if path:find("/worktrees/", 1, true) then
    return vim.fs.basename(vim.fs.dirname(path)) .. "/" .. name
  end
  return name
end

-- Command that opens `nvim` in `path` in a new tab or window of the terminal running this
-- Neovim. The innermost multiplexer wins. Returns nil for an unrecognised terminal.
local function external_cmd(path)
  local nvim = vim.v.progpath
  if vim.env.TMUX then
    return { "tmux", "new-window", "-c", path, "-n", label(path), nvim }
  elseif vim.env.REX_SESSION then
    return { "rex", "window", "new", "-s", vim.env.REX_SESSION, label(path), "-c", path, "--", nvim }
  elseif vim.env.TERM_PROGRAM == "ghostty" then
    -- Ghostty has no CLI to open a tab on macOS, so use its AppleScript dictionary.
    return { "osascript", "-", path, nvim },
      [[
on run argv
  tell application "Ghostty"
    set cfg to new surface configuration
    set initial working directory of cfg to item 1 of argv
    set command of cfg to item 2 of argv
    new tab in front window with configuration cfg
  end tell
end run]]
  elseif vim.env.ALACRITTY_SOCKET then
    local bin = vim.fn.exepath("alacritty")
    if bin == "" then
      bin = "/Applications/Alacritty.app/Contents/MacOS/alacritty"
    end
    return { bin, "msg", "create-window", "--working-directory", path, "-e", nvim }
  end
end

local function open_here(path)
  vim.cmd.cd(vim.fn.fnameescape(path))
  require("fzf-lua").files({ cwd = path })
end

function M.open(path)
  local cmd, stdin = external_cmd(path)
  if not cmd then
    vim.notify("Unknown terminal, opening in this Neovim", vim.log.levels.WARN)
    return open_here(path)
  end
  vim.system(cmd, { text = true, stdin = stdin }, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          ("Could not open %s in a new tab (%s). Use ctrl-e to open it here."):format(
            tilde(path),
            vim.trim(res.stderr or "")
          ),
          vim.log.levels.ERROR
        )
      end)
    end
  end)
end

function M.add(path)
  path = norm(path)
  if vim.fn.isdirectory(path) == 0 then
    return vim.notify(tilde(path) .. " is not a directory", vim.log.levels.ERROR)
  end
  local state = read_state()
  local hidden_before = #state.hidden
  state.hidden = vim.tbl_filter(function(p)
    return norm(p) ~= path
  end, state.hidden)
  local was_hidden = #state.hidden < hidden_before
  if vim.tbl_contains(visible(), path) and not was_hidden then
    return vim.notify(tilde(path) .. " is already listed")
  end
  if not vim.tbl_contains(candidates(state), path) then
    table.insert(state.pinned, path)
  end
  write_state(state)
  vim.notify("Added " .. tilde(path))
end

-- Hand-added entries are dropped. Anything found by scan or history is hidden instead,
-- because it would reappear otherwise.
function M.remove(path)
  path = norm(path)
  local state = read_state()
  local changed = false
  state.pinned = vim.tbl_filter(function(p)
    if norm(p) == path then
      changed = true
      return false
    end
    return true
  end, state.pinned)
  local auto = discover()
  vim.list_extend(auto, vim.tbl_keys(state.seen))
  if vim.tbl_contains(auto, path) and not vim.tbl_contains(state.hidden, path) then
    table.insert(state.hidden, path)
    changed = true
  end
  if changed then
    write_state(state)
  end
  return changed
end

function M.pick()
  local fzf = require("fzf-lua")
  fzf.fzf_exec(vim.tbl_map(tilde, visible()), {
    prompt = "Projects> ",
    fzf_opts = {
      ["--header"] = "enter: new tab | ctrl-e: open here | ctrl-s: grep | ctrl-x: remove",
      ["--no-sort"] = true,
    },
    actions = {
      ["default"] = function(sel)
        if sel[1] then
          M.open(norm(sel[1]))
        end
      end,
      ["ctrl-e"] = function(sel)
        if sel[1] then
          open_here(norm(sel[1]))
        end
      end,
      ["ctrl-s"] = function(sel)
        if sel[1] then
          fzf.live_grep({ cwd = norm(sel[1]) })
        end
      end,
      ["ctrl-x"] = function(sel)
        for _, p in ipairs(sel) do
          M.remove(norm(p))
        end
        vim.schedule(M.pick)
      end,
    },
  })
end

function M.restore()
  local state = read_state()
  local known = candidates(state)
  local hidden = vim.tbl_filter(function(p)
    return vim.tbl_contains(known, norm(p)) and vim.uv.fs_stat(p) ~= nil
  end, state.hidden)
  if #hidden == 0 then
    return vim.notify("No hidden projects")
  end
  require("fzf-lua").fzf_exec(vim.tbl_map(tilde, hidden), {
    prompt = "Restore> ",
    actions = {
      ["default"] = function(sel)
        for _, p in ipairs(sel) do
          M.add(norm(p))
        end
      end,
    },
  })
end

function M.setup()
  vim.keymap.set("n", "<leader>fp", M.pick, { desc = "Projects" })
  vim.api.nvim_create_user_command("ProjectAdd", function(opts)
    M.add(opts.args ~= "" and opts.args or LazyVim.root.git())
  end, { nargs = "?", complete = "dir", desc = "Add a folder to the project list (default: current repo)" })
  vim.api.nvim_create_user_command("ProjectRemove", function(opts)
    local path = opts.args ~= "" and opts.args or LazyVim.root.git()
    vim.notify(M.remove(path) and ("Removed " .. tilde(norm(path))) or "Not in the project list")
  end, { nargs = "?", complete = "dir", desc = "Remove a folder from the project list" })
  vim.api.nvim_create_user_command("ProjectRestore", M.restore, { desc = "Restore hidden projects" })

  -- setup() runs at VeryLazy, after VimEnter, so record the starting directory directly.
  record()
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("projects_record", { clear = true }),
    pattern = "global",
    callback = record,
  })
end

return M
