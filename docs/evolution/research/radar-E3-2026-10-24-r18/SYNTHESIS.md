---
title: Radar E3 r18 — o delta do Claude Code 2.1.310 contra o Onion
date: 2026-10-24
kg: docs/evolution/research/radar-E3-2026-10-24-r18/radar-E3-2026-10-24-r18.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um subagente da sessão, com um juiz subagente independente)"
tokens: 165097
agents: 1
duration_min: 40
review_after: 2026-11-23
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** `tokens` é só o juiz (165.097, 46 chamadas, 10,6 min, medidos pelo harness);
> os da rodada, que rodou como subagente da sessão, não ficaram expostos a ela. `agents: 1` é o juiz.

## O que mediu

A rodada mediu 1 versão, a 2.1.310, com 26 itens (29 linhas). A baseline era 2.1.309; disco e processo estão
em 2.1.310. O /chat do bridge está no SDK 0.3.309 (CLI embutido 2.1.309) e o revisor do CI no pin v1.0.260 da
claude-code-action (CLI 2.1.309): os dois uma versão atrás. O npm já publica o SDK 0.3.310 e a action já tem a
v1.0.261, que só troca versões (1 commit, 6 arquivos). Por ordem desta rodada, nada foi subido: só registrado.

## O que toca a casa

- **Quem serve está uma versão atrás** (`E_HOST_NA_2_1_310_BRIDGE_E_REVISOR_NA_2_1_309_1024`). A razão medida
  para subir o SDK do bridge é a compactação não interativa (linhas 6 e 11), que alcança o /chat e o runner de
  convidado. O pin do revisor é paridade, porque o revisor está desligado por padrão (`ONION_REVIEW_MODE` ausente;
  só a label `review:ia` o liga). A subida é `Q_SUBIR_SDK_DO_BRIDGE_E_PIN_DO_REVISOR_PARA_2_1_310_1024` (SAC-243).
- **A SAC-239 foi cumprida em configuração e segue em Backlog** (`E_SAC_239_CUMPRIDA_NO_VIVO_E_ABERTA_NO_LINEAR_1024`).
  O bridge está provado por execução do binário. O revisor tem o pin v1.0.260 (commit `704c8ebf`), mas nas 7
  execuções do workflow desde então o job saiu `skipped`, então nada prova o CLI 2.1.309 nele. O fecho pede um PR
  com a label `review:ia`, ou a metade do revisor declarada como pin sem execução:
  `Q_FECHAR_SAC_239_COM_O_REVISOR_PROVADO_1024`, comentado na própria SAC-239 (sem issue nova, para não duplicar).
- **Menções no revisor** (`E_REVISOR_SEM_SANITIZAR_ARROBA_NO_PIN_V1_0_260_1024`): o pin já traz a correção das menções
  indevidas da 2.1.309, mas `post-review-comment.sh` segue sem tratar `@` (linhas 113 e 119).
- **Sem efeito no core, medido:**
  - Linha 9, hooks do Windows: os 25 hooks do core e os de 37 settings de adotantes e portas começam por `bash`,
    nenhum é só aspas, e o bundle de plugins também emite `bash`.
  - Linha 13, `/sandbox`: o core não o usa. Neste host o AppArmor barra o `bwrap` (rc 1), e a 2.1.310 passa a dizer
    isso.
  - Linhas 3 e 4, Monitor e gateway: host e revisor falam com a API direta, e o gateway do /chat de convidado só
    existe em ensaio.
  - Linha 14, elicitação MCP: nenhum servidor `ops/mcp-onion-*` pede elicitação.
  - Sem superfície: `cleanupPeriodDays`, o auto mode, o `Image` de mod, o Claude Tag, o Code Review gerenciado e os
    papéis Enterprise de Remote Control.
  - Linha 8: o timeout de pergunta já está corrigido no host.
  - A guarda de deriva de binário (`cited_directive`) segue verde na 2.1.310.
- **Aufhebung:** SUPERSEDES de três nós da r17: as versões de quem serve, a pergunta da subida para a 2.1.309
  (respondida no vivo) e o revisor no CLI 2.1.308 sem a correção das menções.

## Juiz

Juiz **independente**: um subagente `general-purpose` com modelo opus, não-fork, mandato REFUTAR. Os critérios CU1 a
CU5 foram gravados antes em `data/judge-verdicts.json`. Resultado: **11 SUSTENTA, 3 EXAGERA, 0 REPROVA**, 3
superações e 8 omissões; `judge-verdict-check.sh` rc 0.

- A cópia do CHANGELOG bate byte a byte com a oficial (`cmp` e `diff` rc 0), e as linhas citadas batem.
- **EXAGERA:** a pergunta da subida justificava o impacto pela linha 14, que não tem superfície, e omitia a 6; o nó
  da SAC-239 dava por cumprida a metade do revisor, que tem só o pin e nunca rodou; e a superação da pergunta da r17
  tinha a ponta errada (quem a supera é a evidência que a responde, não a pergunta da versão seguinte). Os três foram
  reescritos, e cada superação virou nó `C_SUPERACAO_20261024_*` com `TRACES_TO` ao nó julgado.
- O juiz apontou a falta de uma terceira superação (o revisor no CLI 2.1.308): virou nó.
- Ressalva aceita: a contagem dos settings de adotantes foi refeita (a rodada truncara a listagem em 20; são 37
  legíveis pelo glob de um nível, nenhum só aspas).

## NÃO-VERIFICADOS

- Linha 7 (o pedido de permissão de leitura mostra o destino do link simbólico): só o /chat de convidado lê com
  pedido de permissão; o efeito lá não foi medido.
- Linhas 15 e 16 (VSCode) e 18 a 21 e 23 (diálogos de ambiente em nuvem): telas de IDE e de claude.ai sem
  superfície no core, não medidas uma a uma.
- A versão do CLI no runner do revisor: só o pin a afirma; nenhum job executou desde a subida (ver a SAC-239).
- O efeito real da compactação da 2.1.310 no /chat: só será medido depois da subida do SDK (SAC-243).
