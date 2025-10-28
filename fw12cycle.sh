#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-eDP-1}"
TRANSFORMS=(normal 90 180)
RAW_TRANSFORM=$(niri msg outputs 2>/dev/null | awk -v out="(${OUTPUT})" '
  /^Output[[:space:]]/ { in_block = (index($0, out) > 0) }
  in_block && /^[[:space:]]*Transform:/ {
    sub(/^[[:space:]]*Transform:[[:space:]]*/, "", $0)
    print $0
    exit
  }
')

if [[ -z "${RAW_TRANSFORM:-}" ]]; then
  echo "Warning: could not parse Transform for $OUTPUT; assuming 'normal'." >&2
  CURRENT="180"
else
  if awk 'BEGIN{IGNORECASE=1} /normal/ {exit 0} {exit 1}' <<<"$RAW_TRANSFORM"; then
    CURRENT="normal"
  else
    NUM=$(grep -oE '[0-9]+' <<<"$RAW_TRANSFORM" | head -n1 || true)
    if [[ -z "$NUM" ]]; then
      echo "Warning: no numeric degrees found in Transform ('$RAW_TRANSFORM'), defaulting to 'normal'." >&2
      CURRENT="normal"
    else
      if [[ "$NUM" -eq 270 ]]; then
        CURRENT="90"
      else
        CURRENT="$NUM"
      fi
    fi
  fi
fi

INDEX=-1
for i in "${!TRANSFORMS[@]}"; do
  if [[ "${TRANSFORMS[i]}" == "$CURRENT" ]]; then
    INDEX=$i
    break
  fi
done

if [[ $INDEX -eq -1 ]]; then
  NEXT="${TRANSFORMS[0]}"
else
  NEXT_INDEX=$(( (INDEX + 1) % ${#TRANSFORMS[@]} ))
  NEXT="${TRANSFORMS[NEXT_INDEX]}"
fi

niri msg output "$OUTPUT" transform "$NEXT"
echo "$OUTPUT: $CURRENT -> $NEXT"
