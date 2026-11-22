#!/usr/bin/env bash
# =============================================================================
# gate-probe-lock.sh — a TRAVA por repositório entre quem prova o gate do alvo (lib, para `source`)
#
# POR QUE EXISTE (SAC-444, medido em 2026-11-22): numa adoção de teste greenfield, o
# `install-onion-githook.sh` (cuja prova de vida, o `verify-adopter-gate.sh`, faz um commit-sonda NO
# checkout real e o desfaz com `reset --soft`) rodou ao mesmo tempo que o `prove-gate-blocks.sh` (que
# fotografa HEAD, branch, status e config do alvo no começo e exige a mesma foto no fim). Sozinhos, os
# dois deram rc 0 (o prove com bloqueio PROVADO). Juntos, o prove imprimiu "bloqueio PROVADO" e saiu
# rc 4 INTEGRIDADE: a sonda do outro mudou HEAD e status no meio da foto. A prova era boa; o veredito
# saiu falso porque dois provadores dividiram o mesmo checkout.
#
# O QUE FAZ: `onion_gate_probe_lock <alvo>` pega uma trava EXCLUSIVA no git-dir COMUM do alvo
# (`<common>/onion-gate-probe.lock`, nunca rastreável, fora do status que a foto lê; comum porque o
# `config --local` que a foto lê é do repositório, não da worktree). Quem chega com a trava tomada
# espera, dizendo, até `ONION_GATE_PROBE_LOCK_WAIT` segundos (default 1800). `onion_gate_probe_unlock`
# solta (só necessário no caminho sem flock; com flock a trava morre com o processo).
#   · com `flock` (util-linux): fd 9 no arquivo da trava;
#   · sem `flock` (macOS): `mkdir` atômico de `<lock>.d` com o pid dentro; trava cujo pid morreu é
#     retomada (o dono caiu sem soltar).
# NÃO é a porta de admissão de carga (ops/load-lease.sh, core-only): aquela limita QUANTOS passos pesados
# rodam na máquina; esta impede que DOIS provadores mexam no MESMO repositório. Uma não substitui a outra.
#
# RC de onion_gate_probe_lock: 0 trava pega (ou alvo sem git-dir resolvível: nada a serializar)
#                              1 esperou o teto e a trava seguiu tomada (quem chama declara NÃO MEDIDO)
# Exercitado por lint-selftest.sh (run_prove_gate_blocks_selftests, caso da corrida).
# =============================================================================

_ONION_GPL_DIR=""

onion_gate_probe_lock() {
  local t="${1:-.}" w="${ONION_GATE_PROBE_LOCK_WAIT:-1800}" g lk pid i
  g="$(git -C "${t}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  [ -d "${g}" ] || return 0
  lk="${g}/onion-gate-probe.lock"
  if command -v flock >/dev/null 2>&1; then
    exec 9>>"${lk}" || return 0
    flock -n 9 && return 0
    echo "· outra prova do gate segura ${lk}: esperando até ${w}s (provas no mesmo repositório não rodam juntas)" >&2
    flock -w "${w}" 9 && return 0
    return 1
  fi
  i=0
  while ! mkdir "${lk}.d" 2>/dev/null; do
    pid="$(cat "${lk}.d/pid" 2>/dev/null)" || pid=""
    if [ -n "${pid}" ] && ! kill -0 "${pid}" 2>/dev/null; then
      rm -f "${lk}.d/pid" 2>/dev/null; rmdir "${lk}.d" 2>/dev/null; continue
    fi
    [ "${i}" -eq 0 ] && echo "· outra prova do gate segura ${lk}.d: esperando até ${w}s (provas no mesmo repositório não rodam juntas)" >&2
    i=$((i + 1)); [ "${i}" -ge "${w}" ] && return 1
    sleep 1
  done
  printf '%s\n' "$$" > "${lk}.d/pid" 2>/dev/null
  _ONION_GPL_DIR="${lk}.d"
  return 0
}

onion_gate_probe_unlock() {
  [ -n "${_ONION_GPL_DIR}" ] || return 0
  rm -f "${_ONION_GPL_DIR}/pid" 2>/dev/null; rmdir "${_ONION_GPL_DIR}" 2>/dev/null; _ONION_GPL_DIR=""
}
