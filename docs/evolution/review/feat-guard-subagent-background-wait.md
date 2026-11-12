---
branch: feat/guard-subagent-background-wait
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: "agente de execução (mutantes da bancada) e passada da sessão principal em 2026-11-12; o refutador independente travou duas vezes e foi parado, ver o achado 3"
nota: "tokens e duration_min não medidos (0 = não medido); sem revisor independente nesta passada, só os mutantes da bancada. O MERGE ESPERA O MAESTRO: a guarda muda o .claude/settings.json de todas as sessões."
---

# Passada adversarial: `feat/guard-subagent-background-wait`

## O que muda

Forja pelo `/meta:forge-guard` do veto `.claude/hooks/pretooluse-subagent-background-wait.sh` (SAC-421, decisão do
maestro de 2026-11-12: "ajudante + guarda, medindo antes"). Hook PreToolUse em Bash: quando o JSON de entrada traz
`agent_id` no topo (string não vazia) e `tool_input.run_in_background` é o booleano `true`, sai com exit 2 e diz a
espera certa: `timeout <s> <cmd> > <log> 2>&1` em primeiro plano. Casa por campo JSON, nunca por palavra.

- Defeito datado: quatro subagentes parados em 2026-11-05 e três reincidências em 2026-11-12, esperando aviso de fim
  de tarefa de fundo que não acorda subagente que encerrou o turno.
- Sonda: Claude Code 2.1.322, `agent_id` e `agent_type` presentes só na chamada de subagente (resíduo do ajudante,
  commit 65a1c6716).
- Registro: grupo `Bash` do PreToolUse em `.claude/settings.json`, com `onFailure: block`.
- Doutrina: cláusula 7 da `guard-doctrine` (guarda que lê campo do harness re-mede o campo a cada versão).
- Grafo: `docs/evolution/research/guard-subagent-background-wait-2026-11/subagent-background-wait-2026-11.kg.yaml`
  (radar `--integrity --schema` rc 0, contrato rc 0).
- Bancada: família `run_subagent_background_wait_selftests`.

**Entrada malformada: fail-open declarado.** JSON que não parseia, topo que não é objeto ou python3 ausente: rc 0 com
"NÃO MEDIDO" no stderr. Cláusula 4 da guard-doctrine (erra para calar); a entrada vem do harness, e fechar barraria
todo Bash de toda sessão numa mudança de formato. O `onFailure: block` vale para o hook que quebra.

## Achados

1. **Real, curado (não bloqueia o veredito, mas tornava dois casos enfeite).** A 1ª redação tinha um filtro rápido
   por substring (`*agent_id*` e `*run_in_background*`) antes do juiz. Os mutantes que tiram a checagem do `agent_id`
   e a do fundo NÃO morderam: o filtro sozinho protegia os casos (iii) e (iv). Era casar por palavra, e a cobertura
   anunciada não existia. Cura: o filtro saiu, o juiz python sobe em toda chamada de Bash (~46 ms medidos, carga ~7).

2. **Limite (passada da sessão principal, 2026-11-12).** O mutante `is True` → `== True` sobrevive à bancada: a
   diferença só aparece com `run_in_background: 1` (inteiro), que o harness não emite. Fica declarado como
   equivalente na prática. Os mutantes "ferramenta invertida" e "exit 1 no lugar do exit 2" morrem (rc 1).
3. **Limite, e o mais importante: a guarda não cobre a forma de travamento medida hoje.** O refutador
   independente desta guarda ficou duas vezes por mais de 1h num tool_use sem resultado. A causa, reproduzida
   na sessão principal: um comando com `rm -rf $var` dispara a checagem de segurança do Claude Code, que pede
   aprovação humana; no subagente em segundo plano o pedido fica pendurado. Esta guarda veta o
   `run_in_background` e não enxerga isso. Registrado no SAC-421, com a cura de brief (agente não remove
   diretório por variável) e a de mecanismo a propor (o medidor acusa tool_use sem resultado há N minutos).

## Mutantes

Cópia limpa verde primeiro (m0), depois 8 mutantes, todos mordem (`LC_ALL=C`, `--families subagent_background_wait`,
rc 0): sem a checagem do `agent_id` → (iii) sessão principal com fundo; sem o print do veto → (i) subagente com fundo;
sem a checagem do fundo → (iv) subagente sem fundo; fundo por truthiness → (vii) string "true"; `agent_id` só por
None → (vi) vazio; `agent_id` lido também do `tool_input` → (xi); sem a checagem da ferramenta → (ix); malformado
vetando → (viii).

## Limites declarados

- Sem refutador independente com mandato de achar o falso positivo (o agente de execução não lança agentes).
- O veto não foi disparado pelo harness ao vivo: o dogfood rodou o hook com JSONs no formato da sonda (com e sem
  `agent_id`, malformado, vazio), porque este agente roda sob o settings.json do checkout principal.
- Sonda de uma versão (2.1.322) e um tipo (`general-purpose`): campo renomeado deixa a guarda muda; re-rodar no
  `/meta:cc-update`.
- Não vê `nohup … &` seguido de espera, nem fundo por outra ferramenta (Agent, Monitor).
- **O merge espera o maestro**, porque a guarda muda o `.claude/settings.json` de todas as sessões.
