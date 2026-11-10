#!/usr/bin/env bash
# Lease de carga da máquina compartilhada: transforma a regra de carga da VPS, que era acordo entre as
# sessões (o "lock social" de C_SO_RODIZIO_DE_CPU_E_LOCK_SOCIAL), em mecanismo que qualquer chamador usa.
#
# ── POR QUE EXISTE (medido na noite de 2026-11-05/06) ──────────────────────────────────────────────
# Cada agente escrevia o seu `until [ load -lt 12 ]`, com tetos diferentes; um script de lab esperava por
# 16, sem dizer quando desistia; e o pre-commit de uma forja rodou 192 famílias por 70 min com o load entre
# 13 e 16, porque nada no caminho perguntava pela carga. Houve também espera por `pgrep -f`, que casa o
# próprio shell e nunca libera. Regra repetida à mão em cada sessão é regra que diverge: vira peça única.
#
# Uso:
#   bash ops/load-lease.sh check              rc 0 livre · rc 3 ocupado (load ≥ HIGH) · rc 2 não mediu
#   bash ops/load-lease.sh wait [--max S]     rc 0 liberou · rc 4 teto estourado (diz o load) · rc 2 não mediu
#   bash ops/load-lease.sh run [--max S] -- <cmd…>
#                                             espera a carga E uma das N vagas de PASSO PESADO (flock; N
#                                             derivado da carga, ver load_lease_acquire) e roda <cmd> segurando a vaga; rc = o do <cmd>, ou 4 se o teto estourou
#                                             (pela carga ou pela vaga), sem rodar o <cmd>
#   bash ops/load-lease.sh status             load, PSI, memória, a régua vigente e a sugestão derivada
#   . ops/load-lease.sh                       (sourçado) define load_lease_check/_wait/_acquire/_release
#                                             e load_lease_reexec (porta de admissão do passo pesado direto)
#
# Contrato:
#   · A RÉGUA vem de configuração: ops/load-lease.conf (chave=valor, LIDO, nunca executado) e a variável
#     de ambiente de mesmo nome por cima. Default = os números de hoje (HIGH 15, RESUME 12, teto 1800 s).
#     Mudar a régua é decisão do maestro; `status` imprime a sugestão derivada de nproc e memória, rotulada
#     como sugestão, para ele selar (nó D_SO_LIMITES_DERIVADOS_DO_LEASE_1106).
#   · HISTERESE, como a regra: `wait` libera NA HORA se o load já está abaixo de HIGH; se precisou esperar,
#     só libera abaixo de RESUME. `check` é o instante: < HIGH livre, ≥ HIGH ocupado.
#   · SAÍDA DISTINGUÍVEL: "liberou" (rc 0) e "teto estourado com load N" (rc 4) nunca se confundem; a espera
#     é dita NA HORA e a cada 5 min. Teto estourado nunca segue calado.
#   · O SINAL é o load de 1 min (a régua de hoje). A pressão de CPU do kernel (/proc/pressure/cpu, some
#     avg10) sai junto em toda linha, para a série que decide a troca de sinal existir.
#   · A VAGA DE BANCADA CHEIA é um arquivo de lock por usuário, no MESMO lugar das vagas da bancada
#     (/run/user/<uid>/ se for meu, senão /tmp/…-<uid>): comum a toda worktree e sessão. O fd da vaga NÃO
#     desce ao <cmd> (neto órfão não segura vaga; dono morto por kill -9 solta a vaga com o próprio fd).
#   · ANINHADO: quem já foi admitido exporta ONION_LOAD_LEASE_HELD; um chamador de dentro (o pre-commit que
#     o pr-finalize dispara, uma família da bancada que invoca o hook) não espera de novo nem disputa a vaga
#     que o pai segura (deadlock). A bancada exporta ONION_LOAD_LEASE_HELD=bench para as famílias.
#   · DESLIGADO e DITO: ONION_LOAD_LEASE=off (escape declarado), o runner do CI (GITHUB_ACTIONS=true: um
#     job por runner, a fila é do GitHub) e a plataforma sem /proc/loadavg passam direto, com uma linha
#     dizendo por quê. Fonte que existe e não se lê = rc 2 (falha fechada).
#   · Fontes trocáveis para a bancada: ONION_LOAD_SOURCE (loadavg), ONION_LOAD_PSI_DIR, ONION_LOAD_MEMINFO,
#     ONION_LOAD_LEASE_DIR (diretório da vaga).

_ll_root() { local d; d="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; printf '%s' "${d}"; }
_LL_DIR_SELF="$(_ll_root)"

# lê chave=valor do conf (sem executar) e deixa a variável de ambiente vencer
_ll_conf() {
  local key="$1" def="$2" file="${ONION_LOAD_LEASE_CONF:-${_LL_DIR_SELF}/load-lease.conf}" v=""
  if [ -n "${!key:-}" ]; then printf '%s' "${!key}"; return 0; fi
  if [ -r "${file}" ]; then
    v="$(LC_ALL=C awk -F= -v k="${key}" '$0 !~ /^[[:space:]]*#/ && $1 == k { sub(/^[^=]*=/, ""); gsub(/[[:space:]]/, ""); print; exit }' "${file}")"
  fi
  printf '%s' "${v:-${def}}"
}
_ll_num() { case "$1" in ''|*[!0-9.]*|*.*.*|.) return 1 ;; *) return 0 ;; esac; }

_ll_load_settings() {
  LL_HIGH="$(_ll_conf ONION_LOAD_HIGH 15)"
  LL_RESUME="$(_ll_conf ONION_LOAD_RESUME 12)"
  LL_MAX="$(_ll_conf ONION_LOAD_WAIT_MAX 1800)"
  LL_POLL="$(_ll_conf ONION_LOAD_POLL 20)"
  LL_PSI_HIGH="$(_ll_conf ONION_LOAD_PSI_HIGH '')"
  LL_SLOTS_MAX="$(_ll_conf ONION_LOAD_SLOTS_MAX 4)"
  LL_SLOT_CPUS="$(_ll_conf ONION_LOAD_SLOT_CPUS 2)"
  local bad=""
  if [ -n "${LL_PSI_HIGH}" ]; then _ll_num "${LL_PSI_HIGH}" || bad="ONION_LOAD_PSI_HIGH='${LL_PSI_HIGH}'"; fi
  _ll_num "${LL_HIGH}" || bad="ONION_LOAD_HIGH='${LL_HIGH}'"
  _ll_num "${LL_RESUME}" || bad="${bad:+${bad} }ONION_LOAD_RESUME='${LL_RESUME}'"
  case "${LL_MAX}" in ''|*[!0-9]*) bad="${bad:+${bad} }ONION_LOAD_WAIT_MAX='${LL_MAX}'" ;; esac
  case "${LL_POLL}" in ''|*[!0-9]*|0) bad="${bad:+${bad} }ONION_LOAD_POLL='${LL_POLL}'" ;; esac
  case "${LL_SLOTS_MAX}" in ''|*[!0-9]*|0) bad="${bad:+${bad} }ONION_LOAD_SLOTS_MAX='${LL_SLOTS_MAX}'" ;; esac
  _ll_num "${LL_SLOT_CPUS}" && LC_ALL=C awk -v c="${LL_SLOT_CPUS}" 'BEGIN { exit !(c > 0) }' || bad="${bad:+${bad} }ONION_LOAD_SLOT_CPUS='${LL_SLOT_CPUS}'"
  if [ -n "${bad}" ]; then echo "load-lease: régua inválida (${bad}) — não julgo carga com número que não é número" >&2; return 2; fi
  if LC_ALL=C awk -v r="${LL_RESUME}" -v h="${LL_HIGH}" 'BEGIN { exit !(r > h) }'; then
    echo "load-lease: régua inválida (RESUME ${LL_RESUME} > HIGH ${LL_HIGH}) — a histerese ficaria ao contrário" >&2; return 2
  fi
  return 0
}

# load de 1 min (texto) ou rc 2
_ll_load1() {
  local src="${ONION_LOAD_SOURCE:-/proc/loadavg}" v
  v="$(LC_ALL=C awk 'NR==1 { print $1 }' "${src}" 2>/dev/null)" || v=""
  _ll_num "${v}" || { echo "load-lease: não li o load de ${src} (leu '${v}')" >&2; return 2; }
  printf '%s' "${v}"
}
_ll_psi() {  # cpu some avg10, ou "?"
  local f="${ONION_LOAD_PSI_DIR:-/proc/pressure}/cpu" v
  v="$(LC_ALL=C sed -n '1s/.*avg10=\([0-9.]*\).*/\1/p' "${f}" 2>/dev/null)"
  printf '%s' "${v:-?}"
}
_ll_ge() { LC_ALL=C awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'; }
_ll_lt() { LC_ALL=C awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'; }
# PSI como 2º sinal é OPCIONAL (ONION_LOAD_PSI_HIGH vazio = desligado, o default de hoje). Ligado, ocupa
# também com psi ≥ PSI_HIGH e só retoma com psi abaixo dele. PSI ilegível com o sinal ligado = ocupado
# (falha fechada: o maestro ligou o sinal para ele ser julgado).
_ll_psi_busy() {
  [ -n "${LL_PSI_HIGH:-}" ] || return 1
  local v; v="$(_ll_psi)"
  [ "${v}" = "?" ] && return 0
  _ll_ge "${v}" "${LL_PSI_HIGH}"
}

# rc 0 = passa direto (desligado, CI, aninhado), dizendo por quê; rc 1 = o lease julga
_ll_bypass() {
  if [ "${ONION_LOAD_LEASE:-on}" = "off" ]; then echo "load-lease: DESLIGADO por ONION_LOAD_LEASE=off (escape declarado; a carga não foi julgada)" >&2; return 0; fi
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then echo "load-lease: runner do CI (GITHUB_ACTIONS=true) — um job por runner, a carga não é julgada aqui" >&2; return 0; fi
  # Plataforma SEM a fonte (macOS, BSD: não há /proc/loadavg) não tem o que medir: passa e diz. Fonte que
  # EXISTE e não se lê (ou lê lixo) segue rc 2, falha fechada: ali a régua deveria valer e não pôde.
  if [ ! -e "${ONION_LOAD_SOURCE:-/proc/loadavg}" ]; then echo "load-lease: sem fonte de carga (${ONION_LOAD_SOURCE:-/proc/loadavg} não existe nesta plataforma) — a carga não é julgada aqui" >&2; return 0; fi
  if [ -n "${ONION_LOAD_LEASE_HELD:-}" ]; then echo "load-lease: aninhado (admitido por ${ONION_LOAD_LEASE_HELD}) — não espero de novo" >&2; return 0; fi
  return 1
}

load_lease_check() {
  _ll_load_settings || return 2
  _ll_bypass && return 0
  local l; l="$(_ll_load1)" || return 2
  if _ll_ge "${l}" "${LL_HIGH}"; then
    echo "load-lease: OCUPADO — load ${l} ≥ ${LL_HIGH} (psi cpu $(_ll_psi)%); não abra trabalho pesado novo" >&2; return 3
  fi
  if _ll_psi_busy; then
    echo "load-lease: OCUPADO — psi cpu $(_ll_psi)% ≥ ${LL_PSI_HIGH} (load ${l}); não abra trabalho pesado novo" >&2; return 3
  fi
  echo "load-lease: livre — load ${l} < ${LL_HIGH} (psi cpu $(_ll_psi)%)" >&2; return 0
}

# load_lease_wait [teto em s] → rc 0 liberou · 4 teto estourado · 2 não mediu
load_lease_wait() {
  _ll_load_settings || return 2
  local max="${1:-${LL_MAX}}"
  case "${max}" in ''|*[!0-9]*) echo "load-lease: teto '${max}' não é inteiro de segundos" >&2; return 2 ;; esac
  _ll_bypass && return 0
  local l t0=${SECONDS} el last=0
  l="$(_ll_load1)" || return 2
  if _ll_lt "${l}" "${LL_HIGH}" && ! _ll_psi_busy; then
    echo "load-lease: liberou — load ${l} < ${LL_HIGH} na chegada (psi cpu $(_ll_psi)%)" >&2; return 0
  fi
  echo "load-lease: ⏳ ocupado (load ${l}, régua ${LL_HIGH}${LL_PSI_HIGH:+; psi ${LL_PSI_HIGH}}) — espero cair abaixo de ${LL_RESUME} (teto ${max}s, sondagem ${LL_POLL}s; psi cpu $(_ll_psi)%)" >&2
  while :; do
    el=$(( SECONDS - t0 ))
    if [ "${el}" -ge "${max}" ]; then
      echo "load-lease: TETO ESTOURADO com load ${l} após ${el}s (régua: abaixo de ${LL_RESUME}; psi cpu $(_ll_psi)%) — o trabalho pesado NÃO foi liberado" >&2
      return 4
    fi
    sleep "$(( LL_POLL < max - el ? LL_POLL : (max - el > 0 ? max - el : 1) ))"
    l="$(_ll_load1)" || return 2
    if _ll_lt "${l}" "${LL_RESUME}" && ! _ll_psi_busy; then
      echo "load-lease: liberou — load ${l} < ${LL_RESUME} após $(( SECONDS - t0 ))s de espera (psi cpu $(_ll_psi)%)" >&2; return 0
    fi
    el=$(( SECONDS - t0 ))
    if [ $(( el - last )) -ge 300 ]; then last=${el}; echo "load-lease: ⏳ ainda load ${l} após ${el}s (teto ${max}s)" >&2; fi
  done
}

_ll_lockdir() {
  local uid; uid="$(id -u 2>/dev/null || echo x)"
  if [ -n "${ONION_LOAD_LEASE_DIR:-}" ]; then printf '%s' "${ONION_LOAD_LEASE_DIR}"
  elif [ -d "/run/user/${uid}" ] && [ -O "/run/user/${uid}" ] && [ -w "/run/user/${uid}" ]; then printf '%s' "/run/user/${uid}/onion-load-lease"
  else printf '%s' "/tmp/onion-load-lease-${uid}"; fi
}

LL_FD=""; LL_LOCK=""
# ── VAGAS DE PASSO PESADO: semáforo de N, com N DERIVADO DA CARGA (a batuta, 2026-11-10) ───────────────────────
# Medido às 13:35 UTC de 2026-11-10: com UMA vaga, a fila tinha 4 passos pesados (mutantes, pr-finalize, lint,
# revisor) esperando um ao outro com o load em 3,5 numa máquina de 8 CPUs — o mutex serializava o que cabia
# junto. Agora há N vagas (arquivos slot.<i>.lock, um flock cada), e N se mede A CADA tentativa:
#   N = piso((RESUME − load1) / ONION_LOAD_SLOT_CPUS), entre 1 e ONION_LOAD_SLOTS_MAX
# A folga é medida até a RÉGUA SELADA (abaixo de RESUME a máquina está livre, D_SO_LIMITES_DERIVADOS_DO_LEASE_1106),
# não até nproc: a 1ª versão usava nproc, e o dogfood real deu N=1 já com load 5,3 em 8 CPUs, serializando de novo
# o que a régua do maestro chama de livre. Com carga baixa entram vários juntos; perto de RESUME, N cai a 1; com a carga na régua (load ≥ HIGH
# ou psi ≥ PSI_HIGH) NENHUM novo entra, quantas vagas houver livres: a admissão por carga vem antes da vaga, e é
# re-julgada enquanto se espera vaga. É a forma de mercado da admissão por recurso (`parallel --load`, os slots por
# recurso do Temporal). Quem já entrou não sai se N encolher: a vaga é de admissão, não de preempção.
_ll_slots() {  # $1 = load1 → N
  LC_ALL=C awk -v n="${LL_RESUME}" -v l="$1" -v c="${LL_SLOT_CPUS}" -v m="${LL_SLOTS_MAX}" \
    'BEGIN { k = int((n - l) / c); if (k < 1) k = 1; if (k > m) k = m; print k }'
}
_ll_holders() {  # quem segura as vagas, numa linha
  local d="$1" f out=""
  for f in "${d}"/slot.*.holder; do [ -s "${f}" ] && out="${out:+${out} | }$(basename "${f}" .holder): $(cat "${f}")"; done
  printf '%s' "${out:-nenhum dono registrado}"
}
# load_lease_acquire [teto] → rc 0 com a vaga em LL_FD (exporta ONION_LOAD_LEASE_HELD) · 4 teto · 2 erro
# Só serve SOURÇADO: a vaga vive enquanto o shell que a pegou viver (é fd, não arquivo).
load_lease_acquire() {
  _ll_load_settings || return 2
  local max="${1:-${LL_MAX}}" t0=${SECONDS} rc d l k i fd said=0 left
  case "${max}" in ''|*[!0-9]*) echo "load-lease: teto '${max}' não é inteiro de segundos" >&2; return 2 ;; esac
  _ll_bypass && return 0
  command -v flock >/dev/null 2>&1 || { echo "load-lease: flock ausente (util-linux) — não há vaga para dar" >&2; return 2; }
  d="$(_ll_lockdir)"
  if [ ! -d "${d}" ]; then ( umask 077; mkdir -p "${d}" ) 2>/dev/null || { echo "load-lease: não criei ${d}" >&2; return 2; }; fi
  if [ -L "${d}" ] || [ ! -O "${d}" ] || [ -n "$(find "${d}" -maxdepth 0 -perm /022 2>/dev/null)" ]; then
    echo "load-lease: ${d} é link, não é meu ou aceita escrita de outros — recuso usar como vaga" >&2; return 2
  fi
  load_lease_wait "${max}"; rc=$?; [ "${rc}" = 0 ] || return "${rc}"
  while :; do
    l="$(_ll_load1)" || return 2
    # a carga voltou à régua enquanto eu esperava vaga: nenhum novo entra; volto a esperar a CARGA no teto que resta
    if _ll_ge "${l}" "${LL_HIGH}" || _ll_psi_busy; then
      left=$(( max - (SECONDS - t0) )); [ "${left}" -gt 0 ] || left=0
      load_lease_wait "${left}"; rc=$?; [ "${rc}" = 0 ] || return "${rc}"
      continue
    fi
    k="$(_ll_slots "${l}")"
    for (( i = 0; i < k; i++ )); do
      exec {fd}>>"${d}/slot.${i}.lock" || { echo "load-lease: não abri ${d}/slot.${i}.lock" >&2; return 2; }
      if flock -n "${fd}"; then
        LL_FD="${fd}"; LL_LOCK="${d}/slot.${i}.lock"
        printf 'pid %s · %s · desde %s\n' "$$" "${ONION_LOAD_LEASE_WHO:-${0##*/}}" "$(date -u +%FT%TZ)" > "${d}/slot.${i}.holder" 2>/dev/null || true
        export ONION_LOAD_LEASE_HELD="${LL_LOCK}"
        echo "load-lease: vaga de passo pesado PEGA ($(( i + 1 )) de ${k}: N derivado de load ${l}; ${LL_LOCK})" >&2
        return 0
      fi
      exec {fd}>&-
    done
    if [ "$(( SECONDS - t0 ))" -ge "${max}" ]; then
      echo "load-lease: TETO ESTOURADO esperando vaga de passo pesado (as ${k} vagas de load ${l} ocupadas: $(_ll_holders "${d}")) após $(( SECONDS - t0 ))s — NÃO rodei" >&2
      return 4
    fi
    if [ "${said}" = 0 ]; then said=1
      echo "load-lease: ⏳ vagas de passo pesado OCUPADAS (${k} de load ${l}: $(_ll_holders "${d}")) — espero (teto $(( max - (SECONDS - t0) ))s)" >&2
    fi
    # a vaga se sonda a cada 2 s no máximo: o dogfood real esperou 20 s a mais (a sondagem da CARGA) depois de a vaga soltar
    sleep "$(( LL_POLL < 2 ? LL_POLL : 2 ))"
  done
}
load_lease_release() {
  [ -n "${LL_FD}" ] || return 0
  : > "${LL_LOCK%.lock}.holder" 2>/dev/null || true
  flock -u "${LL_FD}" 2>/dev/null || true
  exec {LL_FD}>&-
  LL_FD=""; unset ONION_LOAD_LEASE_HELD
}

# load_lease_reexec <quem> <script> [args…] — PORTA DE ADMISSÃO do passo pesado chamado DIRETO (a batuta, 2026-11-10).
# Medido em 2026-11-10: três agentes rodaram bancada (`lint-selftest.sh --only …`) e mutantes
# (`ops/mutate-and-restore.sh`) juntos, chamados à mão, e a carga foi a 16–19. Nenhum dos dois passava pelo
# lease: a bancada se marcava "já admitida" (ONION_LOAD_LEASE_HELD=bench) supondo que quem a chama esperou
# antes, e o harness de mutantes não perguntava nada. A cura improvisada foi um `flock` num arquivo do
# scratchpad mais "esperar a carga cair": a mesma regra repetida à mão, que diverge.
# Chamada no topo do script pesado, ela o RE-EXECUTA sob `run` (espera a carga E uma das N vagas de passo
# pesado da máquina) e não volta; já admitido (o pai segura a vaga: pre-commit, pr-finalize, a própria
# bancada), ela volta 0 e o script segue no mesmo processo. ONION_LOAD_LEASE_REEXEC é a GUARDA DO LAÇO:
# quando o lease passa direto (desligado, CI, sem fonte) o `run` não exporta HELD, e sem a guarda o
# script se re-executaria para sempre.
load_lease_reexec() {
  local who="${1:-?}"; shift || true
  [ -n "${ONION_LOAD_LEASE_HELD:-}" ] && return 0
  [ -n "${ONION_LOAD_LEASE_REEXEC:-}" ] && return 0
  [ "$#" -ge 1 ] || { echo "load-lease: reexec sem script" >&2; return 2; }
  export ONION_LOAD_LEASE_REEXEC=1 ONION_LOAD_LEASE_WHO="${who}"
  exec bash "${BASH_SOURCE[0]}" run -- bash "$@"   # o PRÓPRIO arquivo do lease (a cópia da bancada também)
}

load_lease_status() {
  _ll_load_settings || return 2
  local n l psi memav memtot lab_gb="${ONION_LOAD_LAB_GB:-1}" reserve_gb="${ONION_LOAD_MEM_RESERVE_GB:-4}" mi="${ONION_LOAD_MEMINFO:-/proc/meminfo}"
  n="$(nproc 2>/dev/null || echo 1)"
  l="$(_ll_load1 2>/dev/null || echo '?')"; psi="$(_ll_psi)"
  memav="$(LC_ALL=C awk '/^MemAvailable:/ { printf "%d", $2/1024 }' "${mi}" 2>/dev/null)"
  memtot="$(LC_ALL=C awk '/^MemTotal:/ { printf "%d", $2/1024 }' "${mi}" 2>/dev/null)"
  echo "load-lease status"
  echo "  medido agora : load1 ${l} · psi cpu some avg10 ${psi}% · nproc ${n} · memória disponível ${memav:-?} MB de ${memtot:-?} MB"
  echo "  régua VIGENTE: HIGH ${LL_HIGH} · RESUME ${LL_RESUME} · psi ${LL_PSI_HIGH:-desligado} · teto ${LL_MAX}s (ops/load-lease.conf; o ambiente vence)"
  # SUGESTÃO, não vigente: load ≥ nproc já é fila; a régua derivada põe a retomada em nproc e o
  # bloqueio em 1,5×nproc, mais o PSI ≥ 30 como 2º sinal. Medida que a sustenta (sysstat, 878 intervalos
  # de 10 min, 2026-10-30 a 11-06): o PSI do instante prevê a espera por CPU dos 10 min seguintes melhor
  # que o load (correlação 0,83 contra 0,68), e o HIGH 15 de hoje pegou só 6 dos 15 intervalos
  # congestionados (≥ 40% do tempo com tarefa esperando CPU) contra 13 do load ≥ 12 e 13 do psi ≥ 30. Manter
  # 15/12 e LIGAR o psi 30 pega os mesmos 13 com menos alarme falso (22 contra 27 do load 12 com psi 30).
  # Série e script: docs/evolution/research/session-orchestration-2026-11/data/psi-vs-load*.
  # A memória dá um teto próprio de labs simultâneos (lab ≈ ${lab_gb} GB, reserva ${reserve_gb} GB).
  # Quem sela a troca é o maestro (D_SO_LIMITES_DERIVADOS_DO_LEASE_1106).
  local sh sr labs
  sr="${n}"; sh=$(( n + n / 2 ))
  labs="?"
  if [ -n "${memav}" ]; then labs=$(( (memav / 1024 - reserve_gb) / lab_gb )); [ "${labs}" -ge 0 ] || labs=0; fi
  echo "  SUGESTÃO (não vigente; decisão do maestro):"
  echo "    · medida: manter HIGH ${LL_HIGH}/RESUME ${LL_RESUME} e ligar ONION_LOAD_PSI_HIGH=30 (2º sinal do kernel)"
  echo "    · derivada de nproc: HIGH ${sh} (1,5×nproc) · RESUME ${sr} (nproc)"
  echo "    · derivada da memória: labs simultâneos ≤ ${labs} (disponível − ${reserve_gb} GB, ${lab_gb} GB cada)"
  local d; d="$(_ll_lockdir)"
  local k; k="$(_ll_slots "${l}" 2>/dev/null || echo '?')"
  echo "  vagas de passo pesado: ${k} agora (piso((RESUME ${LL_RESUME} − load) / ${LL_SLOT_CPUS}), entre 1 e ${LL_SLOTS_MAX}) · donos: $(_ll_holders "${d}")"
  return 0
}

# ── execução direta ──────────────────────────────────────────────────────────────────────────────
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  set -u
  cmd="${1:-}"; shift || true
  max=""
  if [ "${1:-}" = "--max" ]; then max="${2:-}"; shift 2 || { echo "load-lease: --max sem valor" >&2; exit 2; }; fi
  case "${cmd}" in
    check) load_lease_check; exit $? ;;
    wait)  load_lease_wait ${max:+"${max}"}; exit $? ;;
    status) load_lease_status; exit $? ;;
    run)
      [ "${1:-}" = "--" ] && shift
      [ "$#" -ge 1 ] || { echo "load-lease: run sem comando (uso: run [--max S] -- <cmd…>)" >&2; exit 2; }
      load_lease_acquire ${max:+"${max}"}; rc=$?; [ "${rc}" = 0 ] || exit "${rc}"
      if [ -n "${LL_FD}" ]; then
        "$@" {LL_FD}>&-; rc=$?
      else
        "$@"; rc=$?
      fi
      load_lease_release
      exit "${rc}" ;;
    *) sed -n '12,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
  esac
fi
