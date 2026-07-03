#!/bin/sh
# Scan from the Samsung SCX-4300 flatbed on macOS, via SANE (xerox_mfp backend).
#
#   ./scan.sh                         # Color, 300 dpi, PDF -> ~/Desktop/scan-<timestamp>.pdf
#   ./scan.sh -m Gray -r 150 -f png   # grayscale 150 dpi PNG
#   ./scan.sh -o ~/Desktop/doc.pdf    # explicit output path
#
# Options:
#   -r  resolution: 75|100|150|200|300|600   (default 300)
#   -m  mode:       Color|Gray|Lineart|Halftone   (default Color)
#   -f  format:     pdf|png|jpeg|tiff        (default pdf)
#   -o  output file (default ~/Desktop/scan-<timestamp>.<ext>)
#
# Needs:  brew install sane-backends
set -u

RES=300; MODE=Color; FORMAT=pdf; OUT=""
while getopts "r:m:f:o:h" opt; do
  case "$opt" in
    r) RES=$OPTARG ;;
    m) MODE=$OPTARG ;;
    f) FORMAT=$OPTARG ;;
    o) OUT=$OPTARG ;;
    h) sed -n '2,14p' "$0"; exit 0 ;;
    *) exit 2 ;;
  esac
done

BREW_PREFIX=$(brew --prefix 2>/dev/null || echo /opt/homebrew)
SCANIMAGE="$BREW_PREFIX/bin/scanimage"
[ -x "$SCANIMAGE" ] || SCANIMAGE=$(command -v scanimage 2>/dev/null || true)
[ -x "$SCANIMAGE" ] || { echo "scanimage not found. Install it:  brew install sane-backends"; exit 1; }

if [ -z "$OUT" ]; then
  ext=$FORMAT; [ "$FORMAT" = jpeg ] && ext=jpg
  OUT="$HOME/Desktop/scan-$(date +%Y%m%d-%H%M%S).$ext"
fi

echo ">>> Detecting scanner..."
DEV=$("$SCANIMAGE" -L 2>/dev/null | grep -o "xerox_mfp:[^']*" | head -1)
[ -n "$DEV" ] || { echo "Scanner not found. Is the printer powered on and connected via USB?"; echo "Check with:  $SCANIMAGE -L"; exit 3; }
echo "    $DEV"

# For PDF we scan to PNG first, then wrap with sips (built into macOS).
SANE_FMT=$FORMAT; [ "$FORMAT" = pdf ] && SANE_FMT=png
TMP=$(mktemp -t scx4300scan)
ERR=$(mktemp -t scx4300err)

echo ">>> Put the document face-down on the glass. Scanning ($MODE, ${RES} dpi)..."
# The very first scan after power-on often fails with a transient USB I/O error, so retry.
ok=0
for i in 1 2 3 4 5; do
  if "$SCANIMAGE" -d "$DEV" --mode "$MODE" --resolution "$RES" --format="$SANE_FMT" > "$TMP" 2> "$ERR" \
     && [ "$(stat -f%z "$TMP" 2>/dev/null || echo 0)" -gt 5000 ]; then
    ok=1; break
  fi
  echo "    attempt $i: $(tr '\n' ' ' < "$ERR")retrying..."
done
if [ "$ok" != 1 ]; then
  echo "Scan failed after 5 tries. Last error:"; cat "$ERR"; rm -f "$TMP" "$ERR"; exit 4
fi
rm -f "$ERR"

if [ "$FORMAT" = pdf ]; then
  sips -s format pdf "$TMP" --out "$OUT" >/dev/null 2>&1 || { echo "PDF conversion failed"; rm -f "$TMP"; exit 5; }
  rm -f "$TMP"
else
  mv "$TMP" "$OUT"
fi

echo ">>> Saved: $OUT"
[ -z "${SCAN_NO_OPEN:-}" ] && command -v open >/dev/null 2>&1 && open "$OUT"
