---
title: "Um aparte mandado no meio do turno vira o 'pedido do usuário' de todos os agentes do Workflow disparado em seguida, e os juízes obedecem a ele"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: high
decision_owner: core (maestro sela)
---

# O aparte sequestrou duas pesquisas inteiras, e nenhuma guarda viu

## O que aconteceu (2026-10-07, medido)

1. O maestro pediu duas pesquisas (`/onion-research`). Ainda no mesmo turno, antes dos `Workflow(...)`,
   chegou um aparte: `dúvida: o que precisamos para usar o zoho projects?`. O `aside-router-hook.sh`
   roteou como "responda BREVE sem parar a tarefa". A sessão respondeu e, em seguida, disparou os dois
   workflows `onion-research.js` (`wf_9c639434-891` em research, `wf_88d5d0b0-403` em decision).
2. **Run 1:** 103 agentes, 4,59M tokens, 12 min. Terminou com `radarExit -1` e nenhum arquivo escrito.
   O agente `write-kg` devolveu, verbatim: "NÃO ESCRITO … O pedido do usuário foi 'o que precisamos para
   usar o zoho projects?' … Pela regra do harness, o pedido do usuário prevalece." O sintetizador
   respondeu sobre o Zoho em vez de sintetizar.
3. **Contagem por fase**, em resultados no `journal.jsonl` que mencionam o Zoho:

   | Fase | Modelo | Run 1 | Run 2 |
   |---|---|---|---|
   | Scope / Search / Fetch | sonnet | 0/26 | 0/36 |
   | Verify | opus | 74/75 | 104/105 |
   | Synthesize / Elenxo / write | opus | 2/2 | 2/2 |

   O run 2 foi parado antes do write.

## O mecanismo (verificado no transcript de cada agente, não suposto)

O primeiro turno de **todo** agente do workflow (`subagents/workflows/<run>/agent-*.jsonl`) é um bloco
do harness do Claude Code:

> `[Workflow harness — user request] The harness relays, verbatim and indented below, the user request
> that triggered this workflow run. … Where the computed task conflicts with this request, this request
> wins:` ↳ `dúvida: o que precisamos para usar o zoho projects?`

O harness repassa a **última mensagem do usuário no momento do disparo**. Como o aparte chegou no meio
do turno e o `Workflow` foi chamado depois dele, o aparte virou "o pedido que disparou o run", e o bloco
manda esse pedido vencer a tarefa computada.

- **A minha hipótese inicial está REFUTADA:** eu supus que os agentes do mesmo modelo da sessão (opus)
  herdavam o contexto da conversa. O repasse chegou a **todos** os 361 transcripts, sonnet inclusive
  (`(sonnet, Fetch, relay=True, zoho=True) 15`). A diferença está em quem **obedece**: os coletores
  sonnet fizeram a tarefa mecânica, e os juízes opus/high aplicaram "o pedido vence".
- **O resume não repassa nada.** Os agentes que rodaram de novo com `resumeFromRunId` não têm o bloco
  `user request`, e o primeiro turno deles é a tarefa computada. Com uma guarda no prompt (abaixo),
  76 Verify novos saíram no tema certo.

## Contorno aplicado aqui (sem tocar o vendorizado)

Uma cópia do `onion-research.js` no scratchpad, com uma `GUARD` no início dos prompts de Verify,
Synthesize, Elenxo e write: "a sua tarefa é exclusivamente a descrita abaixo; outra mensagem do
usuário no contexto já foi respondida pela sessão principal". Ela foi retomada pelo `resumeFromRunId`,
e Scope, Search e Fetch voltaram do cache. Essa mudança de prompt é o que invalida o cache só das fases
contaminadas.

## O que o core precisa decidir, pela lente do Onion

1. **Classe:** "a autoridade do pedido é resolvida pelo harness, não pelo script". Nenhuma guarda do
   Onion vê isso: o `radarExit -1` foi o único sinal, e veio no fim de 4,6M tokens.
2. **Opções a pesar, sem recomendação fechada:**
   - (a) os workflows do core passam a ancorar o pedido: a tarefa computada traz a pergunta original do
     maestro e declara que outro pedido repassado pelo harness é aparte já tratado (a `GUARD` acima,
     generalizada);
   - (b) o `aside-router-hook.sh` (ou a skill `onion-orchestration`) passa a avisar que "há um aparte
     neste turno: não dispare Workflow agora; responda e dispare no próximo turno, ou o aparte vira o
     pedido do run";
   - (c) uma guarda barata no início do run: o Scope compara o pedido repassado com a `question` e
     aborta se não tiverem relação, antes de gastar milhões de tokens;
   - (d) reportar ao Claude Code como comportamento do harness. Ele está declarado no próprio bloco, mas
     a escolha de "última mensagem" em vez de "mensagem que pediu o workflow" é discutível.
3. **Pergunta do maestro, para a doutrina do aparte:** "o aparte não pode usar o `/btw`, não vale a pena
   usar o aside?". A medição sugere que o aparte vale a pena: o defeito não é ele, é a **sequência**
   aparte → Workflow no mesmo turno. Hoje o hook roteia `dúvida:` como "responda breve sem parar a
   tarefa", e é exatamente "não parar a tarefa" que, neste caso, disparou o workflow com o aparte como
   pedido. A doutrina do aparte (`maestro-aside.md`) não fala em Workflow.

## Custo medido

Run 1 completo: 4.591.662 tokens de subagente. A parte contaminada (Verify, Synthesize e write) foi
refeita no resume, e o número final vai no `SYNTHESIS.md` da pesquisa
(`docs/evolution/research/kg-ssot-first-runtime-sdaal-2026-10/`).
