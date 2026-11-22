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
# SAÍDA: famílias separadas por vírgula (sempre inclui shell_pipefail_robustness; door_mini e as famílias das
#        fixtures entram pela superfície que o diff toca, cada uma derivada no bloco dela)
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
      # 0 = toca a superfície · 10 = não toca · outro rc = não decidiu (o Python que CAI sai 1, e até 2026-11-22
      # o "1" daqui era também o "não toca": um traceback calava a família). Não decidir ⇒ door_mini entra.
      TOUCHED="${touched}" SURF="${surf}" python3 -c '
import os, sys
surf = os.environ["SURF"].split("\n")
for t in os.environ["TOUCHED"].split("\n"):
    if t and any(t == s or (s.endswith("/") and t.startswith(s)) for s in surf):
        sys.exit(0)
sys.exit(10)'; _dm_rc=$?
      case "${_dm_rc}" in
        0) fams="${fams},door_mini" ;;
        10) : ;;
        *) echo "preflight-families: não decidi a superfície do mini (rc ${_dm_rc}) — door_mini entra" >&2
           fams="${fams},door_mini" ;;
      esac
    fi
  fi
fi
# ── A SUPERFÍCIE DAS REGRAS (2026-11-22) ────────────────────────────────────────────────────────────
# POR QUÊ: o PR #1735 criou a REGRA 122 no lint-artifacts.sh e o pré-voo só escolheu as famílias cujas LINHAS
# da bancada mudaram (agent_color) mais door_mini. A regra nova acusou as fixtures BOAS de agente; o defeito só
# apareceu no CI (fixtures e lint_hard_file), depois de 1 hora de fila. O CI pegou porque, para ele, o
# lint-artifacts.sh é infraestrutura da bancada e compra a completa; o pré-voo não tinha mapa nenhum para isso.
# A SUPERFÍCIE é DERIVADA do lint-artifacts.sh do ÍNDICE: todo arquivo de .claude/validation/ (só o 1º nível,
# .sh/.py/.tsv) cujo nome o lint cita é juiz ou dado de juiz de alguma REGRA, e quem nascer amanhã já nasce
# coberto. Somam-se o próprio lint, o rules-registry.sh, o lint-rules.md e a pasta fixtures/. Fora de propósito:
# a bancada (lint-selftest.sh, que o lint cita; o bloco dela tem regra própria acima) e os baselines .txt (lista
# de resíduos da árvore viva, não mudam o veredito de fixture).
# AS FAMÍLIAS são uma lista curta, porque a ligação delas com o lint passa por SANDBOX e o mapa da bancada não a
# enxerga: fixtures (o manifesto de fixtures boas e más contra o lint), lint_hard_file (uma fixture boa e uma má
# pelo lint com ONION_LINT_HARD_FILE) e sweep_fixtures (a limpeza das fixtures órfãs). Quem confere a lista é a
# bancada (run_preflight_families_selftests, caso g): cada uma tem de existir como família.
# Não decidir não vira "não seleciona": lint presente e superfície que não deriva ⇒ as famílias entram.
RULE_FAMS="fixtures,sweep_fixtures,lint_hard_file"
LINT_REL=".claude/validation/lint-artifacts.sh"
if git cat-file -e ":${LINT_REL}" 2>/dev/null; then
  touched_r="$(git -c core.quotePath=false diff --cached --no-renames --name-only "${BASE}")"
  if [ -n "${touched_r}" ]; then
    # só o 1º nível de .claude/validation/ (o glob não desce): a pasta inteira, com as fixtures, é grande
    _vl="$(git -c core.quotePath=false ls-files --cached -- ':(glob).claude/validation/*')"; _vl_rc=$?
    _lt="$(mktemp)"; git show ":${LINT_REL}" > "${_lt}"; _lt_rc=$?
    _tt="$(mktemp)"; printf '%s\n' "${touched_r}" > "${_tt}"
    _hit_rc=2
    if [ "${_vl_rc}" = 0 ] && [ "${_lt_rc}" = 0 ] && [ -n "${_vl}" ] && [ -s "${_lt}" ]; then
      # o lint e a lista tocada vão por ARQUIVO, nunca por variável de ambiente: o lint passa de 1 MB e estourou o
      # execve (medido: "Argument list too long", que sem o rc à parte viraria "não seleciona")
      VL="${_vl}" python3 - "${_lt}" "${_tt}" <<'PYRULES'
import os, re, sys
lint = open(sys.argv[1], encoding="utf-8", errors="replace").read()
cited = set(re.findall(r"[A-Za-z0-9_.-]+\.(?:sh|py|tsv)\b", lint))
surf = {".claude/validation/lint-artifacts.sh", ".claude/validation/rules-registry.sh",
        ".claude/validation/lint-rules.md"}
for f in os.environ["VL"].split("\n"):
    rest = f[len(".claude/validation/"):]
    if f and "/" not in rest and rest in cited and rest != "lint-selftest.sh":
        surf.add(f)
for t in open(sys.argv[2], encoding="utf-8", errors="replace").read().split("\n"):
    if t and (t in surf or t.startswith(".claude/validation/fixtures/")):
        sys.exit(0)
sys.exit(10)
PYRULES
      _hit_rc=$?
    fi
    rm -f "${_lt}" "${_tt}"
    # 0 = toca a superfície · 10 = não toca · outro rc (o Python que cai sai 1) = não decidiu ⇒ as famílias entram
    case "${_hit_rc}" in
      0) fams="${fams},${RULE_FAMS}" ;;
      10) : ;;
      *) echo "preflight-families: não derivei a superfície das regras (rc ${_vl_rc}/${_lt_rc}/${_hit_rc}) — ${RULE_FAMS} entram" >&2
         fams="${fams},${RULE_FAMS}" ;;
    esac
  fi
fi
# sem repetição (a família pode vir pelos dois caminhos), na ordem em que entrou
printf '%s\n' "${fams}" | tr ',' '\n' | awk 'NF && !seen[$0]++' | paste -sd, -
