#!/usr/bin/env bash
# =============================================================================
# adopter-veto-check.sh — REGRA 118: o veto de repo alheio do adotante está registrado e tem lista
#
# O QUE   : (1) o `.claude/settings.json` registra o `pretooluse-adopter-guard.sh` em PreToolUse com matcher que
#           cobre Bash, Write e Edit e com `"onFailure": "block"`; (2) num adotante carimbado
#           (`role: adopted|hub|standalone`) a lista de repos registrados se resolve (o core local, os `local_path`
#           do members.yaml dele, as linhas `repo` de .claude/adopter-guard.tsv); (3) as linhas do arquivo local
#           têm a forma declarada em .claude/hooks/lib/adopter-scope.sh.
#
# DEFEITO DATADO (2026-11-05, grafo guard-adopter-vetoes-2026-11): a curadoria rodou 31 formas de ato com os 5
#           hooks e o cwd no repo dela, e 27 passaram — merge digitado, push na main, `git -C <core> commit`, Write
#           no core. O merge-gate só avisava e o moat-gate saía cedo sem os dados de ops/ (core-only), e nenhum veto
#           tinha Write ou Edit no matcher. O hook novo fecha isso; esta regra impede que ele volte a não disparar
#           (registro) ou dispare sem lista e CALE sem ninguém saber (lista).
#
# O QUE ELA NÃO EXIGE, de propósito:
#   · lista no core ou em repo sem carimbo: lá o hook não se arma (o core tem o moat-gate);
#   · que o hook PEGUE a escrita: isso é a bancada (run_adopter_guard_selftests), não o lint;
#   · o `permissions.deny` nativo: é camada do adotante, com o selo do maestro, e o hook é a segunda linha.
#
# USO     : adopter-veto-check.sh [REPO] [--format text|tsv] | --selftest
# SAÍDA   : <SEV>\t<classe>\t<rel>\t<msg>   classes: registro-ausente (HARD) · lista-ausente (SOFT) ·
#           linha-invalida (SOFT) · vazio = limpo
# RC      : 0 sempre que julgou (as linhas dizem o resto) · 2 = não pôde julgar (≠ aprovação)
# =============================================================================
set -uo pipefail
MODE="check"; FORMAT="text"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_emit() {  # <sev> <classe> <rel> <msg>
  if [ "${FORMAT}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; else printf '%s [%s] %s: %s\n' "$1" "$2" "$3" "$4"; fi
}

_scan() {
  local repo="$1" st="$1/.claude/settings.json" hook="$1/.claude/hooks/pretooluse-adopter-guard.sh"
  local lib="$1/.claude/hooks/lib/adopter-scope.sh"
  # (1) registro — só quando o hook existe na árvore (adotante com vendor antigo não tem o que registrar)
  if [ -f "${hook}" ] && [ -f "${st}" ]; then
    command -v python3 >/dev/null 2>&1 || { echo "adopter-veto-check: python3 ausente — não pude julgar o registro" >&2; return 2; }
    local miss rc=0
    miss="$(python3 -I -B - "${st}" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    sys.stderr.write("settings não parseia: %s\n" % e); sys.exit(2)
need = {"Bash", "Write", "Edit"}
covered = set()
for g in ((d.get("hooks") or {}).get("PreToolUse") or []) if isinstance(d, dict) else []:
    if not isinstance(g, dict):
        continue
    m = str(g.get("matcher") or "*")
    for h in g.get("hooks") or []:
        if not isinstance(h, dict) or "pretooluse-adopter-guard.sh" not in str(h.get("command") or ""):
            continue
        if h.get("onFailure") != "block":
            continue
        for t in need:
            # o matcher do Claude Code: nome exato, lista com `|`, ou regex; `*`/vazio casa tudo
            if m in ("*", "") or t in m.split("|") or re.fullmatch(m, t):
                covered.add(t)
print(",".join(sorted(need - covered)))
PY
)" || rc=$?
    [ "${rc}" -eq 0 ] || return 2
    [ -z "${miss}" ] || _emit HARD registro-ausente .claude/settings.json \
      "o pretooluse-adopter-guard.sh não está registrado em PreToolUse com \"onFailure\": \"block\" para ${miss} — sem isso, no adotante, a escrita em repo alheio por essa ferramenta passa sem veto"
  fi
  # (2) e (3) só no adotante carimbado, e só com a lib que resolve a lista
  [ -f "${lib}" ] || return 0
  # shellcheck source=/dev/null
  . "${lib}"
  onion_adopter_role "${repo}" >/dev/null || return 0
  local tsv="${repo}/${ONION_ADOPTER_TSV_REL}" n=0 ln k p
  if [ -f "${tsv}" ]; then
    while IFS= read -r ln || [ -n "${ln}" ]; do
      n=$((n + 1))
      case "${ln}" in ''|'#'*|[[:space:]]'#'*) continue ;; esac
      [ -z "$(printf '%s' "${ln}" | tr -d '[:space:]')" ] && continue
      read -r k p _ <<< "${ln}"
      case "${k}" in core|repo|allow) : ;; *)
        _emit SOFT linha-invalida "${ONION_ADOPTER_TSV_REL}:${n}" "diretiva '${k}' desconhecida — as válidas são core, repo e allow"; continue ;; esac
      case "${p}" in "~/"*) p="${HOME}/${p#"~/"}" ;; esac
      case "${p}" in
        /*) [ -d "${p}" ] || _emit SOFT linha-invalida "${ONION_ADOPTER_TSV_REL}:${n}" "${k} ${p}: o diretório não existe nesta máquina — a linha não protege nada" ;;
        *) _emit SOFT linha-invalida "${ONION_ADOPTER_TSV_REL}:${n}" "${k} '${p}': o caminho tem de ser absoluto (ou ~/…)" ;;
      esac
    done < "${tsv}"
  fi
  local own others
  own="$(cd "${repo}" && pwd -P)"
  others="$(onion_adopter_repos "${repo}" | while IFS= read -r r; do [ "$(cd "${r}" 2>/dev/null && pwd -P)" = "${own}" ] || printf '%s\n' "${r}"; done)"
  [ -n "${others}" ] || _emit SOFT lista-ausente "${ONION_ADOPTER_TSV_REL}" \
    "[NAO-MEDIDO] o veto de repo alheio está SEM LISTA: nem 'core <caminho>' em ${ONION_ADOPTER_TSV_REL}, nem adopted_from local no carimbo, nem linhas 'repo'. Ele cala para tudo; o maestro declara o checkout do core (o merge e o push na main seguem vetados)"
  return 0
}

_selftest() {
  local tmp total=0 fails=0 out rc
  tmp="$(mktemp -d)"; mkdir -p "${tmp}/r/.claude/hooks/lib" "${tmp}/core/docs/evolution/federation" "${tmp}/outro"
  cp "${HERE}/../hooks/lib/adopter-scope.sh" "${tmp}/r/.claude/hooks/lib/"
  : > "${tmp}/r/.claude/hooks/pretooluse-adopter-guard.sh"
  printf 'members:\n  - id: x\n    local_path: "%s"\n' "${tmp}/outro" > "${tmp}/core/docs/evolution/federation/members.yaml"
  _st() { printf '{"hooks":{"PreToolUse":[{"matcher":"%s","hooks":[{"type":"command","command":"bash \\"$CLAUDE_PROJECT_DIR/.claude/hooks/pretooluse-adopter-guard.sh\\""%s}]}]}}\n' "$1" "${2:-}" > "${tmp}/r/.claude/settings.json"; }
  _run() { total=$((total+1)); out="$(bash "$0" "${tmp}/r" --format tsv 2>&1)"; rc=$?; }
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1 — saída: ${out:0:200}"; fails=$((fails+1)); }

  # (i) o defeito: o hook existe e não está no matcher de Write/Edit → HARD
  _st "Bash" ',"onFailure":"block"'; _run
  if [ "${rc}" -eq 0 ] && grep -q $'^HARD\tregistro-ausente\t.*Edit,Write' <<< "${out}"; then _ok "(i) registro só em Bash acusa Write e Edit"; else _ko "(i) registro só em Bash acusa Write e Edit"; fi
  # (ii) a cura: matcher completo e block → limpo (sem carimbo, a lista nem se julga)
  _st "Bash|Write|Edit|NotebookEdit" ',"onFailure":"block"'; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(ii) registro completo cala"; else _ko "(ii) registro completo cala"; fi
  # (iii) sem onFailure block → HARD (o veto que não roda deixa passar)
  _st "Bash|Write|Edit"; _run
  if grep -q $'^HARD\tregistro-ausente' <<< "${out}"; then _ok "(iii) sem onFailure block acusa"; else _ko "(iii) sem onFailure block acusa"; fi
  # (iv) adotante carimbado sem lista → SOFT lista-ausente, nunca HARD
  _st "Bash|Write|Edit" ',"onFailure":"block"'
  printf 'role: adopted\nadopted_from: https://example.invalid/x.git\n' > "${tmp}/r/.claude/.onion-version"; _run
  if grep -q $'^SOFT\tlista-ausente' <<< "${out}" && ! grep -q '^HARD' <<< "${out}"; then _ok "(iv) adotante sem lista é SOFT nomeado"; else _ko "(iv) adotante sem lista é SOFT nomeado"; fi
  # (v) a cura da lista: `core <caminho>` com members.yaml → limpo
  printf '# lista\ncore\t%s\n' "${tmp}/core" > "${tmp}/r/.claude/adopter-guard.tsv"; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(v) core declarado resolve a lista e cala"; else _ko "(v) core declarado resolve a lista e cala"; fi
  # (vi) linha inválida (diretiva desconhecida, caminho relativo, diretório ausente) → SOFT por linha
  printf 'core\t%s\nnucleo\t/x\nrepo\trelativo/x\nallow\t%s/nao-existe\n' "${tmp}/core" "${tmp}" > "${tmp}/r/.claude/adopter-guard.tsv"; _run
  if [ "$(grep -c $'^SOFT\tlinha-invalida' <<< "${out}")" -eq 3 ] && ! grep -q '^HARD' <<< "${out}"; then _ok "(vi) as três formas de linha inválida acusam, uma cada"; else _ko "(vi) as três formas de linha inválida acusam, uma cada"; fi
  # (vii) o próprio projeto na lista não conta como lista (o registro o lista; ele nunca é alheio)
  printf 'repo\t%s\n' "${tmp}/r" > "${tmp}/r/.claude/adopter-guard.tsv"; _run
  if grep -q $'^SOFT\tlista-ausente' <<< "${out}"; then _ok "(vii) só o próprio repo na lista segue sem lista"; else _ko "(vii) só o próprio repo na lista segue sem lista"; fi
  # (viii) hook ausente na árvore (vendor antigo) → nada a registrar, cala
  rm -f "${tmp}/r/.claude/hooks/pretooluse-adopter-guard.sh" "${tmp}/r/.claude/.onion-version"; _st "Bash"; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(viii) sem o hook na árvore cala"; else _ko "(viii) sem o hook na árvore cala"; fi
  # (ix) settings ilegível → rc 2 (não julgou), nunca aprovação
  : > "${tmp}/r/.claude/hooks/pretooluse-adopter-guard.sh"; printf '{nao json' > "${tmp}/r/.claude/settings.json"; _run
  if [ "${rc}" -eq 2 ]; then _ok "(ix) settings ilegível sai 2"; else _ko "(ix) settings ilegível sai 2"; fi

  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

case "${MODE}" in
  selftest) _selftest ;;
  *) [ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; _scan "${REPO}" ;;
esac
