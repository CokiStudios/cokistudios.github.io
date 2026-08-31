#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# [SYS] Launch hiOP by CS (Looping Studio) — Development Mode
# ═══════════════════════════════════════════════════════════════

set -e
cd "$(dirname "$0")/vscode-src"

export VSCODE_SKIP_NODE_VERSION_CHECK=1
export NODE_ENV=development

echo "[SYS] Launching hiOP by CS with Looping Compile core..."
./scripts/code.sh "$@"
