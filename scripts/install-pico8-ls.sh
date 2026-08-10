#!/bin/sh
# Build and install pico8-ls, the PICO-8 language server.
#
# pico8-ls ships only as a VS Code extension -- there is no `pico8-ls` package
# on npm, so `npm i -g pico8-ls` returns 404. This clones the repo, builds the
# server, and drops a wrapper on your PATH.
#
# Requires: git, node, npm.

set -eu

PREFIX="${PREFIX:-$HOME/.local}"
SRC="${SRC:-$PREFIX/share/pico8-ls}"
BIN="$PREFIX/bin/pico8-ls"
REPO="${REPO:-https://github.com/japhib/pico8-ls}"

for tool in git node npm; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "error: $tool is required but not installed" >&2
        exit 1
    }
done

if [ -d "$SRC/.git" ]; then
    echo "==> updating $SRC"
    git -C "$SRC" pull --ff-only
else
    echo "==> cloning into $SRC"
    mkdir -p "$(dirname "$SRC")"
    git clone --depth 1 "$REPO" "$SRC"
fi

echo "==> installing server dependencies"
cd "$SRC/server"
npm install --no-audit --no-fund

echo "==> compiling"
# tsc reports errors in the upstream test files (missing mocha types). Those
# are harmless -- what matters is that out/server.js is produced.
npx tsc -p ./ || true

if [ ! -f "$SRC/server/out/server.js" ]; then
    echo "error: build failed, $SRC/server/out/server.js was not produced" >&2
    exit 1
fi

echo "==> installing wrapper to $BIN"
mkdir -p "$PREFIX/bin"
cat >"$BIN" <<EOF
#!/bin/sh
exec node "$SRC/server/out/server.js" "\$@"
EOF
chmod +x "$BIN"

echo
echo "installed: $BIN"
case ":$PATH:" in
    *":$PREFIX/bin:"*) ;;
    *) echo "warning: $PREFIX/bin is not on your PATH" >&2 ;;
esac
