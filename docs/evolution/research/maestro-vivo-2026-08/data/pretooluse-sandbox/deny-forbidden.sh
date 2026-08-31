#!/usr/bin/env bash
# PreToolUse: nega qualquer Bash cujo comando contenha o marcador FORBIDDEN_ONION
input=$(cat)
if printf '%s' "$input" | grep -q "FORBIDDEN_ONION"; then
  echo "GUARDA-PRETOOLUSE: comando negado pelo hook (exit 2)" >&2
  exit 2
fi
exit 0
