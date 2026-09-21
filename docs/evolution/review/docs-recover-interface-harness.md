---
title: 'Resíduo — recupero o estudo inteiro, e digo o que nele NÃO está vivo'
date: 2026-09-21
branch: docs/recover-interface-harness
reviewed_diff_sha256: 449979d8a3de8155d0b70a82e6e7e1d04a217496a0a1ac01f7cfeaf81f44676a
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Recuperação de 7 arquivos que o PR #344 deixou para trás em julho. Sem passada adversarial
  dedicada: não há desenho novo — o conteúdo é de 12-13/07, verbatim, e o que havia a verificar
  (a superfície de telemetria ainda existe? o trabalho foi superado em outro lugar?) foi MEDIDO
  e está declarado abaixo. A única alteração ao conteúdo original é a reconciliação mecânica de
  3 status, explicada na íntegra.
---

# O que se recupera, e por que o grafo vem junto

Sete arquivos de `docs/discussions/interface-state-of-art/` — o harness de telemetria (sink OTLP,
wrapper, analisador), o pré-registro N≥3 e o **grafo-estrela** do estudo. O PR #344 mergeou as notas
e deixou estes para trás; a branch ficou seis semanas sem que ninguém notasse.

**O grafo vem junto por doutrina, não por completude.** Nesta casa o `.kg.yaml` é o **destino** da
investigação e a prosa é projeção dele. Recuperar as notas sem o grafo reproduziria a cicatriz que a
migalha `radar-is-runtime-investigations-born-as-graph` registra: 8 passadas de Elenxo que evaporaram
em prosa porque o grafo não foi escrito.

# As três coisas que o maestro mandou declarar

**(1) A superfície de telemetria foi RE-VERIFICADA e continua válida.** As 8 variáveis que o harness
usa existem no binário instalado (2.1.278), medidas com `strings` sobre o ELF:

| variável | ocorrências |
|---|---:|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | 10 |
| `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA` | 6 |
| `OTEL_LOG_USER_PROMPTS` / `OTEL_LOG_TOOL_CONTENT` | 6 / 4 |
| `OTEL_METRICS_EXPORTER` · `OTEL_EXPORTER_OTLP_PROTOCOL` | 8 · 11 |
| `OTEL_LOGS_EXPORT_INTERVAL` · `OTEL_METRIC_EXPORT_INTERVAL` | 5 · 4 |

Inclusive os dois *gates de conteúdo*, que o harness deliberadamente **não** liga — intake é
estrutura, conteúdo fica fora.

> ⚠️ A 1ª medição deu **zero nas seis** e eu quase concluí que o harness estava morto: `grep` cru num
> ELF de 234 MB não acha as strings. Quarta vez neste dia que *zero de comando que falhou* quase virou
> *zero de fato*.

**(2) ~~O harness NUNCA foi executado desde 12/07.~~ — SUPERADA em 2026-09-21, no MESMO dia.**

Era verdade quando escrevi. Deixou de ser cerca de dez minutos depois, quando o maestro mandou rodar
o dogfood e eu executei o instrumento ponta a ponta. Isso tornou a frase acima um **artefato que mente
sobre si** — a classe que este repo mais persegue —, introduzida por mim e já mergeada em `main`,
orientando quem lesse. Por isso a correção vive aqui, com a frase antiga preservada: Aufhebung, não
reescrita de história.

O que foi medido (sink → sessão instrumentada → analisador, tudo `rc=0`):

| etapa | resultado |
|---|---|
| `otlp_sink.py` | LISTEN em `127.0.0.1:4318` |
| sessão headless instrumentada | os 3 sinais chegaram: `logs` 119 KB · `metrics` 8,6 KB · `traces` 11,9 KB |
| `leg1_analyze.py` | `rc=0`; 1 sessão, `reject-rate=0%`, `blocked_on_user` max=18 ms, 6 spans |

E o analisador **recusou-se a minerar**: com 1 sessão declarou *"nenhum span-pattern de atrito em ≥3
sessões"* e *"sem candidatos a confirmar"* em vez de inventar padrão — a trava anti-HARKing do
pré-registro funcionando no primeiro contato com dado real.

**O estado verdadeiro é outro:** o **instrumento está provado**; o **dado confirmatório da Leg-1 não
existe** e não pode ser gerado por mim. O critério exige ≥4 sessões **interativas** independentes, e o
sinal central (`blocked_on_user`) só nasce quando um humano espera num gate — os 18 ms medidos são o
flatline que a NOTE-05 previu para headless, não espera real. O README já dizia: *"`-p` headless serve
só para validar o instrumento, não conta como sessão Leg-1"*.

Segue valendo que **não há bancada** cobrindo o harness, e segue valendo a razão: é aparato de estudo,
que roda por invocação humana e não no gate.

**(3) O pré-registro N≥3 descreve um dogfood que NÃO aconteceu.** Entra como **plano aberto**, não
como método vigente. E não foi superado em outro lugar: `grep` por `OTEL_`/`CLAUDE_CODE_ENABLE_TELEMETRY`
em `.claude/`, `ops/` e a KB devolve **zero sítios vivos** no core, e a branch viva
`discuss/onion-pessoal-app` — que carrega as outras notas — **não tem nenhum dos 7**. A linha não foi
superada; ela parou.

# A quarta coisa: a reconciliação, e por que ela não é um veredito meu

O grafo entrava reprovando a **REGRA 52 (Todo .kg.yaml do repo passa no radar de INTEGRIDADE)**: três
nós `rule` recebiam `REFUTES` e seguiam `open`.

**As 4 arestas `REFUTES` foram escritas em 2026-07-12, no commit `a04ec873`** — o julgamento é de
julho, não meu. O que faltava era a **consequência mecânica** de uma decisão já registrada, que é o
*repair determinístico* de drift tipo-(c) do `/meta:realign`. Não confundir com o "REFUTED para o
maestro selar" do `/meta:drive`: aquilo é sobre **criar** refutação nova.

| nó | refutado por (julho) | status |
|---|---|---|
| `R_EXIBIR_SKIP_GATEAR_VETO` | `REF_1_DISPLAY_FEEDS_GATE` | `open` → `refuted` |
| `R_FORMATIVO` | `REF_2_LOOP_NEEDS_TREND` | `open` → `refuted` |
| `R_GATE_CAMADAS` | `C_FATIGUE_IS_SECURITY` + `REF_3_EXTERNAL_IS_IRREVERSIBLE` | `open` → `refuted` |

O diff do grafo é **exatamente três linhas de `status:`** — nenhum nó apagado, nenhuma aresta tocada.
Aufhebung: o nó e a razão ficam. Radar exit 0.

**Se o maestro discordar de qualquer um dos três**, reverter é trocar a palavra de volta — e os
refutadores continuam escritos ao lado, que é o ponto de nunca apagar.
