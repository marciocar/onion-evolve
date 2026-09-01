#!/usr/bin/env bash
# PreToolUse(Bash) — o 1º uso REAL da capacidade que compra o acoplamento (Onda 7, 2026-09-01).
# Nega force-push para main: a ação irreversível mais barata de barrar. exit 2 = veto ANTES de executar.
# Escopo estreito por desenho: force-push de BRANCH DE TRABALHO segue livre (o fluxo de stack depende dele).
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)
[ -z "$cmd" ] && exit 0
# Julga POR LINHA DE INVOCAÇÃO, nunca a string inteira: heredoc/prosa num comando composto que
# apenas CITA o vocabulário não pode vetar (falso-positivo medido no 1º dogfood, 2026-09-01 —
# a classe guarda-por-vocabulário; o veto pegou o próprio commit desta feature).
push_lines=$(printf '%s\n' "$cmd" | grep -E '^[[:space:]]*git[[:space:]]+push|(&&|\|\||;)[[:space:]]*git[[:space:]]+push')
[ -z "$push_lines" ] && exit 0
printf '%s' "$push_lines" | grep -qE '(--force([^-]|$)|--force-with-lease|[[:space:]]-[a-eg-z]*f[a-z]*([[:space:]]|$))' || exit 0
main_target=0
printf '%s' "$push_lines" | grep -qE '[[:space:]]main([[:space:]]|$|:)' && main_target=1
if [ "$main_target" -eq 0 ]; then
  # sem refspec explícito: o alvo é a branch corrente
  cur=$(git branch --show-current 2>/dev/null)
  [ "$cur" = "main" ] && main_target=1
fi
if [ "$main_target" -eq 1 ]; then
  echo "GUARDA-PRETOOLUSE: force-push para MAIN negado (hook de produção, Onda 7) — reescrever a história da main é irreversível; se for deliberado, o maestro roda fora da sessão." >&2
  exit 2
fi
exit 0
