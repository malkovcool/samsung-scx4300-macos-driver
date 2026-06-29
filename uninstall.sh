#!/bin/sh
# Remove the Samsung SCX-4300 driver and its print queue.
#   Usage:  sudo ./uninstall.sh
set -u

QUEUE="Samsung_SCX_4300_Series"
FILTERDIR="/usr/libexec/cups/filter"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:  sudo \"$0\""; exit 1
fi

echo ">>> Removing CUPS queue '$QUEUE'"
lpadmin -x "$QUEUE" 2>/dev/null || true

echo ">>> Removing filters"
rm -f "$FILTERDIR/rastertoqpdl" "$FILTERDIR/pstoqpdl"

echo ">>> Done."
