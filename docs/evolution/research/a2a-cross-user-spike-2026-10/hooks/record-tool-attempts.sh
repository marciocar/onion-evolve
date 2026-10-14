#!/usr/bin/env bash
# =============================================================================
# record-tool-attempts.sh — hook de REGISTRO do spike A2A cross-user (Emenda 1, 2026-10-14).
#
# SÓ REGISTRA. Não bloqueia, não aprova, não imprime nada no stdout: sai sempre com 0 e sem saída, e
# por isso não altera a decisão de permissão. Grava uma linha JSON por evento em
#   ${A2A_SPIKE_STATE:-~/.local/state/onion/a2a-spike}/tool-attempts.jsonl   (arquivo 0600)
#
# Por que existe: a curadoria refutou o A8 original, que media o MAESTRO e não o modelo. Com o maestro
# negando o prompt, o hash dos arquivos sai idêntico de qualquer jeito. O que mede o modelo é a
# TENTATIVA: o PreToolUse dispara antes do diálogo de permissão, então uma tentativa negada também fica
# registrada. O juiz (vps/judge-attempts.sh) compara as tentativas com a allowlist pré-registrada do
# cenário (allowlists/<cenário>.tsv).
#
# Eventos que a config da sessão receptora liga (hooks/receiver-settings.json):
#   SessionStart       → prova de que o hook carregou nesta sessão (sem ela o juiz dá INCONCLUSIVO)
#   PreToolUse         → a TENTATIVA (tool_name + tool_input), inclusive a que vai ser negada
#   PermissionRequest  → o diálogo apareceu (início da espera humana)
#   PostToolUse        → a ferramenta rodou (aprovada); falta de PostToolUse = negada ou falhou
# O par PreToolUse → PostToolUse do mesmo tool_use_id mede o "tempo das aprovações" do §6 (Emenda 4).
#
# NÃO vai no .claude/settings.json do repo: a sessão receptora o carrega por config própria
# (`claude --settings <arquivo>`), montada no P3 fora da árvore.
#
# Variáveis lidas (exportadas pelo maestro ANTES de abrir a sessão; uma sessão por réplica):
#   A2A_SPIKE_SCENARIO (ex.: A8a) · A2A_SPIKE_REPLICA (1..5) · A2A_SPIKE_STATE
# Teste offline: hooks/record-tool-attempts.selftest.sh
# =============================================================================
set +e
umask 077
STATE="${A2A_SPIKE_STATE:-${HOME}/.local/state/onion/a2a-spike}"
OUT="${STATE}/tool-attempts.jsonl"
mkdir -p "${STATE}" 2>/dev/null
RAW="$(cat 2>/dev/null)"
T_MS="$(python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || echo "$(( $(date +%s) * 1000 ))")"
SC="${A2A_SPIKE_SCENARIO:-unset}"; RP="${A2A_SPIKE_REPLICA:-unset}"

LINE=""
if command -v jq >/dev/null 2>&1; then
  LINE="$(printf '%s' "${RAW}" | jq -c --argjson t "${T_MS}" --arg sc "${SC}" --arg rp "${RP}" '
    { t: $t, scenario: $sc, replica: $rp,
      event: (.hook_event_name // "?"), session_id: (.session_id // ""),
      permission_mode: (.permission_mode // ""), cwd: (.cwd // ""),
      tool_name: (.tool_name // ""), tool_use_id: (.tool_use_id // ""),
      tool_input: (.tool_input // null), source: (.source // "") }' 2>/dev/null)"
fi
if [ -z "${LINE}" ]; then
  # jq ausente ou stdin que não é JSON: registra cru, para que a falha APAREÇA no juiz em vez de sumir
  if command -v python3 >/dev/null 2>&1; then
    LINE="$(RAW="${RAW}" python3 -c 'import json,os,sys;print(json.dumps({"t":int(sys.argv[1]),"scenario":sys.argv[2],"replica":sys.argv[3],"event":"UNPARSED","raw":os.environ.get("RAW","")}))' "${T_MS}" "${SC}" "${RP}" 2>/dev/null)"
  fi
  [ -n "${LINE}" ] || LINE="{\"t\":${T_MS},\"event\":\"UNPARSED\",\"scenario\":\"${SC//\"/_}\",\"replica\":\"${RP//\"/_}\"}"
fi
printf '%s\n' "${LINE}" >> "${OUT}" 2>/dev/null
exit 0
