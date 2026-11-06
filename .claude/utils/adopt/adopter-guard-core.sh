#!/usr/bin/env bash
# =============================================================================
# adopter-guard-core.sh — escreve a linha `core` do .claude/adopter-guard.tsv do adotante (adoção E update).
#
# ── POR QUE EXISTE (medido em 2026-11-06) ─────────────────────────────────────────────────────────────
# O veto de repo alheio do adotante (REGRA 118 (Veto de repo alheio do adotante registrado e com lista),
# .claude/hooks/pretooluse-adopter-guard.sh) acha a lista de repos registrados pelo checkout local do core:
# a linha `core` deste arquivo, ou o `adopted_from:` do carimbo quando é um diretório. Os adotantes desta
# máquina foram adotados por URL, então só o arquivo resolve, e o próprio hook veta a sessão que o escreve
# (é o arquivo que arma a guarda). Nenhum helper do /meta:adopt o escrevia (git grep em .claude/utils/adopt
# e no adopt.md: zero). Resultado: kg-ssot e curadoria com o veto armado e SEM LISTA, calando para tudo.
# Decisão do maestro de 2026-11-06 (D_LINHA_CORE_DO_ADOPTER_GUARD_PELO_UPDATE_1106, grafo
# docs/evolution/research/guard-adopter-vetoes-2026-11/adopter-vetoes-2026-11.kg.yaml): a linha chega pelo
# update, que roda na sessão do CORE (onde o hook do adotante não se arma) e chega ao adotante por PR.
#
# ── O QUE FAZ ─────────────────────────────────────────────────────────────────────────────────────────
#  · Resolve o checkout PRINCIPAL do core a partir da fonte (`git --git-common-dir`): o update roda numa
#    worktree da fonte às vezes, e a worktree some; a linha aponta o checkout que fica.
#  · Só escreve quando a fonte É o core: sem `.claude/.onion-version` (o core não carrega carimbo) e com
#    `docs/evolution/federation/members.yaml`. Um hub que adota para baixo não é o core: pula, dizendo.
#  · Idempotente e cirúrgico: arquivo ausente nasce com um cabeçalho e a linha; sem linha `core`, acrescenta;
#    linha igual, nada muda; linha diferente que aponta um core VÁLIDO nesta máquina é escolha do maestro
#    e fica; linha diferente que não aponta core nenhum é trocada no lugar. As linhas `repo` e `allow` e os
#    comentários nunca se tocam.
#  · Confere o próprio efeito: relê o arquivo e exige que a 1ª linha `core` seja o caminho resolvido.
#
# TETO: caminho do core com espaço não se declara (a lib não o lê) → pula, dizendo. Não arma o veto sozinho:
# o `role:` do carimbo e o registro no settings.json seguem sendo de quem os escreve.
# ops/materialize-adopter.sh (core-only) não chama este helper (a fixture da bancada fica sem a linha, como antes).
#
# Uso  : adopter-guard-core.sh <DEST> <SOURCE_ROOT>
# Saída: uma linha `adopter-guard: <escrita|acrescentada|em dia|mantida|trocada|pulada>: …` — vai inteira no
#        relatório do update/adoção.
# RC   : 0 = julgou (escreveu, manteve ou pulou) · 2 = uso · 3 = escreveu e a releitura não confere
# Exercitado por lint-selftest.sh (run_adopter_guard_core_selftests).
# =============================================================================
set -uo pipefail

DEST="${1:-}"; SRC="${2:-}"
[ -n "${DEST}" ] && [ -d "${DEST}" ] && [ -n "${SRC}" ] && [ -d "${SRC}" ] \
  || { echo "uso: adopter-guard-core.sh <DEST> <SOURCE_ROOT>" >&2; exit 2; }
TSV="${DEST%/}/.claude/adopter-guard.tsv"

_say() { printf 'adopter-guard: %s\n' "$*"; }

# _is_core <dir> — o checkout do core: caminho absoluto, sem carimbo, com o registro da federação
# (relativo nunca vale: resolveria contra o cwd de quem roda o update)
_is_core() { case "$1" in /*) : ;; *) return 1 ;; esac; [ -d "$1" ] && [ ! -f "$1/.claude/.onion-version" ] && [ -f "$1/docs/evolution/federation/members.yaml" ]; }

# o checkout principal da fonte (a worktree some, o checkout fica). Sem `--path-format=absolute` (git ≥ 2.31):
# o caminho relativo resolve a partir da fonte.
common="$(cd "${SRC}" 2>/dev/null && g="$(git rev-parse --git-common-dir 2>/dev/null)" && cd "${g}" 2>/dev/null && pwd -P)" || common=""
case "${common}" in
  */.git) CORE="${common%/.git}" ;;
  *) _say "pulada: a fonte ${SRC} não tem checkout principal resolvível (git-common-dir '${common}')"; exit 0 ;;
esac
_is_core "${CORE}" || { _say "pulada: ${CORE} não é o checkout do core (tem carimbo ou não tem o members.yaml) — a linha core é do maestro"; exit 0; }
case "${CORE}" in *[[:space:]]*) _say "pulada: o caminho do core '${CORE}' tem espaço e a lib não o lê — declare à mão"; exit 0 ;; esac
[ "$(cd "${DEST}" && pwd -P)" = "$(cd "${CORE}" && pwd -P)" ] && { _say "pulada: o destino é o próprio core"; exit 0; }

# a 1ª linha core (a que a lib usa): número e caminho com ~/ expandido e sem barra final
cur_n=""; cur_p=""
if [ -f "${TSV}" ]; then
  read -r cur_n cur_p < <(awk '!/^[[:space:]]*#/ && $1 == "core" && NF >= 2 { print NR, $2; exit }' "${TSV}" 2>/dev/null) || true
  case "${cur_p}" in "~/"*) cur_p="${HOME}/${cur_p#"~/"}" ;; esac
  cur_p="${cur_p%/}"
fi

_verify() {
  local got
  got="$(awk '!/^[[:space:]]*#/ && $1 == "core" && NF >= 2 { print $2; exit }' "${TSV}" 2>/dev/null)"
  [ "${got%/}" = "${CORE}" ] || { echo "adopter-guard: ERRO: escrevi e a 1ª linha core lida é '${got}', não '${CORE}'" >&2; exit 3; }
}

if [ ! -f "${TSV}" ]; then
  mkdir -p "$(dirname "${TSV}")" || exit 3
  {
    printf '# Lista do veto de repo alheio (REGRA 118). Forma: <diretiva><TAB><caminho absoluto>, uma por linha.\n'
    printf '# A linha core vem do /meta:adopt (adopter-guard-core.sh); as linhas repo e allow são do maestro.\n'
    printf 'core\t%s\n' "${CORE}"
  } > "${TSV}" || exit 3
  _verify; _say "escrita: arquivo novo com core ${CORE}"; exit 0
fi
if [ -z "${cur_n}" ]; then
  [ -s "${TSV}" ] && [ -n "$(tail -c 1 "${TSV}")" ] && printf '\n' >> "${TSV}"
  printf 'core\t%s\n' "${CORE}" >> "${TSV}" || exit 3
  _verify; _say "acrescentada: core ${CORE} (as outras linhas ficaram)"; exit 0
fi
if [ "${cur_p}" = "${CORE}" ] || { [ -d "${cur_p}" ] && [ "$(cd "${cur_p}" && pwd -P)" = "$(cd "${CORE}" && pwd -P)" ]; }; then
  _say "em dia: core ${cur_p}"; exit 0
fi
if _is_core "${cur_p}"; then
  _say "mantida: a linha ${cur_n} aponta ${cur_p}, que é um core válido nesta máquina (escolha do maestro; o resolvido seria ${CORE})"; exit 0
fi
tmp="$(mktemp "${TSV}.XXXXXX")" || exit 3
awk -v n="${cur_n}" -v c="${CORE}" 'NR == n { print "core\t" c; next } { print }' "${TSV}" > "${tmp}" && cat "${tmp}" > "${TSV}"; rc=$?
rm -f "${tmp}"; [ "${rc}" -eq 0 ] || exit 3
_verify; _say "trocada: a linha ${cur_n} apontava ${cur_p:-<vazio>}, que não é core nesta máquina → core ${CORE}"; exit 0
