#!/usr/bin/env bash
# =============================================================================
# resolve-context-dir.sh — diz ONDE mora o contexto de domínio (negócio, técnico, compliance) deste repo.
#
# O passo 1 do resolver das skills de contexto (onion-product-context, onion-engineering-context,
# onion-compliance-context §2) era só prosa, e os comandos que GRAVAM o contexto não o liam: os cinco
# `/docs:build-*` escreviam em `docs/<dim>-context/` fixo. Sinal de campo de 2026-10-19
# (um hub): o repo declara `context.compliance: docs/compliance` em `.claude/onion-context.yaml`,
# e o `/docs:build-compliance-docs` gerou noutra pasta. Declaração explícita vence convenção (skill §2.1);
# este helper é essa regra em forma que se executa.
#
# Ordem (a primeira que responder vence):
#   1. `.claude/onion-context.yaml`, chave `context.<dim>` (o mapa dedicado);
#   2. `.claude/.onion-version` ou `.onion-version`, SÓ se for JSON com `context.<dim>` (o carimbo de
#      adoção hoje é `chave: valor` e não carrega `context` — medido em 2026-10-20 num hub —, então
#      este passo quase sempre cala; fica porque as skills o declaram);
#   3. o default `docs/<dim>-context` (o layout Onion padrão).
#
# Uso   : resolve-context-dir.sh <business|technical|compliance> [--repo <dir>] [--source]
#         --source : imprime também a origem, separada por TAB (`<caminho>\t<onion-context|stamp|default>`).
# Saída : o caminho RELATIVO à raiz do repo, sem barra final.
# Exit  : 0 = resolvido · 2 = uso · 3 = declaração inválida (absoluta, com `..` ou vazia) — o comando PARA:
#         gravar no default calado quando o repo declarou outra coisa é exatamente o defeito de campo.
# Só lê; nunca cria a pasta. Exercitado por lint-selftest.sh (run_resolve_context_dir_selftests).
# TETO: o leitor de YAML é de LINHA (bloco `context:` na margem, chave indentada abaixo, valor escalar
#   na mesma linha). YAML de fluxo (`context: {compliance: x}`) ou âncora não é lido e cai no default,
#   com AVISO no stderr se o arquivo existe e cita a dimensão.
# =============================================================================
set -uo pipefail

DIM=""; REPO=""; SHOW_SOURCE=0
usage() { echo "uso: resolve-context-dir.sh <business|technical|compliance> [--repo <dir>] [--source]" >&2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --repo)   [ "$#" -ge 2 ] || { usage; exit 2; }; REPO="$2"; shift 2 ;;
  --source) SHOW_SOURCE=1; shift ;;
  -h|--help) usage; exit 0 ;;
  -*) usage; exit 2 ;;
  *) [ -z "${DIM}" ] && DIM="$1" || { usage; exit 2; }; shift ;;
esac; done
case "${DIM}" in business|technical|compliance) : ;; *) usage; exit 2 ;; esac
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "${REPO}" ] || { echo "ERRO: repo inexistente: ${REPO}" >&2; exit 2; }

emit() { # <caminho> <origem>
  local p="$1"
  p="${p%/}"
  if [ -z "${p}" ] || [ "${p#/}" != "${p}" ] || [[ "/${p}/" == *"/../"* ]]; then
    echo "ERRO: ${2} declara context.${DIM} = '${1}' — o caminho tem de ser relativo à raiz, sem '..'. Corrija a declaração; não gravo no default em silêncio." >&2
    exit 3
  fi
  if [ "${SHOW_SOURCE}" -eq 1 ]; then printf '%s\t%s\n' "${p}" "$2"; else printf '%s\n' "${p}"; fi
  exit 0
}

# 1. .claude/onion-context.yaml — leitor de linha (sem dependência de PyYAML)
MAP="${REPO}/.claude/onion-context.yaml"
if [ -f "${MAP}" ]; then
  # Só a chave FILHA DIRETA de `context:` responde: a indentação do 1º filho fixa o nível, e uma chave
  # igual aninhada mais fundo (`context: / nested: / compliance:`) não conta. BOM e CRLF não escondem nada.
  # Valor entre aspas guarda `#`; sem aspas, `#` precedido de espaço abre comentário.
  val="$(awk -v dim="${DIM}" '
    { sub(/\r$/, ""); if (NR == 1) sub(/^\357\273\277/, "") }
    /^context:[[:space:]]*(#.*)?$/ { inctx = 1; ind = -1; next }
    /^[^[:space:]#]/ { inctx = 0 }
    inctx && /^[[:space:]]+[^[:space:]#]/ {
      match($0, /^[[:space:]]+/); if (ind < 0) ind = RLENGTH
      if (RLENGTH != ind) next
      if ($0 !~ "^[[:space:]]+" dim ":([[:space:]]|$)") next
      v = $0; sub("^[[:space:]]+" dim ":[[:space:]]*", "", v)
      if (v ~ /^"/)       { sub(/^"/, "", v); sub(/".*$/, "", v) }
      else if (v ~ /^\047/) { sub(/^\047/, "", v); sub(/\047.*$/, "", v) }
      else                { sub(/[[:space:]]+#.*$/, "", v); sub(/[[:space:]]+$/, "", v) }
      print v; found = 1; exit }
    END { if (!found) exit 1 }' "${MAP}")" && emit "${val}" "onion-context"
  command grep -qE "(^|[^a-z])${DIM}([^a-z]|$)" <<< "$(command grep -vE '^[[:space:]]*#' "${MAP}" 2>/dev/null)" \
    && echo "AVISO: ${MAP} cita '${DIM}' fora da forma lida (bloco 'context:' + chave indentada) — usando o próximo passo do resolver" >&2
fi

# 2. carimbo JSON (raro: o carimbo de adoção não é JSON hoje)
for stamp in "${REPO}/.claude/.onion-version" "${REPO}/.onion-version"; do
  [ -f "${stamp}" ] || continue
  head -c 1 "${stamp}" 2>/dev/null | command grep -q '{' || continue
  command -v python3 >/dev/null 2>&1 || { echo "AVISO: ${stamp} é JSON mas não há python3 para lê-lo — pulando" >&2; continue; }
  val="$(python3 -I -c 'import json,sys
try:
    d=json.load(open(sys.argv[1]))
    v=(d.get("context") or {}).get(sys.argv[2])
    print(v) if isinstance(v,str) else sys.exit(1)
except Exception:
    sys.exit(1)' "${stamp}" "${DIM}" 2>/dev/null)" && emit "${val}" "stamp"
done

# 3. default
emit "docs/${DIM}-context" "default"
