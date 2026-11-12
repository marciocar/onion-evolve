---
branch: feat/agent-brief-helper
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: agente de execução (autoverificação por mutantes; sem refutador independente)
nota: "tokens e duration_min não medidos (0 = não medido); sem revisor independente nesta passada, só os mutantes da bancada"
---

# Passada adversarial: `feat/agent-brief-helper`

## O que muda

- `.claude/utils/orchestration/agent-brief.sh`: monta o brief final do subagente (cabeçalho que manda seguir o
  `execution-agent-preamble.md` + a linha «Processos longos: ESPERA EM PRIMEIRO PLANO» lida do preâmbulo por âncora +
  o brief). rc 2 para brief vazio, preâmbulo ausente ou âncora não achada. SAC-421.
- Citado na cláusula 5 da `batuta-doctrine.md` e no gotcha de brief do `onion-orchestration/SKILL.md`.
- Bancada: família `agent_brief` (`run_agent_brief_selftests`), 5 casos, cada um com mutante.

## Achados

Nenhum triado: esta passada não teve revisor independente.

## Mutantes

(a) cabeçalho trocado, (b) linha copiada removida, (c) checagem de brief vazio removida, (d) checagem de preâmbulo
ausente removida, (e) checagem de âncora removida: os cinco reprovam o caso (10/10 verdes, rc 0, `--families agent_brief`).

## Sonda do agent_id

**Pergunta:** o hook PreToolUse recebe `agent_id`/`agent_type` quando o Bash vem de um subagente?

**Medido** (Claude Code 2.1.322, `claude -p --dangerously-skip-permissions` num repositório descartável com
`.claude/settings.json` próprio e um hook PreToolUse que só grava o JSON de entrada; o repositório foi apagado).
O `claude -p` LANÇOU o subagente (`general-purpose`) sem problema em modo não interativo.

- Chamada direta (sem subagente), campos: `session_id, transcript_path, cwd, prompt_id, permission_mode, effort,
  hook_event_name: PreToolUse, tool_name: Bash, tool_input, tool_use_id` — **sem** `agent_id` nem `agent_type`.
- Chamada vinda do subagente, os mesmos campos **mais** `"agent_id": "a56b80dfadbaac02b"` e
  `"agent_type": "general-purpose"`.

**Veredito:** a guarda é POSSÍVEL. A presença de `agent_id` no JSON do PreToolUse distingue, de forma determinística,
a chamada de um subagente da chamada da sessão principal, e `agent_type` diz o tipo. Uma guarda pode, por exemplo,
barrar `run_in_background` de Bash quando `agent_id` está presente. Limite: uma amostra por caso, numa versão (2.1.322);
a guarda, quando forjada, deve tratar o campo ausente como sessão principal e rodar a sonda de novo no `/meta:cc-update`.
Não foi forjada guarda alguma (fora do escopo).

## Limites declarados

- Sem refutador independente; sem medida de tokens e tempo.
- A sonda mediu uma só versão do Claude Code e o tipo `general-purpose`.

## Re-revisão (rebase)

O rebase sobre a main trouxe o lint-selftest.sh com as famílias novas do dia; o bloco da família agent_brief foi mantido inteiro ao lado delas. O pré-voo das famílias agent_brief e shell_pipefail_robustness passou na árvore rebaseada.
