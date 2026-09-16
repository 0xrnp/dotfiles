#!/usr/bin/env bash
# Block secret-like paths and malformed read requests.
set -eu

input=$(cat || true)

python3 - "$input" <<'PY'
import json, os, re, sys
from pathlib import Path

raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    d = json.loads(raw)
except Exception:
    print('{"permission":"deny","user_message":"Blocked: read gate could not parse the request."}')
    raise SystemExit(0)

path = (d.get("file_path") or d.get("path")) if isinstance(d, dict) else None
cwd = d.get("cwd", os.getcwd()) if isinstance(d, dict) else None
if not isinstance(path, str) or not path.strip() or not isinstance(cwd, str) or not cwd.strip():
    print('{"permission":"deny","user_message":"Invalid read path."}')
    raise SystemExit(0)

try:
    original = Path(path.replace("\\", "/")).expanduser()
    resolved = (Path(cwd) / original).resolve()
except (OSError, RuntimeError, ValueError):
    print('{"permission":"deny","user_message":"Read path could not be resolved."}')
    raise SystemExit(0)

# Allow common non-secret examples
allow_names = {
    ".env.example",
    ".env.sample",
    ".env.template",
    "credentials.example.json",
}
deny_names = {
    ".env",
    ".env.local",
    ".env.production",
    ".env.development",
    ".env.staging",
    "id_rsa",
    "id_ed25519",
    "id_ecdsa",
    "credentials.json",
    "service-account.json",
}
deny_suffixes = (".pem", ".p12", ".pfx", ".key")
deny_path_bits = (
    "/.ssh/",
    "/secrets/",
    "/.aws/credentials",
    "/.config/gcloud/",
)

def secret_like(candidate):
    name = candidate.name.lower()
    full = "/" + str(candidate).replace("\\", "/").lower().lstrip("/")
    if any(bit in full for bit in deny_path_bits):
        return True
    if name in allow_names:
        return False
    return name in deny_names or name.endswith(deny_suffixes) or bool(re.fullmatch(r"\.env\..+", name))

blocked = secret_like(original) or secret_like(resolved)

if blocked:
    print(json.dumps({
        "permission": "deny",
        "user_message": f"Blocked reading secret-like file: {Path(path).name}",
    }))
else:
    print('{"permission":"allow"}')
PY
exit 0
