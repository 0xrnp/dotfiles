#!/usr/bin/env bash
# Require plan approval and confirmation for mutating or privileged MCP calls.
set -u

input=$(cat || true)
policy=$(printf '%s' "$input" | python3 "$HOME/ai-standards/approval-gate.py" cursor mcp)
if [[ "$policy" == *'"permission": "deny"'* ]]; then
  printf '%s\n' "$policy"
  exit 0
fi

tool=$(printf '%s' "$input" | python3 -c '
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  print("")
  raise SystemExit(0)
name=(d.get("toolName") or d.get("tool_name") or d.get("name") or "")
server=(d.get("serverName") or d.get("server") or d.get("mcpServer") or "")
print(f"{server} {name}".strip())
' 2>/dev/null || true)

lower=$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')

# Mutating / side-effect patterns → ask
if printf '%s' "$lower" | grep -Eq 'create|update|delete|remove|write|insert|drop|send|post|patch|put|publish|deploy|execute|run_mutation|auth'; then
  printf '%s\n' '{"permission":"ask","user_message":"Mutating or privileged MCP call. Confirm before continuing.","agent_message":"MCP looks mutating or privileged. Prefer local tools if possible and ask the user before proceeding."}'
  exit 0
fi

printf '%s\n' '{"permission":"allow"}'
exit 0
