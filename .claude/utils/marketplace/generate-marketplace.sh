#!/usr/bin/env bash
# =============================================================================
# generate-marketplace.sh — Gera/atualiza .claude-plugin/marketplace.json, em DOIS modos.
#
# Propósito : Fechar o gap do sinal de campo de um adotante de campo 2026-07-13 (A3): ao montar
#             plugins numa adoção, o repo falha o próprio lint por AUSÊNCIA de
#             marketplace.json e NÃO havia gerador — o adotante escrevia à mão.
#             Par do assemble-plugin.sh: aquele monta UM plugin; este agrega o
#             REGISTRO de todos. É o primeiro helper testável da F1 do
#             /meta:create-vertical (ADR onion-adr-create-vertical-2026-07).
#
# Modos:
#   (padrão) BUNDLE — o catálogo de um repo que TEM os plugins montados (o onion-plugins, um adotante
#             que monta os próprios): varre plugins/*/.claude-plugin/plugin.json e emite `source`
#             RELATIVO (`./plugins/<nome>`). É o catálogo que vai a público.
#   --from-manifests — o catálogo da RAIZ DO CORE (F4 das portas, 2026-10-10, SAC-93). O `plugins/`
#             saiu do core: não há plugin.json para varrer. As entradas vêm dos MANIFESTOS
#             (verticals/*.manifest.sh: PLUGIN_NAME, PLUGIN_DESC, KEYWORDS — os mesmos campos que o
#             assembler escreve no plugin.json) e o `source` aponta o REPO PÚBLICO
#             (`git-subdir` sobre ONION_PUBLIC_REPOSITORY, path `plugins/<nome>`). Instalar pela
#             raiz do core instala o PUBLICADO, nunca uma cópia local que ninguém mais regenera.
#             `git-subdir` medido válido no `claude plugin validate --strict` (CC 2.1.296); um tipo
#             de source inventado reprova ali.
#
# Derivação:
#   - plugins[]  : DERIVADO, ordem ALFABÉTICA determinística, campos name/displayName/description/
#                  category/tags/license/homepage/repository/author (SEM version por entrada —
#                  plugin.json é a autoridade; 2026-09-04, padrão oficial do marketplace). Os dois
#                  modos passam pelo MESMO emissor (`_emit_entry`): fora o `source`, a entrada da raiz
#                  e a do catálogo publicado são byte a byte iguais, e a bancada cobra isso.
#   - top-level  : CURADO — name/owner/metadata preservados verbatim do marketplace.json
#                  existente (é metadado humano); se ausente, emite default do repo. No modo
#                  --from-manifests NÃO há `pluginRoot` (ele só vale para source relativo).
#
# Uso   : generate-marketplace.sh [REPO_DIR] [--from-manifests]   (default: .)  → escreve no STDOUT.
#         Escrever no próprio arquivo: NUNCA `> marketplace.json` direto (trunca antes de ler o topo);
#         use `marketplace-root-check.sh --write` (temp + mv).
#
# Determinístico, idempotente, SEM jq (roda em repo adotado; espelha assemble-plugin.sh).
# Coberto por lint-selftest.sh. Extração via grep/sed: plugin.json é MÁQUINA-gerado
# (assemble-plugin.sh) → formato previsível (2-space, um campo por linha).
# =============================================================================
set -euo pipefail

REPO_DIR="."; FROM_MANIFESTS=0
for _a in "$@"; do
  case "${_a}" in
    --from-manifests) FROM_MANIFESTS=1 ;;
    -*) echo "generate-marketplace: opção desconhecida '${_a}'" >&2; exit 2 ;;
    *) REPO_DIR="${_a}" ;;
  esac
done
MKT="${REPO_DIR}/.claude-plugin/marketplace.json"
PLUGINS_DIR="${REPO_DIR}/plugins"
VDIR="${REPO_DIR}/.claude/utils/marketplace/verticals"

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
if [ "${FROM_MANIFESTS}" -eq 1 ]; then
  printf '    "version": "%s"\n' "$(json_escape "${top_ver}")"
else
  printf '    "version": "%s",\n' "$(json_escape "${top_ver}")"
  printf '    "pluginRoot": "%s"\n' "$(json_escape "${top_root}")"
fi
printf '  },\n'
printf '  "plugins": ['

# --- o emissor ÚNICO de entrada (os dois modos passam por aqui) ---
# $1 name · $2 desc · $3 tags (já no formato "a","b") · $4 license · $5 homepage · $6 repository ·
# $7 author · $8 source (JSON pronto: string relativa ou objeto)
first=1
_emit_entry() {
  local name="$1" desc="$2" tags="$3" lic="$4" home="$5" repo="$6" author="$7" src="$8" disp cat
  # displayName / category (padrão de referência do marketplace do Claude Code: displayName, category, tags, license)
  case "${name}" in onion) disp="Onion"; cat="core" ;; *) disp="Onion · $(printf '%s' "${name#onion-}" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')"; cat="vertical" ;; esac
  [ "${first}" -eq 1 ] && first=0 || printf ','
  printf '\n    {\n'
  printf '      "name": "%s",\n' "$(json_escape "${name}")"
  printf '      "displayName": "%s",\n' "$(json_escape "${disp}")"
  printf '      "source": %s,\n' "${src}"
  printf '      "description": "%s",\n' "$(json_escape "${desc}")"
  printf '      "category": "%s",\n' "${cat}"
  [ -n "${tags}" ] && printf '      "tags": [%s],\n' "${tags}"
  [ -n "${lic}" ] && printf '      "license": "%s",\n' "$(json_escape "${lic}")"
  [ -n "${home}" ] && printf '      "homepage": "%s",\n' "$(json_escape "${home}")"
  [ -n "${repo}" ] && printf '      "repository": "%s",\n' "$(json_escape "${repo}")"
  # SEM "version" na entrada: docs oficiais — plugin.json é a autoridade e uma version duplicada/estagnada ESCONDE updates.
  printf '      "author": { "name": "%s" }\n' "$(json_escape "${author:-${top_owner_name}}")"
  printf '    }'
}

if [ "${FROM_MANIFESTS}" -eq 1 ]; then
  # Os valores que o assembler escreve no plugin.json, lidos da MESMA fonte que ele lê: autor e licença
  # são constantes do assembler; casa e canal vêm de public-face.sh. O source é o repo público.
  _pub="${ONION_PUBLIC_REPOSITORY%/}"; _pub="${_pub%.git}.git"
  if [ -d "${VDIR}" ]; then
    while IFS=$'\t' read -r _key _n _d _k; do
      [ -n "${_n}" ] || continue
      _emit_entry "${_n}" "${_d}" "${_k}" "MIT" "${ONION_PUBLIC_HOMEPAGE}" "${ONION_PUBLIC_REPOSITORY}" \
        "Onion - Marcio Carvalho" \
        "{ \"source\": \"git-subdir\", \"url\": \"$(json_escape "${_pub}")\", \"path\": \"plugins/$(json_escape "${_n}")\" }"
    done < <(
      for _m in "${VDIR}"/*.manifest.sh; do
        [ -f "${_m}" ] || continue
        case "$(basename "${_m}")" in __*) continue ;; esac   # fixture de teste não é plugin publicável
        ( set +u; PLUGIN_NAME=""; PLUGIN_DESC=""; KEYWORDS=()
          . "${_m}" >/dev/null 2>&1 || true
          [ -n "${PLUGIN_NAME}" ] || exit 0
          _kw=""; for _x in "${KEYWORDS[@]}"; do _kw="${_kw}\"${_x}\","; done
          # chave "<nome>/" = a MESMA ordem do modo bundle, que ordena caminhos plugins/<nome>/…
          # (onion-compliance antes de onion, porque '-' < '/'): as duas listas casam entrada a entrada
          printf '%s/\t%s\t%s\t%s\n' "${PLUGIN_NAME}" "${PLUGIN_NAME}" "${PLUGIN_DESC}" "${_kw%,}" )
      done | LC_ALL=C sort -t$'\t' -k1,1
    )
  fi
else
  # --- plugins[]: derivado, ordem alfabética por diretório ---
  if [ -d "${PLUGINS_DIR}" ]; then
    while IFS= read -r pj; do
      [ -f "${pj}" ] || continue
      pdir="$(dirname "$(dirname "${pj}")")"; pname="$(basename "${pdir}")"
      name="$(field "${pj}" name)";       [ -n "${name}" ] || name="${pname}"
      desc="$(field "${pj}" description)"
      author="$(awk '/"author"/{sub(/.*"name"[[:space:]]*:[[:space:]]*"/,"");sub(/".*/,"");print;exit}' "${pj}")"
      lic="$(field "${pj}" license)"; home="$(field "${pj}" homepage)"; repo="$(field "${pj}" repository)"
      tags="$(awk '/"keywords"/{sub(/.*"keywords"[[:space:]]*:[[:space:]]*\[/,"");sub(/\].*/,"");print;exit}' "${pj}" | tr -d ' ')"
      _emit_entry "${name}" "${desc}" "${tags}" "${lic}" "${home}" "${repo}" "${author}" "\"./plugins/$(json_escape "${pname}")\""
    done < <(find "${PLUGINS_DIR}" -mindepth 2 -maxdepth 3 -name plugin.json -path '*/.claude-plugin/*' 2>/dev/null | LC_ALL=C sort)
  fi
fi
printf '\n  ]\n}'
printf '\n'
