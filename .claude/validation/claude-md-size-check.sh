#!/usr/bin/env bash
# =============================================================================
# claude-md-size-check.sh — REGRA 109: o CLAUDE.md não cresce sem tirar o equivalente ou citar um nó
# (catraca de tamanho)
#
# O QUE   : o CLAUDE.md carrega em TODA sessão e em TODA compactação. Cada byte que entra nele é pago
#           sempre, e a história deste repo mede que instrução entra muito mais do que sai. A guarda
#           põe um TETO em bytes num baseline versionado. Passar do teto é HARD. O teto só sobe com uma
#           linha `raise:` que cite um nó de .kg.yaml existente, que é onde o porquê vive; sem ela,
#           subir o teto contra a integração é HARD. Ficar muito abaixo do teto é SOFT: a poda só vale
#           se a catraca travar o ganho.
#
# DEFEITO DATADO (medido em 2026-10-19): o CLAUDE.md do core foi de 17.041 B (baseline do grafo
#           poda-instruction-bloat-2026-09, 2026-09-03) para 25.918 B (+52%, +132/−38 linhas em ~20
#           commits), DEPOIS do selo de 2026-09-25 (D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS) que
#           mandava medir antes de podar. Carregou em 90 sessões e 40 compactações no censo L1. A decisão
#           do maestro de 2026-10-19 (D_PODA_CATRACA_E_L2_DIRIGIDO_1019, grafo fila-2026-10-06) pediu
#           esta catraca e o replay L2 antes de qualquer corte.
#
# BASELINE: .claude/validation/claude-md-size-ceiling.txt
#             ceiling: <bytes>
#             raise: <AAAA-MM-DD> +<bytes> <NODE_ID> <motivo>     (zero ou mais)
#           Sem baseline (adotante, porta) a guarda não tem objeto: cala, rc 0.
#
# TETO: a guarda mede BYTES, não comportamento. Ela não sabe se a linha nova evita um erro (é o L2 que
#   mede isso), nem se o corte que abriu a folga tirou algo que importava. O nó citado num `raise:` só é
#   conferido por EXISTÊNCIA (`id: <NODE_ID>` num .kg.yaml rastreado), não por pertinência. E a catraca
#   precisa de uma ref de integração com o baseline: sem ela (bootstrap, ref ausente), só o teto vale.
#   A base da catraca é o MERGE-BASE com a integração, não a ponta: um PR honesto que não tocou o
#   baseline não é acusado quando a main abaixa o teto depois dele (achado do Elenxo, 2026-10-19).
#   NÃO VÊ os outros arquivos que também carregam sempre: `@import` dentro do CLAUDE.md, um
#   `.claude/CLAUDE.md` e rule sem `paths:`. Nenhum existe no core em 2026-10-19 (as 7 rules têm
#   `paths:`), mas a rota está aberta e declarada.
#
# Uso    : claude-md-size-check.sh [REPO_DIR] [--format text|tsv] [--base-ref <ref>] [--selftest]
# Saída  : tsv = SEV<TAB>CODE<TAB>PATH<TAB>MSG · rc 0 = sem HARD · 1 = HARD · 2 = não pôde julgar
# =============================================================================
set -uo pipefail

FOLGA_SOFT=512
NODE_RE='^[A-Za-z0-9_-]+$'   # NODE_ID literal: nunca entra cru numa regex (achado do Elenxo: '.*' passava)
SELF="${BASH_SOURCE[0]}"

_ceiling_of() { awk '/^ceiling:/{gsub(/\r/,"",$2); print $2; exit}' <<< "$1"; }
_raises_of()  { command grep -E '^raise:' <<< "$1" | tr -d '\r' || true; }

run_check() {
  local repo="$1" fmt="$2" base_ref="$3"
  local md="${repo}/CLAUDE.md" bl_rel=".claude/validation/claude-md-size-ceiling.txt"
  local bl="${repo}/${bl_rel}" hard=0
  [ -f "${md}" ] || return 0
  if [ -z "${base_ref}" ]; then
    local ib; ib="$(bash "$(dirname "${SELF}")/resolve-integration-branch.sh" "${repo}" 2>/dev/null || true)"
    [ -n "${ib}" ] && base_ref="origin/${ib}"
  fi
  # a base da catraca é o merge-base, não a ponta da integração
  local base_commit=""
  if [ -n "${base_ref}" ]; then
    base_commit="$(git -C "${repo}" merge-base HEAD "${base_ref}" 2>/dev/null || true)"
  fi
  local base_txt=""
  [ -n "${base_commit}" ] && base_txt="$(git -C "${repo}" show "${base_commit}:${bl_rel}" 2>/dev/null || true)"
  if [ ! -f "${bl}" ]; then
    # sem baseline e sem baseline na base: adotante/porta, sem objeto. Com ele na base: foi REMOVIDO.
    if [ -n "${base_txt}" ]; then
      if [ "${fmt}" = tsv ]; then printf 'HARD\tBASELINE-REMOVIDO\t%s\t%s\n' "${bl_rel}" "o baseline existe na base (${base_ref}) e sumiu aqui: apagar o baseline desliga a catraca do CLAUDE.md"
      else printf 'REGRA 109: [HARD/BASELINE-REMOVIDO] %s — o baseline existe na base (%s) e sumiu aqui\n' "${bl_rel}" "${base_ref}"; fi
      return 1
    fi
    return 0
  fi
  local bl_txt; bl_txt="$(cat "${bl}")"
  local ceiling; ceiling="$(_ceiling_of "${bl_txt}")"
  case "${ceiling}" in ''|*[!0-9]*)
    echo "claude-md-size-check: '${bl_rel}' sem 'ceiling: <bytes>' legível — não posso julgar" >&2; return 2 ;;
  esac
  local size; size="$(wc -c < "${md}" | tr -d ' ')"

  _emit() { # $1 sev $2 code $3 path $4 msg
    if [ "${fmt}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
    else printf 'REGRA 109: [%s/%s] %s — %s\n' "$1" "$2" "$3" "$4"; fi
  }

  if [ "${size}" -gt "${ceiling}" ]; then
    _emit HARD CRESCEU CLAUDE.md "o CLAUDE.md tem ${size} B e o teto é ${ceiling} B (+$(( size - ceiling )) B). Ele carrega em toda sessão e toda compactação: tire o equivalente, ou suba o teto em ${bl_rel} com uma linha 'raise: <data> +<bytes> <NODE_ID> <motivo>' que cite o nó do porquê"
    hard=1
  elif [ $(( ceiling - size )) -gt "${FOLGA_SOFT}" ]; then
    _emit SOFT FOLGA "${bl_rel}" "o CLAUDE.md tem ${size} B, $(( ceiling - size )) B abaixo do teto ${ceiling}: abaixe o 'ceiling:' para ${size}, ou a poda não fica travada"
  fi

  # catraca: o teto só sobe contra o merge-base com raise: NOVO (acrescentado, nunca editado) que cite nó
  # existente e cubra a subida
  if [ -n "${base_txt}" ]; then
    local gone; gone="$(comm -23 <(_raises_of "${base_txt}" | sort -u) <(_raises_of "${bl_txt}" | sort -u))"
    if [ -n "${gone}" ]; then
      _emit HARD RAISE-EDITADA "${bl_rel}" "linha(s) raise: da base foram editadas ou apagadas: $(head -1 <<< "${gone}") — raise: é histórico, só se acrescenta"
      hard=1
    fi
    local base_ceiling; base_ceiling="$(_ceiling_of "${base_txt}")"
    case "${base_ceiling}" in ''|*[!0-9]*) base_ceiling="" ;; esac
    if [ -n "${base_ceiling}" ] && [ "${ceiling}" -gt "${base_ceiling}" ]; then
      local delta=$(( ceiling - base_ceiling )) covered=0 bad="" line
      local new_raises; new_raises="$(comm -13 <(_raises_of "${base_txt}" | sort -u) <(_raises_of "${bl_txt}" | sort -u))"
      while IFS= read -r line; do
        [ -n "${line}" ] || continue
        local add node
        add="$(awk '{print $3}' <<< "${line}")"; node="$(awk '{print $4}' <<< "${line}")"
        add="${add#+}"
        case "${add}" in ''|*[!0-9]*) bad="${bad} '${line}' (bytes ilegíveis)"; continue ;; esac
        if [ -z "${node}" ] || ! [[ "${node}" =~ ${NODE_RE} ]] \
           || ! git -C "${repo}" grep -qE "^[[:space:]]*-?[[:space:]]*\{?[[:space:]]*id:[[:space:]]*[\"']?${node}[\"']?[[:space:]]*([,}#].*)?$" -- '*.kg.yaml' 2>/dev/null; then
          bad="${bad} '${node:-<sem nó>}' (nó inexistente em .kg.yaml rastreado)"; continue
        fi
        covered=$(( covered + add ))
      done <<< "${new_raises}"
      if [ -n "${bad}" ] || [ "${covered}" -lt "${delta}" ]; then
        _emit HARD TETO-SUBIU-SEM-NO "${bl_rel}" "o teto subiu de ${base_ceiling} para ${ceiling} B (+${delta}) contra ${base_ref}, e as linhas 'raise:' novas cobrem ${covered} B${bad:+; recusadas:${bad}} — cada subida cita o nó que diz por quê"
        hard=1
      fi
    fi
  fi
  return "${hard}"
}

run_selftest() {
  local d pass=0 fail=0 out rc
  d="$(mktemp -d)"; trap 'rm -rf "${d}"' RETURN
  _repo() { # $1 = tamanho do CLAUDE.md · $2 = baseline do commit de base · $3 = baseline de HEAD (opcional)
    rm -rf "${d}/r"; mkdir -p "${d}/r/.claude/validation" "${d}/r/kg"
    git -C "${d}/r" init -q -b main 2>/dev/null || git -C "${d}/r" init -q
    printf 'nodes:\n  - id: D_PORQUE_EXISTE\n' > "${d}/r/kg/x.kg.yaml"
    head -c "$1" /dev/zero | tr '\0' 'a' > "${d}/r/CLAUDE.md"
    printf '%s\n' "$2" > "${d}/r/.claude/validation/claude-md-size-ceiling.txt"
    git -C "${d}/r" add -A && git -C "${d}/r" -c user.email=t@t -c user.name=t commit -qm base
    git -C "${d}/r" branch -q base
    [ -n "${3:-}" ] && printf '%s\n' "$3" > "${d}/r/.claude/validation/claude-md-size-ceiling.txt"
    git -C "${d}/r" add -A && git -C "${d}/r" -c user.email=t@t -c user.name=t commit -qm head --allow-empty
    if out="$(bash "${SELF}" "${d}/r" --format tsv --base-ref base 2>&1)"; then rc=0; else rc=$?; fi
  }
  _ok() { pass=$((pass+1)); echo "  ✓ claude-md-size: $1"; }
  _ko() { fail=$((fail+1)); echo "  ✗ claude-md-size: $1 — rc=${rc}: ${out:0:200}"; }

  _repo 25918 'ceiling: 17041'
  { [ "${rc}" = 1 ] && command grep -q $'^HARD\tCRESCEU' <<< "${out}"; } && _ok "(a) o caso medido: 25.918 B contra teto 17.041 → HARD CRESCEU" || _ko "(a)"
  _repo 25700 'ceiling: 25918'
  { [ "${rc}" = 0 ] && [ -z "${out}" ]; } && _ok "(b) dentro do teto e sem folga grande → SILENCIOSO" || _ko "(b)"
  _repo 20000 'ceiling: 25918'
  { [ "${rc}" = 0 ] && command grep -q $'^SOFT\tFOLGA' <<< "${out}"; } && _ok "(c) folga acima de ${FOLGA_SOFT} B → SOFT pede abaixar o teto" || _ko "(c)"
  _repo 26000 'ceiling: 25918' 'ceiling: 26000'
  { [ "${rc}" = 1 ] && command grep -q $'^HARD\tTETO-SUBIU-SEM-NO' <<< "${out}"; } && _ok "(d) teto subiu sem raise: → HARD" || _ko "(d)"
  _repo 26000 'ceiling: 25918' $'ceiling: 26000\nraise: 2026-10-19 +82 D_PORQUE_EXISTE seção nova da guarda'
  { [ "${rc}" = 0 ] && [ -z "${out}" ]; } && _ok "(e) teto subiu com raise: que cita nó existente e cobre a subida → SILENCIOSO" || _ko "(e)"
  _repo 26000 'ceiling: 25918' $'ceiling: 26000\nraise: 2026-10-19 +82 D_NAO_EXISTE motivo'
  { [ "${rc}" = 1 ] && command grep -q 'D_NAO_EXISTE' <<< "${out}"; } && _ok "(f) raise: que cita nó inexistente → HARD nomeando o nó" || _ko "(f)"
  _repo 26000 'ceiling: 25918' $'ceiling: 26000\nraise: 2026-10-19 +10 D_PORQUE_EXISTE motivo'
  { [ "${rc}" = 1 ] && command grep -q 'cobrem 10 B' <<< "${out}"; } && _ok "(g) raise: que não cobre a subida inteira → HARD" || _ko "(g)"
  _repo 26000 'ceiling: 25918' $'ceiling: 26000\nraise: 2026-10-19 +82 .* injeção de regex'
  { [ "${rc}" = 1 ] && command grep -q $'^HARD\tTETO-SUBIU-SEM-NO' <<< "${out}"; } && _ok "(j) NODE_ID com metacaractere de regex é recusado (não casa qualquer nó)" || _ko "(j)"
  _repo 26050 $'ceiling: 26000\nraise: 2026-10-19 +82 D_PORQUE_EXISTE motivo' $'ceiling: 26050\nraise: 2026-10-19 +132 D_PORQUE_EXISTE motivo'
  { [ "${rc}" = 1 ] && command grep -q $'^HARD\tRAISE-EDITADA' <<< "${out}"; } && _ok "(k) raise: antiga editada para cobrir a subida → HARD" || _ko "(k)"
  _repo 999 'ceiling: 100'
  rm -f "${d}/r/.claude/validation/claude-md-size-ceiling.txt"; git -C "${d}/r" add -A; git -C "${d}/r" -c user.email=t@t -c user.name=t commit -qm rm
  if out="$(bash "${SELF}" "${d}/r" --format tsv --base-ref base 2>&1)"; then rc=0; else rc=$?; fi
  { [ "${rc}" = 1 ] && command grep -q $'^HARD\tBASELINE-REMOVIDO' <<< "${out}"; } && _ok "(l) baseline apagado com a base tendo um → HARD (não desliga a guarda)" || _ko "(l)"
  # (n) PR honesto que não tocou o baseline, e a main abaixou o teto depois: compara com o merge-base → SILENCIOSO
  _repo 140 'ceiling: 150'
  git -C "${d}/r" checkout -q -b feat; printf 'b\n' >> "${d}/r/x"; git -C "${d}/r" add -A; git -C "${d}/r" -c user.email=t@t -c user.name=t commit -qm feat
  git -C "${d}/r" checkout -q base; printf 'ceiling: 140\n' > "${d}/r/.claude/validation/claude-md-size-ceiling.txt"
  git -C "${d}/r" add -A; git -C "${d}/r" -c user.email=t@t -c user.name=t commit -qm poda; git -C "${d}/r" checkout -q feat
  if out="$(bash "${SELF}" "${d}/r" --format tsv --base-ref base 2>&1)"; then rc=0; else rc=$?; fi
  { [ "${rc}" = 0 ] && ! command grep -q '^HARD' <<< "${out}"; } && _ok "(n) a main abaixou o teto depois do PR honesto → compara com o merge-base, SILENCIOSO" || _ko "(n)"
  if out="$(timeout 5 bash "${SELF}" "${d}/r" --base-ref 2>&1)"; then rc=0; else rc=$?; fi
  { [ "${rc}" = 2 ]; } && _ok "(o) flag sem valor → rc 2 (não trava)" || _ko "(o)"
  rm -rf "${d}/r"; mkdir -p "${d}/r"; printf 'x\n' > "${d}/r/CLAUDE.md"
  if out="$(bash "${SELF}" "${d}/r" --format tsv 2>&1)"; then rc=0; else rc=$?; fi
  { [ "${rc}" = 0 ] && [ -z "${out}" ]; } && _ok "(h) sem baseline (adotante, porta) → sem objeto, SILENCIOSO" || _ko "(h)"
  _repo 100 'teto: 100'
  { [ "${rc}" = 2 ]; } && _ok "(i) baseline sem ceiling: legível → rc 2 (não pôde julgar, nunca verde)" || _ko "(i)"

  echo "  claude-md-size --selftest: ${pass} passaram, ${fail} falharam"
  [ "${fail}" -eq 0 ]
}

REPO="."; FMT="text"; BASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) run_selftest; exit $? ;;
    --format|--base-ref)
      [ $# -ge 2 ] || { echo "claude-md-size-check: $1 exige um valor" >&2; exit 2; }
      if [ "$1" = --format ]; then FMT="$2"; else BASE="$2"; fi; shift 2 ;;
    -*) echo "claude-md-size-check: argumento desconhecido '$1'" >&2; exit 2 ;;
    *) REPO="$1"; shift ;;
  esac
done
run_check "${REPO}" "${FMT}" "${BASE}"
