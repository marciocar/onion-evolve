#!/usr/bin/env bash
# =============================================================================
# marketplace-root-check.sh — o marketplace.json da RAIZ aponta o repo PÚBLICO e é projeção dos
# manifestos (REGRA 76)
#
# O QUE   : `.claude-plugin/marketplace.json` do core deve ser byte-a-byte a saída de
#           `generate-marketplace.sh <repo> --from-manifests`: as entradas vêm dos manifestos
#           (verticals/*.manifest.sh) e o `source` de cada uma é `git-subdir` sobre o repo PÚBLICO
#           (ONION_PUBLIC_REPOSITORY, path plugins/<nome>). Nenhum `source` relativo: o core não
#           guarda mais os plugins montados.
#
# POR QUÊ : (1) 2026-09-04 — o arquivo da raiz estava no formato pré-2026-09-04 e nenhuma guarda o
#           comparava ao gerador; projeção que envelhece calada é pior que ausente (classe da REGRA 62).
#           (2) 2026-10-10, F4 das portas (SAC-93) — o `plugins/` versionado saiu do core. Até ali a
#           raiz listava `./plugins/<nome>` e esta guarda regenerava a partir de plugins/*/plugin.json,
#           o que obrigava todo PR que tocasse uma fonte bundlada a regenerar e commitar plugin +
#           catálogo. Agora a raiz só depende dos MANIFESTOS (nome, descrição, keywords) e da face
#           pública: um PR que muda o corpo de um agente bundlado não toca este arquivo; um PR que
#           muda a descrição de um plugin, sim — e o pre-commit regenera (tabela de projeções).
#           Instalar pela raiz do core instala o PUBLICADO.
#
# USO     : marketplace-root-check.sh [REPO] [--format text|tsv] | --write | --selftest
#           --write regenera COM SEGURANÇA (temp + mv). `gerador > marketplace.json` direto TRUNCA o arquivo
#           antes de o gerador ler o top-level dele (name/owner viram default) — medido no selftest desta guarda.
# SAÍDA   : HARD<TAB><classe><TAB>.claude-plugin/marketplace.json<TAB><msg> · vazio = limpo
#           classes: ausente · gerador-falhou · source-local · desatualizado
# =============================================================================
set -u
MODE="check"; FORMAT="text"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --write) MODE="write"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
GEN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/marketplace/generate-marketplace.sh"

_check() {
  local repo="$1" fmt="$2" f="${1}/.claude-plugin/marketplace.json" tmp
  [ -f "${GEN}" ] || return 0
  # O objeto desta guarda é o catálogo de quem PUBLICA a partir de manifestos (a fonte). Sem
  # manifestos não há o que projetar — e quem chama já decidiu o papel (_publishes_marketplace).
  ls "${repo}"/.claude/utils/marketplace/verticals/*.manifest.sh >/dev/null 2>&1 || return 0
  [ -f "${f}" ] || { _emit "${fmt}" "ausente" "arquivo ausente — gere: bash .claude/validation/marketplace-root-check.sh --write"; return 0; }
  # Mensagem PRÓPRIA para o defeito que a F4 tirou do core: source relativo aponta um plugins/ que
  # não existe mais aqui. O byte-a-byte também pegaria, mas diria só "desatualizado".
  if grep -qE '"source"[[:space:]]*:[[:space:]]*"\./' "${f}"; then
    _emit "${fmt}" "source-local" "entrada com source RELATIVO ($(grep -cE '"source"[[:space:]]*:[[:space:]]*"\./' "${f}")) — o core não guarda plugins montados desde a F4; a raiz aponta o repo público (git-subdir). Regenere: bash .claude/validation/marketplace-root-check.sh --write"
  fi
  tmp="$(mktemp)"; trap 'rm -f "${tmp}"' RETURN
  if ! bash "${GEN}" "${repo}" --from-manifests > "${tmp}" 2>/dev/null; then _emit "${fmt}" "gerador-falhou" "generate-marketplace.sh --from-manifests saiu ≠ 0 — não dá para comparar"; return 0; fi
  if ! cmp -s "${f}" "${tmp}"; then
    _emit "${fmt}" "desatualizado" "difere da projeção dos manifestos ($(diff "${f}" "${tmp}" | grep -c '^[<>]') linha(s)) — regenere: bash .claude/validation/marketplace-root-check.sh --write"
  fi
}
_write() {
  local repo="$1" f="${1}/.claude-plugin/marketplace.json" tmp
  [ -f "${GEN}" ] || { printf 'gerador ausente: %s\n' "${GEN}" >&2; return 2; }
  tmp="$(mktemp)"; bash "${GEN}" "${repo}" --from-manifests > "${tmp}" || { rm -f "${tmp}"; return 2; }
  mkdir -p "$(dirname "${f}")"; mv "${tmp}" "${f}"; printf 'marketplace.json regenerado: %s\n' "${f#${repo}/}"
}
_emit() { if [ "$1" = "tsv" ]; then printf 'HARD\t%s\t.claude-plugin/marketplace.json\t%s\n' "$2" "$3"; else printf 'HARD [%s] .claude-plugin/marketplace.json: %s\n' "$2" "$3"; fi; }

_selftest() {
  local fails=0 out d
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; d="${SELFTEST_D}"
  mkdir -p "${d}/r/.claude-plugin" "${d}/r/.claude/utils/marketplace/verticals"
  printf 'PLUGIN_NAME="probe"\nPLUGIN_DESC="Sonda"\nKEYWORDS=(a b)\n' > "${d}/r/.claude/utils/marketplace/verticals/probe.manifest.sh"
  printf '{\n  "name": "probe-mkt",\n  "owner": { "name": "t" },\n  "plugins": [\n    { "name": "probe", "source": "./plugins/probe" }\n  ]\n}\n' > "${d}/r/.claude-plugin/marketplace.json"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if grep -q "^HARD	source-local" <<< "${out}" && grep -q "^HARD	desatualizado" <<< "${out}"; then echo "  ✅ (a) source relativo + stale → HARD source-local e desatualizado"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  bash "$0" "${d}/r" --write >/dev/null
  out="$(bash "$0" "${d}/r" --format tsv)"
  if [ -z "${out}" ] && grep -q '"probe-mkt"' "${d}/r/.claude-plugin/marketplace.json" && grep -q '"git-subdir"' "${d}/r/.claude-plugin/marketplace.json"; then echo "  ✅ (b) --write regenera = limpo, top-level preservado, source público"; else echo "  ✗ (b): ${out} $(head -3 "${d}/r/.claude-plugin/marketplace.json" | tr -d '\n')"; fails=$((fails+1)); fi
  # (c) o modo-armadilha: `gerador > arquivo` trunca antes de ler → top-level vira default (documenta o porquê do --write)
  bash "${GEN}" "${d}/r" --from-manifests > "${d}/r/.claude-plugin/marketplace.json" 2>/dev/null
  if ! grep -q '"probe-mkt"' "${d}/r/.claude-plugin/marketplace.json"; then echo "  ✅ (c) redirecionar direto perde o top-level (por isso --write existe)"; else echo "  ✗ (c) esperava perder o top-level"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "marketplace-root-check selftest: OK"; return 0; }
  echo "marketplace-root-check selftest: ${fails} falha(s)"; return 1
}

case "${MODE}" in selftest) _selftest ;; write) _write "${REPO}" ;; *) _check "${REPO}" "${FORMAT}" ;; esac
