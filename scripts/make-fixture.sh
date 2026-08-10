#!/bin/sh
# Regenerate test/fixtures/manual-signatures.txt from a PICO-8 manual.
#
# The manual ships with PICO-8 and is not redistributable in full, so CI runs
# the API check against just the signature lines. Run this after a PICO-8
# upgrade to pick up new or changed API functions.
#
# Usage: scripts/make-fixture.sh [path/to/pico-8_manual.txt]

set -eu

MANUAL="${1:-}"

if [ -z "$MANUAL" ]; then
    for candidate in \
        /opt/pico-8/pico-8_manual.txt \
        /usr/share/pico-8/pico-8_manual.txt \
        "$HOME/pico-8/pico-8_manual.txt" \
        "/Applications/PICO-8.app/Contents/Resources/pico-8_manual.txt"; do
        if [ -f "$candidate" ]; then
            MANUAL="$candidate"
            break
        fi
    done
fi

if [ -z "$MANUAL" ] || [ ! -f "$MANUAL" ]; then
    echo "error: could not find pico-8_manual.txt; pass its path" >&2
    exit 1
fi

DEST="$(dirname "$0")/../test/fixtures/manual-signatures.txt"
mkdir -p "$(dirname "$DEST")"

VERSION="$(grep -m1 -oE 'PICO-8 v[0-9.]+' "$MANUAL" || echo 'PICO-8 (version unknown)')"

{
    echo "$VERSION API signature lines, extracted from pico-8_manual.txt."
    echo "Fixture for scripts/check-api.lua so CI can run without the manual,"
    echo "which ships only with PICO-8 (paid software)."
    echo ""
    echo "Regenerate with: scripts/make-fixture.sh /path/to/pico-8_manual.txt"
    echo ""
    grep -E '^ {4}[A-Z_][A-Z0-9_]*\(' "$MANUAL"
} >"$DEST"

echo "wrote $DEST ($(wc -l <"$DEST" | tr -d ' ') lines) from $VERSION"
