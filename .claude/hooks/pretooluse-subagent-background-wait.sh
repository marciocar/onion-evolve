#!/usr/bin/env bash
# PreToolUse(Bash) — veta `run_in_background` quando a chamada vem de um SUBAGENTE (SAC-421). Decisão do maestro de
# 2026-11-12: "ajudante + guarda, medindo antes". O ajudante (agent-brief.sh) põe a regra no brief; esta guarda barra o ato.
# Grafo: docs/evolution/research/guard-subagent-background-wait-2026-11/subagent-background-wait-2026-11.kg.yaml
#
# ── O DEFEITO MEDIDO (datado, não suposto) ─────────────────────────────────────────────────────
# 2026-11-05: três subagentes da sessão principal ficaram parados de 10 min a 1 h (guard-plugin-fix-4, route-paper-conductor,
# persona-postrun), todos com "aguardando o monitor"; antes, o guard-plugin-finish-2 parou 1h40. Nos quatro, o processo de
# fundo já tinha terminado com a saída em disco: o aviso de fim da tarefa de fundo NÃO acorda um subagente que encerrou o
# turno. A regra foi para o preâmbulo do agente de execução (linha "Processos longos"). 2026-11-12: reincidiu 3 vezes num dia,
# com briefs que não citavam o preâmbulo — regra na disciplina da sessão é cura nula.
#
# ── POR QUE É POSSÍVEL (a sonda, medida, não suposta) ──────────────────────────────────────────
# Claude Code 2.1.322, `claude -p` num repo descartável com um PreToolUse que só gravava o JSON de entrada (resíduo
# docs/evolution/review/feat-agent-brief-helper.md, seção "Sonda do agent_id"): a chamada de Bash vinda de subagente traz
# `agent_id` e `agent_type` no topo do JSON; a chamada direta da sessão principal não traz nenhum dos dois.
#
# ── O QUE VETA (exit 2, antes de executar) ─────────────────────────────────────────────────────
# JSON de entrada com `agent_id` no TOPO, string não vazia, E `tool_input.run_in_background` booleano `true`, para a
# ferramenta Bash (ou sem `tool_name`). Casa por CAMPO JSON, nunca por palavra: o comando que CITA `agent_id` ou
# `run_in_background` é texto, não campo (cláusula 3 da guard-doctrine).
#
# ── O QUE NÃO VETA (teto declarado) ────────────────────────────────────────────────────────────
#  · a sessão principal (sem `agent_id`): para ela o aviso de fim chega, e o fundo é legítimo;
#  · subagente sem fundo, com `run_in_background: false`, ou com o valor como STRING "true" (só o booleano conta);
#  · `nohup <cmd> > <log> 2>&1 &` numa chamada normal: é como um subagente sobe servidor que precisa ficar vivo, e o veto o
#    indica; quem depois "aguarda" esse processo sem medir volta ao defeito — esta guarda não vê isso;
#  · outras ferramentas de fundo (Agent, Monitor): o matcher é Bash;
#  · o harness que RENOMEIE o campo `agent_id` deixa a guarda muda sem aviso: a sonda tem de ser re-rodada no
#    /meta:cc-update (cláusula na guard-doctrine). Uma só versão medida (2.1.322) e um só tipo (general-purpose);
#  · não há filtro por palavra antes do juiz (seria casar por texto): o python sobe em toda chamada de Bash, ~20 ms.
#
# ── ENTRADA MALFORMADA: FAIL-OPEN DECLARADO ────────────────────────────────────────────────────
# JSON que não parseia, topo que não é objeto, ou python3 ausente → rc 0 com aviso "NÃO MEDIDO" no stderr. Cláusula 4 da
# guard-doctrine: a guarda erra para CALAR. A entrada vem do harness, não de terceiro (cláusula 5), e fechar aqui barraria
# TODO Bash de toda sessão numa mudança de formato do harness, que é o pior falso positivo possível. O `onFailure: block`
# do registro segue valendo para o hook que QUEBRA (rc fora de 0/2); malformado não é quebra, é rc 0 declarado.
# Escape: não há flag. Espere em primeiro plano com teto.
set -uo pipefail

# ── o juiz (Python, stdlib) ── stdin: o JSON do hook · stdout: VETO | MALFORMED | nada
_onion_sbw_judge() {
  python3 -I -B -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    print("MALFORMED"); sys.exit(0)
if not isinstance(d, dict):
    print("MALFORMED"); sys.exit(0)
aid = d.get("agent_id")
if not (isinstance(aid, str) and aid.strip()):
    sys.exit(0)                                   # sessão principal, ou agent_id vazio/nulo: cala
tool = d.get("tool_name")
if tool is not None and tool != "Bash":
    sys.exit(0)
ti = d.get("tool_input")
if not isinstance(ti, dict):
    sys.exit(0)
if ti.get("run_in_background") is True:           # só o booleano: "true" string não é o campo do harness
    print("VETO")
'
}

_onion_sbw_main() {
  local input out
  input="$(cat)"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "GUARDA-PRETOOLUSE (fundo em subagente): python3 ausente — NÃO MEDIDO, a guarda cala." >&2
    return 0
  fi
  out="$(printf '%s' "${input}" | _onion_sbw_judge 2>/dev/null)" || out="MALFORMED"
  case "${out}" in
    VETO)
      echo "GUARDA-PRETOOLUSE (fundo em subagente): subagente não usa run_in_background — o aviso de fim da tarefa de fundo não acorda um subagente que encerrou o turno. Espere em primeiro plano com teto: timeout <s> <cmd> > <log> 2>&1 (servidor que precisa ficar vivo: nohup <cmd> > <log> 2>&1 & numa chamada normal)." >&2
      exit 2 ;;
    MALFORMED)
      echo "GUARDA-PRETOOLUSE (fundo em subagente): entrada do hook não parseia como objeto JSON — NÃO MEDIDO, a guarda cala (fail-open declarado)." >&2
      return 0 ;;
  esac
  return 0
}

# ── --selftest: as duas polaridades, pelo MESMO caminho do runner (JSON no stdin) ──
_onion_sbw_selftest() {
  command -v python3 >/dev/null 2>&1 || { echo "selftest: python3 ausente — não medido"; return 0; }
  local self ok=0 tot=0
  self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  # os campos que a sonda viu em 2.1.322, menos agent_id/agent_type (que cada caso põe ou tira)
  local B='"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","permission_mode":"bypassPermissions","hook_event_name":"PreToolUse","tool_use_id":"toolu_1"'
  _run() {  # $1=entrada crua → rc do hook
    local rc=0
    printf '%s' "$1" | bash "${self}" >/dev/null 2>&1 || rc=$?
    printf '%s' "${rc}"
  }
  _c() {  # <nome> <rc esperado> <entrada>
    tot=$((tot + 1)); local got; got="$(_run "$3")"
    if [ "${got}" = "$2" ]; then ok=$((ok + 1)); echo "✓ $1"; else echo "✗ $1 (esperava rc=$2, veio ${got})"; fi
  }
  # ── polaridade ACUSA ──
  _c "(i) subagente com fundo, no formato da sonda (agent_id + agent_type)" 2 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"bash .claude/validation/lint-selftest.sh\",\"run_in_background\":true},\"agent_id\":\"a56b80dfadbaac02b\",\"agent_type\":\"general-purpose\"}"
  _c "(ii) subagente sem agent_type, só agent_id" 2 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"sleep 60\",\"run_in_background\":true},\"agent_id\":\"f0\"}"
  # ── polaridade CALA ──
  _c "(iii) sessão principal com fundo (sem agent_id)" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"bash .claude/validation/lint-selftest.sh\",\"run_in_background\":true}}"
  _c "(iv) subagente sem run_in_background" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"timeout 900 bash x.sh > x.log 2>&1\"},\"agent_id\":\"a56b80dfadbaac02b\",\"agent_type\":\"general-purpose\"}"
  _c "(v) subagente com run_in_background false" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\",\"run_in_background\":false},\"agent_id\":\"a1\"}"
  _c "(vi) agent_id vazio ou nulo é sessão principal" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\",\"run_in_background\":true},\"agent_id\":\"  \",\"agent_type\":null}"
  _c "(vii) run_in_background como string \"true\" não é o booleano" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\",\"run_in_background\":\"true\"},\"agent_id\":\"a1\"}"
  _c "(viii) entrada malformada: fail-open declarado" 0 \
    "{${B},\"tool_name\":\"Bash\",\"agent_id\":\"a1\",\"tool_input\":{\"run_in_background\":true"
  _c "(ix) ferramenta que não é Bash" 0 \
    "{${B},\"tool_name\":\"Agent\",\"tool_input\":{\"prompt\":\"x\",\"run_in_background\":true},\"agent_id\":\"a1\"}"
  _c "(x) palavra no comando da sessão principal não é campo" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo '\\\"agent_id\\\":\\\"a1\\\",\\\"run_in_background\\\":true'\"}}"
  _c "(xi) agent_id dentro do tool_input não é o do topo" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\",\"agent_id\":\"a1\",\"run_in_background\":true}}"
  _c "(xii) run_in_background no topo, fora do tool_input" 0 \
    "{${B},\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"},\"run_in_background\":true,\"agent_id\":\"a1\"}"
  _c "(xiii) topo que não é objeto: fail-open declarado" 0 '["agent_id","run_in_background",true]'
  echo "selftest: ${ok}/${tot} verdes"
  [ "${ok}" -eq "${tot}" ]
}

if [ "${1:-}" = "--selftest" ]; then _onion_sbw_selftest; exit $?; fi
_onion_sbw_main; exit $?
