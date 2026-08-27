#!/usr/bin/env bash
set -euo pipefail
H="$HOME"
test -r "$H/ai-standards/universal.md"
test -r "$H/ai-standards/identity.md"
test -r "$H/ai-standards/approve-phrases.txt"
test -x "$H/.cursor/hooks/gate-edit.sh"
test -x "$H/.cursor/hooks/gate-plan-approve.sh"
test -r "$H/.cursor/skills/using-skill-guide/SKILL.md"
test -r "$H/.cursor/skills/homes-flutter/SKILL.md"
test -r "$H/.cursor/skills/homes-js-ts/SKILL.md"
test -r "$H/.cursor/skills/homes-git/SKILL.md"
test -r "$H/.cursor/skills/unslop/SKILL.md"
test -r "$H/.cursor/skills/self-review/SKILL.md"
test -r "$H/.cursor/skills/react-native/SKILL.md"
test -r "$H/.cursor/skills/schema-design/SKILL.md"
test -r "$H/.cursor/skills/blast-radius/SKILL.md"
test -r "$H/.cursor/skills/mongo-aggregations/SKILL.md"
grep -q 'Plan → approve → edit' "$H/ai-standards/universal.md"
grep -q 'Scope lock' "$H/ai-standards/universal.md"
grep -q 'using-skill-guide' "$H/ai-standards/identity.md"
grep -q 'Questions are read-only' "$H/ai-standards/identity.md"
grep -q 'Repo > skill > memory' "$H/ai-standards/identity.md"
grep -q 'self-review' "$H/ai-standards/identity.md"
grep -q 'rubber-stamp' "$H/ai-standards/identity.md"
grep -q 'push back' "$H/ai-standards/universal.md"
grep -q './hooks/gate-edit.sh' "$H/.cursor/hooks.json"
grep -q './hooks/gate-plan-approve.sh' "$H/.cursor/hooks.json"
echo '{}' | "$H/.cursor/hooks/inject-standards.sh" | grep -q 'Plan'
echo '{}' | "$H/.cursor/hooks/inject-standards.sh" | grep -q 'gooo'
echo '{}' | "$H/.cursor/hooks/inject-standards.sh" | grep -q 'using-skill-guide'
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
assert phrases[0] == "gooo", f"primary should be gooo, got {phrases[0]!r}"

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

# any-case: mixed primary must unlock
approve(phrases[0].swapcase(), "chk-mix", "g0")
assert gate_edit("chk-mix", "g0") == "allow", f"mixed case did not unlock: {phrases[0]!r}"
Path(f"{h}/.cursor/ai-standards-state/edit-ok-chk-mix").unlink(missing_ok=True)

# substring must not unlock (goo vs google)
approve("please google thanks", "chk-google", "g0")
assert gate_edit("chk-google", "g0") == "deny", "google unlocked via goo"
Path(f"{h}/.cursor/ai-standards-state/edit-ok-chk-google").unlink(missing_ok=True)

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
