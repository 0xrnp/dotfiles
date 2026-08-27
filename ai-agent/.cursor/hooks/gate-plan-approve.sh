#!/usr/bin/env bash
# Approve edits for this turn when the user explicitly green-lights.
# Phrases: ~/ai-standards/approve-phrases.txt (case-insensitive).
# Fail open.
set -u

input=$(cat || true)

python3 - "$input" <<'PY'
import json, os, re, sys
from pathlib import Path

raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    d = json.loads(raw)
except Exception:
    print("{}")
    raise SystemExit(0)

prompt = d.get("prompt") or ""
cid = d.get("conversation_id") or d.get("session_id") or ""
gid = d.get("generation_id") or ""

phrases_path = Path(os.path.expanduser("~/ai-standards/approve-phrases.txt"))
phrases = []
if phrases_path.is_file():
    for line in phrases_path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            phrases.append(line)

approve = False
if phrases:
    parts = [r"\s+".join(re.escape(w) for w in p.split()) for p in phrases]
    approve = bool(re.search(r"\b(?:" + "|".join(parts) + r")\b", prompt, re.IGNORECASE))

state_dir = Path(os.path.expanduser("~/.cursor/ai-standards-state"))
state_dir.mkdir(parents=True, exist_ok=True)

if approve and cid and gid:
    (state_dir / f"edit-ok-{cid}").write_text(gid)
elif approve and cid:
    (state_dir / f"edit-ok-{cid}").write_text("any")

print("{}")
PY
exit 0
