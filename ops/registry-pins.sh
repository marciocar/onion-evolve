#!/usr/bin/env bash
# registry-pins.sh — confere (e carimba) o pin de cada ADOTANTE do registro contra o carimbo VIVO dele.
#
# Uso: ops/registry-pins.sh --check|--seal [--members <path>] [--only <id>] [--no-remote]
#      --check     : acusa divergência, NÃO escreve.
#      --seal      : carimba o que diverge E foi lido do REMOTO E é commit da integração do core.
#      --only <id> : um membro só.     --no-remote : não consulta o forge (lê só os clones).
#      rc=0 tudo lido e em dia (ou carimbado) · rc=1 há divergência não carimbada
#      rc=3 nada diverge, mas há membro ILEGÍVEL (declarado) · rc=2 uso/precondição
#
# ══ POR QUE EXISTE (F1.5 das portas, SAC-90, 2026-10-09) ══════════════════════════════════════
# O `onion_version` de um `kind: adopter` no `members.yaml` era mantido À MÃO, e à mão apodrece —
# medido no mesmo dia em dois membros: o brain-granaai estava registrado em 663fdbc5 com o carimbo
# vivo em 1c459812, e o onion-kg-ssot em fe8359e3 depois de um update que o levou a 0d293c07.
# A porta já tinha o `ops/door-seal-pin.sh`; o adotante não tinha equivalente. Este é o molde dele,
# com as diferenças que o objeto pede:
#   · porta é ESPELHO do core e se confere pelo clone + push; adotante é REPO DE OUTRA SESSÃO, e o que
#     vale é o carimbo commitado na branch de INTEGRAÇÃO dele (I3: a sessão dele carimba, o core lê);
#   · por isso a leitura é REMOTO primeiro (`gh api …/contents/.claude/.onion-version?ref=<branch>`)
#     e o clone é só fallback (`git show origin/<branch>:` — sem fetch: este script não escreve em
#     repo alheio, nem em `refs/remotes`). Clone lido pode estar atrasado; o relatório diz a fonte;
#   · `--seal` carimba SÓ o que veio do remoto. Clone desatualizado não vira registro.
#
# ══ A BRANCH DE INTEGRAÇÃO, e de onde ela vem (a ordem é a da confiança) ══════════════════════
#   (1) `integration_branch:` do REGISTRO · (2) `integration_branch:` do carimbo VERSIONADO na branch
#   default do remoto · (3) a própria default do remoto · e só sem remoto: (4) `integration_branch:` do
#   carimbo da árvore do clone · (5) branch corrente do clone. A coluna `branch` do relatório diz qual
#   valeu — quem ler `(5)` sabe que a resposta depende de onde a sessão dele estava parada.
#
# ══ O QUE ELE NÃO FAZ ════════════════════════════════════════════════════════════════════════
# Não lê `lineages:` (pins por linhagem seguem manuais e comentados no registro), não toca porta
# (`kind: door` é do door-seal-pin.sh) nem membro que não vendoriza (`onion_version: n/a`).
# É `ops/` e não REGRA do lint pelo mesmo motivo do door-seal-pin.sh: precisa de rede e de clones
# que o CI não tem, e guarda que só passa na máquina de uma pessoa é armadilha.
set -uo pipefail

MODE=""; MEMBERS=""; ONLY=""; NOREMOTE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check; shift ;;
    --seal)  MODE=seal; shift ;;
    --members) MEMBERS="${2:?--members exige path}"; shift 2 ;;
    --only) ONLY="${2:?--only exige id}"; shift 2 ;;
    --no-remote) NOREMOTE=1; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${MODE}" ] || { echo "uso: registry-pins.sh --check|--seal [--members <path>] [--only <id>] [--no-remote]" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "${HERE}/.." && pwd)"
: "${MEMBERS:=${CORE}/docs/evolution/federation/members.yaml}"
[ -f "${MEMBERS}" ] || { echo "ERRO: registro ausente: ${MEMBERS}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null \
  || { echo "ERRO: python3+PyYAML ausente — não leio o registro com regex (leitor menos fiel que o do members-validate.sh)." >&2; exit 2; }

# A ponta da integração do CORE contra a qual o pin vivo tem de ser ancestral. Sem `origin/main`
# local cai em HEAD — mais estrito nunca, mais frouxo também não: é declarado no cabeçalho do relatório.
CORE_TIP="HEAD"
git -C "${CORE}" rev-parse --verify --quiet "origin/main^{commit}" >/dev/null && CORE_TIP="origin/main"

# id \x1f kind \x1f remote \x1f local_path \x1f onion_version \x1f integration_branch — por YAML de verdade.
ROWS="$(python3 - "${MEMBERS}" "${ONLY}" <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
only = sys.argv[2]
for m in doc.get('members') or []:
    if not isinstance(m, dict): continue
    mid = str(m.get('id') or '').strip()
    if only and mid != only: continue
    f = lambda k: ' '.join(str(m.get(k) or '').split())
    print('\x1f'.join([mid, f('kind'), f('remote'), f('local_path'), f('onion_version'), f('integration_branch')]))
PY
)" || { echo "ERRO: não parseei ${MEMBERS} (YAML inválido é cobrança do members-validate.sh)." >&2; exit 2; }
[ -n "${ROWS}" ] || { echo "ERRO: nenhum membro${ONLY:+ com id '${ONLY}'} em ${MEMBERS}." >&2; exit 2; }

# owner/repo a partir de qualquer forma de URL do GitHub (https, ssh, com " (privado)" anotado).
_owner_repo() {
  printf '%s' "$1" | sed -nE 's#.*github\.com[/:]([^/[:space:]]+)/([^/[:space:]()]+).*#\1/\2#p' | sed -E 's#\.git$##' | head -1
}
_stamp_pin() {  # stdin = carimbo; source_commit vence onion_version (dialeto novo do write-stamp.sh)
  local s; s="$(cat)"; local v
  v="$(printf '%s\n' "${s}" | grep -m1 -E '^source_commit:' | sed -E 's/^source_commit:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')"
  [ -n "${v}" ] || v="$(printf '%s\n' "${s}" | grep -m1 -E '^onion_version:' | sed -E 's/^onion_version:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')"
  printf '%s' "${v}"
}
_same_pin() {  # prefixo comum de no mínimo 7 hex
  local a="${1,,}" b="${2,,}"
  [ "${#a}" -ge 7 ] && [ "${#b}" -ge 7 ] || return 1
  case "${a}" in "${b}"*) return 0 ;; esac
  case "${b}" in "${a}"*) return 0 ;; esac
  return 1
}

TODAY="$(date +%F)"
n_ok=0; n_div=0; n_ill=0; n_sealed=0; n_out=0
SEAL_LIST=""
printf '%-26s %-14s %-14s %-24s %-30s %s\n' "membro" "registro" "vivo" "fonte" "branch" "ação"
while IFS=$'\x1f' read -r mid kind remote lpath regpin ibranch; do
  [ -n "${mid}" ] || continue
  if [ "${kind}" != "adopter" ]; then
    printf '%-26s %-14s %-14s %-24s %-30s %s\n' "${mid}" "${regpin:-—}" "—" "—" "—" "fora (kind ${kind:-?}$([ "${kind}" = door ] && echo ' → ops/door-seal-pin.sh'))"
    n_out=$((n_out + 1)); continue
  fi
  clone=""; [ -n "${lpath}" ] && [ -d "${lpath}/.git" -o -f "${lpath}/.git" ] && clone="${lpath}"
  orep="$(_owner_repo "${remote}")"; orep_src="registro"
  if [ -z "${orep}" ] && [ -n "${clone}" ]; then
    orep="$(_owner_repo "$(git -C "${clone}" remote get-url origin 2>/dev/null || true)")"; orep_src="origin do clone"
  fi

  # ── a branch de integração ──────────────────────────────────────────────────────────────
  # ⚠️ A 1ª versão consultava o carimbo da ÁRVORE do clone antes do remoto, e a passada real a
  #    derrubou no primeiro membro: o clone do metagamify estava parado numa branch de trabalho cujo
  #    carimbo dizia `integration_branch: chore/onion-framework`, e o pin lido lá era ANTERIOR ao do
  #    registro — o --seal teria rebaixado o registro. O carimbo versionado na branch DEFAULT do
  #    remoto diz `develop`. Árvore de clone é onde a outra sessão está, não onde ela integra.
  branch=""; bsrc=""; rdef=""
  if [ -n "${ibranch}" ]; then branch="${ibranch}"; bsrc="(1)registro"; fi
  if [ -z "${branch}" ] && [ -n "${orep}" ] && [ "${NOREMOTE}" -eq 0 ]; then
    rdef="$(gh api "repos/${orep}" --jq '.default_branch' 2>/dev/null || true)"
    if [ -n "${rdef}" ]; then
      branch="$(gh api "repos/${orep}/contents/.claude/.onion-version?ref=${rdef}" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null \
                | awk '/^integration_branch:/{gsub(/\r/,"",$2); print $2; exit}')"
      if [ -n "${branch}" ]; then bsrc="(2)carimbo@${rdef}"; else branch="${rdef}"; bsrc="(3)default"; fi
    fi
  fi
  if [ -z "${branch}" ] && [ -n "${clone}" ] && [ -f "${clone}/.claude/.onion-version" ]; then
    branch="$(awk '/^integration_branch:/{gsub(/\r/,"",$2); print $2; exit}' "${clone}/.claude/.onion-version")"
    [ -n "${branch}" ] && bsrc="(4)carimbo-do-clone"
  fi
  if [ -z "${branch}" ] && [ -n "${clone}" ]; then
    branch="$(git -C "${clone}" branch --show-current 2>/dev/null || true)"; [ -n "${branch}" ] && bsrc="(5)branch-do-clone"
  fi

  # ── o carimbo VIVO: remoto primeiro, clone depois ───────────────────────────────────────
  live=""; src=""; why=""
  if [ -n "${orep}" ] && [ -n "${branch}" ] && [ "${NOREMOTE}" -eq 0 ]; then
    _st="$(gh api "repos/${orep}/contents/.claude/.onion-version?ref=${branch}" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)"
    if [ -n "${_st}" ]; then live="$(printf '%s\n' "${_st}" | _stamp_pin)"; src="remoto"; else why="remoto ilegível (${orep}@${branch})"; fi
  elif [ -z "${orep}" ]; then why="sem remoto no registro nem no clone"
  elif [ "${NOREMOTE}" -eq 1 ]; then why="--no-remote"
  else why="branch de integração não resolvida"; fi
  if [ -z "${live}" ] && [ -n "${clone}" ] && [ -n "${branch}" ]; then
    _ref=""
    if git -C "${clone}" rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null; then _ref="origin/${branch}"; src="clone(origin/${branch})"
    elif ! git -C "${clone}" remote | grep -q .; then _ref="${branch}"; src="clone-local(sem remoto)"; fi
    if [ -n "${_ref}" ]; then
      live="$(git -C "${clone}" show "${_ref}:.claude/.onion-version" 2>/dev/null | _stamp_pin)"
      [ -n "${live}" ] || { src=""; why="${why:+${why}; }carimbo ausente em ${_ref}"; }
    else why="${why:+${why}; }clone sem origin/${branch}"; fi
  elif [ -z "${live}" ] && [ -z "${clone}" ]; then
    why="${why:+${why}; }sem clone"
  fi

  if [ -z "${live}" ] || ! printf '%s' "${live}" | grep -qE '^[0-9a-fA-F]{7,40}$'; then
    [ -n "${live}" ] && why="pin ilegível no carimbo: '${live}'"
    printf '%-26s %-14s %-14s %-24s %-30s %s\n' "${mid}" "${regpin:-—}" "?" "—" "${branch:-?} ${bsrc}" "ILEGÍVEL: ${why:-motivo não apurado}"
    n_ill=$((n_ill + 1)); continue
  fi
  live12="${live:0:12}"
  if _same_pin "${regpin}" "${live}"; then
    printf '%-26s %-14s %-14s %-24s %-30s %s\n' "${mid}" "${regpin}" "${live12}" "${src}" "${branch} ${bsrc}" "ok"
    n_ok=$((n_ok + 1)); continue
  fi

  # Diverge. O pin vivo tem de ser commit do core E estar na integração — senão não se carimba.
  verdict="DIVERGE"
  if ! git -C "${CORE}" cat-file -e "${live}^{commit}" 2>/dev/null; then verdict="DIVERGE (pin vivo NÃO é commit deste core)"
  elif ! git -C "${CORE}" merge-base --is-ancestor "${live}" "${CORE_TIP}" 2>/dev/null; then verdict="DIVERGE (pin vivo fora de ${CORE_TIP})"
  # Pin vivo ANTERIOR ao do registro: o adotante não volta no tempo por update; o sinal mais provável é
  # branch errada (o caso do metagamify na 1ª passada). Acusa e não carimba — rebaixar o registro
  # pela leitura de uma branch parada é a mentira na direção oposta.
  elif git -C "${CORE}" cat-file -e "${regpin}^{commit}" 2>/dev/null \
       && git -C "${CORE}" merge-base --is-ancestor "${live}" "${regpin}" 2>/dev/null; then verdict="DIVERGE (vivo ATRÁS do registro — branch de integração errada?)"
  elif [ "${src}" != "remoto" ]; then verdict="DIVERGE (lido do ${src}: --seal só carimba o remoto)"
  else SEAL_LIST="${SEAL_LIST}${mid} ${live12} ${branch}"$'\n'; fi
  printf '%-26s %-14s %-14s %-24s %-30s %s\n' "${mid}" "${regpin:-—}" "${live12}" "${src}" "${branch} ${bsrc}" "${verdict}"
  n_div=$((n_div + 1))
done <<< "${ROWS}"

echo "── ${n_ok} em dia · ${n_div} divergente(s) · ${n_ill} ilegível(is) · ${n_out} fora do escopo (ponta do core: ${CORE_TIP})"
[ "${n_ill}" -gt 0 ] && echo "   ⚠️ ILEGÍVEL não é 'em dia': o pin desses membros NÃO foi conferido nesta passada." >&2

if [ "${MODE}" = "seal" ] && [ -n "${SEAL_LIST}" ]; then
  TMP="$(mktemp)"; trap 'rm -f "${TMP}"' EXIT
  while read -r sid spin sbranch; do
    [ -n "${sid}" ] || continue
    # CARIMBO CIRÚRGICO — o mesmo awk do door-seal-pin.sh: só a 1ª linha `onion_version:` do bloco
    # do membro; o resto do arquivo (comentários inclusive) sai byte a byte.
    awk -v want="${sid}" -v pin="${spin}" -v note="carimbado por ops/registry-pins.sh (remoto ${sbranch} conferido em ${TODAY})" '
      function clean(s) { sub(/^[^:]*:[[:space:]]*/,"",s); sub(/[[:space:]]*#.*$/,"",s); gsub(/[[:space:]]+$/,"",s); gsub(/"/,"",s); gsub(/\047/,"",s); return s }
      /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { cur=(clean($0)==want) }
      cur && done!=1 && /^[[:space:]]*onion_version:[[:space:]]*/ {
        match($0, /^[[:space:]]*/); ind=substr($0, 1, RLENGTH)
        print ind "onion_version: " pin "   # " note; done=1; next }
      { print }' "${MEMBERS}" > "${TMP}"
    _b="$(wc -l < "${MEMBERS}")"; _a="$(wc -l < "${TMP}")"
    if [ "${_b}" -ne "${_a}" ] || ! grep -qE "^[[:space:]]*onion_version: ${spin} " "${TMP}"; then
      echo "ERRO: o carimbo de '${sid}' não saiu como uma linha só (${_b} → ${_a} linhas) — registro NÃO gravado." >&2; exit 1
    fi
    cat "${TMP}" > "${MEMBERS}"
    echo "✅ carimbado: ${sid} → ${spin} (remoto ${sbranch})"
    n_sealed=$((n_sealed + 1))
  done <<< "${SEAL_LIST}"
  n_div=$((n_div - n_sealed))
fi

[ "${n_div}" -gt 0 ] && exit 1
[ "${n_ill}" -gt 0 ] && exit 3
exit 0
