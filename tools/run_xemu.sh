#!/usr/bin/env bash
# Launch xemu MEGA65 with megamind.d81
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D81="${ROOT}/target/megamind.d81"
XEMU="${XEMU:-}"

if [[ ! -f "$D81" ]]; then
  "${ROOT}/tools/build_d81.sh"
fi

if [[ -z "$XEMU" ]]; then
  for c in xemu-xmega65 xmega65 "$HOME/.local/bin/xemu-xmega65"; do
    if command -v "$c" >/dev/null 2>&1; then XEMU="$(command -v "$c")"; break; fi
    if [[ -x "$c" ]]; then XEMU="$c"; break; fi
  done
fi

if [[ -z "${XEMU}" || ! -x "${XEMU}" ]]; then
  echo "xemu MEGA65 binary not found. Set XEMU=/path/to/xemu-xmega65" >&2
  exit 1
fi

EXTRA=()
if [[ -n "${ETHERTAP:-}" ]]; then
  EXTRA+=(-ethertap "$ETHERTAP")
fi
if [[ "${HEADLESS:-}" == "1" ]]; then
  EXTRA+=(-headless -nosound -sleepless -fastboot)
fi

echo "Using: $XEMU"
echo "Disk:  $D81"
echo "Autoload via -autoload (LOAD/RUN megamind)"
exec "$XEMU" -skipconfigfile -8 "$D81" -autoload -besure "${EXTRA[@]}" "$@"
