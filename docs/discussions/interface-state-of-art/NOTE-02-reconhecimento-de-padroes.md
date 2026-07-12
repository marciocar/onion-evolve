---
title: "Nota 02 — Reconhecimento de padrões: candidato → doutrina (pergunta 2 do SEED)"
category: discussion-note
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
responde: SEED.md — pergunta 2
metodo: pesquisa orquestrada citada (2 frentes novas) antes de posição
relacionado: NOTE-01-telemetria-util-e-etica.md
---

# 🧵 Nota 02 — A interface percebe "isto já aconteceu / vira padrão candidato"

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Síntese aterrada em pesquisa citada. Fontes ao final.

## Posição em uma linha

O Onion **já tem** o pipeline que a pergunta descreve (diário → padrão candidato →
doutrina), inclusive o re-teste com validade (`/meta:diary review` — "migalha vencida →
re-testar, nunca re-carimbar"). Então a interface **não deve auto-promover padrão**. Deve
fazer a metade barata — **detectar + surfacear recorrência com evidência** — e alimentar o
pipeline humano-gated que já existe, adicionando **uma trava de refutação** que hoje falta.

## O achado cruzado com a Nota 01 (mesmo fato estrutural, valência oposta)

Na Nota 01, o colapso "observado = beneficiário = maestro" **dissolveu** o risco ético.
Aqui, o **mesmo colapso** — "quem propõe o padrão = quem aprova = maestro" — é **perigoso**:
a literatura converge que *quem propõe o candidato não pode ser o único gate* (viés de
aliança/confirmação; red-teaming exige entidade dedicada só a refutar). Instância única =
proponente e aprovador na mesma pessoa → sem refutação independente, **apofenia
institucionalizada** vira doutrina. Mesmo colapso da Nota 01, sinal trocado: lá salva, aqui
morde. Essa simetria é, por si só, um princípio de design.

## Lente Aristóteles (igual→transfere / diferente→desenha)

- **Rule of Three** — *igual, transfere.* 2 ocorrências = coincidência; a 3ª (independente) =
  candidato. Limiar canônico anti-overfitting. Gate mínimo pra *surfacear* candidato — não pra promover.
- **Recorrência ≠ importância** — *diferente, desenha.* Issue recorrente às vezes é **ruído
  tolerado** (reapareceu e ninguém agiu = baixa prioridade). Cruzar "quantas vezes" com "o que
  aconteceu quando apareceu antes" — contexto que o Onion já tem no diário + git.
- **Anomalia vs recorrência** — *diferente, dois motores.* Recorrência = "virou hábito, estruture";
  anomalia = "raro e perigoso, aja agora". Confundir os dois é o erro mais citado. Dois loops em paralelo.
- **Dedup semântico, não match exato** — *igual, transfere.* "Já aconteceu" por proximidade em
  embedding/grafo (trace clustering, trajectory similarity), não string igual.
- **Camada de reflexão separada do log bruto** — *igual, transfere.* Generative Agents / AWM /
  `napkin` (skill real, `.claude/napkin.md`, **cap top-10 por categoria**): stream bruto → cluster
  por similaridade → síntese condensada com teto. O diário Onion já é a reflexão; a telemetria da
  Nota 01 é o stream bruto. Manter separados; o cap anti-inchaço é a lição do napkin.
- **Emergência por densidade de links (Zettelkasten)** — *igual, transfere.* Sinal de "merece
  doutrina" = densidade orgânica de reuso/citação cross-sessão, não convicção one-shot. KG já modela.

## O que a interface adiciona a um pipeline que já existe

A transição episódico→semântico (provenance de volta à trajetória) é a fronteira aberta que o
Onion hoje faz **em prosa**. A interface adiciona **lastro estruturado**: candidato deixa de ser
"senti que se repetiu" e vira "span-pattern X recorreu em N sessões independentes, com
reject-rate/blocked_on_user tais" (liga na Nota 01). **Mas** minerar sessões atrás de "o que se
repete" é uma **máquina de falso-padrão**: testando o suficiente, *algo* sempre parece
significativo (multiple comparisons; Texas sharpshooter; HARKing). Nota honesta da literatura: em
ML de produção a correção pra isso **é rara por padrão** — não assumir que o pipeline protege sozinho.

## O gate de promoção proposto (candidato → doutrina) — o que FALTA em negrito

1. **N≥3 ocorrências independentes** antes de considerar promoção (Rule of Three). *[novo]*
2. **Separar descoberta de confirmação** (anti-HARKing): evidência que *gerou* o candidato ≠ a que
   o *confirma*; exigir ocorrência **nova, pós-formulação**. *[novo — trava mais ausente]*
3. **Sem autopromoção → refutador adversarial**: agente com mandato único de *quebrar* o candidato.
   O Onion **já suporta** — padrão "adversarial verify" da orquestração. *[reusar o que existe]*
4. **TTL / re-teste programado**: `/meta:diary review` ("migalha vencida → re-testar") já é isto. ✅
5. **Contradição reabre revisão**, não é "exceção a ignorar" (erro que custou market share à United).
   Doutrina de dogfood ("veredito = hipótese a verificar") tem o instinto; falta o gatilho automático. *[semi-novo]*
6. **Registrar o critério de promoção antes de aplicar** (pré-registro): declarar o limiar *antes* de
   minerar, pra não ajustar a régua depois que "quase bate". *[novo]*
7. **Instrumentar contra múltiplas comparações** explicitamente. *[novo]*

Síntese: a interface faz (1) e prepara (2,6,7 — rigor anti-falso-padrão); o **humano + refutador**
fazem (3,5); o diário já cobre (4). **A interface propõe com lastro e ceticismo embutido; o maestro
+ um refutador dedicado decidem.**

## Fios abertos que voltam ao maestro

1. O **refutador adversarial** vale como peça obrigatória do pipeline (dado o colapso do "no
   self-promotion" na instância única)? É barato — o Onion já sabe orquestrar.
2. **N≥3 independentes + ocorrência nova pós-formulação** vale como gate mínimo, ou é rígido demais
   pro ritmo atual (onde uma sessão só já gera doutrina)?
3. A interface deve distinguir na superfície **"padrão recorrente (estruture)"** de **"anomalia rara
   (aja agora)"** como dois canais — ou é over-engineering pra escala atual?

## Fontes (seleção)

- Rule of Three (refactoring/reuse) — https://blog.codinghorror.com/rule-of-three/ · https://erikbern.com/2017/08/29/the-software-engineering-rule-of-3.html
- Frequent Episode Mining (survey 2024) — https://www.philippe-fournier-viger.com/Survey_Episode_mining.pdf
- PrefixSpan (pattern-growth) — http://www.philippe-fournier-viger.com/spmf/prefixspan.pdf
- Agent Workflow Memory (AWM, ICML 2025) — https://arxiv.org/abs/2409.07429
- Generative Agents (reflection tree) — https://arxiv.org/html/2305.16291
- RecMem (recorrência como gate de consolidação) — https://arxiv.org/abs/2605.16045
- Graph-based Agent Memory (survey) — https://arxiv.org/html/2602.05665v1
- Governing Evolving Memory / SSGM (poisoning, semantic drift) — https://arxiv.org/html/2603.11768v1
- CODESKILL (skill bank com recompensa híbrida) — https://arxiv.org/abs/2605.25430
- napkin (skill comunitária, cross-session runbook) — https://github.com/blader/napkin · issue https://github.com/anthropics/claude-code/issues/51735
- Apophenia — https://en.wikipedia.org/wiki/Apophenia
- Clustering illusion — https://en.wikipedia.org/wiki/Clustering_illusion
- Texas sharpshooter fallacy — https://en.wikipedia.org/wiki/Texas_sharpshooter_fallacy
- Multiple comparisons em ML/exploração — https://escholarship.org/uc/item/6h32g578
- Questionable Practices in ML (correção multi-comparação é rara) — https://arxiv.org/pdf/2407.12220
- Backtest overfitting (Bailey et al.) — https://www.researchgate.net/publication/275302374_Pseudo-Mathematics_and_Financial_Charlatanism
- Pré-registro (anti-HARKing) — https://www.cos.io/initiatives/prereg
- Zettelkasten (emergência) — https://zettelkasten.de/overview/
