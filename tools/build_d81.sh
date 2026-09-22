#!/usr/bin/env bash
# Build megamind.prg and megamind.d81 (BASIC65 + Mega-IP eth.bin + config)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${ROOT}/target"
mkdir -p "$TARGET"

PETCAT="${PETCAT:-petcat}"
C1541="${C1541:-c1541}"

if ! command -v "$PETCAT" >/dev/null 2>&1; then
  echo "petcat not found (VICE). Set PETCAT=/path/to/petcat" >&2
  exit 1
fi
if ! command -v "$C1541" >/dev/null 2>&1; then
  echo "c1541 not found (VICE). Set C1541=/path/to/c1541" >&2
  exit 1
fi

echo "petcat -> megamind.prg"
"$PETCAT" -w65 -o "$TARGET/megamind.prg" -- "$ROOT/basic/megamind.bas"

cp "$ROOT/vendor/eth.bin" "$TARGET/eth.bin"
cp "$ROOT/config/megamind.cfg" "$TARGET/megamind.cfg"

echo "c1541 -> megamind.d81"
rm -f "$TARGET/megamind.d81"
"$C1541" -format "megamind,65" d81 "$TARGET/megamind.d81"
"$C1541" "$TARGET/megamind.d81" \
  -write "$TARGET/megamind.prg" megamind \
  -write "$TARGET/eth.bin" eth.bin \
  -write "$TARGET/megamind.cfg" megamind.cfg,s

echo "OK: $TARGET/megamind.d81"
ls -la "$TARGET/megamind.d81" "$TARGET/megamind.prg"
"$C1541" "$TARGET/megamind.d81" -list
