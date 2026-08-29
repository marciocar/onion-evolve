---
title: "Revisão — lote 3 do drive: REPROVADO em 8 achados ALTA, e retomado antes do PR"
date: 2026-08-29
branch: drive/open-threads-batch3
reviewer: "2 lentes adversariais opus/high (números+reprodutibilidade · doutrina+selagem) sobre o diff e os manifests dos runs; os achados ALTA foram RE-MEDIDOS por mim antes de aceitos"
reviewed_diff_sha256: d578ff7e2ce73460787098237d15fb22e43be620783ba24ef5b58212f731a439
findings_total: 20
findings_real: 20
verdict: REPROVADO_E_CORRIGIDO
tokens: 300614
duration_min: 14
---

# Resíduo — REGRA 56

**2 de 2 lentes REPROVARAM. 20 achados reais, 8 ALTA.** O drive tem guarda para isto
(*"Elenxo reprovado → PARE e reporte; retome a fase quebrada, nunca contorne a jusante"*), e ela
disparou: **a 1ª redação do lote foi corrigida antes de virar PR.**

## O achado que matou um nó inteiro

`E_IDADE_DO_CARIMBO_PREDIZ_DRIFT` **era circular, e foi REMOVIDO.** Os 8 nós foram re-verificados
na **mesma** passada de 08-23: os "recentes" têm `verified_at: 08-23` *porque voltaram limpos*; os
"velhos" têm o carimbo congelado *porque voltaram parciais*. O "tempo desde a última medição
executada" — a variável que eu nomeei como preditor — é **6 dias para os oito**. Variância zero.
Eu estava prevendo drift com um campo que **codifica o resultado**.

E a contagem que o sustentava estava inflada 3×: usei os vereditos **brutos**, ressuscitando como
"drift" os dois que a GUARDA 1 do fan-in rebaixou *porque o worker não conseguiu medir*. O
`contagem` do run diz `{CONFIRMED:3, UNVERIFIABLE:4, DRIFTED:1}`. Honesto: **1 de 4 contra 0 de 4**,
Fisher p=1,0.

## O achado que me pega fazendo o que eu acusava

Escrevi que o nó *"errou por 3×"* ao dizer 192. **Falso, e a manobra é minha:** os 192 sempre
foram os **itens abertos do `docs/backlog.md`**; os 612 que eu pus no lugar são nós
`PROD/impact>=4`, uma população **96% já fechada** (só 23 open). **Troquei a população e imputei
o erro a quem escreveu o nó** — exatamente a manobra de denominador que esta casa mediu nos
workers hoje de manhã, repetida na página seguinte. Com o denominador certo: **190 × 139.537 =
26,5M**, não 85,4M.

## Números que não reproduziram

| declarei | recontagem independente |
|---|---|
| corpus de **3.029** | **3.290** (transposição de dígitos) |
| **612** nós PROD/impact≥4 | **611** — e **24 são fixtures de bancada** |
| **85,4M** de censo | **26,5M** com a população certa |

Retirados do nó. Sobrevive só o custo unitário — **139.537 tok/nó** — que reproduz exato
(a soma por agente bate com o `totalTokens` dos dois manifests).

## O que sobreviveu, e menor do que eu escrevi

A byte-identidade do `-radar.md` (10373 = 10373) é real e o revisor a reproduziu. **Mas ela é um
top-25**: cita 30 dos 319 abertos; o frescor cobre 62. **257 abertos seguem sem projeção e sem
veredito.** A refutação da metade forte do dissenso vale em ~10-19% do grafo, não no todo.

E a forma estreita re-medida confirma limpo: **319 abertos, ZERO** em `docs/backlog.md`.

## Dois HARD que o lote criou e que a revisão pegou antes do CI

- **REGRA 58** — apendei 3 nós num arquivo com `TETO: 20` sem colher nenhum: 21 > 20.
  Resolvido pela remoção do nó circular: **20 exatos**.
- **REGRA 62** — mudei a fila aberta e não regenerei `docs/backlog.md`. Regenerado (191 → 190).

## Correções de doutrina

- `Q_CENSO` fechada como **`done`**, não `confirmed`: o `kg-radar.sh:542` manda isso literalmente, e
  `statusFactor` **0.1 vs 1.0** decide se uma pergunta respondida some do radar ou fica em 5º lugar
  para sempre — o dano que o nó vizinho `E_A_ATENCAO_NAO_PROTEGE_CONTRA_MORTE` descreve.
- `C_DISSENSO` tinha **flip nu**: `status: confirmed` com o label ainda terminando em *"Fica
  DRIFTED"*. O label foi reconciliado com a medição de hoje.
- `D_CENSO` ganhou `drive_kind: decision` — sem ele o censo o rotearia para **execução**, não para
  *propor a chamada*, contradizendo o próprio checkpoint.

## O que fica aberto e é do maestro

`D_CENSO_VIRA_AMOSTRA_ESTRATIFICADA` (`open`). ⚠️ **Não é soberana**: a mesma pergunta já existe
aberta em `kg-freshness-dogfood-2026-08` como `Q_CENSO_DOS_63_CORTADOS`, com o mesmo gatilho. O
radar não cruza arquivos — **feche uma das duas, não ambas.**

## Gate mecânico

- `kg-radar.sh --integrity --schema` → **exit 0** (20 nós, 21 arestas)
- `kg-realign-project.sh --check` → **ALINHADO** (agg 0.0)
- `docs/backlog.md` regenerado — REGRA 62 em dia
