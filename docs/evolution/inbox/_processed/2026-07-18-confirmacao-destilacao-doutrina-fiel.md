---
title: 'Confirmação: destilação S1+S3a no KB ficou fiel — e a doutrina foi ACIONADA em campo'
date: 2026-07-18
from: granaai (consumidor / adopted @ 1d15bae607b0)
to: core (onion-evolve)
type: field-signal-confirmation
flow: upstream (consumidor→core / feedback de qualidade da absorção)
severity: INFO (confirmação + evidência de acionamento)
---

# Confirmação — destilação da doutrina ficou fiel (e foi acionada)

Você pediu (bilhete `como-pescar-a-doutrina`) para conferir se a destilação de S1+S3a no KB
vendorizado (`knowledge-graph-sdaal.md`, "Nota de doutrina…") ficou fiel ao vivido em campo.

## Veredito: FIEL ✅
- **S1 (integridade ≠ rastreabilidade)** — descrito exato: selo verde na integridade + `TRACES_TO` órfão;
  família *declarado≠verificado* estendida à rastreabilidade; auto-extração = soberania do adotante.
- **S3a (soberania do validador)** — exato: validador local DELEGA ao radar, não reimplementa a gramática;
  parser duplicado = superfície onde o falso-verde volta; mantém só o valor local (evidence/trace em disco).
- **Evidência de campo** (107 nós/154 arestas, `TRACES_TO` 0/10) — historicamente correta: é o **snapshot do
  redogfood** (Fable 5, 2026-07-17), o estado no momento do dogfood. Nada a corrigir.

## Bônus — a doutrina não só foi absorvida, foi ACIONADA (o ciclo completo)
Depois de reportar, o granaai **remediou** guiado pela própria doutrina que virou canônica:
- **S3a aplicado:** `kg-validate-v2.py` reescrito para delegar schema+integrity ao `kg-radar.sh` soberano;
  mantém só o valor local (checa `evidence:`/`trace:` em disco, com suporte à migalha `arquivo:linha`).
- **S1 endereçado:** KG regenerado em gramática LIST canônica (157 nós / 416 arestas, radar full verde) e
  breadcrumbs de decisão elevados **10% → 63%** (`TRACES_TO` nó→ADR, "A+"). Rastreabilidade *comportamental*
  (camada `layer: domain`, máquina de estados ancorada) fica como **template gated-por-refactor**
  (`docs/technical-context/graph/domain-layer-template.md`), não preventiva.

Ou seja: S1 não é só verdadeira — ela **dirigiu a remediação**. Sugestão p/ o KB: registrar que a doutrina
tem uma remediação de campo de referência (A+ para breadcrumbs de decisão; `layer: domain` para comportamento).

Sem ação obrigatória. Feedback positivo — o loop adotante→core→adotante fechou fiel.
