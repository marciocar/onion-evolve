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
# Falha   : exit 1 (falha-alto — a SSOT nunca recebe estrutura/cor malformada) em:
#           - valor não-hex #rrggbb (6 díg.) com $type=color — alinhado ao gate
#             lint-design-tokens.sh, que só computa contraste de #rrggbb;
#           - chave reservada DTCG ($-prefixada) — corromperia o $type do grupo;
#           - segmento de caminho vazio (".a"/"a..b"/"a.") — nó sem nome;
#           - colisão de prefixo ("brand" + "brand.orange") — nó folha-E-grupo
#             ambíguo e não-determinístico.
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

# Entrada vazia → mensagem dedicada (em vez do diagnóstico genérico de "não-objeto").
if [ -z "${INPUT//[[:space:]]/}" ]; then
  echo "ERRO: entrada vazia — forneça uma paleta JSON {nome: \"#hex\"}." >&2; exit 1
fi

# JSON de entrada válido + é um objeto plano (nome→string).
if ! printf '%s' "${INPUT}" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "ERRO: paleta não é um objeto JSON plano {nome: valor}." >&2; exit 1
fi

# Falha-alto estrutural: chaves reservadas DTCG ($-prefixadas) corromperiam o
# $type/$schema do grupo na emissão — rejeitar (não emitir DTCG malformado).
dollar="$(printf '%s' "${INPUT}" | jq -r 'keys[] | select(startswith("$"))' 2>/dev/null)"
if [ -n "${dollar}" ]; then
  echo "ERRO: chave(s) reservada(s) DTCG (começam com \$) não são nomes de token válidos:" >&2
  printf '  ✗ %s\n' ${dollar} >&2
  exit 1
fi

# Falha-alto estrutural: segmento de caminho vazio (".x", "a..b", "x.") gera nó
# sem nome — DTCG ambíguo.
empty_seg="$(printf '%s' "${INPUT}" | jq -r 'keys[] | select(test("(^\\.)|(\\.\\.)|(\\.$)|(^$)"))' 2>/dev/null)"
if [ -n "${empty_seg}" ]; then
  echo "ERRO: chave(s) com segmento de caminho vazio (use 'a.b', não '.a'/'a..b'/'a.'):" >&2
  printf '  ✗ %s\n' ${empty_seg} >&2
  exit 1
fi

# Falha-alto estrutural: colisão de prefixo (uma chave é prefixo estrito de outra,
# ex. "brand" + "brand.orange") produziria um nó folha-E-grupo — DTCG ambíguo e
# não-determinístico (a ordem das chaves mudaria a saída).
collision="$(printf '%s' "${INPUT}" | jq -r '
  keys as $k
  | $k[] as $a | $k[] as $b
  | select($a != $b and ($b | startswith($a + ".")))
  | $a' 2>/dev/null | sort -u)"
if [ -n "${collision}" ]; then
  echo "ERRO: colisão de prefixo — chave é folha E grupo (DTCG ambíguo):" >&2
  printf '  ✗ %s\n' ${collision} >&2
  exit 1
fi

# Falha-alto: com $type=color, todo valor precisa ser hex de 6 dígitos (#rrggbb).
# Alinhado ao gate lint-design-tokens.sh, que só computa contraste de #rrggbb —
# aceitar #rgb/#rrggbbaa aqui quebraria o round-trip prometido no README.
if [ "${TYPE}" = "color" ]; then
  bad="$(printf '%s' "${INPUT}" | jq -r '
    to_entries
    | map(select((.value | type != "string")
              or (.value | test("^#[0-9a-fA-F]{6}$") | not)))
    | .[].key' 2>/dev/null)"
  if [ -n "${bad}" ]; then
    echo "ERRO: valor(es) não-hex (#rrggbb, 6 dígitos) para \$type=color:" >&2
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
