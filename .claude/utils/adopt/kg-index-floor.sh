#!/usr/bin/env bash
# =============================================================================
# kg-index-floor.sh — o vendor kg-ssot do ALVO regera o índice de leitura do KG? (piso: 4.25.1)
#
# POR QUE EXISTE (sinal de campo de um adotante, 2026-10-26, medido lá): desde a kg-ssot 4.25.1 o índice de
# leitura (`docs/onion/kg-read-index.tsv`, REGRA 84 (Índice de leitura do KG em sincronia com os traces)) sai do
# `resolved_targets` do `kg_trace.py` do PRODUTO, e o `--update` remove o resolvedor antigo da casa
# (`kg-trace-resolve.sh`). Um alvo com vendor kg-ssot PRÓPRIO anterior à 4.25.1 — que o update não sobrescreve —
# fica sem regerador: o `kg-trace.sh --emit-index` sai rc 2, e a REGRA 84 só declara NAO-JULGOU. O dano mora
# no intervalo: ninguém avisou ANTES. Este helper é o aviso, em uma linha, para o relatório do update e para o
# manifesto que detecta o vendor próprio.
#
# USO  : kg-index-floor.sh <TARGET>
# SAÍDA: só quando há o que avisar, UMA linha "AVISO kg-index: …" no stdout.
# EXIT : 0 = o vendor do alvo tem o regerador (versão >= 4.25.1 e kg_trace.py presente) — nada impresso
#        1 = AVISO impresso: vendor anterior à 4.25.1, carimbo sem versão legível, ou kg_trace.py ausente
#            (o perfil `gate` do release não o leva)
#        4 = não se aplica: o alvo não tem vendor/kg-ssot (o próprio produto, com tools/ na raiz, cai aqui)
#        2 = uso errado
# Só LÊ o alvo (o carimbo `.kg-ssot-version` e a existência do kg_trace.py); nunca escreve.
# =============================================================================
set -uo pipefail
FLOOR="4.25.1"
T="${1:-}"
[ -n "${T}" ] && [ -d "${T}" ] || { echo "uso: kg-index-floor.sh <TARGET> (diretório)" >&2; exit 2; }
V="${T}/vendor/kg-ssot"
[ -d "${V}" ] || exit 4   # sem vendor (inclui o próprio produto, que se julga pelo tools/ da raiz)
_ver="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "${V}/.kg-ssot-version" 2>/dev/null | head -1)"
_msg="o regerador do índice de leitura precisa da kg-ssot >= ${FLOOR}; adote a kg-ssot junto, ou o índice fica sem regerador"
if [ -z "${_ver}" ]; then
  echo "AVISO kg-index: vendor/kg-ssot do alvo sem versão legível no carimbo (.kg-ssot-version) — ${_msg}."; exit 1
fi
# sort -V: se a menor das duas é o piso, a versão do alvo é >= piso
if [ "$(printf '%s\n%s\n' "${FLOOR}" "${_ver}" | sort -V | head -1)" != "${FLOOR}" ]; then
  echo "AVISO kg-index: vendor/kg-ssot do alvo é ${_ver} — ${_msg}."; exit 1
fi
if [ ! -f "${V}/tools/kg_trace.py" ]; then
  echo "AVISO kg-index: vendor/kg-ssot do alvo é ${_ver} sem tools/kg_trace.py (perfil gate) — ${_msg} (perfil completo)."; exit 1
fi
exit 0
