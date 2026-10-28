#!/usr/bin/env bash
# =============================================================================
# verify.sh — check that everything the config needs is installed on this machine.
#
# Reports programs, a JDK 25+ for jdtls, Mason packages, Treesitter parsers and the Groovy jars.
# Installs nothing. Exit code 1 when something is missing.
#
# Usage:
#   scripts/verify.sh
# =============================================================================

set -euo pipefail

command -v nvim >/dev/null || {
    echo "❌ nvim not found" >&2
    exit 1
}

nvim --headless -c "lua require('config.bootstrap').check()"
