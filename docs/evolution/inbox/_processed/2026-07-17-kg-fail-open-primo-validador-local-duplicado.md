---
title: 'Signal: kg-radar fail-open — primo confirmado (validador LOCAL duplicado em gramática divergente)'
date: 2026-07-17
from: granaai (consumidor / adopted @ 61a3148299fa)
to: core (onion-evolve)
type: field-signal-fix-validation
flow: upstream (consumidor→core / validação de campo + primo descoberto)
severity: MEDIUM (o fix funciona; mas há um primo que o anúncio não cobre)
---

# Signal — kg-radar fail-open: fix validado + PRIMO (validador local duplicado)

## TL;DR

1. **O fix do fail-open funciona em campo.** Rodamos `/meta:adopt --update` (pin `fb08cc6be4ad → 61a3148299fa`),
   e a guarda de legibilidade **reprovou** o `.kg.yaml` MAPA da granaai (2779 linhas → `exit 1`,
   "gramática não reconhecida"), enquanto o happy-path (LIST válido) segue `exit 0`. Confirmado.
2. **Mas o fix do RADAR não bastou** — a granaai tinha um **segundo validador**, LOCAL, plugado no
   pre-commit + GitHub Actions (`.claude/validation/kg-validate-v2.py`, commitado em `a8d2faa1e`), que
   **reimplementava a gramática MAPA** em Python. Esse é o **primo do fail-open**: um parser duplicado
   em gramática divergente. O fix do radar soberano **não alcança** o gate real do adotante.

## O primo, em detalhe (o achado que vale pro core)

O `kg-validate-v2.py` da granaai parseava nós como **chaves de mapa** (`  id:type:`), arestas com `type:`
na coluna 0, e seções `decisions:`/`validation:`/`stats:` próprias. Quando regeneramos o KG para a
gramática **LIST canônica** (a que o `kg-radar.sh` exige), ele leu **0 nós** e bloqueou.

- **Ironia dupla:** aqui o validador local era **fail-CLOSED** (tinha guarda "PARSE VÁCUO" própria), então
  bloqueou corretamente. Mas isso é sorte de implementação — o ponto estrutural é: **enquanto existe um
  parser duplicado numa gramática divergente, o selo de um lado não protege o outro.** Dois validadores,
  duas gramáticas, uma verdade. Foi exatamente essa duplicação que gerou o falso-verde original (o gerador
  local `kg-ssot-sdaal` emitia MAPA; o radar do core esperava LIST; ninguém batia).

- **Padrão generalizável:** *"adotante que plugou um validador LOCAL de `.kg.yaml` que REIMPLEMENTA a
  gramática = risco latente de falso-verde (ou falso-vermelho na regeneração)."* O anúncio do fix já fala
  "se você plugou o kg-radar.sh num gate, leia isto" — mas quem plugou um validador **próprio** (não o
  radar) fica de fora do alcance do fix.

## Cura aplicada na granaai (proposta de doutrina p/ o core)

Reescrevemos o `kg-validate-v2.py` para **DELEGAR** schema+integrity ao `kg-radar.sh` soberano
(subprocess, honra exit code) e manter **só o valor local**: checar que os paths de `evidence:`/`trace:`
dos nós **existem em disco** (o radar não faz isso). Fim do parser duplicado.

**Sugestão ao core:** o anúncio/doutrina do fix poderia recomendar explicitamente:
> *"Se você tem um validador LOCAL de `.kg.yaml` (pre-commit/CI), faça-o DELEGAR ao `kg-radar.sh` — não
> reimplemente a gramática. Um parser local é a superfície onde o falso-verde volta."*

## Notas menores

- **`--update` deixou `docs/onion/inventory.md` stale** → o lint HARD bloqueou o 1º commit. A Fase 3 da
  adoção regenera o inventário, mas o `--update` não. Talvez o `--update` devesse regenerar (ou avisar).
- **Dogfood de sucesso (contraste com o falso-verde):** regeneramos o KG da granaai em LIST canônica
  (157 nós, 332 arestas), com **drive-to-verify** de 14 agentes via Workflow nativo (157/157 traces
  existem no monorepo vivo; 156 substanciados; 1 fraco: `entity:payment`, sem model Payment direto no
  prisma). Todos com `verified_at` → radar **full green de verdade** (schema ✅ · integrity ✅ · freshness ✅).
  Decisão de modelagem: **remap fiel** (cartografia de arquitetura → enums canônicos, ontologia original
  preservada em `arch_type`/`arch_rel`), não domain SSOT — este fica em aberto como `layer: domain` futuro.

## Ação sugerida no core
- Considerar a nota de doutrina "validador local deve delegar ao radar" no anúncio/KB do fail-open.
- Avaliar se `--update` deve regenerar o inventário (ou avisar sobre a staleness).
