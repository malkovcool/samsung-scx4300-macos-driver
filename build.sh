#!/bin/sh
# Build the SpliX 'rastertoqpdl' QPDL filter from source, for macOS.
#
#   Usage:  ./build.sh        (run as a NORMAL user — Homebrew refuses root)
#
# Produces bin/rastertoqpdl and bin/pstoqpdl. Then run: sudo ./install.sh
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
WORK="$HERE/build"
ORIG="splix_2.0.1.orig.tar.gz"
URL="https://deb.debian.org/debian/pool/main/s/splix/$ORIG"

echo ">>> Checking toolchain..."
command -v cc          >/dev/null 2>&1 || { echo "Xcode Command Line Tools needed:  xcode-select --install"; exit 1; }
command -v make        >/dev/null 2>&1 || { echo "'make' needed (Xcode Command Line Tools)"; exit 1; }
command -v cups-config >/dev/null 2>&1 || { echo "'cups-config' not found (ships with macOS)"; exit 1; }
command -v curl        >/dev/null 2>&1 || { echo "'curl' needed"; exit 1; }

# jbigkit provides libjbig85, a build dependency.
BREW_PREFIX=$(brew --prefix 2>/dev/null || echo /opt/homebrew)
if [ ! -f "$BREW_PREFIX/lib/libjbig85.a" ]; then
  if command -v brew >/dev/null 2>&1; then
    echo ">>> Installing jbigkit (build dependency) via Homebrew..."
    brew install jbigkit
  else
    echo "Homebrew not found. Install it from https://brew.sh then:  brew install jbigkit"
    exit 1
  fi
fi

mkdir -p "$WORK"; cd "$WORK"
[ -f "$ORIG" ] || { echo ">>> Downloading SpliX 2.0.1 source..."; curl -fSL -o "$ORIG" "$URL"; }
rm -rf splix-2.0.1
tar xf "$ORIG"
cd splix-2.0.1

echo ">>> Repointing MacPorts paths (/opt/local) to Homebrew ($BREW_PREFIX)..."
sed -i '' "s|/opt/local|$BREW_PREFIX|g" module.mk

echo ">>> Compiling..."
make

echo ">>> Installing built binaries into $HERE/bin/"
mkdir -p "$HERE/bin"
cp optimized/rastertoqpdl optimized/pstoqpdl "$HERE/bin/"

echo ""
echo ">>> Build OK. Next:  sudo \"$HERE/install.sh\""
