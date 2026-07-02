#!/usr/bin/env bash
# =============================================================================
# merge-onion-hooks.sh — Merge IDEMPOTENTE dos hooks Onion no settings.json do alvo
#
# Propósito : Levar os hooks Onion (SessionStart "you have mail" + worklog;
#             PreCompact breadcrumb) ao settings.json de um repo ADOTADO **sem
#             clobbar** hooks/permissions próprios do alvo. Resolve o gap do
#             /meta:adopt --update (sinal de campo
#             docs/evolution/inbox/2026-06-18-adopt-update-skips-phase3-steps.md):
#             um adotante com settings.json próprio recebia os SCRIPTS dos hooks
#             mas não o REGISTRO → o aviso 📬 não disparava.
#
# Mecânica  : Para cada evento COM HOOKS NA FONTE (derivado de $src.hooks|keys —
#             não hardcoded; regressão 2026-07-02: a lista fixa [SessionStart,
#             PreCompact] deixaria UserPromptSubmit/SessionEnd do farol de sessão
#             fora da distribuição), garante que cada
#             entrada de hook da FONTE esteja presente no ALVO. "Presente" =
#             existe no alvo um hook com o MESMO .command (os commands Onion são
#             canônicos e idênticos após a cópia do manifesto — bash .claude/
#             hooks/X.sh / detector inline). Ausentes são ANEXADOS como grupo
#             próprio ({hooks:[obj]}); tudo do alvo é preservado.
#             IDEMPOTENTE: rodar 2× = no-op na 2ª (todos já presentes).
#
# Uso       : merge-onion-hooks.sh <source-settings.json> <target-settings.json>
#             Emite o JSON merjado em STDOUT (não escreve no lugar — o chamador
#             redireciona). Exit 0 em sucesso.
#
# Fallback  : sem jq → emite o target inalterado em STDOUT + aviso em STDERR +
#             exit 3 (o chamador decide; mesma doutrina graciosa dos worklog-*.sh).
#
# Determinístico, sem LLM. Consumido por /meta:adopt (Fase 3 + --update) e
# exercitado pelo lint-selftest.sh (kind=merge).
# =============================================================================
set -euo pipefail

SRC="${1:-}"
TGT="${2:-}"

if [ -z "${SRC}" ] || [ -z "${TGT}" ]; then
  echo "uso: merge-onion-hooks.sh <source-settings.json> <target-settings.json>" >&2
  exit 2
fi
[ -f "${SRC}" ] || { echo "ERRO: source não encontrado: ${SRC}" >&2; exit 2; }
[ -f "${TGT}" ] || { echo "ERRO: target não encontrado: ${TGT}" >&2; exit 2; }

# Fallback gracioso (padrão dos hooks de worklog): sem jq, não muta — devolve o
# alvo como está e sinaliza, em vez de corromper o settings.json.
if ! command -v jq >/dev/null 2>&1; then
  echo "AVISO: jq ausente — settings.json do alvo NÃO merjado (registre os hooks Onion à mão)." >&2
  cat "${TGT}"
  exit 3
fi

# Para cada evento, anexa ao alvo os hooks da fonte cujo .command ainda não
# aparece no alvo (índice por .command). Preserva matchers/permissions/outros.
jq -n \
  --slurpfile s "${SRC}" \
  --slurpfile t "${TGT}" '
  ($s[0]) as $src | ($t[0]) as $tgt |
  reduce (($src.hooks // {}) | keys[]) as $ev ($tgt;
    # commands Onion já presentes no alvo, para este evento
    ([ (.hooks[$ev] // [])[].hooks[]?.command ]) as $present
    # entradas de hook da fonte (achatando os grupos) ainda ausentes no alvo
    | ([ ($src.hooks[$ev] // [])[].hooks[]?
         | select(.command as $c | ($present | index($c)) == null) ]) as $missing
    # garante .hooks objeto e anexa cada ausente como grupo próprio
    | .hooks = (.hooks // {})
    | .hooks[$ev] = ((.hooks[$ev] // []) + [ $missing[] | {hooks: [.]} ])
  )
'
