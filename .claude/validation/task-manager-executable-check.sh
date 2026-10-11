#!/usr/bin/env bash
# =============================================================================
# task-manager-executable-check.sh — REGRA 104: o executável do adapter e a declaração de capacidades
# dizem a MESMA coisa
#
# O QUE   : quando existe `.claude/utils/task-manager/adapters/<p>.py` (ou `<p>.sh`) — o executável que o
#           dispatcher `tm.sh` chama —, a guarda roda `<exe> --capabilities` (local, sem rede, com ambiente
#           LIMPO: nenhuma chave, nenhum .env) e cobra, contra `adapters/<p>.capabilities.tsv`:
#             · todo verbo que o executável lista está DECLARADO no tsv, e com status ≠ not_implemented
#               (o executável não pode exercer o que a declaração diz que não existe);
#             · todo `implemented` cuja fonte cita `adapter:` (medição registrada no adapter) está na lista
#               do executável (medição que nada executa é a prosa de antes, com carimbo novo);
#             · executável sem declaração reprova; executável que não responde `--capabilities` (rc ≠ 0 ou
#               lista vazia) reprova — mudo não é aprovação.
#
# DEFEITO DATADO (SAC-65, 2026-10-11): até aqui a declaração (REGRA 103) era conferida contra a PROSA do
#           adapter (`linear.md` define `getTask(` em TypeScript que nada executa), e a sessão principal
#           operava o Linear por scripts GraphQL avulsos fora do repo. Com o executável nascendo, a casa passa
#           a ter DUAS fontes da mesma verdade — a lista do executável e o tsv — e a classe já tem precedente
#           medido: o "Bulk-first" do CLAUDE.md declarava capacidade que nenhum adapter exercia (SAC-63, a
#           mesma data). Medido ao forjar: no 1º estado desta branch o executável implementava 12 verbos que
#           o tsv ainda declarava `unverified`, e o `comment.list` estava `implemented` sem nada que o
#           executasse. A guarda nasce com o executável para que as duas listas não se separem em silêncio.
#
# FORA DO ESCOPO / TETO (declarado, não esquecido):
#   · confere a LISTA, não o comportamento: um verbo listado que devolve lixo passa. O comportamento é a
#     medição ao vivo registrada no adapter (REGRA 103 confere que o trecho existe).
#   · `unverified` listado pelo executável passa: o executável pode exercer o que ninguém mediu ainda — a
#     declaração só não pode dizer `not_implemented`.
#   · `implemented` com fonte só `kg:`/`local` não precisa estar na lista: evidência do provedor não é
#     promessa do executável.
#   · python3 ausente: o executável `.py` não é conferido (o lint não inventa veredito sem o interpretador).
#   · o executável é código do próprio repo, rodado com `timeout 15` e ambiente limpo (PATH, HOME, LC_ALL).
#   · TODO `.py`/`.sh` em `adapters/` é lido como executável de provedor (o nome do arquivo é o provedor): um
#     helper solto ali sem tsv reprova como `executavel-sem-declaracao`. Helper de provedor mora um nível
#     acima (como `zoho-token.sh`), não em `adapters/`.
#
# Uso    : task-manager-executable-check.sh [REPO_DIR] [--format text|tsv]
#          task-manager-executable-check.sh --selftest
# Saída  : HARD<TAB><classe><TAB><caminho><TAB><msg> (tsv) · vazio = limpo
#          classes: executavel-sem-declaracao · executavel-mudo · verbo-nao-declarado ·
#                   verbo-declarado-nao-implementado · medido-fora-do-executavel
# Exit   : 0 = limpo · 1 = ao menos uma HARD · 2 = uso.
# =============================================================================
set -uo pipefail

FORMAT="text"; SELFTEST=0; REPO_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --selftest) SELFTEST=1; shift ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    -*) echo "uso: $0 [REPO_DIR] [--format text|tsv] | --selftest" >&2; exit 2 ;;
    *) REPO_DIR="$1"; shift ;;
  esac
done

FOUND=0
_emit() {  # $1=classe $2=caminho relativo $3=mensagem
  FOUND=1
  if [ "${FORMAT}" = "tsv" ]; then printf 'HARD\t%s\t%s\t%s\n' "$1" "$2" "$3"
  else printf 'HARD [%s] %s: %s\n' "$1" "$2" "$3"; fi
}

# Roda `<exe> --capabilities` com ambiente LIMPO: nenhuma chave de provedor, nenhum TM_ENV_FILE.
# É isso que garante "sem rede, sem segredo": um executável que precisa da chave para listar sai mudo.
_list_caps() {  # $1=arquivo → verbos em stdout; rc do executável
  local f="$1" runner
  case "${f}" in
    *.py) command -v python3 >/dev/null 2>&1 || return 99; runner="python3 -I -B" ;;
    *.sh) runner="bash" ;;
    *) return 98 ;;
  esac
  # shellcheck disable=SC2086
  env -i PATH="${PATH}" HOME="${HOME:-/tmp}" LC_ALL=C timeout 15 ${runner} "${f}" --capabilities 2>/dev/null
}

check_repo() {
  local repo="$1" ad="$1/.claude/utils/task-manager/adapters" rel=".claude/utils/task-manager/adapters"
  [ -d "${ad}" ] || return 0
  local f base decl caps rc
  for f in "${ad}"/*.py "${ad}"/*.sh; do
    [ -f "${f}" ] || continue
    base="$(basename "${f}")"; base="${base%.*}"
    decl="${ad}/${base}.capabilities.tsv"
    if [ ! -f "${decl}" ]; then
      _emit "executavel-sem-declaracao" "${rel}/$(basename "${f}")" "executável do provedor '${base}' sem ${base}.capabilities.tsv — o que ele exerce não está declarado em lugar nenhum"
      continue
    fi
    if caps="$(_list_caps "${f}")"; then rc=0; else rc=$?; fi
    [ "${rc}" -eq 99 ] && continue          # python3 ausente: teto declarado, não veredito
    caps="$(LC_ALL=C sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "${caps}" | LC_ALL=C grep -v '^$' || true)"
    if [ "${rc}" -ne 0 ] || [ -z "${caps}" ]; then
      _emit "executavel-mudo" "${rel}/$(basename "${f}")" "'--capabilities' não respondeu (rc=${rc}, $(wc -l <<< "${caps}" | tr -d ' ') verbo(s)) com ambiente limpo — a lista tem de ser local, sem chave e sem rede"
      continue
    fi
    # declaração: cap → status|source (sem BOM, sem CR, sem comentário, sem cabeçalho)
    local declmap
    declmap="$(LC_ALL=C sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' "${decl}" | awk -F'\t' '/^#/ || NF < 6 || $1 == "capability" { next } { print $1 "\t" $3 "\t" $5 }')"
    local verb row st
    while IFS= read -r verb; do
      row="$(awk -F'\t' -v v="${verb}" '$1 == v { print; exit }' <<< "${declmap}")"
      if [ -z "${row}" ]; then
        _emit "verbo-nao-declarado" "${rel}/${base}.capabilities.tsv" "${verb}: o executável ${base}.$(basename "${f}" | sed 's/.*\.//') lista o verbo e o tsv não o declara"
        continue
      fi
      st="$(cut -f2 <<< "${row}")"
      if [ "${st}" = "not_implemented" ]; then
        _emit "verbo-declarado-nao-implementado" "${rel}/${base}.capabilities.tsv" "${verb}: declarado not_implemented, mas o executável o implementa — a declaração mente para baixo"
      fi
    done <<< "${caps}"
    local cap src
    while IFS=$'\t' read -r cap st src; do
      [ -n "${cap}" ] || continue
      [ "${st}" = "implemented" ] || continue
      case ";${src};" in *";adapter:"*) : ;; *) continue ;; esac
      LC_ALL=C grep -qxF -- "${cap}" <<< "${caps}" || \
        _emit "medido-fora-do-executavel" "${rel}/${base}.capabilities.tsv" "${cap}: implemented com fonte adapter: (medição), mas o executável não o lista em --capabilities"
    done <<< "${declmap}"
  done
}

# =============================================================================
run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0 out total=10
  local A="${tmp}/.claude/utils/task-manager/adapters"
  _run() { out="$(bash "$0" "${tmp}" --format tsv 2>/dev/null)"; }
  _has() { command grep -q -- "$1" <<< "${out}"; }
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1"; fails=$((fails+1)); }
  _exe() {  # executável .sh que lista os verbos dados
    { printf '#!/usr/bin/env bash\n[ "$1" = "--capabilities" ] || exit 2\n'; local v; for v in "$@"; do printf 'echo %s\n' "${v}"; done; } > "${A}/alpha.sh"
  }
  _decl() { { printf '# d\ncapability\trequirement\tstatus\tapi_version\tsource\tnote\n'; local l; for l in "$@"; do printf "${l}\n"; done; } > "${A}/alpha.capabilities.tsv"; }
  _reset() {
    rm -rf "${tmp}/.claude"; mkdir -p "${A}"
    _exe item.read comment.add
    _decl 'item.read\trequired\timplemented\tv1\tadapter:alpha.md§MEDIDO AO VIVO 2026-10-11 item.read:\t' \
          'comment.add\trequired\tunverified\tv1\t-\t' \
          'comment.list\trequired\timplemented\tv1\tkg:g#E_X\t' \
          'bulk.create\toptional\tnot_implemented\tv1\t-\t'
  }

  # (i) o HONESTO: listado ⊆ declarado (≠ not_implemented), medido ⊆ listado → cala
  _reset; _run
  if [ -z "${out}" ]; then _ok "(i) executável e declaração coerentes calam"; else _ko "(i) honesto acusou: ${out}"; fi

  # (ii) verbo listado e ausente do tsv
  _reset; _exe item.read comment.add search.query; _run
  if _has $'^HARD\tverbo-nao-declarado\t.*search.query'; then _ok "(ii) verbo do executável sem declaração reprova"; else _ko "(ii) ${out}"; fi

  # (iii) verbo listado e declarado not_implemented (a declaração mente para baixo)
  _reset; _exe item.read comment.add bulk.create; _run
  if _has $'^HARD\tverbo-declarado-nao-implementado\t.*bulk.create'; then _ok "(iii) verbo do executável declarado not_implemented reprova"; else _ko "(iii) ${out}"; fi

  # (iv) implemented com fonte adapter: e o executável não o lista (medição que nada executa)
  _reset; _exe comment.add; _run
  if _has $'^HARD\tmedido-fora-do-executavel\t.*item.read'; then _ok "(iv) implemented medido fora da lista do executável reprova"; else _ko "(iv) ${out}"; fi

  # (v) implemented só com kg: fora da lista cala (evidência do provedor não é promessa do executável)
  _reset; _run
  if ! _has 'comment.list'; then _ok "(v) implemented só com kg: fora da lista cala"; else _ko "(v) ${out}"; fi

  # (vi) executável mudo (rc != 0) reprova — mudo não é aprovação
  _reset; printf '#!/usr/bin/env bash\nexit 1\n' > "${A}/alpha.sh"; _run
  if _has $'^HARD\texecutavel-mudo\t.*alpha.sh'; then _ok "(vi) executável que não responde --capabilities reprova"; else _ko "(vi) ${out}"; fi

  # (vii) ambiente LIMPO: executável que só lista com a chave no ambiente sai mudo (lista tem de ser local)
  _reset; printf '#!/usr/bin/env bash\n[ -n "${TM_PROBE_KEY:-}" ] || exit 3\necho item.read\necho comment.add\n' > "${A}/alpha.sh"
  out="$(TM_PROBE_KEY=1 bash "$0" "${tmp}" --format tsv 2>/dev/null)"
  if _has $'^HARD\texecutavel-mudo\t'; then _ok "(vii) --capabilities roda com ambiente limpo (chave do ambiente não vaza)"; else _ko "(vii) ${out}"; fi

  # (viii) executável sem declaração reprova
  _reset; rm -f "${A}/alpha.capabilities.tsv"; _run
  if _has $'^HARD\texecutavel-sem-declaracao\t.*alpha.sh'; then _ok "(viii) executável sem .capabilities.tsv reprova"; else _ko "(viii) ${out}"; fi

  # (ix) sem executável, a regra não se aplica (o adapter que é só prosa segue com a REGRA 103)
  _reset; rm -f "${A}/alpha.sh"; _run
  if [ -z "${out}" ]; then _ok "(ix) adapter sem executável cala"; else _ko "(ix) ${out}"; fi

  # (x) executável .py é conferido igual (o caso do Linear real), com CRLF na lista
  _reset; rm -f "${A}/alpha.sh"
  if command -v python3 >/dev/null 2>&1; then
    printf 'import sys\nif sys.argv[1:] == ["--capabilities"]:\n    sys.stdout.write("item.read\\r\\nsearch.query\\r\\n")\n' > "${A}/alpha.py"; _run
    if _has $'^HARD\tverbo-nao-declarado\t.*search.query' && ! _has 'item.read'; then _ok "(x) executável .py conferido (CRLF na lista não vira verbo novo)"; else _ko "(x) ${out}"; fi
  else _ok "(x) python3 ausente — caso .py pulado (teto declarado)"; fi

  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

[ "${SELFTEST}" -eq 1 ] && { run_selftest; exit $?; }
[ -n "${REPO_DIR}" ] || REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
check_repo "${REPO_DIR}"
[ "${FOUND}" -eq 0 ] && exit 0 || exit 1
