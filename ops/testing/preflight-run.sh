#!/usr/bin/env bash
# =============================================================================
# preflight-run.sh — o PRÉ-VOO da bancada: roda as famílias que o diff alterou num ambiente que imita o runner
#
# POR QUÊ (SAC-141, decisão do maestro de 2026-10-15, nó D_PRE_VOO_SEMPRE_E_SOMBRA em
#   docs/evolution/research/preflight-gap-2026-10/preflight-gap-2026-10.kg.yaml): o pré-voo nasceu em 2026-10-07
#   dentro do `pr-finalize.sh`, SÓ sob ONION_FINALIZE_CHECKPOINT=1. Medido de 10-07 a 10-14: só 89 de 431 chamadas
#   do `pr-finalize --push` passaram a variável (21%), e 9 de 29 reprovações do CI eram casos que o pré-voo
#   pegaria se tivesse rodado. A condição era prosa (uma variável que a sessão precisa lembrar). Agora o pré-voo
#   roda sempre, e mora aqui para que o `pr-finalize` e o `pre-push` chamem o MESMO corpo.
#
# O QUE FAZ: pergunta ao `preflight-families.sh` as famílias que o diff (contra o merge-base com origin/main)
#   alterou por dentro, mais a catraca `shell_pipefail_robustness`, e as roda com git sem identidade adivinhada
#   (user.useConfigOnly), HOME limpo, LC_ALL=C e sem variáveis ONION_* — o ambiente do runner.
#
# CACHE: a chave é a ÁRVORE do índice (`git write-tree`) mais a lista de famílias. Árvore igual com as mesmas
#   famílias já verdes = pula, e diz que pulou. O marcador fica no git-common-dir (fora do índice; as worktrees
#   o compartilham, e a árvore é única por conteúdo).
#
# USO  : preflight-run.sh [--families-only]
#        ONION_SELFTEST_FULL=1 → bancada completa (opt-in; o `env -i` a apagaria, por isso é traduzida aqui)
# EXIT : 0 verde (ou pulado pelo cache) · 1 reprovou · 2 não descobri as famílias (não chuta)
# Bancada: run_preflight_families_selftests e run_machine_slots_selftests (g).
# =============================================================================
set -uo pipefail

[ -f ops/testing/preflight-families.sh ] || { echo "preflight-run: ops/testing/preflight-families.sh ausente" >&2; exit 2; }
fams="$(bash ops/testing/preflight-families.sh)" || { echo "preflight-run: não descobri as famílias alteradas" >&2; exit 2; }
[ "${1:-}" = --families-only ] && { printf '%s\n' "${fams}"; exit 0; }

full="${ONION_SELFTEST_FULL:-0}"
tree="$(git write-tree 2>/dev/null)" || tree=""
mark="$(git rev-parse --git-common-dir 2>/dev/null)/onion-preflight-ok"
key="${tree} ${full} ${fams}"
if [ -n "${tree}" ] && [ -f "${mark}" ] && grep -qxF -- "${key}" "${mark}" 2>/dev/null; then
  echo "pré-voo: PULADO pelo cache — a árvore ${tree:0:12} já passou com estas famílias (${fams})"
  exit 0
fi

sel=(--families "${fams}")
if [ "${full}" = 1 ]; then
  sel=(); echo "pré-voo COMPLETO pedido (ONION_SELFTEST_FULL=1, opt-in) — todas as famílias"
else
  echo "pré-voo no ambiente do runner — famílias: ${fams} (a completa é do CI; ONION_SELFTEST_FULL=1 a pede aqui)"
fi
home="$(mktemp -d)"; printf '[user]\n\tuseConfigOnly = true\n' > "${home}/.gitconfig"
out="$(env -i PATH="${PATH}" HOME="${home}" GIT_CONFIG_NOSYSTEM=1 LC_ALL=C TERM=dumb \
  bash .claude/validation/lint-selftest.sh ${sel[@]+"${sel[@]}"} 2>&1)"; rc=$?
rm -rf "${home}"
if [ "${rc}" != 0 ] || grep -q 'ABORTOU' <<< "${out}"; then
  grep -E '  ✗ |ABORTOU' <<< "${out}" | head -12 >&2
  echo "pré-voo reprovou no ambiente do runner (rc=${rc}) — o CI quebraria igual" >&2
  exit 1
fi
echo "pré-voo verde ($(grep -oE 'Passaram : [0-9]+' <<< "${out}" | tail -1))"
# guarda as últimas chaves verdes (teto pequeno: é cache, não histórico)
if [ -n "${tree}" ]; then
  { [ -f "${mark}" ] && tail -n 49 "${mark}"; printf '%s\n' "${key}"; } > "${mark}.tmp" 2>/dev/null && mv -f "${mark}.tmp" "${mark}"
fi
exit 0
