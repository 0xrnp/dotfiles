#!/usr/bin/env bash
# Inject the canonical personal standards into every Cursor agent session.
# Fail open: never block session start.
set -u

STANDARDS="${HOME}/ai-standards/AGENTS.md"
PHRASES="${HOME}/ai-standards/approve-phrases.txt"

PRIORITY='PRIORITY: classify the request, inspect evidence, present a file-level plan, and wait for an approval token (last non-empty line of the user message) before any mutation. Control tokens may be stacked one per line. Keep the approved scope. Repository instructions outrank personal skills.'

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
        extra = "\n\n## Approval phrases (any case; primary first)\n" + "\n".join(f"- `{x}`" for x in lines)
print(json.dumps({"additional_context": priority + "\n\n" + body + extra}))
PY
exit 0
