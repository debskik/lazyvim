#!/usr/bin/env bash
# =============================================================================
# install-libs.sh — download the Groovy / AEM jars of the groovy-language-server classpath.
#
# Reads scripts/groovy-libs.tsv (name, URL, SHA-256), downloads every jar that is missing or has
# a different checksum into $GROOVY_LIBS_DIR (default ~/libs) and verifies it.
#
# Usage:
#   scripts/install-libs.sh            # download what is missing, verify all
#   scripts/install-libs.sh --check    # verify only, download nothing
#
# Exit code: 0 when every jar is present and verified, 1 otherwise.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/groovy-libs.tsv"
LIBS_DIR="${GROOVY_LIBS_DIR:-${HOME}/libs}"
CHECK_ONLY=0

die() {
    echo "❌ $*" >&2
    exit 1
}

case "${1:-}" in
"") ;;
--check) CHECK_ONLY=1 ;;
-h | --help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
*) die "unknown option $1 (see --help)" ;;
esac

[[ -f "$MANIFEST" ]] || die "manifest not found: ${MANIFEST}"
command -v sha256sum >/dev/null || die "sha256sum not found (coreutils)"
if [[ $CHECK_ONLY -eq 0 ]]; then
    command -v curl >/dev/null || die "curl not found"
    mkdir -p "$LIBS_DIR"
fi

sum_of() {
    sha256sum "$1" | cut -d' ' -f1
}

failed=0
while IFS=$'\t' read -r name url sha || [[ -n "${name:-}" ]]; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    target="${LIBS_DIR}/${name}"

    if [[ -f "$target" && "$(sum_of "$target")" == "$sha" ]]; then
        echo "ok        ${name}"
        continue
    fi
    if [[ $CHECK_ONLY -eq 1 ]]; then
        echo "MISSING   ${name} (absent or checksum differs)"
        failed=1
        continue
    fi

    echo "download  ${name}"
    tmp="$(mktemp "${LIBS_DIR}/.${name}.XXXXXX")"
    if curl -fsSL --retry 3 -o "$tmp" "$url" && [[ "$(sum_of "$tmp")" == "$sha" ]]; then
        mv "$tmp" "$target"
    else
        rm -f "$tmp"
        echo "FAILED    ${name} (download or checksum)" >&2
        failed=1
    fi
done <"$MANIFEST"

if [[ $failed -eq 0 ]]; then
    echo "✅ all jars verified in ${LIBS_DIR}"
fi
exit "$failed"
