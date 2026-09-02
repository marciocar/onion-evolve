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
# a classe guarda-por-vocabulário; o veto pegou o próprio commit desta feature). A redução mora na
# lib partilhada com o merge-gate desde a auditoria de 2026-09-02, que mediu `command git push -f
# origin main`, `\git push`, `env git push`, `bash -c "…"` e `git -C . push` passando rc=0 aqui.
# shellcheck source=lib/invocation-lines.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/invocation-lines.sh"
push_lines=$(onion_invocation_lines "$cmd" | grep -E '^git[[:space:]]+push([[:space:]]|$)' || true)
[ -z "$push_lines" ] && exit 0
printf '%s' "$push_lines" | grep -qE '(--force([^-]|$)|--force-with-lease|[[:space:]]-[a-eg-z]*f[a-z]*([[:space:]]|$))' || exit 0
main_target=0
# `HEAD:main` / `x:main` / `refs/heads/main` também são alvo main — a v1 exigia ESPAÇO antes de
# `main` e deixava passar o refspec com dois-pontos (buraco achado pela bancada da auditoria
# D_AUDITAR_GATES_TEXTUAIS, 2026-09-02: `git push -f origin HEAD:main` saía rc=0).
printf '%s' "$push_lines" | grep -qE '([[:space:]]|:)(refs/heads/)?main([[:space:]]|$|:)' && main_target=1
if [ "$main_target" -eq 0 ]; then
  # Fallback branch-corrente SÓ para push NU (flags apenas, sem remote/refspec): um push com alvo
  # explícito que não cita main não pode herdar o veto da branch onde a sessão está SENTADA —
  # o 2º falso-positivo de produção (2026-09-01): loop de merge parado em main pushava "$br" de
  # feature e era vetado. Push nu = a linha termina após push+flags.
  if printf '%s' "$push_lines" | grep -qE 'git[[:space:]]+push([[:space:]]+-[^[:space:]]+)*[[:space:]]*$'; then
    cur=$(git branch --show-current 2>/dev/null)
    [ "$cur" = "main" ] && main_target=1
  fi
fi
if [ "$main_target" -eq 1 ]; then
  echo "GUARDA-PRETOOLUSE: force-push para MAIN negado (hook de produção, Onda 7) — reescrever a história da main é irreversível; se for deliberado, o maestro roda fora da sessão." >&2
  exit 2
fi
exit 0
