#!/usr/bin/env bash
# onion-effect-gate.sh — R15.3b (ONION-R15): gate de efeito para ação DERIVADA de conteúdo não-confiável.
#
# PROTÓTIPO isolado (discuss/guardrails-nemo-lens). NÃO é o core — dogfood em quarentena.
#
# Propósito: torna EXECUTÁVEL a camada de liberação (intake×execução, authorization-layers) para o canal C3
# (adopt / reverse-consolidate), que — diferente de C1/C2 — não tem o efeito-gate estrutural. Dado um verbo
# de ação e se ela deriva de conteúdo não-confiável, decide: INTAKE (autônomo, segue) vs EXECUÇÃO
# (irreversível/externo → GATE, requer o maestro).
#
# A regra determinizável (o núcleo de R15.3b):
#   AÇÃO DE EXECUÇÃO **derivada de conteúdo não-confiável** = SEMPRE gate (requer maestro).
#   Ingestão/análise/rascunho é autônomo; commit/push/PR/apply/send/install é gated quando a origem é suspeita.
#
# Fail-safe (padrão Onion: deny-by-default como trust-topology / veto como a2a-verify):
#   verbo DESCONHECIDO → gate. Na dúvida, exige o maestro.
#
# Uso : onion-effect-gate.sh --action <verbo> [--untrusted-derived true|false]
# Exit: 0 = allow (segue) · 3 = gate (requer maestro) · 2 = uso inválido.
# Stdout: "<verdict> <classe>" — ex.: "allow intake" · "gate execution-untrusted" · "gate unknown-verb"

set -uo pipefail

ACTION=""; UNTRUSTED="false"
# guarda contra flag-sem-valor: `shift 2` com 1 só argumento falha (rc=1) e, sem `set -e`, o loop
# reprocessaria $1 para sempre. Exige o valor ANTES de deslocar.
while [ $# -gt 0 ]; do
  case "$1" in
    --action)            [ $# -ge 2 ] || { echo "ERRO: --action requer valor" >&2; exit 2; }; ACTION="$2"; shift 2 ;;
    --untrusted-derived) [ $# -ge 2 ] || { echo "ERRO: --untrusted-derived requer valor" >&2; exit 2; }; UNTRUSTED="$2"; shift 2 ;;
    -h|--help)           echo "uso: onion-effect-gate.sh --action <verbo> [--untrusted-derived true|false]"; exit 0 ;;
    *)                   echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

[ -n "$ACTION" ] || { echo "ERRO: --action obrigatório" >&2; exit 2; }
case "$UNTRUSTED" in true|false) ;; *) echo "ERRO: --untrusted-derived deve ser true|false" >&2; exit 2 ;; esac

# normaliza o verbo (lower, sem espaços)
VERB="$(printf '%s' "$ACTION" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"

# classes de verbo (whitelist de intake · denylist de execução)
INTAKE="read analyze summarize draft propose plan generate-draft write-scratchpad review classify extract"
EXECUTION="commit push pr merge tag apply install delete send deliver publish rebase reset force-push amend"

in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

if in_list "$VERB" "$INTAKE"; then
  echo "allow intake"; exit 0
elif in_list "$VERB" "$EXECUTION"; then
  if [ "$UNTRUSTED" = "true" ]; then
    echo "gate execution-untrusted"                                  # o coração de R15.3b
    echo "  → ação de execução derivada de conteúdo não-confiável: requer o maestro (gate de liberação)." >&2
    exit 3
  else
    echo "allow execution-normal"                                    # fora do escopo de R15; fluxo normal (GitFlow/forge) aplica seus gates
    exit 0
  fi
else
  echo "gate unknown-verb"                                           # fail-safe: deny-by-default
  echo "  → verbo '$VERB' não classificado: gated por segurança (na dúvida, maestro)." >&2
  exit 3
fi
