#!/usr/bin/env bash
set -u

exec python3 "$HOME/ai-standards/verify-turn.py" cursor "$1"
