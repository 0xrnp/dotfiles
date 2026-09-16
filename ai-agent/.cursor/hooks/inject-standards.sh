#!/usr/bin/env bash
# Inject the canonical personal standards into every Cursor agent session.
# Fail open: never block session start.
set -u

STANDARDS="${HOME}/ai-standards/AGENTS.md"
PRIORITY='PRIORITY: classify the request, inspect evidence, present a file-level plan for non-trivial changes, then implement and verify within the requested scope in the same turn. Ask only for a material user choice or separately authorized action. Repository instructions outrank personal skills.'

if [[ ! -r "$STANDARDS" ]]; then
  python3 -c 'import json,sys; print(json.dumps({"additional_context":sys.argv[1]}))' "$PRIORITY"
  exit 0
fi

python3 - "$PRIORITY" "$STANDARDS" <<'PY'
import json, sys
from pathlib import Path
priority, standards = sys.argv[1], sys.argv[2]
body = Path(standards).read_text()
print(json.dumps({"additional_context": priority + "\n\n" + body}))
PY
exit 0
