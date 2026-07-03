#!/bin/sh
# Double-click in Finder to scan from the Samsung SCX-4300 to a PDF.
# (Runs scan.sh from this same folder with default settings.)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
cd "$(dirname "$0")" || exit 1
./scan.sh || { echo ""; echo "Press Enter to close this window."; read -r _; }
