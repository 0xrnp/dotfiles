#!/usr/bin/env bash
# Record the Cursor CLI session so agent-resume can reopen it later.
# Fail open: never block session start.
recorder="${HOME}/.local/bin/agent-session-record"
[[ -x "$recorder" ]] || { echo '{}'; exit 0; }
exec "$recorder" cursor
