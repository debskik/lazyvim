#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — set up this Neovim config on a new machine, end to end.
#
#   1. system packages              scripts/install-prereqs.sh       (skip: --no-system)
#   2. Groovy / AEM jars            scripts/install-libs.sh
#   3. plugins at the locked versions   nvim --headless "+Lazy! restore" (twice, see below)
#   4. Mason packages + Treesitter parsers   lua require('config.bootstrap').install()
#   5. verification                 scripts/verify.sh
#
# The config has to be at ~/.config/nvim (git clone <repo> ~/.config/nvim).
#
# Usage:
#   scripts/bootstrap.sh [--no-system] [--optional]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
NO_SYSTEM=0
PREREQ_ARGS=()

die() {
    echo "❌ $*" >&2
    exit 1
}

for arg in "$@"; do
    case "$arg" in
    --no-system) NO_SYSTEM=1 ;;
    --optional) PREREQ_ARGS+=(--optional) ;;
    -h | --help)
        sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *) die "unknown option ${arg} (see --help)" ;;
    esac
done

step() {
    echo
    echo "==== $* ===="
}

if [[ $NO_SYSTEM -eq 0 ]]; then
    step "1/5 system packages"
    "${SCRIPT_DIR}/install-prereqs.sh" "${PREREQ_ARGS[@]}"
fi

command -v nvim >/dev/null || die "nvim not found: install the system packages first"
[[ "$(realpath "$CONFIG_DIR")" == "$(realpath "${XDG_CONFIG_HOME:-${HOME}/.config}/nvim")" ]] ||
    die "this config is not the one Neovim loads: clone it to ${XDG_CONFIG_HOME:-${HOME}/.config}/nvim"

step "2/5 Groovy / AEM jars"
"${SCRIPT_DIR}/install-libs.sh"

# A first restore on an empty machine can move plugins and rewrite lazy-lock.json (it did for
# SchemaStore.nvim). Keep the committed lockfile and restore a second time against it.
step "3/5 plugins (lazy-lock.json)"
cp "${CONFIG_DIR}/lazy-lock.json" "${CONFIG_DIR}/lazy-lock.json.bak"
nvim --headless "+Lazy! restore" "+qa"
cp "${CONFIG_DIR}/lazy-lock.json.bak" "${CONFIG_DIR}/lazy-lock.json"
nvim --headless "+Lazy! restore" "+qa"
rm -f "${CONFIG_DIR}/lazy-lock.json.bak"

step "4/5 Mason packages and Treesitter parsers"
nvim --headless -c "lua require('config.bootstrap').install()"

step "5/5 verification"
"${SCRIPT_DIR}/verify.sh"
