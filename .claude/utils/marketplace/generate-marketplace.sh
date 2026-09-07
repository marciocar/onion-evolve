#!/usr/bin/env bash
# =============================================================================
# generate-marketplace.sh — Gera/atualiza .claude-plugin/marketplace.json a partir
# dos plugins montados (SSOT: cada plugins/<name>/.claude-plugin/plugin.json).
#
# Propósito : Fechar o gap do sinal de campo de um adotante de campo 2026-07-13 (A3): ao montar
#             plugins numa adoção, o repo falha o próprio lint por AUSÊNCIA de
#             marketplace.json e NÃO havia gerador — o adotante escrevia à mão.
#             Par do assemble-plugin.sh: aquele monta UM plugin; este agrega o
#             REGISTRO de todos. É o primeiro helper testável da F1 do
#             /meta:create-vertical (ADR onion-adr-create-vertical-2026-07).
#
# Derivação:
#   - plugins[]  : DERIVADO — varre plugins/*/.claude-plugin/plugin.json (ordem
#                  ALFABÉTICA determinística), extrai name/displayName/description/category/tags/license/homepage/author
#                  (SEM version por entrada — plugin.json é a autoridade; 2026-09-04, padrão oficial do marketplace).
#   - top-level  : CURADO — name/owner/metadata preservados verbatim do marketplace.json
#                  existente (é metadado humano); se ausente, emite default do repo.
#
# Uso   : generate-marketplace.sh [REPO_DIR]   (default: .)  → escreve no STDOUT.
#         Ex.: bash generate-marketplace.sh > .claude-plugin/marketplace.json
#
# Determinístico, idempotente, SEM jq (roda em repo adotado; espelha assemble-plugin.sh).
# Coberto por lint-selftest.sh. Extração via grep/sed: plugin.json é MÁQUINA-gerado
# (assemble-plugin.sh) → formato previsível (2-space, um campo por linha).
# =============================================================================
set -euo pipefail

REPO_DIR="${1:-.}"
MKT="${REPO_DIR}/.claude-plugin/marketplace.json"
PLUGINS_DIR="${REPO_DIR}/plugins"

# --- escapa " e \ para embutir string em JSON (robustez p/ plugins de terceiros) ---
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# --- lê um campo escalar "chave": "valor" da 1ª ocorrência num plugin.json ---
field() { sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\\(.*\\)\".*/\\1/p" "$1" | head -1; }

# --- top-level: preserva do marketplace.json existente, senão default do repo ---
# O default do nome do marketplace é o repo PÚBLICO, nunca o source privado: este arquivo é
# artefato público, e um fallback com o nome privado é o nome errado à espera de um dia sem
# marketplace.json prévio (resíduo (7) do nó Q_RESIDUOS_DA_FONTE_PRIVADA_NO_PUBLICO).
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/public-face.sh"
top_name="${ONION_MARKETPLACE_NAME}"; top_owner_name="Onion"; top_owner_email=""
top_desc="Marketplace de plugins Onion (verticais como spec-as-code)."; top_ver="0.1.0"; top_root="./plugins"
if [ -f "${MKT}" ]; then
  v="$(field "${MKT}" name)";                    [ -n "${v}" ] && top_name="${v}"
  v="$(awk '/"owner"/{f=1} f&&/"name"/{sub(/.*"name"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${MKT}")"; [ -n "${v}" ] && top_owner_name="${v}"
  v="$(awk '/"owner"/{f=1} f&&/"email"/{sub(/.*"email"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${MKT}")"; [ -n "${v}" ] && top_owner_email="${v}"
  v="$(awk '/"metadata"/{f=1} f&&/"description"/{sub(/.*"description"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${MKT}")"; [ -n "${v}" ] && top_desc="${v}"
  v="$(awk '/"metadata"/{f=1} f&&/"version"/{sub(/.*"version"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${MKT}")"; [ -n "${v}" ] && top_ver="${v}"
  v="$(awk '/"metadata"/{f=1} f&&/"pluginRoot"/{sub(/.*"pluginRoot"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${MKT}")"; [ -n "${v}" ] && top_root="${v}"
fi

# --- emite o topo ---
printf '{\n'
printf '  "name": "%s",\n' "$(json_escape "${top_name}")"
printf '  "owner": {\n    "name": "%s"' "$(json_escape "${top_owner_name}")"
[ -n "${top_owner_email}" ] && printf ',\n    "email": "%s"' "$(json_escape "${top_owner_email}")"
printf '\n  },\n'
printf '  "metadata": {\n'
printf '    "description": "%s",\n' "$(json_escape "${top_desc}")"
printf '    "version": "%s",\n' "$(json_escape "${top_ver}")"
printf '    "pluginRoot": "%s"\n' "$(json_escape "${top_root}")"
printf '  },\n'
printf '  "plugins": ['

# --- plugins[]: derivado, ordem alfabética por diretório ---
first=1
if [ -d "${PLUGINS_DIR}" ]; then
  while IFS= read -r pj; do
    [ -f "${pj}" ] || continue
    pdir="$(dirname "$(dirname "${pj}")")"; pname="$(basename "${pdir}")"
    name="$(field "${pj}" name)";       [ -n "${name}" ] || name="${pname}"
    desc="$(field "${pj}" description)"
    author="$(awk '/"author"/{sub(/.*"name"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${pj}")"
    lic="$(field "${pj}" license)"; home="$(field "${pj}" homepage)"; repo="$(field "${pj}" repository)"
    # displayName / category (padrão de referência do marketplace do Claude Code: displayName, category, tags, license)
    case "${name}" in onion) disp="Onion"; cat="core" ;; *) disp="Onion · $(printf '%s' "${name#onion-}" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')"; cat="vertical" ;; esac
    tags="$(awk '/"keywords"/{sub(/.*"keywords"[[:space:]]*:[[:space:]]*\[/,"");sub(/\].*/,"");print;exit}' "${pj}" | tr -d ' ')"
    [ "${first}" -eq 1 ] && first=0 || printf ','
    printf '\n    {\n'
    printf '      "name": "%s",\n' "$(json_escape "${name}")"
    printf '      "displayName": "%s",\n' "$(json_escape "${disp}")"
    printf '      "source": "./plugins/%s",\n' "$(json_escape "${pname}")"
    printf '      "description": "%s",\n' "$(json_escape "${desc}")"
    printf '      "category": "%s",\n' "${cat}"
    [ -n "${tags}" ] && printf '      "tags": [%s],\n' "${tags}"
    [ -n "${lic}" ] && printf '      "license": "%s",\n' "$(json_escape "${lic}")"
    [ -n "${home}" ] && printf '      "homepage": "%s",\n' "$(json_escape "${home}")"
    [ -n "${repo}" ] && printf '      "repository": "%s",\n' "$(json_escape "${repo}")"
    # SEM "version" na entrada: docs oficiais — plugin.json é a autoridade e uma version duplicada/estagnada ESCONDE updates.
    printf '      "author": { "name": "%s" }\n' "$(json_escape "${author:-${top_owner_name}}")"
    printf '    }'
  done < <(find "${PLUGINS_DIR}" -mindepth 2 -maxdepth 3 -name plugin.json -path '*/.claude-plugin/*' 2>/dev/null | sort)
fi
[ "${first}" -eq 1 ] && printf '\n  ]\n}' || printf '\n  ]\n}'
printf '\n'
