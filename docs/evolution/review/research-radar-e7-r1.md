---
branch: research/radar-e7-r1
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: "a sessão que fechou a rodada, com mandato de refutar: 5 nós conferidos contra a fonte por WebFetch, e o critério de uma objeção sobrevivente rodado por curl"
nota: "tokens = 0 porque a passada rodou dentro da sessão, sem agente medido à parte; o custo da rodada (1.558.281 tokens, 24 agentes) está no frontmatter da SYNTHESIS. O achado é uma objeção do Elenxo refutada pela medida: a janela de 60 dias do degrau de 2026-07-02 da OpenAI está verbatim na página. Virou o nó E_E7_PR_PASS_60_DAYS_VERBATIM_1027, com REFUTES na objeção E_OBJECAO_E7_02, que passou a refuted."
---

# Passada adversarial: `research/radar-e7-r1`

## O que muda

- 1ª rodada do eixo E7-treino-inferencia do radar de mundo: grafo `radar-E7-2026-10-27.kg.yaml` (57 nós, 55 do
  run e 2 do fechamento), `data/workflow-return.json` (o retorno do run wf_2be7b5c9-f34) e `SYNTHESIS.md`.
- Baseline do E7 selada em `docs/onion/radar-baselines.yaml` no mesmo commit do grafo: sai o `never_run`, entram
  `last_run: 2026-10-27` e o `kg:`. A REGRA 65 (Radar de mundo com baseline DATADA por eixo) parou de acusar o eixo.
- Roster `treino-inferencia` em `docs/onion/radar-sources.yaml`: 9 fontes ancoradas pela rodada, com
  `last_checked: 2026-10-27`; a página de descontinuações da OpenAI teve o `last_checked` renovado.
- O sinal da curadoria foi para `docs/evolution/inbox/_processed/`.

## Conferência contra a fonte (5 nós, WebFetch em 2026-10-27)

1. `E_GEMINI_4_ARGON_INPUT_PRICE_DOUBLES_20261201`: "$2.00 through November 30, 2026." e "$4.00 starting
   December 1, 2026."; página "Last updated 2026-10-26 UTC". Bate.
2. `E_GEMINI_4_ARGON_OUTPUT_PRICE_DOUBLES_20261201`: "$10.00 through November 30, 2026." e "$20.00 starting
   December 1, 2026.". Bate.
3. `E_OPENAI_FT_CLOSED_ALL_NEW_JOBS_20270106`: "Active existing customers will no longer be able to create new
   fine-tuning jobs on this date.", na linha de 2027-01-06. Bate.
4. `E_BEDROCK_RFT_LAUNCH_QWEN3_GPTOSS_20260217`: "Posted on: Feb 17, 2026" e "Models supported at this launch
   are: qwen.qwen3-32b and openai.gpt-oss-20b.". Bate.
5. `E_DISTILL_8B_622_H100_HOURS`: PDF do arXiv 2602.20164, p. 8, Seção 4.2: "requires approximately 622 H100
   GPU-hours, a reduction of over 2,000 times", com "Total Distillation FLOPs: (8.22×10^20) + (2.88×10^19)". Bate,
   e confirma que o 2.000x é marginal (inferência do professor mais treino do aluno).

## Achado

1. A objeção sobrevivente `E_OBJECAO_E7_02` dizia que a janela de 60 dias do degrau de 2026-07-02 não estava
   ancorada. O critério dela (`grep '60 days'` no texto da página) foi rodado por curl: a frase completa termina em
   "in the past 60 days.". O verificador tinha ancorado a frase cortada. Corrigido no grafo: nó novo
   `E_E7_PR_PASS_60_DAYS_VERBATIM_1027` com REFUTES na objeção, que passou a `refuted`; radar `--integrity
   --schema` exit 0 e contrato rc 0 depois da mudança.

## Limites declarados

- A pergunta `Q_E7_BASELINE_CLOSE_BEFORE_SEAL_1027` (três primárias a mais e a linha por fonte do que muda para o
  Onion) segue aberta: o selo é de baseline, como o próprio Elenxo pediu, e não a responde.
- Nenhum veredito desta rodada derruba decisão selada; nada fica PROPOSTO.
- A passada não foi feita por agente separado: foi a sessão que fechou a rodada, com mandato de refutar.
