#!/usr/bin/env bash
# =============================================================================
# install-prereqs.sh — install the system packages this Neovim config needs.
#
# Supported: Ubuntu 26.04 LTS (apt) and openSUSE Leap 16.0 / Tumbleweed (zypper).
# The package lists are the ones documented in README.md.
#
# Usage:
#   scripts/install-prereqs.sh                 # required packages
#   scripts/install-prereqs.sh --optional      # + clipboard tools and image preview helpers
#   scripts/install-prereqs.sh --dry-run       # print the commands, change nothing
# =============================================================================

set -euo pipefail

WITH_OPTIONAL=0
DRY_RUN=0

die() {
    echo "❌ $*" >&2
    exit 1
}

for arg in "$@"; do
    case "$arg" in
    --optional) WITH_OPTIONAL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help)
        sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *) die "unknown option ${arg} (see --help)" ;;
    esac
done

[[ -r /etc/os-release ]] || die "/etc/os-release not found: unsupported system"
# shellcheck disable=SC1091
. /etc/os-release
family="${ID:-} ${ID_LIKE:-}"

# --- package lists (names verified against Ubuntu 26.04 and openSUSE Leap 16.0 / Tumbleweed) ---
APT_REQUIRED=(
    neovim git curl wget unzip tar gzip build-essential tree-sitter-cli
    ripgrep fd-find fzf lazygit nodejs npm python3 python3-venv openjdk-25-jdk-headless
)
APT_OPTIONAL=(xclip wl-clipboard imagemagick ghostscript)

ZYPPER_REQUIRED=(
    neovim git curl wget unzip tar gzip patterns-devel-base-devel_basis tree-sitter
    ripgrep fd fzf lazygit nodejs-default npm-default python3 python3-pip java-25-openjdk-headless
)
ZYPPER_OPTIONAL=(xclip wl-clipboard ImageMagick ghostscript)

sudo_cmd=()
if [[ $EUID -ne 0 ]]; then
    sudo_cmd=(sudo)
fi

run() {
    echo "+ $*"
    if [[ $DRY_RUN -eq 0 ]]; then
        "$@"
    fi
}

case "$family" in
*ubuntu* | *debian*)
    packages=("${APT_REQUIRED[@]}")
    [[ $WITH_OPTIONAL -eq 1 ]] && packages+=("${APT_OPTIONAL[@]}")
    run "${sudo_cmd[@]}" apt-get update
    run "${sudo_cmd[@]}" apt-get install -y "${packages[@]}"
    ;;
*suse*)
    packages=("${ZYPPER_REQUIRED[@]}")
    [[ $WITH_OPTIONAL -eq 1 ]] && packages+=("${ZYPPER_OPTIONAL[@]}")
    run "${sudo_cmd[@]}" zypper --non-interactive install --no-recommends "${packages[@]}"
    ;;
*)
    die "unsupported distribution (${PRETTY_NAME:-unknown}): install the packages of README.md by hand"
    ;;
esac

cat <<'EOF'

Next:
  - A Nerd Font is needed in the terminal that shows Neovim (on WSL: install it on Windows).
  - jdtls needs JDK 25; if the default `java` is older, config/jdk.lua finds the JDK 25 by itself.
  - scripts/install-libs.sh   downloads the Groovy / AEM jars
  - scripts/bootstrap.sh      installs plugins, Mason packages and Treesitter parsers
EOF
