---
date: 2026-07-18
instance: onion-evolve
type: observation
classification: collective
tags: [runtime, backlog, boundary, sovereign-engine, quality, trilha]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "RE-TESTADO 2026-09-26: ITEM2 e S4 estão FEITOS (medidos por execução, ver ## Re-teste). O que resta é a Trilha-no-KG (dogfood-gated) e os C-gated, cada um com gatilho próprio — nenhum é 'retomar fresco', são esperas."
review_after: 2026-12-26
conflict_class: static
---

## Signal
**O runtime autônomo DRENOU o backlog seguro-autônomo** — 8 merges numa sessão (contrato · reconcile · federation-radar
· outbox-self-heal · adopt-S3B · diário · breadcrumb-doctrine · transporte). O que sobra **NÃO é seguro de fazer
autônomo no fim de uma maratona**, e nomeá-lo é a Trilha pra a próxima sessão não re-tentar cego:
- **Delicado-core (editar motor soberano):** ITEM2 (warn no `kg-radar.sh`) · S4 (`/meta:kg map` paralelo). A própria
  doutrina absorvida do granaai (*validador soberano confiável*) proíbe tocar o radar com pressa — bug awk lá
  **false-greena tudo**. `declarado≠verificado` aplicado à MINHA confiabilidade: 100+ turnos = risco de degradação.
- **Gated:** Trilha-no-KG (aresta/campo forward — dogfood-gated pela própria doutrina de breadcrumbs) · C-gated
  (telescope-seal · guardrails-PR2 · create-vertical-F3 · F2.3 · poda do órfão sdaal, que é prune não-`--merged`).
- **Design (validation-pattern candidato):** G1 (downstream pra method-adopter — o marcio-pessoal represado).

## Evidence
- Contrato do runtime: `docs/analysis/onion-adr-autonomous-thread-runtime-2026-07.md` (guarda de parada
  "abort-on-anomaly" + o moat). Migalhas irmãs: `2026-07-18-autonomous-thread-runtime-graduated-ladder`,
  `-self-reinforcing-radar-loop`, `-breadcrumb-doctrine-three-genera`.
- Todo o backlog Nível-0/AUDIT reversível foi conduzido; o `federation-radar` confirma o estado (self-heal 32→15).

## Next crumb
**Parar aqui não é a guarda "max fios" travando — é a doutrina de QUALIDADE** (dogfood honesto: o motor soberano
não se edita por pressa). A próxima sessão: pegar UM item delicado-core por vez, FRESCO, com fixture + selftest +
re-dogfood do radar antes/depois (não-regressão). O ITEM2 já tem o escopo preciso pela doutrina nova: `decision`
sem NENHUMA proveniência (nem aresta `TRACES_TO` nem campo `trace:` inline) = warn advisory, aditivo, não-HARD.


## Re-teste — 2026-09-26 (medido por execução, não relembrado)

A migalha venceu em 2026-09-15 e o `/catch-up` a apontou. A doutrina é **re-testar, nunca
re-carimbar**, então cada item nomeado foi medido contra o vivo:

**ITEM2 — warn de proveniência no `kg-radar.sh`: FEITO, e DISPARA.** Provado com fixture (um
`decision` sem `trace:` e sem aresta `TRACES_TO`):

```
══ PROVENIÊNCIA — decisão ancorada em origem (⚠ atenção, não reprova) ══
  ⚠ decisão-sem-proveniência: D_SEM_PROVENIENCIA (sem aresta TRACES_TO nem campo trace: inline
    — origem não ancorada)
```

Entregue **exatamente no escopo que esta migalha especificou** — "sem NENHUMA proveniência = warn
advisory, aditivo, não-HARD". O `kg-radar.sh` ganhou também um `RULE-sem-trace` irmão para
regra/invariante não ancorada. A cautela desta migalha (*"o motor soberano não se edita por pressa —
bug awk lá false-greena tudo"*) valeu: o warn é aditivo e não toca o veredito.

**S4 — `map` paralelo no `/meta:kg`: FEITO.** `kg.md:250` declara a leva de ~16 documentos com **um
subagente `sonnet`/`medium` por documento, em paralelo**.

**`/meta:guardrails`: NÃO existe** — não há arquivo de comando `guardrails` em
`.claude/commands/meta/` (conferido por listagem, não por memória). Segue gated na
decisão índice-vs-DSL, consistente com o que o registro diz. **`create-vertical` F1–F3: FEITAS**, com
sinal de campo do dogfood de 2026-07-30 no próprio comando; a **F4 (face de design) segue gated**.

**O que sobra, e a re-leitura que o re-teste produziu:** a Trilha-no-KG e os C-gated **não são
"retomar fresco"** — são **esperas com gatilho nomeado**. A redação original tratava-os como fila de
trabalho, e isso convida a próxima sessão a puxá-los sem o gatilho ter disparado. Corrigido no
`next_recommended`.

**Nova validade: 2026-12-26** (90 dias — cadência de item gated, não de ferramenta). O carimbo novo
vale porque houve medição executada; sem ela, a regra manda deixar vencido.
