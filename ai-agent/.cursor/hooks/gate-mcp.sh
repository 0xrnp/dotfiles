#!/usr/bin/env bash
# Confirm mutating or privileged MCP calls.
set -u

input=$(cat || true)

tool=$(printf '%s' "$input" | python3 -c '
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  print("")
  raise SystemExit(0)
name=(d.get("toolName") or d.get("tool_name") or d.get("name") or "")
server=(d.get("serverName") or d.get("server") or d.get("mcpServer") or "")
if not isinstance(name, str) or not isinstance(server, str):
  print("")
  raise SystemExit(0)
print(f"{server} {name}".strip())
' 2>/dev/null || true)

if [[ -z "$tool" ]]; then
  printf '%s\n' '{"permission":"deny","user_message":"Invalid MCP hook payload."}'
  exit 0
fi

lower=$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')

# Mutating / side-effect patterns → ask
if printf '%s' "$lower" | grep -Eq 'create|update|delete|remove|write|insert|drop|send|post|patch|put|publish|deploy|execute|run_mutation|auth'; then
  printf '%s\n' '{"permission":"ask","user_message":"Mutating or privileged MCP call. Confirm before continuing.","agent_message":"MCP looks mutating or privileged. Prefer local tools if possible and ask the user before proceeding."}'
  exit 0
fi

printf '%s\n' '{"permission":"allow"}'
exit 0
