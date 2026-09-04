---
title: "Postura MCP no canal público de plugins (decisão R3) — (c) nada agora é a posição de espera correta; (a) reprovada, (b) reprovada como especificada"
date: 2026-09-04
kg: docs/evolution/research/plugin-mcp-posture-2026-09/plugin-mcp-posture-2026-09.kg.yaml
run_id: wf_9ad3aba7-b48
tokens: 6957989
agents: 104
duration_min: 35
genre: decision
mode: decision
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2026-10-04
---

# Postura MCP no canal público — decisão R3

> **Projeção** do grafo (31 nós, radar exit 0). Nó de decisão **`D_PLUGIN_MCP_POSTURE_0904`** (status `open`) — o maestro sela. Contexto: o Onion **já é** MCP (tríade kg/exec/framework, `D_TRIADE_MCP_POR_EIXO`, 2026-08-21) só para o LibreChat da VPS.

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 6.957.989 |
| Workers do run | 104 · 15 fontes · 43 claims · 25 verificadas (15 confirmadas, 10 refutadas) |
| Parede | ~35 min |

## O que se confirmou

- Plugins podem empacotar servidores MCP (`mcpServers` em `.mcp.json`/`plugin.json`, comando via `${CLAUDE_PLUGIN_ROOT}`); o campo é **opcional** no repo oficial; tools ficam namespaceadas `mcp__plugin_<plugin>_<server>__<tool>` (3-0, tier 10).
- Critérios de review de **conectores** (tier 10, 3-0): tools de leitura e escrita separados (catch-all é rejeitado); anotações `title`/`readOnlyHint`/`destructiveHint` obrigatórias; API de primeira parte e domínio do serviço; repo público. MCP remoto autenticado exige OAuth com CA reconhecida (2-1).
- Superfície de supply-chain real: caso `postmark-mcp` (pacote npm modificado para exfiltrar), servidores MCP operam com alta confiança no toolchain (3-0, tier baixo).

## O veredito do Elenxo (o que o maestro sela)

**(c) nada agora — como posição de espera correta, não como conclusão.** "(c) hoje é a escolha certa pelo motivo errado": o motivo errado seria "MCP aumenta a superfície na triagem" (cortado por orçamento; e o plugin já embarca hooks de shell); o motivo certo é que **os dois caminhos foram medidos e nenhum está pronto**.

- **(a) conector remoto público: REPROVADA, não gated.** Três bloqueios independentes: repo público obrigatório × core **privado** (o repo que tem o KG não pode ser submetido; o público não tem `docs/knowledge-base/`, `.claude/diary/`, `.kg.yaml` — exatamente o que `ops/mcp-onion-kg/server.py` lê); API de primeira parte × a tríade executa git/grep/bash no filesystem do maestro; conta de teste populada × servidor de um repo só, sem tenant. E `propose_kg_write` grava conteúdo arbitrário em `kg-inbox/` sem cota — num conector público é canal de injeção.
- **(b) stdio embarcado: REPROVADA como especificada.** Não é adapter, é reescrita com defeito de raiz: `REPO = dirname(dirname(dirname(__file__)))` sob `${CLAUDE_PLUGIN_ROOT}` resolve para o **plugin**, não para o projeto do adotante — serviria o próprio plugin, nunca "o KG do adotante". Mais: **zero** annotations nos 3 servidores (medido por grep); transporte HTTP + X-Api-Key, não stdio; truncamento silencioso em 60k; descrição de `kb_search` já mente ("91 KBs" contra 94).
- **(c) sub-evidenciada** — mas é a espera correta. Selar "o Onion não faz MCP" com este corpus seria decidir com a página errada e quatro eixos cortados por orçamento.

## CONSTRAINS (objeções sobreviventes)

1. **Conflação de regime**: 5 achados tier 10 vêm do review de **conectores** (claude.ai), não do marketplace de **plugins**. Válidos contra (a); **não estabelecidos** contra (b). Ler `claude.com/docs/connectors/directory` e `code.claude.com/docs/en/mcp` (ambos não lidos) antes de qualquer selo sobre (b).
2. **Demanda de hosts não-Claude-Code está em aberto** — zero issues/fóruns de Cursor/Codex/ChatGPT/LibreChat lidos; não invocar demanda externa como razão para (b).
3. **Tração cortada onde a memória do core manda olhar**: repos KG-MCP por trajetória e o Graphify (que venceu **como skill, não como MCP**) ficaram sem leitura — evidência potencialmente decisiva contra (b).
4. **Quarta opção eliminada por orçamento**: skill-bundle via git-subdir — a mais alinhada à postura de acoplamento e ao precedente 2026-08-07.
5. **Custo recorrente nunca precificado** (revisão contínua para permanecer listado; 4 breaking changes da spec).
6. **Precedentes de pé**: REGRA 10 (MCP é transporte opcional do SDAAL); `E_LINT_SLOW_VIA_MCP` (`_run` do kg tem timeout 60 s — `kg_radar` em grafo grande já vira erro); a capacidade que compra acoplamento é o `exit 2` de hook — MCP não é capacidade que não existe fora.

## Gatilho nomeado que reabre (b) (não é próxima tarefa)

(i) ler as duas páginas de primeira parte e estabelecer **qual regime governa plugin-embedded**; (ii) medir a base rate: clonar `anthropics/claude-plugins-official` e contar `.mcp.json`; (iii) resolver a **raiz do projeto do adotante** (sem variável de raiz de projeto, (b) é impossível, não cara); (iv) só então um servidor **novo**, stdio, com annotations, sem truncamento silencioso, sem contagens hardcoded, com gate mecânico (MCP-Scan em CI). Sem (i)–(iii), (b) não se planeja.

## Mercado (eixo invariante)

Sem sinal de capital para o canal de plugins. Tração de uso (top-2 >1M instalações). A posição do Thoughtworks Radar sobre MCP e a parceria Stytch×Cloudflare (autorização MCP remota) foram **refutadas** — não usar. O capital institucional em MCP está na governança do registry, não em produto de terceiro.

## NÃO-VERIFICADOS (declarado)

Refutados 10 (SBOM/assinatura/pin como exigência; "sem vetting"; "descrições só revisadas na 1ª conexão"; analista); fora do orçamento 18 claims e 36 fontes — entre elas as do regime de plugin-embedded e as de tração por trajetória.

## valeu-a-pena

6,96M tokens ÷ 31 nós ≈ **224k/nó** (3× o censo). O que se comprou: o resumo do run dizia "(b) com escopo estrito"; o **Elenxo mediu o servidor real** e derrubou (a) e (b) como especificadas — sem ele eu teria planejado um `.mcp.json` que serviria o próprio plugin. O custo alto veio dos eixos cortados por orçamento; a reabertura barata é o gatilho (i)–(iii) acima (sessão curta, não outra rodada).

## O que muda no plano

| Antes (plano F4) | Depois (R3) |
|---|---|
| Default (c); se (b), adapter stdio do `onion-kg` | **(c) confirmado** como espera; (b) tem gatilho nomeado de 3 passos antes de existir como plano; (a) sai de "gated" para **reprovada** |
| — | Achado colateral: a tríade existente precisa de annotations `readOnlyHint`/`title`, timeout do `_run` e descrição honesta de `kb_search` — dívida da VPS, fio separado |
| — | Skill-bundle via git-subdir entra como 4ª opção a considerar quando o gatilho abrir |
