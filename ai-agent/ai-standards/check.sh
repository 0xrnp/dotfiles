#!/usr/bin/env bash
set -euo pipefail
H="$HOME"
test -r "$H/ai-standards/universal.md"
test -r "$H/ai-standards/approve-phrases.txt"
test -x "$H/.cursor/hooks/gate-edit.sh"
test -x "$H/.cursor/hooks/gate-plan-approve.sh"
grep -q 'Plan → approve → edit' "$H/ai-standards/universal.md"
grep -q 'Scope lock' "$H/ai-standards/universal.md"
grep -q './hooks/gate-edit.sh' "$H/.cursor/hooks.json"
grep -q './hooks/gate-plan-approve.sh' "$H/.cursor/hooks.json"
echo '{}' | "$H/.cursor/hooks/inject-standards.sh" | grep -q 'Plan'
echo '{}' | "$H/.cursor/hooks/inject-standards.sh" | grep -q 'GO AHEAD'
echo '{"tool_name":"Write","conversation_id":"chk","generation_id":"g1"}' | "$H/.cursor/hooks/gate-edit.sh" | grep -q '"deny"'

python3 - "$H" <<'PY'
import json, os, subprocess, sys
from pathlib import Path

h = sys.argv[1]
phrases = [
    ln.strip()
    for ln in Path(f"{h}/ai-standards/approve-phrases.txt").read_text().splitlines()
    if ln.strip() and not ln.strip().startswith("#")
]
assert phrases, "approve-phrases.txt is empty"

def gate_edit(cid, gid="g"):
    out = subprocess.check_output(
        [f"{h}/.cursor/hooks/gate-edit.sh"],
        input=json.dumps({"tool_name": "Write", "conversation_id": cid, "generation_id": gid}),
        text=True,
    )
    return json.loads(out)["permission"]

def approve(prompt, cid, gid="g"):
    subprocess.check_output(
        [f"{h}/.cursor/hooks/gate-plan-approve.sh"],
        input=json.dumps({"prompt": prompt, "conversation_id": cid, "generation_id": gid}),
        text=True,
    )

# lowercase of first phrase must NOT unlock
lo = phrases[0].lower()
approve(lo, "chk-lo", "g0")
assert gate_edit("chk-lo", "g0") == "deny", f"lowercase unlocked: {lo!r}"
Path(f"{h}/.cursor/ai-standards-state/edit-ok-chk-lo").unlink(missing_ok=True)

for i, phrase in enumerate(phrases):
    cid = f"chk-{i}"
    approve(f"please {phrase} thanks", cid, "g1")
    assert gate_edit(cid, "g1") == "allow", f"did not unlock: {phrase!r}"
    Path(f"{h}/.cursor/ai-standards-state/edit-ok-{cid}").unlink(missing_ok=True)

payload = {"command": "git commit -m x --trailer Co-authored-by: Cursor <agent@cursor.com>"}
out = subprocess.check_output(
    [f"{h}/.cursor/hooks/gate-shell.sh"], input=json.dumps(payload), text=True
)
assert '"deny"' in out
print("OK")
PY
