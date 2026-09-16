#!/usr/bin/env bash
# Ask for mutating, privileged, and unclassified external tools.
set -eu

input=$(cat || true)

python3 - "$input" <<'PY'
import json, re, sys

def result(permission, message):
    print(json.dumps({"permission": permission, "user_message": message}))
    raise SystemExit(0)

try:
    data = json.loads(sys.argv[1])
except (ValueError, IndexError):
    result("deny", "Invalid MCP hook payload.")
if not isinstance(data, dict):
    result("deny", "Invalid MCP hook payload.")
name = data.get("toolName") or data.get("tool_name") or data.get("name")
server = data.get("serverName") or data.get("server") or data.get("mcpServer") or ""
if not isinstance(name, str) or not name.strip() or not isinstance(server, str):
    result("deny", "Invalid MCP tool name.")

# Names provide hints, not proof of read-only behavior. A generic query/execute
# tool can mutate through its arguments. Never infer SQL safety.
identity = f"{server} {name}".lower()
# Match action words, not fragments such as "put" inside "input". Split
# camelCase too, since adapters do not all use snake_case operation names.
words = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", f"{server} {name}").lower()
if re.search(r"(?:^|[^a-z0-9])(?:create|update|delete|remove|write|insert|drop|send|post|patch|put|publish|deploy|execute|mutation|auth)(?:[^a-z0-9]|$)", words):
    result("ask", "Mutating or privileged external tool. Confirm the intended action.")
if re.search(r"mongo|postgres|mysql|database|redis|sql|query|aggregate|production|payment|razorpay|secret", identity):
    result("ask", "Data or privileged target access. Confirm the named connection and scope.")

operation = re.split(r"__|:", name.lower())[-1]
if re.match(r"^(?:get|list|search|find|read|fetch|describe|view|inspect)(?:[_-]|$)", operation):
    result("allow", "Recognized read operation; task authorization still applies.")
result("ask", "Unclassified external tool. Confirm its target and effects before continuing.")
PY
