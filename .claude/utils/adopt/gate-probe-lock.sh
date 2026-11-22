#!/usr/bin/env bash
# =============================================================================
# gate-probe-lock.sh — a TRAVA por repositório entre quem prova o gate do alvo (lib, para `source`)
#
# POR QUE EXISTE (SAC-444, medido em 2026-11-22): numa adoção de teste greenfield, o
# `install-onion-githook.sh` (cuja prova de vida faz um commit-sonda NO checkout real e o desfaz com
# `reset --soft`) rodou ao mesmo tempo que o `prove-gate-blocks.sh` (que fotografa HEAD, branch, status e
# config do alvo no começo e exige a mesma foto no fim). Sozinhos, os dois deram rc 0 (a prova com
# bloqueio PROVADO). Juntos, a prova imprimiu "bloqueio PROVADO" e saiu rc 4 INTEGRIDADE: a sonda do outro
# mudou HEAD e status no meio da foto. A prova era boa; o veredito saiu falso porque dois provadores
# dividiram o mesmo checkout.
#
# O QUE FAZ: `onion_gate_probe_lock <alvo>` pega uma trava EXCLUSIVA no git-dir COMUM do alvo
# (`<common>/onion-gate-probe.lock`, nunca rastreável, fora do status que a foto lê; comum porque o
# `config --local` que a foto lê é do repositório, não da worktree). Quem chega com a trava tomada
# espera, dizendo, até `ONION_GATE_PROBE_LOCK_WAIT` segundos (default 1800). `onion_gate_probe_unlock`
# solta (necessário no caminho sem flock; com flock a trava morre com o último dono do descritor).
#   · com `flock` (util-linux): fd 9 no arquivo da trava. Quem segura a trava e roda comandos que podem
#     deixar processo vivo (o commit pelo hook do alvo) fecha o fd 9 neles (`9>&-`): um daemon solto pelo
#     hook herdaria o descritor e seguraria a trava depois do fim (passada adversarial de 2026-11-22);
#   · sem `flock` (macOS): `mkdir` atômico de `<lock>.d` com o pid dentro. Trava cujo pid morreu é
#     retomada só por quem pega a trava de retomada (`<lock>.reclaim`, outro mkdir) e confere o pid de
#     novo dentro dela: sem isso, dois retomadores apagavam a trava recém-criada um do outro (medido:
#     dupla posse em 6 de 20 rodadas). Pid ainda não escrito (janela do mkdir) nunca é velho.
# REENTRADA: quem pega a trava exporta `ONION_GATE_PROBE_LOCK_HELD=<common>`; um filho que chama a lib
# para o MESMO repositório segue sem pegar de novo (o instalador segura a trava e chama o verificador,
# que também a pede: sem isto, o filho esperaria o pai até o teto).
# NÃO é a porta de admissão de carga do core (core-only): aquela limita QUANTOS passos pesados rodam na
# máquina; esta impede que DOIS provadores mexam no MESMO repositório. Uma não substitui a outra.
#
# RC de onion_gate_probe_lock: 0 trava pega, já segura por um ancestral, ou alvo sem git-dir resolvível
#                              1 esperou o teto e a trava seguiu tomada (quem chama declara NÃO MEDIDO)
# Exercitado por lint-selftest.sh (run_prove_gate_blocks_selftests, casos da corrida).
# =============================================================================

_ONION_GPL_DIR=""

onion_gate_probe_lock() {
  local t="${1:-.}" w="${ONION_GATE_PROBE_LOCK_WAIT:-1800}" g lk pid i
  g="$(git -C "${t}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  [ -d "${g}" ] || return 0
  [ "${ONION_GATE_PROBE_LOCK_HELD:-}" = "${g}" ] && return 0
  lk="${g}/onion-gate-probe.lock"
  if command -v flock >/dev/null 2>&1; then
    exec 9>>"${lk}" || return 0
    if ! flock -n 9; then
      echo "· outra prova do gate segura ${lk}: esperando até ${w}s (provas no mesmo repositório não rodam juntas)" >&2
      flock -w "${w}" 9 || return 1
    fi
    export ONION_GATE_PROBE_LOCK_HELD="${g}"
    return 0
  fi
  i=0
  while ! mkdir "${lk}.d" 2>/dev/null; do
    pid="$(cat "${lk}.d/pid" 2>/dev/null)" || pid=""
    if [ -n "${pid}" ] && ! kill -0 "${pid}" 2>/dev/null && mkdir "${lk}.reclaim" 2>/dev/null; then
      # dentro da trava de retomada: só apaga se o pid lido AGORA ainda é o morto
      [ "$(cat "${lk}.d/pid" 2>/dev/null)" = "${pid}" ] && { rm -f "${lk}.d/pid"; rmdir "${lk}.d"; } 2>/dev/null
      rmdir "${lk}.reclaim" 2>/dev/null
      continue
    fi
    [ "${i}" -eq 0 ] && echo "· outra prova do gate segura ${lk}.d: esperando até ${w}s (provas no mesmo repositório não rodam juntas)" >&2
    i=$((i + 1)); [ "${i}" -ge "${w}" ] && return 1
    sleep 1
  done
  printf '%s\n' "$$" > "${lk}.d/pid" 2>/dev/null
  _ONION_GPL_DIR="${lk}.d"
  export ONION_GATE_PROBE_LOCK_HELD="${g}"
  return 0
}

onion_gate_probe_unlock() {
  [ -n "${_ONION_GPL_DIR}" ] || return 0
  rm -f "${_ONION_GPL_DIR}/pid" 2>/dev/null; rmdir "${_ONION_GPL_DIR}" 2>/dev/null; _ONION_GPL_DIR=""
}
