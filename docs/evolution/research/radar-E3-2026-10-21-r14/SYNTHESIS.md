---
title: Radar E3 r14 — o delta do Claude Code de 2.1.303 a 2.1.306 contra o Onion
date: 2026-10-21
kg: docs/evolution/research/radar-E3-2026-10-21-r14/radar-E3-2026-10-21-r14.kg.yaml
run_id: "nenhum (rodada conduzida pela sessão, sem Workflow; o juiz é um subagente avulso)"
tokens: 208625
agents: 1
duration_min: 60
review_after: 2026-11-20
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** O custo cobre só o juiz (208.625 tokens). A medição da sessão não
> foi contada.

## O que mediu

São 4 versões (2.1.303 a 2.1.306) e 117 itens, com cópias byte a byte em `data/`, conferidas pelo juiz
(CU1). O host está na 2.1.306. O SDK do bridge segue no 0.3.302, com o CLI 2.1.302 embutido. O revisor
do CI subiu para a action v1.0.256 (CLI 2.1.306) no PR #1252.

## O que toca a casa

- **Resume de Workflow (2.1.305):** a correção dos agentes de `pipeline()`/`parallel()` reexecutados
  alcança os dois workflows salvos do core. Para a migalha de 2026-07-24 ela é **causa candidata**, não
  explicação, porque a migalha também culpa o journal noutra sessão. → **SAC-180**, com o critério de
  re-teste corrigido pelo juiz.
- **Revisor do CI:** o job foi **pulado em 40 de 40 runs**, e nenhum PR teve a label `review:ia`. O pin
  novo segue sem prova. → **SAC-181**, que supera a pergunta da r13.
- **Compactação (2.1.304):** a lista de skills volta depois de compactar, o que toca a escorregada para
  EN registrada na memória. → **SAC-182**.
- **/chat (bridge):** fica 4 versões atrás. Nenhum conserto de correção ou segurança o alcança, e o ganho
  do 0.3.306 é desempenho no resume que ele faz a cada turno. O PR do SDK ainda não está no forge.
- **Sinais sem ato:** o preâmbulo do agente de execução depende do resume por mensagem (2.1.304
  corrigiu); o aviso de custo do resume no plano Max encontra o `resume_command` do hook de worklog; o
  shutdown de time não derruba mais a CLI; e o modelo do juiz gravado nas rodadas é **declarado** pela
  sessão, o que a 2.1.305 mostra que podia mentir no fallback.
- **Sem consumidor (medido):** worktree do CLI, hooks de skill, sandbox, gateway com tool search, mods,
  deny de PreToolUse com callback do SDK, setMcpServers, `/loop`, retry watchdog.

## Juiz

Subagente opus/high, pedido pela sessão (o modelo é declarado, não medido; ver o nó do fallback). Deu 11
vereditos: 5 SUSTENTA, 6 EXAGERA e 0 REPROVA. Ele apontou 13 omissões, e as 5 de impacto 2 viraram nós.
Também apontou 2 superações da r13 que a rodada não tinha declarado: o /chat "igual ao host" e a pergunta
de prova presa ao v1.0.252. O `judge-verdict-check.sh` dá 0 recusados e 0 superações achadas. Os
exageros corrigidos foram:
- o grep, que só reproduz com `-E`;
- a linha do pin (l.414);
- o impacto do SDK, que caiu de 4 para 2;
- o número 114 sem fonte;
- a superfície escondida do preâmbulo;
- a dicotomia falsa do re-teste.

## NÃO-VERIFICADOS

- O binário do SDK em produção (sem sudo): o lockfile e a hora do processo apontam para o 0.3.302.
- O modelo efetivo do juiz.
- O script do workflow de julho da migalha, que é irrecuperável.
