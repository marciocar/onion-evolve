#!/usr/bin/env bash
# =============================================================================
# file-to-tokens.sh — source DETERMINÍSTICO (adapter `file` do design-source)
#
# INGESTÃO: lê uma paleta "flat" (mapa nome→cor) de um arquivo/STDIN e emite a
# SSOT em W3C/DTCG (docs/design-context/*.tokens.json) em STDOUT. É a via-de-
# entrada espelhada do design-sink (que faz a SAÍDA, DTCG→formato-alvo).
#
#   entrada (flat)            saída (DTCG)
#   {                         {
#     "brand.orange":"#D97757"  "$schema":"…",
#     "neutral.0":"#FFFFFF"     "color": { "$type":"color",
#   }                             "brand":   { "orange": { "$value":"#D97757" } },
#                                 "neutral": { "0":      { "$value":"#FFFFFF" } } } }
#
# Chaves PONTILHADAS viram aninhamento DTCG (`brand.orange` → color.brand.orange).
# Tradução de DADOS (sem LLM). O gate lint-design-tokens.sh valida a saída
# (DTCG + refs + WCAG) ANTES de ela entrar na SSOT — este script só normaliza.
#
# Uso     : file-to-tokens.sh <paleta.json|-> [<grupo>] [<$type>]
#           <grupo> default "color"; <$type> default "color". "-" lê de STDIN.
# Saída   : DTCG JSON em STDOUT (o chamador redireciona para o arquivo da SSOT).
# Falha   : valor não-hex (#rgb/#rrggbb/#rrggbbaa) com $type=color → exit 1
#           (falha-alto; a SSOT nunca recebe cor malformada).
# Gracioso: jq ausente → aviso STDERR + exit 0 (mesma doutrina dos demais helpers).
#
# Adapter IRMÃO (costura, não implementado — sem ferramenta viva p/ dogfoodar):
#   figma  → Figma API (color styles) → normaliza p/ flat → reusa esta emissão.
#   penpot → Penpot API/export        → idem.
# (Mesma costura de gitlab/bitbucket no forge: interface pronta, provider 🔜.)
# =============================================================================
set -uo pipefail

SRC="${1:-}"
GROUP="${2:-color}"
TYPE="${3:-color}"

if [ -z "${SRC}" ]; then
  echo "uso: file-to-tokens.sh <paleta.json|-> [<grupo>] [<\$type>]" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "AVISO: jq ausente — ingestão file-to-tokens PULADA (instale jq)." >&2
  exit 0
fi

# Lê a paleta (arquivo ou STDIN).
if [ "${SRC}" = "-" ]; then
  INPUT="$(cat)"
else
  [ -f "${SRC}" ] || { echo "ERRO: paleta não encontrada: ${SRC}" >&2; exit 2; }
  INPUT="$(cat "${SRC}")"
fi

# JSON de entrada válido + é um objeto plano (nome→string).
if ! printf '%s' "${INPUT}" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "ERRO: paleta não é um objeto JSON plano {nome: valor}." >&2; exit 1
fi

# Falha-alto: com $type=color, todo valor precisa ser hex válido.
if [ "${TYPE}" = "color" ]; then
  bad="$(printf '%s' "${INPUT}" | jq -r '
    to_entries
    | map(select((.value | type != "string")
              or (.value | test("^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$") | not)))
    | .[].key' 2>/dev/null)"
  if [ -n "${bad}" ]; then
    echo "ERRO: valor(es) não-hex para \$type=color:" >&2
    printf '  ✗ %s\n' ${bad} >&2
    exit 1
  fi
fi

# Emite DTCG: chaves pontilhadas → aninhamento; folha = { "$value": <cor> }.
printf '%s' "${INPUT}" | jq \
  --arg group "${GROUP}" \
  --arg type "${TYPE}" '
  (reduce to_entries[] as $e ({};
     setpath(($e.key | split(".")) + ["$value"]; $e.value))) as $tree
  | { "$schema": "https://design-tokens.github.io/community-group/format/",
      ($group): ({ "$type": $type } + $tree) }
'
exit 0
