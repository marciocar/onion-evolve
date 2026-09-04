#!/usr/bin/env bash
# =============================================================================
# marketplace-root-check.sh — o marketplace.json da RAIZ é projeção do gerador (REGRA 76)
#
# O QUE   : `.claude-plugin/marketplace.json` do core deve ser byte-a-byte a saída de
#           `generate-marketplace.sh <repo>` (que deriva as entradas de plugins/*/.claude-plugin/plugin.json
#           e preserva o top-level name/owner/metadata do arquivo existente).
#
# POR QUÊ : medido 2026-09-04: o arquivo da raiz estava no formato PRÉ-2026-09-04 (todas as entradas
#           com `version: 0.1.0`, sem displayName/category/tags/license/homepage) e nenhuma guarda o
#           comparava ao gerador — a REGRA 37 só faz `grep -q "<vertical>"`. O repo do core também é um
#           marketplace instalável (`/plugin marketplace add marciocar/onion-evolve`, B5_9); projeção
#           que envelhece calada é pior que ausente (mesma classe da REGRA 62).
#           Cura: o pre-commit regenera junto com os plugins; o CI confere.
#
# USO     : marketplace-root-check.sh [REPO] [--format text|tsv] | --write | --selftest
#           --write regenera COM SEGURANÇA (temp + mv). `gerador > marketplace.json` direto TRUNCA o arquivo
#           antes de o gerador ler o top-level dele (name/owner viram default) — medido no selftest desta guarda.
# SAÍDA   : HARD<TAB>desatualizado<TAB>.claude-plugin/marketplace.json<TAB><msg> · vazio = limpo
# =============================================================================
set -u
MODE="check"; FORMAT="text"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --write) MODE="write"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
GEN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/marketplace/generate-marketplace.sh"

_check() {
  local repo="$1" fmt="$2" f="${1}/.claude-plugin/marketplace.json" tmp
  [ -f "${GEN}" ] || return 0
  [ -d "${repo}/plugins" ] || return 0
  [ -f "${f}" ] || { _emit "${fmt}" "ausente" "arquivo ausente — gere: bash .claude/validation/marketplace-root-check.sh --write"; return 0; }
  tmp="$(mktemp)"; trap 'rm -f "${tmp}"' RETURN
  if ! bash "${GEN}" "${repo}" > "${tmp}" 2>/dev/null; then _emit "${fmt}" "gerador-falhou" "generate-marketplace.sh saiu ≠ 0 — não dá para comparar"; return 0; fi
  if ! cmp -s "${f}" "${tmp}"; then
    _emit "${fmt}" "desatualizado" "difere da saída do gerador ($(diff "${f}" "${tmp}" | grep -c '^[<>]') linha(s)) — regenere: bash .claude/validation/marketplace-root-check.sh --write"
  fi
}
_write() {
  local repo="$1" f="${1}/.claude-plugin/marketplace.json" tmp
  [ -f "${GEN}" ] || { printf 'gerador ausente: %s\n' "${GEN}" >&2; return 2; }
  tmp="$(mktemp)"; bash "${GEN}" "${repo}" > "${tmp}" || { rm -f "${tmp}"; return 2; }
  mkdir -p "$(dirname "${f}")"; mv "${tmp}" "${f}"; printf 'marketplace.json regenerado: %s\n' "${f#${repo}/}"
}
_emit() { if [ "$1" = "tsv" ]; then printf 'HARD\t%s\t.claude-plugin/marketplace.json\t%s\n' "$2" "$3"; else printf 'HARD [%s] .claude-plugin/marketplace.json: %s\n' "$2" "$3"; fi; }

_selftest() {
  local fails=0 out d
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; d="${SELFTEST_D}"
  mkdir -p "${d}/r/.claude-plugin" "${d}/r/plugins/probe/.claude-plugin"
  # o gerador lê JSON linha a linha (sem jq): fixture pretty-printed, como o assembler escreve
  printf '{\n  "name": "probe",\n  "version": "0.1.3",\n  "description": "Sonda",\n  "author": { "name": "t" },\n  "keywords": ["a"],\n  "license": "MIT",\n  "homepage": "https://x",\n  "repository": "https://x"\n}\n' > "${d}/r/plugins/probe/.claude-plugin/plugin.json"
  printf '{\n  "name": "probe-mkt",\n  "owner": { "name": "t" },\n  "plugins": []\n}\n' > "${d}/r/.claude-plugin/marketplace.json"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "^HARD	desatualizado"; then echo "  ✅ (a) arquivo stale → HARD desatualizado"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  bash "$0" "${d}/r" --write >/dev/null
  out="$(bash "$0" "${d}/r" --format tsv)"
  if [ -z "${out}" ] && grep -q '"probe-mkt"' "${d}/r/.claude-plugin/marketplace.json"; then echo "  ✅ (b) --write regenera = limpo, top-level preservado"; else echo "  ✗ (b): ${out} $(head -3 "${d}/r/.claude-plugin/marketplace.json" | tr -d '\n')"; fails=$((fails+1)); fi
  # (c) o modo-armadilha: `gerador > arquivo` trunca antes de ler → top-level vira default (documenta o porquê do --write)
  bash "${GEN}" "${d}/r" > "${d}/r/.claude-plugin/marketplace.json" 2>/dev/null
  if ! grep -q '"probe-mkt"' "${d}/r/.claude-plugin/marketplace.json"; then echo "  ✅ (c) redirecionar direto perde o top-level (por isso --write existe)"; else echo "  ✗ (c) esperava perder o top-level"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "marketplace-root-check selftest: OK"; return 0; }
  echo "marketplace-root-check selftest: ${fails} falha(s)"; return 1
}

case "${MODE}" in selftest) _selftest ;; write) _write "${REPO}" ;; *) _check "${REPO}" "${FORMAT}" ;; esac
