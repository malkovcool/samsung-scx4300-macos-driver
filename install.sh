#!/bin/sh
# Install the QPDL print driver for the Samsung SCX-4300 on macOS.
#
#   Usage:  sudo ./install.sh
#
# Uses the prebuilt arm64 binary in bin/ when possible, otherwise the one you
# built with ./build.sh. Auto-detects the printer's USB address.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
FILTERDIR="/usr/libexec/cups/filter"
QUEUE="Samsung_SCX_4300_Series"
PPD="$HERE/ppd/scx4300.ppd"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:  sudo \"$0\""; exit 1
fi

[ -f "$PPD" ] || { echo "PPD not found at $PPD"; exit 1; }

# Pick the filter binary: freshly built (build/) wins, else the prebuilt arm64 one.
ARCH=$(uname -m)
BIN=""; PBIN=""
BUILT="$HERE/build/splix-2.0.1/optimized"
if [ -x "$BUILT/rastertoqpdl" ]; then
  BIN="$BUILT/rastertoqpdl"; PBIN="$BUILT/pstoqpdl"
elif [ -x "$HERE/bin/rastertoqpdl" ] && [ "$ARCH" = "arm64" ]; then
  BIN="$HERE/bin/rastertoqpdl"; PBIN="$HERE/bin/pstoqpdl"
fi

if [ -z "$BIN" ]; then
  echo "No usable rastertoqpdl binary for this architecture ($ARCH)."
  echo "Build it first (as a normal user, NOT root):"
  echo "    \"$HERE/build.sh\""
  echo "then re-run:  sudo \"$0\""
  exit 2
fi

echo ">>> Installing filter into $FILTERDIR"
cp "$BIN" "$FILTERDIR/rastertoqpdl" && chmod 755 "$FILTERDIR/rastertoqpdl" && chown root:wheel "$FILTERDIR/rastertoqpdl" || exit 11
if [ -n "$PBIN" ] && [ -x "$PBIN" ]; then
  cp "$PBIN" "$FILTERDIR/pstoqpdl" && chmod 755 "$FILTERDIR/pstoqpdl" && chown root:wheel "$FILTERDIR/pstoqpdl"
fi

echo ">>> Detecting the printer on USB..."
URI=$(lpinfo -v 2>/dev/null | awk 'tolower($0) ~ /scx-4300/ {print $2; exit}')
if [ -z "$URI" ]; then
  echo "!! Printer not found on USB. Connect it, power it on, then re-run."
  echo "   (List devices manually with:  lpinfo -v )"
  exit 3
fi
echo "    found: $URI"

echo ">>> Configuring CUPS queue '$QUEUE'"
lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD" || exit 15
cupsenable "$QUEUE" 2>/dev/null
cupsaccept "$QUEUE" 2>/dev/null

echo ""
echo ">>> Done. Queue status:"
lpstat -p "$QUEUE" 2>&1
echo ""
echo "Test it:   echo 'hello' | lp -d $QUEUE"
