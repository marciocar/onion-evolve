#!/usr/bin/env bash
# =============================================================================
# preflight-families.sh — as famílias da bancada que o diff STAGEADO de fato alterou
#
# POR QUÊ (2026-10-07): sob checkpoint (ONION_FINALIZE_CHECKPOINT=1) o motor só lintava, e a bancada ficava
# para o CI. Num só dia, três PRs quebraram no CI por casos NOVOS que passavam local: identidade git ausente
# no runner (#943, duas vezes), `[ ] && echo` devolvendo 1 sem a variável (#944) e um sítio novo da catraca
# `| grep -q` (#936). O mapa `--affected-staged` não serve aqui: mexer no lint-selftest.sh cai no failsafe
# "tudo" (217 famílias). Este helper responde a pergunta estreita que o pré-voo precisa — QUAIS famílias o
# diff alterou por dentro — e soma sempre a catraca estática `shell_pipefail_robustness`.
#
# USO  : preflight-families.sh [BASE]     (BASE default: merge-base com origin/main, ou main)
# SAÍDA: famílias separadas por vírgula (sempre inclui shell_pipefail_robustness)
# EXIT : 0 ok · 2 sem base para comparar (não chuta)
# =============================================================================
set -uo pipefail
SUT=".claude/validation/lint-selftest.sh"
BASE="${1:-$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || true)}"
[ -n "${BASE}" ] || { echo "preflight-families: sem merge-base com origin/main nem main — não chuto" >&2; exit 2; }

fams="shell_pipefail_robustness"
if git cat-file -e ":${SUT}" 2>/dev/null; then
  # linhas do arquivo STAGEADO tocadas pelo diff (lado +, com -U0) → a função run_*_selftests que as contém
  changed="$(git diff --cached -U0 "${BASE}" -- "${SUT}" | sed -n 's/^@@ -[0-9,]* +\([0-9]*\)\(,\([0-9]*\)\)\{0,1\} @@.*/\1 \3/p')"
  if [ -n "${changed}" ]; then
    hit="$(git show ":${SUT}" | CH="${changed}" python3 -c '
import os, re, sys
lines = sys.stdin.read().split("\n")
owner, cur = {}, None
for i, l in enumerate(lines, 1):
    m = re.match(r"^run_([a-z0-9_]+)_selftests\(\) \{", l)
    if m: cur = m.group(1)
    elif l.startswith("}") and cur: owner[i] = cur; cur = None; continue
    if cur: owner[i] = cur
out = set()
for row in os.environ["CH"].split("\n"):
    p = row.split()
    if not p: continue
    start = int(p[0]); n = int(p[1]) if len(p) > 1 and p[1] != "" else 1
    for k in range(start, start + max(n, 1)):
        if k in owner: out.add(owner[k])
print(",".join(sorted(out)))
')"
    [ -n "${hit}" ] && fams="${fams},${hit}"
  fi
fi

# ── A PORTA MINI (2026-11-06, tarefa #31) ────────────────────────────────────────────────────────────
# POR QUÊ: a família door_mini materializa o onion-mini e roda o door-mini-check (ponteiro morto, allowlist
# exata). O que a reprova é um arquivo QUE VIAJA ao mini, não uma linha da bancada; por isso o mapa acima nunca
# a escolhia. Medido: os PRs #1497 (engineer/pr.md passou a citar review-triage.md) e #1501 (o adapter do
# ClickUp passou a citar a bancada dele) saíram verdes no pré-voo e reprovaram no CI na door_mini (a).
# A SUPERFÍCIE é DERIVADA do roles.yaml do ÍNDICE (a allowlist, relativa a .claude/, e as fontes dos overlays):
# arquivo que entrar na allowlist amanhã já nasce coberto. Somam-se só os insumos da própria verificação
# (o roles.yaml, o resolvedor, o checador, o manifesto e o materializador). Limite declarado: arquivo NOVO
# fora do mini cujo nome um arquivo do mini já cita (comando, agente) também cria ponteiro morto e não seleciona.
# Não decidir não vira "não seleciona": roles.yaml presente e resolvedor que falha ⇒ a família entra.
ROLES_REL=".claude/utils/marketplace/roles.yaml"
RESOLVER=".claude/utils/marketplace/resolve-role-bundle.sh"
if git cat-file -e ":${ROLES_REL}" 2>/dev/null && [ -f "${RESOLVER}" ] \
   && git grep -q --cached -E '^run_door_mini_selftests\(\) \{' -- "${SUT}" 2>/dev/null; then
  touched="$(git -c core.quotePath=false diff --cached --no-renames --name-only "${BASE}")"
  if [ -n "${touched}" ]; then
    _rt="$(mktemp)"; git show ":${ROLES_REL}" > "${_rt}"
    _al="$(bash "${RESOLVER}" mini --allowlist "${_rt}" 2>/dev/null)"; _al_rc=$?
    _ov="$(bash "${RESOLVER}" mini --overlays "${_rt}" 2>/dev/null)"; _ov_rc=$?
    rm -f "${_rt}"
    if [ "${_al_rc}" != 0 ] || [ "${_ov_rc}" != 0 ] || [ -z "${_al}" ]; then
      echo "preflight-families: não resolvi a allowlist do mini (rc ${_al_rc}/${_ov_rc}) — door_mini entra" >&2
      fams="${fams},door_mini"
    else
      surf="$( { printf '%s\n' "${_al}" | sed 's#^#.claude/#'; printf '%s\n' "${_ov}" | cut -f2
                 printf '%s\n' "${ROLES_REL}" "${RESOLVER}" .claude/validation/door-mini-check.sh \
                   .claude/utils/adopt/vendor-manifest.sh ops/materialize-door.sh; } | sed '/^$/d')"
      if TOUCHED="${touched}" SURF="${surf}" python3 -c '
import os, sys
surf = os.environ["SURF"].split("\n")
for t in os.environ["TOUCHED"].split("\n"):
    if t and any(t == s or (s.endswith("/") and t.startswith(s)) for s in surf):
        sys.exit(0)
sys.exit(1)'; then
        fams="${fams},door_mini"
      fi
    fi
  fi
fi
# sem repetição (a família pode vir pelos dois caminhos), na ordem em que entrou
printf '%s\n' "${fams}" | tr ',' '\n' | awk 'NF && !seen[$0]++' | paste -sd, -
