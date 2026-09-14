#!/usr/bin/env bash
# =============================================================================
# kb-vendored-link-check.sh — GUARD CORE-SIDE do link vendorizado (com catraca)
#
# O QUE   : uma KB vendorizada (docs/knowledge-base/**) NÃO deve carregar um link
#           markdown VIVO para um caminho CORE-PRIVADO (docs/analysis, docs/onion,
#           docs/evolution, docs/discussions, docs/{applying,materials,plans},
#           .claude/diary, .claude/sessions). Esses caminhos NÃO são vendorizados
#           a NENHUM adotante (cheio ou door) — o link resolve no core (role:source)
#           e o lint local passa, mas no adotante é um link MORTO: 404 ao clicar.
#
# POR QUÊ  : `_scan_relative_links` (REGRA de links KB) já TOLERA esses alvos no
#           adotante (pula os "ausente-por-desenho") — mas tolerar o *lint* não
#           conserta a *experiência*: o adotante lê "ADR interno do core" e não
#           alcança nada. A superação (pedido do maestro, 2026-07-24) é
#           fonte≠derivação com DIMENSÃO: transformar o link em referência
#           plain-text + um GLOSS que carrega a essência do artefato. Este guard é
#           o mecanismo que força a conversão NO CORE, antes de o link morto
#           embarcar. É "o adotante é o oráculo" mecanizado: o core passa a checar
#           a perspectiva do adotante que ele mesmo não enxerga.
#           Origem: bug de campo numa adoção (link p/ .claude/diary numa KB
#           vendorizada reprovou o lint DENTRO do repo dele; o do core deixou passar).
#
# ---------------------------------------------------------------------------
# A CATRACA (idêntica em espírito à REGRA 29 — kg-provenance-coverage.sh)
# ---------------------------------------------------------------------------
#   O passivo é grande (~30 KBs citam ADRs/análises por link relativo). Sem
#   catraca o guard nasce reprovando dezenas e é desligado no 1º dia. Por isso:
#     · passivo existente vai para BASELINE versionado e é TOLERADO (SOFT);
#     · link NOVO fora do baseline p/ caminho core-privado = HARD;
#     · o baseline SÓ PODE ENCOLHER — acrescentar entrada é REGRESSÃO (HARD),
#       checado contra a versão anterior do baseline no git (origin/integração).
#   A métrica de saúde é o baseline DIMINUINDO (cada migração link→gloss remove uma
#   linha), não o guard passando.
#
# ---------------------------------------------------------------------------
# DECIDIDO SÓ COM O REPO (CI-safe, determinístico, sem LLM)
# ---------------------------------------------------------------------------
#   Escopo (find sob docs/knowledge-base), resolução (realpath -m interno), baseline
#   (arquivo versionado) e versão anterior (git show de ref do próprio repo). Nenhum
#   estado externo participa: clone limpo no CI => mesmo veredito.
#
# Uso    : kb-vendored-link-check.sh [REPO_DIR] [--format text|tsv] [--summary]
#          kb-vendored-link-check.sh [REPO_DIR] --emit-baseline > <baseline>
#          kb-vendored-link-check.sh --selftest
# Baseline default: <repo>/.claude/validation/kb-vendored-link-baseline.txt
# Exit   : 0 = sem HARD · 1 = ao menos uma HARD · 2 = uso.
# =============================================================================
set -uo pipefail

FORMAT="text"; SUMMARY=0; EMIT_BASELINE=0; SELFTEST=0; BASELINE=""; PREV_BASELINE=""; BASE_REF=""
REPO_DIR=""

# Prefixos CORE-PRIVADOS: ausentes em TODO adotante (cheio ou door). Alinhado ao
# skip-list de _scan_relative_links (docs/*) + .claude/{diary,sessions} (que NÃO
# estão lá e por isso QUEBRAM o lint do adotante — o bug de campo).
_is_core_private() {
  case "$1" in
    docs/analysis/*|docs/onion/*|docs/evolution/*|docs/discussions/*) return 0 ;;
    docs/applying/*|docs/materials/*|docs/plans/*)                    return 0 ;;
    .claude/diary/*|.claude/sessions/*)                              return 0 ;;
  esac
  return 1
}
# Pré-filtro barato (perf: evita realpath p/ o link intra-KB, que é a maioria) —
# só resolve o alvo cujo texto CRU contém um segmento core-privado plausível.
_maybe_core_private='(analysis|onion|evolution|discussions|applying|materials|plans|diary|sessions)/'

# AS RAÍZES VENDORIZADAS — o que o adotante de fato RECEBE.
# Espelha `want=` de .claude/commands/meta/adopt.md:113 e `roots=` da REGRA 36. Um path novo
# vendorizado no adopt precisa entrar aqui também, ou nasce descoberto.
#
# ⚠️ ATÉ 2026-08-03 ESTE GUARD VARRIA SÓ `docs/knowledge-base` — 1 DE 9.
# A revisão das guardas mediu o custo: 46 links markdown VIVOS p/ caminho core-privado, em 21
# arquivos das outras 8 raízes (ex.: .claude/skills/onion/SKILL.md, .claude/commands/meta/adopt.md,
# .claude/agents/meta/onion.md → ../../../docs/analysis/*.md), TODOS 404 em qualquer adotante.
# Ninguém os cobria: a REGRA 22 não varre `.claude/`, a 48 só pega backtick, esta só pegava KB.
# O incômodo maior era a MÉTRICA: o guard drenou 101 links da KB até o baseline zerar e
# DECLAROU VITÓRIA com o mesmo modo de falha vivo na porta ao lado — `declarado ≠ verificado`
# dentro da própria métrica de saúde de uma guarda. [[fix-must-become-mechanism]]
# RAÍZES DERIVADAS DO TRANSPORTE (SSOT: .claude/utils/adopt/vendor-manifest.sh). Medido 2026-09-13:
# esta lista tinha 9 raízes contra as 11 que o /meta:adopt copia — `.claude/rules` e `.claude/workflows`
# viajavam e nenhuma das duas guardas de vendorização os via. Fallback explícito (nunca vazio: lista
# vazia zeraria a guarda em silêncio, que é o modo de falha que o cabeçalho acima já narra).
VENDORED_ROOTS=()
_VM="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils/adopt" 2>/dev/null && pwd)/vendor-manifest.sh"
if [ -f "${_VM}" ]; then
  while IFS= read -r _r; do [ -n "${_r}" ] && VENDORED_ROOTS+=("${_r}"); done < <(bash "${_VM}" --emit-scrub-roots 2>/dev/null || true)
fi
if [ "${#VENDORED_ROOTS[@]}" -eq 0 ]; then
  echo "AVISO: vendor-manifest.sh nao respondeu — usando a lista de fallback (pode estar defasada)" >&2
  VENDORED_ROOTS=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation
                  .claude/hooks .claude/rules .claude/workflows docs/meta-specs docs/knowledge-base docs/sdaal)
fi

# Extrai (rel|resolved_rel) de cada link relativo core-privado vivo do corpus vendorizado.
collect_violations() { # <repo_dir>  -> stdout: "<rel>|<resolved_rel>"
  local repo="$1" r bases=()
  for r in "${VENDORED_ROOTS[@]}"; do [ -d "${repo}/${r}" ] && bases+=("${repo}/${r}"); done
  [ "${#bases[@]}" -gt 0 ] || return 0
  local f dir rel lineno target clean res
  while IFS= read -r -d '' f; do
    dir="$(dirname "${f}")"; rel="${f#${repo}/}"
    while IFS=$'\t' read -r lineno target; do
      [ -n "${target}" ] || continue
      case "${target}" in *"://"*|"#"*|/*) continue ;; esac
      # pré-filtro (perf): regex BASH nativo, sem fork — a maioria dos links é
      # intra-KB e para aqui sem tocar realpath. Fork por link afogaria o lint.
      [[ "${target}" =~ ${_maybe_core_private} ]] || continue
      clean="${target%%#*}"; [ -n "${clean}" ] || continue
      res="$(realpath -m --relative-to="${repo}" "${dir}/${clean}" 2>/dev/null)" || continue
      _is_core_private "${res}" && printf '%s|%s\n' "${rel}" "${res}"
    done < <(awk '
      /^[[:space:]]*```/ { fence = !fence; next }
      fence { next }
      { line = $0
        while (match(line, /\]\(([^)]+)\)/)) {
          tgt = substr(line, RSTART + 2, RLENGTH - 3)
          line = substr(line, RSTART + RLENGTH)
          if (tgt ~ /^(https?|mailto):/) continue
          if (tgt ~ /^[\/#]/) continue
          printf "%d\t%s\n", NR, tgt
        }
      }' "${f}")
  done < <(find "${bases[@]}" -type f -name '*.md' -print0 2>/dev/null) | sort -u
}

# ---------------------------------------------------------------------------
# SELFTEST (self-contido, à la ladder-integrity-check.sh) — dogfood do guard
# ---------------------------------------------------------------------------
run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0 out
  local kbdir="${tmp}/docs/knowledge-base/concepts"
  mkdir -p "${kbdir}" "${tmp}/docs/analysis" "${tmp}/.claude/validation"
  local BL="${tmp}/.claude/validation/kb-vendored-link-baseline.txt"
  # NB: captura em VAR, nunca `child | grep -q` — sob set -o pipefail o grep -q sai
  # no 1º match, fecha a pipe, o child morre de SIGPIPE(141) e a pipe reporta falso
  # (a armadilha documentada no cabeçalho de kg-provenance-coverage.sh).
  _run() { out="$("$0" "${tmp}" --format tsv 2>/dev/null)"; }

  # (i) link VIVO p/ docs/analysis SEM baseline => HARD (novo)
  printf '# a\nver [x](../../analysis/foo.md) fim\n' > "${kbdir}/a.md"
  printf '# baseline vazio\n' > "${BL}"; _run
  if printf '%s' "${out}" | grep -q "^HARD"; then echo "  ✅ (i) link core-privado novo reprova"; else echo "  ✗ (i)"; fails=$((fails+1)); fi

  # (ii) MESMO link no baseline => tolerado (SOFT, sem HARD)
  printf 'docs/knowledge-base/concepts/a.md|docs/analysis/foo.md\n' >> "${BL}"; _run
  if printf '%s' "${out}" | grep -q "^HARD"; then echo "  ✗ (ii) passivo no baseline não deveria dar HARD"; fails=$((fails+1)); else echo "  ✅ (ii) passivo baselined tolerado (SOFT)"; fi

  # (iii) link intra-KB (não core-privado) => IGNORADO (nunca viola)
  printf '# b\nver [y](outra-kb.md) e [z](../frameworks/g.md) fim\n' > "${kbdir}/b.md"
  printf '# baseline vazio\n' > "${BL}"; _run
  if printf '%s' "${out}" | grep -q "b.md"; then echo "  ✗ (iii) link intra-KB não deveria violar"; fails=$((fails+1)); else echo "  ✅ (iii) link intra-KB ignorado"; fi

  # (iv) link p/ .claude/diary (o bug de campo) => HARD
  printf '# c\nver [w](../../../.claude/diary/2026-07-21-x.md) fim\n' > "${kbdir}/c.md"
  printf '# baseline vazio\n' > "${BL}"; _run
  if printf '%s' "${out}" | grep -q "diary"; then echo "  ✅ (iv) link p/ .claude/diary reprova (o bug de campo)"; else echo "  ✗ (iv)"; fails=$((fails+1)); fi

  # (v) link p/ .claude/skills (VENDORIZADO — adotante recebe) => IGNORADO
  rm -f "${kbdir}/c.md"
  printf '# d\nver [s](../../../.claude/skills/onion/SKILL.md) fim\n' > "${kbdir}/d.md"
  printf '# baseline vazio\n' > "${BL}"; _run
  if printf '%s' "${out}" | grep -q "skills"; then echo "  ✗ (v) .claude/skills é vendorizado, não deveria violar"; fails=$((fails+1)); else echo "  ✅ (v) link p/ .claude/skills (vendorizado) ignorado"; fi

  # (vi) sem baseline => HARD acionável (NO-BASELINE), não silêncio
  rm -f "${kbdir}/d.md" "${kbdir}/b.md"; rm -f "${BL}"
  printf '# a\nver [x](../../analysis/foo.md) fim\n' > "${kbdir}/a.md"; _run
  if printf '%s' "${out}" | grep -q "NO-BASELINE"; then echo "  ✅ (vi) baseline ausente = HARD acionável"; else echo "  ✗ (vi)"; fails=$((fails+1)); fi

  rm -rf "${tmp}"; echo "  selftest: $((6-fails))/6 verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

# --- args --------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --selftest)           SELFTEST=1; shift ;;
    --format)             FORMAT="${2:-text}"; shift 2 ;;
    --format=*)           FORMAT="${1#--format=}"; shift ;;
    --summary)            SUMMARY=1; shift ;;
    --emit-baseline)      EMIT_BASELINE=1; shift ;;
    --baseline)           BASELINE="${2:-}"; shift 2 ;;
    --baseline=*)         BASELINE="${1#--baseline=}"; shift ;;
    --previous-baseline)  PREV_BASELINE="${2:-}"; shift 2 ;;
    --base-ref)           BASE_REF="${2:-}"; shift 2 ;;
    -h|--help)            printf 'Uso: kb-vendored-link-check.sh [REPO_DIR] [--format text|tsv] [--summary] [--emit-baseline] | --selftest\n'; exit 0 ;;
    *)                    if [ -z "${REPO_DIR}" ]; then REPO_DIR="$1"; fi; shift ;;
  esac
done

[ "${SELFTEST}" -eq 1 ] && { run_selftest; exit $?; }
case "${FORMAT}" in text|tsv) ;; *) printf '❌ --format inválido: %s\n' "${FORMAT}" >&2; exit 2 ;; esac
REPO_DIR="${REPO_DIR:-.}"
[ -d "${REPO_DIR}" ] || { printf '⚠️  kb-vendored-link-check: "%s" não é diretório.\n' "${REPO_DIR}" >&2; exit 0; }
REPO_DIR="$(cd "${REPO_DIR}" && pwd)"

BASELINE_REL=".claude/validation/kb-vendored-link-baseline.txt"
[ -n "${BASELINE}" ] || BASELINE="${REPO_DIR}/${BASELINE_REL}"

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
collect_violations "${REPO_DIR}" > "${TMP}/current"

# --emit-baseline: bootstrap operado À MÃO (o script nunca ESCREVE o baseline —
# escrita automática desarmaria a catraca).
if [ "${EMIT_BASELINE}" -eq 1 ]; then
  printf '# Baseline de links vendorizados p/ caminho core-privado — PASSIVO TOLERADO.\n'
  printf '# Gerado por: bash .claude/validation/kb-vendored-link-check.sh --emit-baseline > %s\n' "${BASELINE_REL}"
  printf '# formato: <rel>|<resolved_core_private_rel>. SÓ PODE ENCOLHER (migre link→gloss e remova a linha).\n'
  # SCOPE — a catraca compara passivos; passivos de ESCOPOS diferentes não são comparáveis.
  # Sem esta linha, ampliar a varredura dispara "CATRACA VIOLADA" em massa e o autor é
  # empurrado a NÃO ampliar — a catraca passa a DEFENDER o ponto cego que ela deveria expor.
  printf '# scope: %s\n' "${VENDORED_ROOTS[*]}"
  cat "${TMP}/current"
  exit 0
fi

read_baseline() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null | sed 's/[[:space:]]*$//' | sort -u || true; }
HARD=0; SOFT=0; : > "${TMP}/out"
say() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${TMP}/out"; [ "$1" = "HARD" ] && HARD=$((HARD+1)) || SOFT=$((SOFT+1)); }

if [ ! -f "${BASELINE}" ]; then
  say "HARD" "NO-BASELINE" "${BASELINE_REL}" "baseline AUSENTE — catraca desarmada; nenhum link novo pode ser distinguido do passivo. Gere: bash .claude/validation/kb-vendored-link-check.sh --emit-baseline > ${BASELINE_REL}"
  while IFS= read -r p; do [ -n "${p}" ] && say "SOFT" "NO-BASELINE-LINK" "${p%%|*}" "link core-privado '${p#*|}' (severidade rebaixada: sem baseline)"; done < "${TMP}/current"
else
  read_baseline "${BASELINE}" > "${TMP}/baseline"
  # (a) NOVO fora do baseline => HARD
  comm -23 "${TMP}/current" "${TMP}/baseline" > "${TMP}/novos"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "HARD" "NEW" "${p%%|*}" "link VIVO p/ caminho core-privado '${p#*|}' — morto no adotante. Troque por referência plain-text + GLOSS que carregue a dimensão do artefato (convenção fonte≠derivação, graduated-automation-ladder.md)"
  done < "${TMP}/novos"
  # (b) passivo tolerado => SOFT
  comm -12 "${TMP}/current" "${TMP}/baseline" > "${TMP}/passivo"
  while IFS= read -r p; do [ -n "${p}" ] && say "SOFT" "PASSIVO" "${p%%|*}" "passivo: link core-privado '${p#*|}' — migre p/ plain-text+gloss e remova do baseline"; done < "${TMP}/passivo"
  # (c) entrada obsoleta/órfã => SOFT (a catraca cobra o encolhimento)
  while IFS= read -r p; do [ -n "${p}" ] && ! grep -qxF "${p}" "${TMP}/current" && say "SOFT" "BASELINE-OBSOLETA" "${BASELINE_REL}" "entrada OBSOLETA '${p}' — já não existe (link migrado?). Remova do baseline (só encolhe)"; done < "${TMP}/baseline"
  # (d) CATRACA — baseline SÓ ENCOLHE (vs origin/integração > HEAD)
  : > "${TMP}/prev"; PREV_SOURCE=""
  PREV_RAW=""      # de ONDE veio o prev — o `# scope:` tem de sair da mesma fonte que o passivo
  if [ -n "${PREV_BASELINE}" ] && [ -f "${PREV_BASELINE}" ]; then
    read_baseline "${PREV_BASELINE}" > "${TMP}/prev"; PREV_SOURCE="arquivo"; PREV_RAW="${PREV_BASELINE}"
  elif git -C "${REPO_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    refs="${BASE_REF}"; if [ -z "${refs}" ]; then
      _sib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/resolve-integration-branch.sh"
      integ=""; [ -x "${_sib}" ] && integ="$("${_sib}" "${REPO_DIR}" 2>/dev/null || true)"
      [ -n "${integ}" ] && refs="origin/${integ} ${integ}"; refs="${refs} HEAD"
    fi
    for r in ${refs}; do
      if git -C "${REPO_DIR}" show "${r}:${BASELINE_REL}" >"${TMP}/prev.raw" 2>/dev/null; then
        read_baseline "${TMP}/prev.raw" > "${TMP}/prev"; PREV_SOURCE="git ${r}"; PREV_RAW="${TMP}/prev.raw"
        case "${r}" in origin/*) : ;; *) [ -n "${BASE_REF}" ] || say "SOFT" "CATRACA-FRACA" "${BASELINE_REL}" "catraca vs '${r}' (ref LOCAL): crescimento já commitado aqui não é detectado — só origin/<integração> é referência forte"; esac
        break
      fi
    done
  fi
  # Escopo declarado em cada baseline (linha `# scope:`). Ausente = escopo legado (só a KB).
  _scope_of() { grep -m1 '^# scope:' "$1" 2>/dev/null | sed 's/^# scope:[[:space:]]*//' || true; }
  CUR_SCOPE="$(_scope_of "${BASELINE}")"; PREV_SCOPE=""
  # Lê da MESMA fonte que produziu ${TMP}/prev — antes lia sempre de prev.raw, que só existe no
  # ramo git: sob --previous-baseline o scope vinha vazio, os escopos "divergiam" e a catraca
  # se suspendia sozinha. Bug achado no MUT-2 desta própria mudança, 2026-08-03.
  [ -n "${PREV_RAW}" ] && [ -f "${PREV_RAW}" ] && PREV_SCOPE="$(_scope_of "${PREV_RAW}")"
  if [ -n "${PREV_SOURCE}" ]; then
    if [ "${CUR_SCOPE}" != "${PREV_SCOPE}" ]; then
      # EXPANSÃO DE ESCOPO — a comparação de crescimento fica SUSPENSA nesta rodada, com aviso
      # visível. Não é porta dos fundos: o `scope:` é DERIVADO de VENDORED_ROOTS pelo script (não
      # se escreve à mão), então usá-lo para mascarar crescimento exige alterar o código do guard
      # — que aparece no diff. E o SOFT abaixo garante que a suspensão nunca passe em silêncio.
      say "SOFT" "ESCOPO-EXPANDIDO" "${BASELINE_REL}" \
        "escopo do guard MUDOU ('${PREV_SCOPE:-<legado: só docs/knowledge-base>}' → '${CUR_SCOPE}') — catraca de crescimento SUSPENSA nesta rodada (passivos de escopos distintos não são comparáveis). Na próxima, a catraca volta a valer sobre o novo escopo."
    else
      comm -13 "${TMP}/prev" "${TMP}/baseline" > "${TMP}/added"
      while IFS= read -r p; do [ -n "${p}" ] && say "HARD" "CATRACA" "${BASELINE_REL}" "CATRACA VIOLADA: '${p}' ACRESCENTADO ao baseline (vs ${PREV_SOURCE}) — só pode ENCOLHER. Link morto se migra p/ gloss, não se amplia a tolerância"; done < "${TMP}/added"
    fi
  fi
fi

if [ "${FORMAT}" = "tsv" ]; then
  cat "${TMP}/out"
else
  printf '=== Links vendorizados p/ caminho core-privado (escopo: docs/knowledge-base) ===\n'
  printf '  Links core-privados: %s · Baseline: %s\n\n' "$(wc -l < "${TMP}/current" | tr -d ' ')" "$([ -f "${BASELINE}" ] && printf '%s entrada(s)' "$(wc -l < "${TMP}/baseline" 2>/dev/null | tr -d ' ')" || printf 'AUSENTE')"
  while IFS=$'\t' read -r sev tag path msg; do [ -n "${sev}" ] && printf '%s [%s] %s: %s\n' "$([ "${sev}" = "HARD" ] && printf '❌ HARD' || printf '⚠️  SOFT')" "${tag}" "${path}" "${msg}"; done < "${TMP}/out"
fi
[ "${SUMMARY}" -eq 1 ] && printf 'SUMMARY\tHARD=%s\tSOFT=%s\n' "${HARD}" "${SOFT}"
[ "${HARD}" -eq 0 ] || exit 1
exit 0
