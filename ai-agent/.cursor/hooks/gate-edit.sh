#!/usr/bin/env bash
# Deny file edits until the user green-lights this turn (plan-first).
# Fail open only on parse errors; missing approval → deny.
set -u

input=$(cat || true)

python3 - "$input" <<'PY'
import json, os, sys
from pathlib import Path

raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    d = json.loads(raw)
except Exception:
    print('{"permission":"allow"}')
    raise SystemExit(0)

tool = (d.get("tool_name") or d.get("tool") or "").strip()
# Only gate mutating file tools
if tool not in {"Write", "StrReplace", "Delete", "EditNotebook", "Edit", "ApplyPatch", "DeleteFile", "SearchReplace"}:
    print('{"permission":"allow"}')
    raise SystemExit(0)

cid = d.get("conversation_id") or d.get("session_id") or ""
gid = d.get("generation_id") or ""
state = Path(os.path.expanduser("~/.cursor/ai-standards-state")) / f"edit-ok-{cid}"

allowed = False
if cid and state.exists():
    token = state.read_text().strip()
    if token == "any" or (gid and token == gid):
        allowed = True

if allowed:
    print('{"permission":"allow"}')
    raise SystemExit(0)

phrases_path = Path(os.path.expanduser("~/ai-standards/approve-phrases.txt"))
phrases = []
if phrases_path.is_file():
    for line in phrases_path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            phrases.append(line)
primary = phrases[0] if phrases else "gooo"
listed = ", ".join(phrases) if phrases else "gooo"

print(json.dumps({
    "permission": "deny",
    "user_message": (
        f"Plan-first: show a change plan, then say an approval phrase "
        f"(primary: {primary}). Phrases: {listed}."
    ),
    "agent_message": (
        "EDIT BLOCKED by personal plan-first gate. Do NOT retry the edit yet. "
        "Reply with: (1) goal, (2) files to touch, (3) concrete changes per file, "
        "(4) what you will not change, (5) risks. Scope lock — nothing outside that plan. "
        f"Then STOP and ask for approval. Primary: {primary}. Phrases: {listed}."
    ),
}))
PY
exit 0
