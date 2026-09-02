#!/usr/bin/env bash
# UserPromptSubmit — a sessão roda o binário que o disco já não tem? (Onion, 2026-09-02)
#
# ── O BURACO (medido, não suposto) ───────────────────────────────────────────────────────────
# O auto-updater do Claude Code troca o binário em disco COM A SESSÃO VIVA: o processo segue rodando
# a versão antiga (/proc/<pid>/exe → "… (deleted)"). Medido 2026-09-02: a sessão interativa do
# maestro rodava 2.1.247 por 6 dias com o disco em 2.1.258 — o picker do /model mostrava "Fable 5.1
# (disabled) — Update to 2.1.255+" num sistema já atualizado, e os hooks PreModelSwitch (2.1.251+)
# simplesmente não existiam naquele processo. `claude --version` e a REGRA 65 liam o DISCO e diziam
# "instalado=2.1.258": declarado ≠ verificado. Picker, hooks e capacidades refletem o PROCESSO.
#
# ── POR QUE UserPromptSubmit e não SessionStart ─────────────────────────────────────────────
# No SessionStart processo e disco coincidem por construção; o drift nasce DEPOIS, quando o updater
# roda. Só um hook que dispara ao longo da vida da sessão o vê. Custo: 2 readlink por prompt.
#
# ── DISCIPLINA ──────────────────────────────────────────────────────────────────────────────
# Avisa UMA vez por (sessão, versão-do-disco): se o disco andar de novo, avisa de novo. Nunca
# bloqueia (exit 0 sempre): reiniciar é ato do maestro. Sinais, em ordem: CLAUDE_CODE_EXECPATH
# (o caminho do binário do processo, exportado pelo Claude Code) → /proc/$CLAUDE_PID/exe.
set -uo pipefail
exec_path="${ONION_CC_EXECPATH-${CLAUDE_CODE_EXECPATH:-}}"   # `-` e não `:-`: override DEFINIDO-vazio isola a bancada do vazamento da sessão
proc_ver=""; deleted=""
if [ -n "${exec_path}" ]; then
  proc_ver="$(printf '%s' "${exec_path##*/}" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)"
fi
if [ -n "${CLAUDE_PID:-}" ] && [ -r "/proc/${CLAUDE_PID}/exe" ]; then
  link="$(readlink "/proc/${CLAUDE_PID}/exe" 2>/dev/null || true)"
  case "${link}" in *" (deleted)") deleted=1 ;; esac
  [ -z "${proc_ver}" ] && proc_ver="$(printf '%s' "${link%% (deleted)}" | sed 's|.*/||' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)"
fi
[ -n "${proc_ver}" ] || exit 0                       # sem sinal do processo: nada a comparar
cc_bin="${ONION_CC_BIN:-claude}"
command -v "${cc_bin}" >/dev/null 2>&1 || exit 0
disk_ver="$(readlink -f "$(command -v "${cc_bin}")" 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)"
[ -n "${disk_ver}" ] || disk_ver="$("${cc_bin}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
[ -n "${disk_ver}" ] || exit 0
[ "${proc_ver}" != "${disk_ver}" ] || exit 0
# rate-limit: 1 aviso por (sessão, versão do disco)
state_dir="${ONION_VERSION_DRIFT_STATE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/onion-version-drift}"
mkdir -p "${state_dir}" 2>/dev/null || true
marker="${state_dir}/${CLAUDE_CODE_SESSION_ID:-nosession}-${disk_ver}"
[ -e "${marker}" ] && exit 0
: > "${marker}" 2>/dev/null || true
del_note=""; [ -n "${deleted}" ] && del_note=" (binário do processo já DELETADO do disco)"
echo "⚠️ Onion: esta sessão roda o Claude Code ${proc_ver}${del_note}; o disco já tem ${disk_ver}. Picker de modelo, hooks e capacidades refletem o PROCESSO — o que só existe em ${disk_ver} está invisível aqui. Reinicie a sessão (/exit → claude --continue) para pegar a versão nova; avise o maestro se a diferença importar para a tarefa."
exit 0
