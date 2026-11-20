-- cmd+; then one key jumps to a tab of the active session. Digits are tabs
-- 1-9, the top letter row is tabs 10-14.
--
-- This is a custom action rather than client.tab.goto because that one counts
-- tabs across every expanded session when the sidebar toolbar layout is used.
-- One action per tab so the key hint popup reads "Tab 3" instead of repeating
-- a long title on every row.
local function goto_tab(ctx, index)
  local view, err = rex.session.view{ session_id = ctx.session_id }
  if err ~= nil then error(err, 0) end
  local win = view.windows[index]
  if win == nil then return end
  rex.client.queue("session.select", {
    session_id = ctx.session_id,
    window_id = win.window_id,
  })
end

-- Sessions: cmd+; j / k. Bound before the tabs so they sit last in the popup.
rex.bind("cmd+;>j", "session.next")
rex.bind("cmd+;>k", "session.previous")

local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "q", "w", "e", "r", "t" }

-- The popup lists the newest binding first, so bind in reverse for 1 on top.
for i = #keys, 1, -1 do
  local name = "tab_" .. i
  rex.action{
    name  = name,
    title = "Tab " .. i,
    run   = function(ctx) goto_tab(ctx, i) end,
  }
  rex.bind("cmd+;>" .. keys[i], name)
end

-- cmd+; c opens the saved agent sessions picker (agent-resume) for Claude and
-- Cursor in a new tab of the active session and shows it. The picker closes
-- itself after it opens your picks.
rex.action{
  title = "Resume agent session",
  name  = "resume_agent",
  run   = function(ctx)
    local proc = rex.exec.start({
      "/bin/sh", "-c",
      'rex="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"; ' ..
      '[ -x "$rex" ] || rex="$(command -v rex)"; ' ..
      'PATH="$(dirname "$rex"):$HOME/.local/bin:/opt/homebrew/bin:$PATH" exec "$HOME/.local/bin/agent-resume" --tab "$1"',
      "sh", ctx.session_id,
    })
    proc:wait()
  end,
}
rex.bind("cmd+;>c", "resume_agent")
