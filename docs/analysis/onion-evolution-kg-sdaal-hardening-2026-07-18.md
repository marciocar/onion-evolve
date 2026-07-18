---
title: 'Backlog de evolução — triagem de 3 sinais KG-SDAAL do granaai'
date: 2026-07-18
type: evolution-backlog
status: aberto
severity: MEDIUM
origin: co-evolução (upstream granaai → core) — 3 sinais de campo triados 2026-07-18
signals:
  - docs/evolution/inbox/_processed/2026-07-17-kg-fail-open-primo-validador-local-duplicado.md
  - docs/evolution/inbox/_processed/2026-07-17-redogfood-kg-sdaal-validation-gaps.md
  - docs/evolution/inbox/_processed/2026-07-17-kg-discovery-granaai-canonical-monorepo.md
---

# Backlog — hardening KG-SDAAL (3 sinais de campo do granaai)

> Triados na sessão de co-evolução de 2026-07-18. Os 3 sinais vêm do adotante **granaai** (upstream),
> todos sobre o sistema KG-SDAAL. **Recalibração-chave (drive-to-verify no core):** o "generator" que os
> sinais citam (`kg-ssot-sdaal`, `kg-validate-v2.py`) é **LOCAL do granaai**, não o core `/meta:kg`. O core
> já tem modo `map <área>` e a gramática já suporta `TRACES_TO`/`CONTROLLED_BY` — o que falta é
> **auto-extração**, que é feature do gerador do adotante. Isso enquadra o que é core vs adotante.

## Itens acionáveis de core

### 1 — 🟢 Nota de doutrina: validador local deve DELEGAR ao radar (alto valor, baixo esforço)
**Origem:** sinal `kg-fail-open-primo` (o "primo" do fail-open). O granaai tinha um 2º validador LOCAL
(`kg-validate-v2.py`) que **reimplementava a gramática MAPA** em Python → o fix do radar soberano **não
alcança** o gate real do adotante. Padrão generalizável: *"parser duplicado em gramática divergente = a
superfície onde o falso-verde volta."* Cura aplicada no granaai: o validador local passou a **DELEGAR** ao
`kg-radar.sh` (subprocess, honra exit code) e manter só valor local (checar que paths de `evidence:`/`trace:`
existem em disco — o radar não faz isso).
- **Ação:** adicionar ao KB/anúncio do fail-open a diretriz: *"Se você tem um validador LOCAL de `.kg.yaml`
  (pre-commit/CI), faça-o DELEGAR ao `kg-radar.sh` — não reimplemente a gramática."*
- **doctrine_pattern:** single-validator-sovereignty · **exec:** `/meta:create-knowledge-base` (update fail-open KB)

### 2 — 🟡 Check de completude de breadcrumbs no kg-radar (médio, bounded)
**Origem:** sinal `redogfood-kg-sdaal`. O KG do granaai passou **integridade técnica 100%** (0 ciclos, 0
órfãos, evidence 100%) **mas** com breadcrumbs SDAAL órfãos: `TRACES_TO` 0/10 (nenhuma decision linkada aos
nós que justifica), `CONTROLLED_BY` 21/45 (audit trail incompleto). **Insight durável p/ o core:**
*integridade técnica ≠ completude de rastreabilidade* — um KG pode selar verde com breadcrumbs órfãos.
- **Ação:** avaliar um **check opcional (warn, não HARD)** no `kg-radar.sh`: avisar quando há decisions com
  0 `TRACES_TO` ou capabilities sem `CONTROLLED_BY` (na camada domain/audit). A auto-**extração** (parsing de
  ADRs/compliance) é do gerador local do adotante, **não** do core.
- **doctrine_pattern:** guard-completeness · **exec:** `/meta:create-command` (kg-radar breadcrumb check)

### 3 — 📎 Case-study / receita de canonicalização de monorepo (docs, baixa prio)
**Origem:** sinal `kg-discovery`. granaai canonicalizou seu monorepo (45 apps, 453 libs, 6 domínios) em
`.kg.yaml` válido via orquestração Workflow (5 scanners paralelos, 171s). `/meta:kg map <área>` **já existe**
(mas domain-SSOT, não canonicalização de monorepo NX). Oportunidade de **receita/case-study**: "canonicalizar
um monorepo NX" (NX scan + RFT + ADR + business + compliance). Verificar se o `map` PFR já roda os scanners em
paralelo (o granaai reporta que a v1 do script deles era sequencial — bug de design corrigido p/ `parallel()`).
- **doctrine_pattern:** case-study · **exec:** `/meta:create-knowledge-base` (receita) — opcional

## Conexão com backlog existente
- **B4 do cluster adopt-update-hardening** (ver `onion-evolution-adopt-update-hardening-2026-07-17.md`): o
  sinal `kg-fail-open-primo` reporta que `--update` deixou `docs/onion/inventory.md` **stale** → lint HARD
  bloqueou o 1º commit. A Fase 3 da adoção regenera o inventário, mas o `--update` não. Adicionado lá como B4.

## Nota de resposta ao granaai (pendente — downstream)
O sinal `kg-fail-open-primo` pede feedback explícito. Ack positivo (fail-open validado em campo) + a nota de
doutrina do item 1 devem voltar via `/meta:co-announce` (human-transported). **Não** executado nesta triagem.
