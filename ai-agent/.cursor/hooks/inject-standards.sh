#!/usr/bin/env bash
# Inject personal AI standards into every Cursor agent session.
# Fail open: never block session start.
set -u

STANDARDS="${HOME}/ai-standards/universal.md"
PHRASES="${HOME}/ai-standards/approve-phrases.txt"

PRIORITY='PRIORITY — Plan → approve → edit. Scope lock: do only what was asked; no drive-by or “also fix” work. Do not edit until the user gives an ALL CAPS phrase from ~/ai-standards/approve-phrases.txt (e.g. GO AHEAD / DO IT / JUST DO IT), unless already in the same request. Smallest diff; evidence from the repo; no Cursor co-author trailers. Lead with the answer/plan; no fluff.'

if [[ ! -r "$STANDARDS" ]]; then
  python3 -c 'import json,sys; print(json.dumps({"additional_context":sys.argv[1]}))' "$PRIORITY"
  exit 0
fi

python3 - "$PRIORITY" "$STANDARDS" "$PHRASES" <<'PY'
import json, sys
from pathlib import Path
priority, standards, phrases_path = sys.argv[1], sys.argv[2], sys.argv[3]
body = Path(standards).read_text()
extra = ""
p = Path(phrases_path)
if p.is_file():
    lines = [ln.strip() for ln in p.read_text().splitlines() if ln.strip() and not ln.strip().startswith("#")]
    if lines:
        extra = "\n\n## Approval phrases (ALL CAPS exact)\n" + "\n".join(f"- `{x}`" for x in lines)
print(json.dumps({"additional_context": priority + "\n\n" + body + extra}))
PY
exit 0
