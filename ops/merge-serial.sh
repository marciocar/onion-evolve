#!/usr/bin/env bash
# =============================================================================
# merge-serial.sh — merge de uma SÉRIE de PRs do core, em ordem, pelo caminho verificado (core-only).
#
# Uso: bash ops/merge-serial.sh <PR> [<PR>...]
#
# ── POR QUE EXISTE (D_MERGE_PROCESS_ONION_2026_10, passo C; nó C_OPCAO_C_MERGE_SERIAL_IN_OPS) ──────
# Duas séries de merge em paralelo mergeiam fora de ordem e derrubam os vizinhos em CONFLICTING (as
# projeções geradas e a bancada são compartilhadas). O serializador existia — mas no SCRATCHPAD da
# sessão, e o provisório tinha três defeitos medidos em 2026-10-13:
#   1. o lock valia para a série INTEIRA, inclusive a espera de CI de ~15 min: com a bancada dentro do
#      lock a vazão cai para ~4 merges/h (E_OBJECAO_LOCK_ONLY_ON_REBASE_AND_MERGE,
#      E_OBJECAO_LOCK_SCOPE_SETS_THROUGHPUT);
#   2. editar o script durante a execução quebrou uma série: o bash lê o arquivo aos pedaços;
#   3. a dispensa do revisor era PREVENTIVA (passava sempre, e repetia sem ela quando era recusada).
# E o provisório que fica no scratchpad volta como incidente (E_OBJECAO_HELPER_LIVES_ONLY_IN_SCRATCHPAD).
#
# ── O DESENHO ────────────────────────────────────────────────────────────────────────────────────
#  · PRÉ-VOO: cada PR da lista tem de ter worktree local da sua branch (é onde o auto-rebase roda).
#    Faltou uma → a série NÃO começa, nomeando o PR e a branch. Sem isso um PR mais novo passaria à
#    frente de um mais antigo que está CONFLICTING sem worktree — a ordem (FIFO) dos argumentos é a
#    ordem dos merges, e um PR que falha PARA a série (os seguintes não passam à frente dele).
#  · CI FORA DO LOCK: espera os check-runs do head do PR nascerem e terminarem (e `gh pr checks` sem
#    pendente), com teto. PR CONFLICTING não tem CI (o GitHub não dispara): vai direto ao lock, onde
#    o auto-rebase o destrava.
#  · LOCK SÓ NO REBASE E NO MERGE: `flock` exclusivo, com teto de espera, em volta da chamada ao
#    `ops/pr-merge-verified.sh` (core-only) — é ELE que rebaseia e mergeia pela API (`gh pr merge`), e o git
#    não rejeita non-fast-forward de merge por API, então o lock tem de envolver essa chamada
#    (E_OBJECAO_FLOCK_MUST_WRAP_API_MERGE). O fd do lock é FECHADO no filho (`9>&-`): um neto que
#    sobrevivesse (daemon do git, processo órfão) seguraria o lock depois de nós.
#  · AUTO-REBASE ⇒ VOLTA À FILA: o verificado roda com --no-wait-after-rebase; se rebaseou, sai rc 4,
#    o lock é solto, o CI do head novo é esperado FORA do lock, e o PR volta ao lock. O limite de
#    rebases (ONION_MERGE_REBASE_MAX, 2) vale para a série inteira (ONION_MERGE_REBASE_DONE).
#  · DISPENSA SÓ QUANDO O CHECK FALHA E O REVISOR NÃO REVISOU: `--dispensa onion-review-verdict` só é
#    passada se `gh pr checks` mostra o check em `fail` no head E a anotação dele diz "NÃO revisou".
#    Se a anotação diz que ele APONTOU violação, a série PARA: dispensar achado é decisão humana, com
#    motivo próprio, nunca o motivo padrão desta ferramenta. Anotação ilegível também para.
#  · SAÍDA: uma linha por PR com o estado PROVADO (mergedAt lido do forge depois do merge).
#  · O CORPO INTEIRO É UMA FUNÇÃO, chamada na ÚLTIMA linha: o bash lê a função toda antes de rodar,
#    então editar este arquivo no meio de uma série não muda o que a série executa (defeito 2).
#
# ── O QUE ELE NÃO GARANTE (teto declarado) ─────────────────────────────────────────────────────
#  · Duas séries rodam juntas na espera de CI; só o trecho rebase+merge é exclusivo. Entre séries a
#    ordem é a de chegada ao lock (o flock não é fila justa): um PR de outra série pode entrar entre
#    dois PRs desta — o efeito é um rebase a mais, nunca um merge sem os gates.
#  · `ops/pr-merge-verified.sh` (core-only) chamado DIRETO (fora desta ferramenta) não toma o lock.
#  · O helper antigo do scratchpad usava OUTRO arquivo de lock: as duas ferramentas não se excluem.
#
# Ambiente (todos com default):
#   (o lock é <git-common-dir>/onion-merge-serial.lock, fixo de propósito: sem knob que tire uma série dele)
#   ONION_MERGE_SERIAL_LOCK_WAIT     teto de espera pelo lock, s (1800)
#   ONION_MERGE_SERIAL_CI_WAIT       teto de espera pelo CI de um head, s (2700)
#   ONION_MERGE_SERIAL_POLL          intervalo de leitura do CI, s (60)
#   ONION_MERGE_SERIAL_ROUNDS        rodadas por PR (CI → lock → verificado) antes de desistir (6)
#   ONION_MERGE_SERIAL_MERGE_TIMEOUT teto da chamada ao verificado dentro do lock, s (1200)
#   ONION_MERGE_REBASE_MAX           rebases automáticos por PR na série inteira (2)
# =============================================================================
set -uo pipefail

main() {
  local _here _verified
  _here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # o verificado é o IRMÃO deste arquivo — nunca o da worktree do PR (o PR pode estar mudando o próprio
  # verificado, e mergear com o código que se está revisando é mergear sem gate). Não há variável que
  # troque esse caminho: um knob desses seria um desvio do veto do hook de merge.
  _verified="${_here}/pr-merge-verified.sh"

  say() { printf '  %s\n' "$*"; }
  die() { printf '✗ merge-serial: %s\n' "$*"; exit 1; }

  case "${1:-}" in
    ''|-h|--help) sed -n '/^# Uso:/p;/^# ── O DESENHO/,/^# Ambiente/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; [ -n "${1:-}" ]; exit $? ;;
  esac
  [ -f "${_verified}" ] || die "não achei ${_verified} — sem o caminho verificado não há merge"
  command -v flock >/dev/null 2>&1 || die "flock ausente (util-linux) — sem lock duas séries mergeiam juntas; não começo"
  command -v gh >/dev/null 2>&1 || die "gh ausente — não leio o forge, logo não mergeio"

  local _lock_wait="${ONION_MERGE_SERIAL_LOCK_WAIT:-1800}" _ci_wait="${ONION_MERGE_SERIAL_CI_WAIT:-2700}"
  local _poll="${ONION_MERGE_SERIAL_POLL:-60}" _rounds_max="${ONION_MERGE_SERIAL_ROUNDS:-6}"
  local _merge_to="${ONION_MERGE_SERIAL_MERGE_TIMEOUT:-1200}" _rebase_max="${ONION_MERGE_REBASE_MAX:-2}"
  local _v; for _v in "${_lock_wait}" "${_ci_wait}" "${_poll}" "${_rounds_max}" "${_merge_to}" "${_rebase_max}"; do
    case "${_v}" in ''|*[!0-9]*) die "parâmetro de ambiente não inteiro: '${_v}'" ;; esac
  done

  # o lock mora no git-common-dir: é o MESMO para todas as worktrees do repo, e só delas. Sem variável que
  # o troque — apontar outra série para outro arquivo seria tirá-la da serialização sem ninguém ver.
  local _lock _gcd
  _gcd="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" \
    || die "não estou dentro de um repositório git — o lock mora no git-common-dir do repo"
  _lock="${_gcd}/onion-merge-serial.lock"

  # ── argumentos: inteiros, sem repetição, na ordem dada ──
  local -a PRS=(); local _a _p
  for _a in "$@"; do
    case "${_a}" in ''|*[!0-9]*) die "argumento '${_a}' não é número de PR (uso: ops/merge-serial.sh <PR> [<PR>...])" ;; esac
    for _p in "${PRS[@]:-}"; do [ "${_p}" = "${_a}" ] && die "PR #${_a} repetido na lista — a ordem ficaria ambígua"; done
    PRS+=("${_a}")
  done

  # ── PRÉ-VOO: estado e worktree de TODOS, antes de qualquer merge (FIFO) ──
  local -A WT=() SKIP=()
  local _st _br _mg _ma _wt
  for _p in "${PRS[@]}"; do
    _st="$(gh pr view "${_p}" --json state,headRefName,mergeable,mergedAt \
           --jq '.state + "\t" + .headRefName + "\t" + .mergeable + "\t" + (.mergedAt // "null")' 2>/dev/null)"
    [ -n "${_st}" ] || die "não consegui LER o PR #${_p} no forge — a série não começa"
    IFS=$'\t' read -r _st _br _mg _ma <<< "${_st}"
    case "${_st}" in
      MERGED) SKIP[${_p}]="${_ma}"; continue ;;
      OPEN) ;;
      *) die "PR #${_p} está ${_st} — não mergeio PR fechado; tire-o da lista" ;;
    esac
    _wt="$(git worktree list --porcelain 2>/dev/null \
           | awk -v b="branch refs/heads/${_br}" '/^worktree /{w=substr($0,10)} $0==b{print w; exit}')"
    [ -n "${_wt}" ] || die "PR #${_p} (branch '${_br}', mergeable=${_mg}) não tem worktree local — é nela que o auto-rebase roda. A série NÃO começa: nenhum PR seguinte passa à frente deste. Crie a worktree (git worktree add <dir> ${_br}) ou tire o PR da lista."
    WT[${_p}]="${_wt}"
  done

  local _slug
  _slug="$(gh pr view "${PRS[0]}" --json headRepositoryOwner,headRepository \
           --jq '.headRepositoryOwner.login + "/" + .headRepository.name' 2>/dev/null)"
  [ -n "${_slug}" ] && [ "${_slug}" != "/" ] || die "não consegui ler owner/repo do PR #${PRS[0]}"

  # ── espera do CI de UM head, FORA do lock. rc 0 pronto · 2 CONFLICTING (sem CI) · 1 teto vencido ──
  _wait_ci() {
    local _pr="$1" _t0 _hm _head _mgb _runs _chk
    _t0="$(date +%s)"
    while :; do
      _hm="$(gh pr view "${_pr}" --json headRefOid,mergeable --jq '.headRefOid + " " + .mergeable' 2>/dev/null)"
      _head="${_hm%% *}"; _mgb="${_hm#* }"
      if [ -n "${_head}" ]; then
        [ "${_mgb}" = CONFLICTING ] && return 2
        _runs="$(gh api "repos/${_slug}/commits/${_head}/check-runs?per_page=100" --jq '.check_runs[] | .status' 2>/dev/null)"
        if [ -n "${_runs}" ] && ! grep -qvx completed <<< "${_runs}"; then
          _chk="$(gh pr checks "${_pr}" 2>/dev/null)"
          if [ -n "${_chk}" ] && ! awk -F'\t' '$2=="pending"{f=1} END{exit !f}' <<< "${_chk}"; then
            return 0
          fi
        fi
      fi
      if [ $(( $(date +%s) - _t0 )) -ge "${_ci_wait}" ]; then
        say "teto de ${_ci_wait}s vencido esperando o CI do PR #${_pr} (head ${_head:0:8})"
        return 1
      fi
      sleep "${_poll}"
    done
  }

  # ── a dispensa: SÓ com o check falhando no head e o revisor dizendo que NÃO revisou ──
  # imprime o motivo (ou vazio = sem dispensa); rc 1 = a série tem de parar (achado ou ilegível)
  _dispensa_motivo() {
    local _pr="$1" _chk _vst _head _ids _id _ann=""
    _chk="$(gh pr checks "${_pr}" 2>/dev/null)"
    _vst="$(awk -F'\t' '$1=="onion-review-verdict"{print $2; exit}' <<< "${_chk}")"
    [ "${_vst}" = fail ] || return 0
    _head="$(gh pr view "${_pr}" --json headRefOid --jq '.headRefOid' 2>/dev/null)"
    # TODAS as runs do check neste head (re-run gera outra): um "apontou" em qualquer uma delas basta para parar
    _ids="$(gh api "repos/${_slug}/commits/${_head}/check-runs?per_page=100" \
           --jq '.check_runs[] | select(.name=="onion-review-verdict") | .id' 2>/dev/null)"
    for _id in ${_ids}; do
      _ann="${_ann}$(gh api "repos/${_slug}/check-runs/${_id}/annotations" --jq '.[].message' 2>/dev/null)"$'\n'
    done
    if LC_ALL=C grep -qE 'apontou [1-9]' <<< "${_ann}"; then
      echo "o onion-review-verdict APONTOU violação no head ${_head:0:8} — dispensar achado é decisão humana com motivo próprio: bash ops/pr-merge-verified.sh ${_pr} --dispensa onion-review-verdict --motivo \"<por que o achado não procede>\""
      return 1
    fi
    if ! LC_ALL=C grep -qF 'NÃO revisou' <<< "${_ann}"; then
      echo "o onion-review-verdict falhou no head ${_head:0:8} e eu não consegui LER a anotação que diz por quê — não dispenso o que não sei; decida à mão"
      return 1
    fi
    printf 'revisor do CI NÃO revisou o head %s (%s) — dispensa nomeada por ops/merge-serial.sh; demais checks verdes\n' \
      "${_head:0:8}" "$(LC_ALL=C grep -m1 -F 'NÃO revisou' <<< "${_ann}" | cut -c1-160)"
  }

  exec 9>>"${_lock}" || die "não consegui abrir o arquivo do lock ${_lock}"

  local _pr _round _rebases _rc _out _mot _final _ok=0
  local -a _ARGS
  for _pr in "${PRS[@]}"; do
    if [ -n "${SKIP[${_pr}]:-}" ]; then
      printf '#%s já estava MERGED antes desta série (mergedAt=%s) — não é merge deste run\n' "${_pr}" "${SKIP[${_pr}]}"
      continue
    fi
    _rebases=0; _round=0; _rc=1
    while :; do
      _round=$((_round+1))
      [ "${_round}" -le "${_rounds_max}" ] \
        || { printf '#%s NÃO mergeou — %s rodadas sem fechar (CI/rebase); a série PARA aqui\n' "${_pr}" "${_rounds_max}"; return 1; }
      say "#${_pr} rodada ${_round}: esperando o CI do head (fora do lock)"
      _wait_ci "${_pr}"; _rc=$?
      if [ "${_rc}" -eq 1 ]; then
        printf '#%s NÃO mergeou — o CI não terminou em %ss; a série PARA aqui\n' "${_pr}" "${_ci_wait}"; return 1
      fi
      _ARGS=("${_pr}" --no-wait-after-rebase)
      if [ "${_rc}" -eq 2 ]; then
        say "#${_pr} está CONFLICTING (sem CI) — vai ao lock para o auto-rebase"
      else
        # a decisão da dispensa é FORA do lock (são leituras do forge, e gh pendurado não pode segurar o
        # lock). Se o head mudar até o lock, o verificado recusa a dispensa que deixou de valer (preventiva)
        # ou o veredito que passou a falhar — as duas direções param, nenhuma mergeia sem gate.
        _mot="$(_dispensa_motivo "${_pr}")" \
          || { printf '#%s NÃO mergeou — %s; a série PARA aqui\n' "${_pr}" "${_mot}"; return 1; }
        [ -n "${_mot}" ] && { _ARGS+=(--dispensa onion-review-verdict --motivo "${_mot}"); say "#${_pr} dispensa NOMEADA: ${_mot}"; }
      fi

      # ═══ LOCK: só rebase + merge ═══
      if ! flock -w "${_lock_wait}" 9; then
        printf '#%s NÃO mergeou — o lock %s seguiu ocupado por %ss (último dono registrado, pode ser antigo: %s); a série PARA aqui\n' \
          "${_pr}" "${_lock}" "${_lock_wait}" "$(cat "${_lock}.holder" 2>/dev/null || echo '?')"
        return 1
      fi
      printf 'pid=%s pr=#%s desde=%s\n' "$$" "${_pr}" "$(date -u +%FT%TZ)" > "${_lock}.holder" 2>/dev/null || true
      _out="$(cd "${WT[${_pr}]}" && ONION_MERGE_REBASE_DONE="${_rebases}" ONION_MERGE_REBASE_MAX="${_rebase_max}" \
              timeout -k 10 "${_merge_to}" bash "${_verified}" "${_ARGS[@]}" 9>&- 2>&1)"; _rc=$?
      : > "${_lock}.holder" 2>/dev/null; flock -u 9
      # ═══ fim do lock ═══
      printf '%s\n' "${_out}" | sed 's/^/    /'
      case "${_rc}" in
        0) break ;;
        4) _rebases=$((_rebases+1)); say "#${_pr} rebaseado (${_rebases}/${_rebase_max}) — lock solto; o CI do head novo é esperado fora dele"; continue ;;
        124|137) printf '#%s NÃO mergeou (ou não sei) — o verificado passou do teto de %ss; confira o PR no forge; a série PARA aqui\n' "${_pr}" "${_merge_to}"; return 1 ;;
      esac
      # head andou entre a espera e o lock (check novo nasceu): outra rodada, não falha
      if LC_ALL=C grep -qE 'check PENDENTE|ainda não-completo|ZERO check-runs' <<< "${_out}"; then
        say "#${_pr} o head ganhou check pendente entre a espera e o lock — nova rodada"; continue
      fi
      printf '#%s NÃO mergeou — %s; a série PARA aqui\n' "${_pr}" "$(LC_ALL=C grep -E '^✗' <<< "${_out}" | tail -1 | cut -c1-300)"
      return 1
    done
    # prova independente: o estado lido do forge, não o rc
    _final="$(gh pr view "${_pr}" --json state,mergedAt --jq '.state + "|" + (.mergedAt // "null")' 2>/dev/null)"
    case "${_final}" in
      MERGED\|null|MERGED\|) printf '#%s estado inconsistente no forge (%s) — a série PARA aqui\n' "${_pr}" "${_final}"; return 1 ;;
      MERGED\|*) printf '#%s MERGED mergedAt=%s (lido do forge)\n' "${_pr}" "${_final#*|}"; _ok=$((_ok+1)) ;;
      *) printf '#%s o verificado saiu 0 mas o forge diz %s — a série PARA aqui\n' "${_pr}" "${_final:-<ilegível>}"; return 1 ;;
    esac
  done
  say "série concluída: ${_ok} merge(s) deste run, ordem dos argumentos respeitada"
  return 0
}

main "$@"; exit $?
