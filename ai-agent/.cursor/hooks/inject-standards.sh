#!/usr/bin/env bash
# Inject personal AI standards into every Cursor agent session.
# Fail open: never block session start.
set -u

STANDARDS="${HOME}/ai-standards/universal.md"
IDENTITY="${HOME}/ai-standards/identity.md"
PHRASES="${HOME}/ai-standards/approve-phrases.txt"

PRIORITY='PRIORITY — Plan → approve → edit. Scope lock: do only what was asked; no drive-by or “also fix” work. Do not rubber-stamp; if the user may be wrong, push back with evidence and wait. Do not edit until the user approves using a phrase from the list below (primary: gooo), unless already in the same request. Smallest diff; evidence from the repo; no Cursor co-author trailers. Lead with the answer/plan; no fluff.'

if [[ ! -r "$STANDARDS" ]]; then
  python3 -c 'import json,sys; print(json.dumps({"additional_context":sys.argv[1]}))' "$PRIORITY"
  exit 0
fi

python3 - "$PRIORITY" "$STANDARDS" "$PHRASES" "$IDENTITY" <<'PY'
import json, sys
from pathlib import Path
priority, standards, phrases_path, identity_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
body = Path(standards).read_text()
identity = ""
ip = Path(identity_path)
if ip.is_file():
    identity = "\n\n" + ip.read_text()
extra = ""
p = Path(phrases_path)
if p.is_file():
    lines = [ln.strip() for ln in p.read_text().splitlines() if ln.strip() and not ln.strip().startswith("#")]
    if lines:
        extra = "\n\n## Approval phrases (any case; primary first)\n" + "\n".join(f"- `{x}`" for x in lines)
print(json.dumps({"additional_context": priority + "\n\n" + body + extra + identity}))
PY
exit 0
