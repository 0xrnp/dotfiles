#!/usr/bin/env bash
set -u

exec python3 "$HOME/ai-standards/approval-gate.py" cursor prompt
