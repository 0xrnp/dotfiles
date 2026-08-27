#!/usr/bin/env bash
# Soft DoD check: only nudge once if the agent claimed completion without verification notes.
# Relies on loop_limit: 1 in hooks.json. Fail open.
set -u

input=$(cat || true)

loop_count=$(printf '%s' "$input" | python3 -c '
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  print(0)
  raise SystemExit(0)
print(d.get("loop_count") or 0)
' 2>/dev/null || echo 0)

status=$(printf '%s' "$input" | python3 -c '
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  print("")
  raise SystemExit(0)
print(d.get("status") or "")
' 2>/dev/null || true)

# Only act on first completed stop
if [[ "$status" != "completed" ]] || [[ "$loop_count" != "0" ]]; then
  printf '{}\n'
  exit 0
fi

# Soft nudge. The agent may ignore it if already covered; loop_limit prevents spam.
printf '%s\n' '{"followup_message":"Quick DoD check: for non-trivial work, confirm changed files, why the diff is minimal, verification run or why not, and residual risks. If already covered or the task was trivial, reply with just OK."}'
exit 0
