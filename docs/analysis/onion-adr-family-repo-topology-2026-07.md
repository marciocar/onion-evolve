---
title: 'ADR — Topologia de repositórios da família Onion: core selável + doors + apps'
date: 2026-07-19
type: adr
status: aceito (F0-F1 doutrina; F2+ execução gated fora deste worktree)
decision-scope: meta / família-onion / distribuição / topologia-de-repos
supersedes: none
extends: onion-adr-claude-door-topology-2026-07.md
resolves: onion-adr-claude-door-topology-2026-07.md (D2 — em favor de B via adopt)
deciders: maestro + sessão de investigação (rescue-adopters-core-vs-hub)
context_freshness: 2026-07-19
related:
  - docs/knowledge-base/concepts/public-door-vs-private-core.md (a doutrina que este ADR estende)
  - docs/knowledge-base/concepts/source-vs-derivation.md (fonte≠derivação — "uma só fonte")
  - docs/evolution/rfc/rfc-0004-a2a-live-interop.md (single-source p/ identidade/contratos)
  - docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md (tiers de federação)
  - docs/analysis/onion-adr-mini-distillation-2026-07.md (destilação federada — o outro modo)
  - .claude/utils/marketplace/roles.yaml (mapa role→bundle — o recorte por papel)
---

# ADR — Topologia de repositórios da família Onion

> **Status: ACEITO (2026-07-19).** F0-F1 (doutrina/taxonomia) decididos aqui; F2+ (nascer os repos
> públicos, extrair site/hub) são execução **gated**, fora deste worktree, sob gate do maestro.
> Este ADR **resolve** a D2 pendente do [door-topology ADR](onion-adr-claude-door-topology-2026-07.md).

## Contexto

`onion-evolve` é hoje um **monólito privado**: o core do framework (`.claude/`), a memória de evolução
privada (diário, `docs/evolution/`, `docs/analysis/`, ledger de federação, sessions, os `.kg.yaml`) **e**
artefatos de runtime (o subdir `site/`, referências a bridge/app) coabitam. A investigação
[door-topology](onion-adr-claude-door-topology-2026-07.md) achou (verificado ao vivo) o colapso
`onion-claude` ≡ `onion-evolve` (redirect privado) + a vitrine congelada em 2026-06-04.

O maestro decidiu **desmembrar a família em repos próprios**, mantendo `onion-evolve` como **core
completo e privado, selável**, e propôs o mecanismo: **"adotar pastas vazias como novo projeto"**
(dogfoodar `/meta:adopt`). Decisão de forma: **híbrido por tipo de repo**.

A pergunta central — *"cada repo derivado leva uma fatia do SSOT e os KGs correspondentes?"* — é
respondida pela doutrina existente (D3 abaixo): **não como fatia de SSOT** (isso criaria segunda fonte),
mas como **derivação que cita**, keyed ao tipo de repo.

## Decisões

### D1 — Taxonomia: 4 tipos de repo, 1 mecanismo cada (aceito)

| Tipo | Repos | Nascimento | Sync core→repo |
|---|---|---|---|
| **Porta de framework** | `onion-standalone` ≡ `onion-claude` | **adopt pasta-vazia**, role-scoped ao bundle `standalone` (sem meta-factory) | `/meta:adopt --update` (vendor-branch 3-way) |
| **Meta/vitrine** | `onion-hub` | adopt (só `.claude/` como tooling) + narrativa autoral | regen da narrativa (deriva da identity KB) |
| **Destilação curada** | `onion-mini` (feito), `onion-personal` | reescrita curada — **nunca** vendoriza `.claude/` | co-evolução curada (à mão) |
| **App de runtime** | `onion-bridge` (feito), `onion-site`, `onion-app`, `onion-personal-app` | split como repo-fonte próprio | nenhum — consome um SSOT em runtime / deploy puro |

### D2 — Resolve o door-topology D2 em favor de **B via adopt** (aceito)

A porta pública Claude **não** é um espelho read-only destilado (a formulação original de D2-B); é uma
**instância adotada** (`/meta:adopt` role-scoped numa pasta vazia). `onion-standalone` é o repo público
adotável; `onion-claude` = **mesmo código** (mirror/alias), e o redirect atual `onion-claude`→core-privado
**re-aponta para a standalone pública** — o que desfaz o colapso. Isso reusa a maquinaria provada
(`/meta:adopt --update`, `vendor-branch.sh`, `pin-integrity-check.sh`), sem pipeline novo.

### D3 — Como a doutrina/SSOT/KG particiona (aceito — o invariante do split)

**Nenhum repo derivado leva uma fatia do SSOT como segunda fonte** — vetado por
[RFC-0004](../evolution/rfc/rfc-0004-a2a-live-interop.md) (single-source p/ identidade/contratos; só o
**destilado** circula, nunca o repo bruto) + [`fonte ≠ derivação`](../knowledge-base/concepts/source-vs-derivation.md)
(litmus: "se a fonte muda, edito em UM lugar"). Cada repo leva **derivação que cita**:

- **Doors de framework:** o recorte **operacional** — as KBs empacotadas nos verticais do bundle
  `standalone` ([`roles.yaml`](../../.claude/utils/marketplace/roles.yaml): engineering/product/testing/docs),
  com proveniência (`tree_sha`/pin) que **cita** o core. **Não** levam meta-factory, KBs de auto-análise,
  memória privada de evolução, nem os KGs.
- **Destilações:** doutrina **reescrita** (essência destilada), não KBs verbatim.
- **Hub:** a **narrativa** (derivação da identity KB). **Apps:** **zero** doutrina.
- **KGs (`.kg.yaml`):** ficam no core (privados — a autobiografia do core; só destilado circula). Um door
  que investigue gera seus **próprios** KGs locais, **soberanos** (como o KG privado da granaai que "nem o
  core lê") — nunca uma fatia do core.

### D4 — Selar a fronteira do core (aceito)

O que um door de framework **recebe** = o bundle `standalone` via `resolve-role-bundle.sh`. O que **nunca
sai** do core: a **meta-factory** (`/meta:create-*`, `/meta:adopt`, `/meta:federation-*`, `/meta:evolve`,
`/meta:graph`, `/meta:inventory`), `docs/evolution/`, `docs/analysis/`, o diário, `sessions/`, e os
`.kg.yaml`. Isso já está codificado em [`roles.yaml`](../../.claude/utils/marketplace/roles.yaml)
("a meta-factory nunca é plugin — nenhum grupo a recebe") — o selo reusa esse recorte, não inventa outro.

### D5 — Mecanismo manual-first; automação gated (aceito)

O gap real (convergência dos exploradores): o core sabe **empacotar** verticais in-repo (`assemble-plugin.sh`)
e **ser adotado** (pull), mas **não** sabe **empurrar** um bundle para um repo git público externo. A ideia
do maestro resolve isso **manual-first, sem tooling novo**: repo-door vazio → `/meta:adopt` role-scoped →
commit → push. A automação (`.claude/utils/marketplace/project-door.sh`: assemble-por-papel→push com
drift-guard) é **`gated-until-trigger`** — nasce só quando ≥2 doors provarem o padrão.

## Consequências

- **Selar o core é compatível com a doutrina** (o core já é privado/Claude-Code-only/não-distribuído; RFC-0004
  veta 2º `role: source`). O que muda: **a porta pública passa a ser obrigatória** — adoção externa não pode
  depender de acesso ao core (`porta ≠ core`).
- **O único elo que "selar" rompe é o cold-adopter externo** (`Q_COLD_ADOPTER`, aberto). Adotantes locais
  que vendorizam do core vivo (granaai/pulse-mais/metagamify/gustavo-pulga) estão corretos por design.
- **O split não exige doutrina nova de particionamento** — `assemble` + `roles.yaml` já sabem recortar a
  doutrina por door. Só falta o push externo (D5), gated.

## Rampa (PFR — retomável)

| Fase | O quê | Estado |
|---|---|---|
| F0 | Ratificar topologia (este ADR) + doutrina `porta≠core` (§tipos de repo) | ✅ 2026-07-19 (este worktree) |
| F1 | Selar a fronteira (D4) — escrito; reusa `roles.yaml` | ✅ 2026-07-19 (doutrina) |
| F2 | 1ª porta `onion-standalone` (≡`onion-claude`): adopt role-scoped → push; re-apontar redirect; registrar em members.yaml (pin verificado) | ⏳ gated (repo público, fora da árvore) |
| F3 | `onion-site`: extrair `site/` p/ repo próprio (⚠️ webroot mistura 3 fontes — cuidado com `rsync --delete`) | ⏳ gated |
| F4 | `onion-hub`: des-congelar + re-narrar (deriva da identity KB) | ⏳ gated |
| F5 | Automação `project-door.sh` (assemble→push + drift-guard) | ⏳ gated (≥2 doors provarem o padrão) |
| F6 | 5 portas de plataforma (cursor/codex/copilot/zed/antigravity): registrar + des-congelar por destilação | ⏳ gated |
| F7 | `onion-personal`: destilar o método pessoal (molde Mini) em repo próprio; dado soberano (D6) | ⏳ gated |
| F8 | apps: `onion-app` (produtizar bridge sobre o core) + `onion-personal-app` (materializar `discuss/onion-pessoal-app`) | ⏳ gated |

## D6 — `onion-personal` e os dois apps (resolvido 2026-07-19)

### `onion-personal` = destilação curada do MÉTODO pessoal (tipo destilação, molde Mini)
Produtiza o método provado na pesquisa `onion-pessoal-marcio` (Company Brain N=1, KG SDAAL para uma
pessoa). A [P3](../discussions/onion-pessoal-marcio/03-fronteira-core.md) já cravou a fronteira:
**"membro adotante pelo MÉTODO, soberano no DADO"** — privacidade ≠ sair da federação. Logo:
`onion-personal` (produto) **destila o método** (como o Mini destila o framework); **nunca vendoriza
`.claude/`**; o **dado bruto de cada usuário fica soberano/privado** (nunca sobe). Distinto do membro
`marcio-pessoal`, que permanece o **braço de pesquisa/dogfood N=1 privado** (prova o método, não é o produto).

### Dois apps = duas superfícies de runtime sobre dois SSOTs
- **`onion-app`** = o **bridge produtizado sobre o core** — lê `onion-evolve` ao vivo (`ONION_CWD`), como
  `app.onionevolve.com` já faz. O `onion-bridge` é o embrião; `onion-app` é o produto. **Sobre o core, não
  sobre a porta pública** (decisão do maestro 2026-07-19).
- **`onion-personal-app`** = o app companheiro **sobre o grafo pessoal soberano** (`~/onion-pessoal`). **Não
  é greenfield** — já tem a branch de pesquisa `discuss/onion-pessoal-app` (4 pesquisas + ADR-001 + "git
  FICA o SoT" + compat 25/25).

Ambos são **tipo app de runtime**: janelas sobre um SSOT distinto (framework vs cérebro pessoal), sem
carregar doutrina — consomem o SSOT ao vivo.

## Referências

- Doutrina estendida: [`public-door-vs-private-core.md`](../knowledge-base/concepts/public-door-vs-private-core.md) · [`source-vs-derivation.md`](../knowledge-base/concepts/source-vs-derivation.md)
- ADR resolvido: [`onion-adr-claude-door-topology-2026-07.md`](onion-adr-claude-door-topology-2026-07.md)
- Outro modo: [`onion-adr-mini-distillation-2026-07.md`](onion-adr-mini-distillation-2026-07.md)
- Single-source: [`rfc-0004-a2a-live-interop.md`](../evolution/rfc/rfc-0004-a2a-live-interop.md) · tiers: [`rfc-0003-federated-identity-collective-intelligence.md`](../evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md)
- Maquinaria: [`roles.yaml`](../../.claude/utils/marketplace/roles.yaml) · `resolve-role-bundle.sh` · `assemble-plugin.sh`
