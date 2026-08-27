#!/usr/bin/env bash
# Require plan approval for mutating shell and block dangerous commands.
set -u

input=$(cat || true)
policy=$(printf '%s' "$input" | python3 "$HOME/ai-standards/approval-gate.py" cursor shell)
if [[ "$policy" == *'"permission": "deny"'* ]]; then
    printf '%s\n' "$policy"
    exit 0
fi

python3 - "$input" <<'PY'
import json, re, sys

raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    d = json.loads(raw)
except Exception:
    print('{"permission":"allow"}')
    raise SystemExit(0)

cmd = d.get("command") or ""
c = " ".join(cmd.split())

def deny(msg="Blocked dangerous shell command by personal hook."):
    print(json.dumps({
        "permission": "deny",
        "user_message": msg,
        "agent_message": "Blocked by ~/.cursor/hooks/gate-shell.sh. Do not workaround; ask the user if needed.",
    }))
    raise SystemExit(0)

def ask(msg="Review this shell command before allowing it."):
    print(json.dumps({
        "permission": "ask",
        "user_message": msg,
        "agent_message": "Flagged by personal shell gate. Get explicit user approval.",
    }))
    raise SystemExit(0)

# --- Hard deny: Cursor / AI co-author attribution on commits & PRs ---
# Covers Co-authored-by, Made-with, trailers, cursor.com emails.
attrib_pat = re.compile(
    r"(?i)(co-authored-by\s*:.*cursor|"
    r"made-with\s*:.*cursor|"
    r"generated-by\s*:.*cursor|"
    r"--trailer\s+[^\s]*cursor|"
    r"cursoragent@|"
    r"@cursor\.com|"
    r"made with cursor)",
)
if re.search(r"\bgit\s+commit\b", c) and attrib_pat.search(cmd):
    deny("Blocked: never add Cursor/AI Co-authored-by or Made-with trailers. Commit without attribution.")
if re.search(r"\bgh\s+pr\s+create\b", c) and attrib_pat.search(cmd):
    deny("Blocked: never add Cursor attribution to PRs.")

# --- Hard deny: wipe root / home / system trees ---
rm_flags = r"(?:-[a-zA-Z]*[rfR][a-zA-Z]*[rfR]?[a-zA-Z]*|--force|--recursive|--no-preserve-root)"
rm_prefix = rf"(?:^|[;&|]\s*)(?:sudo\s+)?(?:env\s+[^\s;|&]*\s+)*rm"
rm_cmd = rf"{rm_prefix}(?:\s+{rm_flags})+\s+"

dangerous_targets = [
    r"/", r"/\*",
    r"~", r"~/\*",
    r"\$HOME", r"\$HOME/\*",
    r"\$\{HOME\}", r"\$\{HOME\}/\*",
    r"/Users", r"/Users/\*", r"/Users/[^/\s]+", r"/Users/[^/\s]+/\*",
    r"/home", r"/home/\*", r"/home/[^/\s]+", r"/home/[^/\s]+/\*",
    r"/etc(?:/\*)?", r"/usr(?:/\*)?", r"/var(?:/\*)?",
    r"/System(?:/\*)?", r"/Library(?:/\*)?",
    r"/bin(?:/\*)?", r"/sbin(?:/\*)?", r"/opt(?:/\*)?", r"/Applications(?:/\*)?",
]
target_re = "|".join(f"(?:{t})" for t in dangerous_targets)
if re.search(rm_cmd + rf"(?:{target_re})(?:\s|$)", c):
    deny("Blocked: refusing rm against root/home/system paths.")
if re.search(rf"{rm_prefix}\s+(?:{target_re})\s+{rm_flags}", c):
    deny("Blocked: refusing rm against root/home/system paths.")

# --- Hard deny: other catastrophic ---
if re.search(r"git\s+push\b[^;&|]*(\s--force\b|\s-f\b)[^;&|]*\b(main|master)\b", c):
    deny("Blocked: force-push to main/master.")
if re.search(r"git\s+reset\s+--hard\b", c):
    deny("Blocked: git reset --hard.")
if re.search(r"\bmkfs\.", c) or re.search(r"\bdd\s+if=.*\bof=/dev/", c):
    deny("Blocked: disk-destroying command.")
if re.search(r":\(\)\s*\{\s*:\|:\s*&\s*\}\s*;\s*:", c):
    deny("Blocked: fork bomb.")

# curl|sh / wget|bash style remote code execution
if re.search(r"(curl|wget|fetch)\b[^;&|\n]*\|\s*(?:sudo\s+)?(?:ba)?sh\b", c):
    deny("Blocked: pipe remote download into a shell.")
if re.search(r"(curl|wget|fetch)\b[^;&|\n]*\|\s*python(?:3)?\b", c):
    deny("Blocked: pipe remote download into python.")

# --- Ask: git writes (user must explicitly want commits/pushes) ---
if re.search(r"\bgit\s+commit\b", c):
    ask("Git commit. Confirm and ensure there is no Cursor Co-authored-by trailer.")
if re.search(r"\bgit\s+push\b", c):
    ask("Git push. Confirm before allowing.")

# --- Ask: infra / publish nukes ---
if re.search(r"\bterraform\s+(apply|destroy)\b", c):
    ask("Terraform apply or destroy. Confirm before allowing.")
if re.search(r"\bkubectl\s+delete\b", c):
    ask("kubectl delete. Confirm before allowing.")
if re.search(r"\b(npm|pnpm|yarn)\s+publish\b", c):
    ask("Package publish. Confirm before allowing.")
if re.search(r"\bdocker\s+system\s+prune\b", c):
    ask("docker system prune. Confirm before allowing.")

# --- Ask: local mass delete / secrets peek / chmod 777 ---
if re.search(r"\brm\s+(-[a-zA-Z]*f[a-zA-Z]*|--force)", c) and re.search(r"\brm\s+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)", c):
    ask("Recursive force-delete. Confirm before allowing.")
if re.search(r"(^|[;&|]\s*)cat\s+[^\n;|&]*\.env(\s|$)", c):
    ask("Reading .env. Confirm before allowing.")
if re.search(r"chmod\s+-R\s+777\b", c):
    ask("chmod -R 777. Confirm before allowing.")

print('{"permission":"allow"}')
PY
exit 0
