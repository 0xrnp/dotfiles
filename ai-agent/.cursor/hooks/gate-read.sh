#!/usr/bin/env bash
# Block reading secrets into the model. Fail open on parse errors.
set -u

input=$(cat || true)

python3 - "$input" <<'PY'
import json, re, sys
from pathlib import Path

raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    d = json.loads(raw)
except Exception:
    print('{"permission":"deny","user_message":"Blocked: read gate could not parse the request."}')
    raise SystemExit(0)

path = d.get("file_path") or d.get("path") or ""
name = Path(path).name.lower()
full = path.replace("\\", "/").lower()

# Allow common non-secret examples
allow_names = {
    ".env.example",
    ".env.sample",
    ".env.template",
    "credentials.example.json",
}
if name in allow_names:
    print('{"permission":"allow"}')
    raise SystemExit(0)

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

blocked = name in deny_names or name.endswith(deny_suffixes) or any(b in full for b in deny_path_bits)
# .env.* except allowed examples
if re.fullmatch(r"\.env\..+", name) and name not in allow_names:
    blocked = True

if blocked:
    print(json.dumps({
        "permission": "deny",
        "user_message": f"Blocked reading secret-like file: {Path(path).name}",
    }))
else:
    print('{"permission":"allow"}')
PY
exit 0
