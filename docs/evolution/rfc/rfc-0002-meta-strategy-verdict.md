---
title: 'RFC-0002 — Veredito profundo da camada de meta-estratégia (catálogo-first + reposicionamento)'
status: accepted (catálogo-first aceito como doutrina, materialização diferida; reposicionamento ratificado via distribuição por camadas)
canonical-in: onion-evolve (core) — série de RFCs de co-evolução
re: docs/analysis/onion-strategy-layer-handoff-2026-06-17.md (+ 4 docs irmãos)
responde: docs/evolution/inbox/_processed/2026-06-17-veredito-strategy-layer.md (ack da sala de obra)
date: 2026-06-22
---

# RFC-0002 — Veredito profundo da camada de meta-estratégia

## 1. Contexto e escopo

O handoff de meta-estratégia de 2026-06-17 ([handoff](../../analysis/onion-strategy-layer-handoff-2026-06-17.md)
+ [ADR-draft](../../analysis/onion-strategy-layer-adr-draft-2026-06-17.md) ·
[capability-draft](../../analysis/onion-strategy-layer-capability-draft-2026-06-17.md) ·
[blindspots](../../analysis/onion-strategy-layer-blindspots-2026-06-17.md) ·
[reposicionamento](../../analysis/onion-repositioning-sdaal-session-2026-06-17.md)) propôs **duas teses**.
A sala de obra (`rhilo-metagamify`) deu **ack** e registrou ambas como `assess` no seu radar (blips #9 e #10),
pedindo de volta o **veredito profundo** — este RFC ([ack](../inbox/_processed/2026-06-17-veredito-strategy-layer.md)).
[RFC-0001 §6](rfc-0001-co-evolution-comms.md) o listava como o único item em aberto da série.

Este RFC **julga** (aceitar/rejeitar/ratificar com evidência; validação adversarial é insumo, não ordem).

**Não-objetivos:** materializar o catálogo agora; escrever o ADR formal de reposicionamento ou trocar a
licença; fechar o blocker higiênico do `agent-creator-specialist` (todos → §5, follow-ups).

## 2. Veredito A — catálogo-first / recognition-primed: **ACEITO (doutrina), materialização DIFERIDA**

A tese: dado um objetivo, **reconhecer** contra um catálogo de playbooks (`situação → fluxo → grupo de
ferramentas → sequência`) e **aplicar** (barato); só **deliberar** (fan-out/juízes — caro) quando não há
match, e o resíduo vira novo playbook (o catálogo aprende). Precedente exato: o SDAAL fez isso com integrações.

**Validação adversarial contra o `.claude/` real** (o insumo que o ack pediu):

| Artefato | Reconhece o quê | Sobreposição com catálogo-first |
|---|---|---|
| skill `onion-fleet` / `/meta:fleet` | **forma de trabalho** (independência → fan-out, judge-panel, pipeline) | parcial (~60%) — mas dimensão **diferente** |
| skill `onion-patterns` | convenções estruturais (naming, YAML, limites) | baixa — é doutrina de forma, não de caso |
| `/meta:analyze-complex-problem` | **um** problema (template de análise) | baixa — analisa, não seleciona estratégia |

**Conclusão:** a sobreposição é real mas a distinção é **genuína** — `onion-fleet` reconhece *forma de
orquestração*; catálogo-first reconhece *caso de uso* (`refatorar-feature-legada`, `descoberta→backlog`…).
**Não é redundância** → a doutrina se sustenta.

- **Veredito:** **aceitar catálogo-first como princípio** (recognition-primed > deliberação-first: mais
  barato, auditável, e aprende).
- **Forma de materialização (quando sair da fila):** **estender `onion-patterns`** com uma seção
  "playbooks" (3-5 destilados do que já existe) — **não** skill/comando novo. Como o handoff recomendou.
- **Fila:** **diferida atrás do reposicionamento** (prioridade viva) — barata o bastante para crescer em
  paralelo, mas não passa na frente. Blip #9: `assess` → **`trial`** (doutrina aceita, materialização pendente).

## 3. Veredito B — reposicionamento como produto: **direção RATIFICADA**

A tese (BSL + control-plane sobre Federação + ICP regulado multi-repo) aparentava **contradizer** a
identidade canônica de 2026-05-18 ("framework template em `.claude/`, não produto npm, sem CLI standalone").

**A tensão já foi resolvida — por decomposição** — em
[onion-distribution-strategy-2026-06.md](../../analysis/onion-distribution-strategy-2026-06.md) (2026-06-20):

- **Camada 1** (`.claude/` — commands/agents/skills) → **nativa/open** (plugins, SKILL.md, proveniência SHA).
- **Camadas 2+3** (spec-as-code + Federação) → **moat/control-plane = o produto** (cobra-se pelo hub que
  coordena, não pelo que roda no cliente — open-core clássico; precedentes PostHog/Terraform/Confluent).

A identidade de maio **continua vigente para a camada 1**; o "produto" é a camada 2+3. Não há contradição —
há fronteira.

- **Veredito:** **ratificar** essa direção. O reposicionamento **não** é tese aberta — é decisão de norte tomada.
- **Residual (follow-up, não-bloqueante):** ADR FASE-0 formal (produto-não-consultoria, ICP, modelo
  faseado), `LICENSE` MIT→BSL e versionamento nomeado. Blip #10: `assess` → **`adopt`** (direção escolhida;
  execução faseada por apetite).

## 4. Reconciliação com a sala de obra (downstream)

Os blips #9/#10 vivem no `radar.md` do **`rhilo-metagamify`** (sala de obra), não no core. Este veredito
volta ao adotante por **downstream** (CHANGELOG + `/meta:co-announce` → `inbound/`) para que **ele** mova os
blips (#9→trial, #10→adopt). O core não escreve o radar do derivado (um escritor por repo).

## 5. Em aberto / follow-ups (fora do escopo deste RFC)

- **Materializar o catálogo** — seção "playbooks" em `onion-patterns` (3-5), quando sair da fila. → backlog.
- **ADR FASE-0 de reposicionamento** + `LICENSE` BSL + versionamento nomeado. → backlog (execução por apetite).
- **Blocker higiênico** ([blindspots §3](../../analysis/onion-strategy-layer-blindspots-2026-06-17.md)):
  `agent-creator-specialist` orienta listar ferramentas MCP sem steering SDAAL → novos agentes nascem
  violando API-first. É pré-requisito de higiene para expandir frota — item separado do `/meta:evolve`.

## 6. Decisão (resumo)

| Tese | Veredito | Blip |
|---|---|---|
| Catálogo-first / recognition-primed | **Aceito como doutrina**; materialização diferida (estender `onion-patterns`) | #9 → `trial` |
| Reposicionamento como produto | **Direção ratificada** (distribuição por camadas); ADR/BSL = follow-up | #10 → `adopt` |
