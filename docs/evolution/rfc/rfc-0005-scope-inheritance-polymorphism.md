---
title: 'RFC-0005 — Herança e polimorfismo de escopo (framework → empresa → time → pessoa)'
status: accepted (2026-07-09) — fundamentada em pesquisa orquestrada (scope-inheritance-2026)
canonical-in: onion-evolve (core) — série de RFCs de co-evolução
drafted-in: onion-evolve (2026-07-09)
grounded-in: docs/evolution/research/scope-inheritance-2026/ (SYNTHESIS.md + H1-H4)
relates-to: RFC-0004 (topologia de comunicação — este é o eixo ORTOGONAL de config/conhecimento)
reuses: vendor-branch.sh (Achado #2) · meta:kg (SUPERSEDES) · resolve-integration-branch.sh (precedência) · camadas nativas do Claude Code
---

# RFC-0005 — Herança e polimorfismo de escopo

> **Estado: ACCEPTED.** Decisão **fundamentada em evidência** (pesquisa orquestrada de 4 streams +
> verificação adversarial em `docs/evolution/research/scope-inheritance-2026/`). Onde a evidência foi
> rebaixada (`declarado≠verificado`), está marcado e **não** sustenta a decisão.

## 1. Decisão (headline)

A entrega do Onion (`.claude` + `docs` + agentes + scripts) se herda e polimorfa através de escopos
(**framework → empresa → time → pessoa**) por um mecanismo **HÍBRIDO de três planos ortogonais** — não um só.
**Branch-para-escopo é rejeitado** como herança (não compõe; antipadrão GitOps); branch permanece no eixo
**versão** (`vendor-branch` no tempo). **Versão × escopo são eixos separados.**

## 2. Os três planos (o mecanismo)

| Plano | Superfície | Mecanismo | Fundamentação |
|-------|-----------|-----------|---------------|
| **1. Cognitivo** | `CLAUDE.md`, skills, agentes, contexto SDAAL (`*-context`) | **Cascata-NATIVA do Claude Code** | O Claude Code **já concatena** N camadas (`managed > user > project > local`) + **walk-up por diretório** (raiz→cwd) → **time-dentro-do-repo é nativo**. `H2·F5/F7`, `H1·F3`, `H3·F11`, `H4·F1`. **Cavalgar, não reinventar.** |
| **2. Configuração** | `settings.json` | **Merge-N-camadas** (generalizar `vendor-branch` 2→N; qualidade strategic-merge type-aware) | Assimetria decisiva: `settings.json` **NÃO herda pela árvore** (self-contained por diretório, `H2·F7`) → **é o único gap de engenharia real**. `H1·F4`. |
| **3. Conhecimento/verdade** | claims, decisões, doutrina | **`SUPERSEDES` bitemporal** (KG) — ortogonal ao merge de arquivo | "git merge não reconcilia verdades"; a regra do time supera a do framework sem apagá-la. Zep/Graphiti (`H4·F5`), OPA conflito-explícito (`H1·F12`). |

**Overlays** entram como **modelo de qualidade** do merge (never-clobber por-chave) + **components/mixins**
para o eixo horizontal (verticais opt-in), **não como transporte** (`H1·F5`, `H3·F8`). Requisito transversal:
**resolver de proveniência** estilo `git config --show-scope` (qual camada setou cada valor — `H1·F1`).

**Ranking dos mecanismos:** cascata-nativa > merge-N-camadas > overlays > branches (rejeitado).

## 3. Por que branch-para-escopo é rejeitado (validando a intuição do maestro)

- **Antipadrão GitOps documentado** (fonte primária Octopus/Kapelonis, `H1·F6`): merge de branch propaga config
  indesejada; promoção não é merge simples.
- **Branch não COMPÕE:** herança precisa de **N camadas coexistindo** como função pura de leitura; unir 4
  linhagens = merge 4-way textual **sem proveniência por-chave**. Fica-se em UMA branch por vez — a intuição do
  maestro ("não se fica em 4 branches ao mesmo tempo") **é** o consenso de mercado.
- **Nada no vetor Claude Code modela herança por branch** — o nativo compõe em **runtime** (concatenação) e por
  **precedência de resolução**, não por branch.
- **Branch permanece útil** no eixo ortogonal **versão**: reconciliar o framework no tempo (o 3-way do
  `vendor-branch.sh`, upgrade core→adotante) + servir de transporte/proveniência/ledger.

## 4. Matriz escopo × mecanismo

| Escopo | Versiona | Herda | Sobrepõe | Camada nativa que mapeia |
|--------|----------|-------|----------|--------------------------|
| **framework** | `vendor-branch`/pin (`source_commit`) | — (é a base) | — | vendored `.claude` (onion/vendor) |
| **empresa** | pin de overlay da org | do framework | config/doutrina da org | `managed`/enterprise settings + overlay de org |
| **time** | pin/dir no monorepo | da empresa | contexto/regras do time | **subdiretório** (walk-up) `.claude`/`CLAUDE.md` + `project` settings |
| **pessoa** | dotfiles versionados | do time | preferências pessoais | `user` (`~/.claude/settings.json`, `~/.claude/CLAUDE.md`) + `local` |

Plano **cognitivo** resolve por concatenação/precedência nativa (grátis). Plano **config** exige o merge-N-camadas
(o gap). Plano **conhecimento** usa `SUPERSEDES` (o escopo inferior supera o superior sem apagar).

### 4.1 Adendo (2026-07-10) — "forma de adoção" é dimensão de 1ª classe (ground-truth Grana.Ai)

> Origem: sinal de campo [`2026-07-10-rfc5-docs-only-adoption-ground-truth`](../inbox/_processed/2026-07-10-rfc5-docs-only-adoption-ground-truth.md)
> — no dia seguinte ao aceite desta RFC, o time Grana.Ai materializou em `master` uma **adoção docs-only**
> (PR #1127, Mauricio: *"`.claude/` (capability layer) and `CLAUDE.md` stay OUT of git"*), coexistindo com a
> adoção **full** em `develop`. Escrito do `main` do core com o workstream de pesquisa dormente — a sessão de
> `docs/scope-inheritance-research` deve **reconciliar** este adendo ao acordar.

- **FORMA DE ADOÇÃO** — `full | docs-only | in-place` — é uma dimensão **ortogonal a escopo E a versão**,
  que esta matriz não nomeava. Sem nome, ela **vaza para branch** (`master` docs-only vs `develop` full —
  exatamente o uso de branch que o §3 rejeita). O ground-truth **confirma os 3 planos** (o time separou
  conhecimento→versiona de capacidade→não-versiona) e **valida** a intuição: a escolha existe de fato;
  falta o vocabulário para ela não se expressar por branch.
- **4º modo de proveniência (GATED, a-desenhar): capability-update fora-do-git.** Adotante `docs-only`
  não tem `.claude/` rastreado → não há árvore para o 3-way do `vendor-branch.sh`; o `--update` de
  capability vira **entrega-fora-do-git** (parentesco: doc-bridge/entrega-sem-commit), maestro-gated —
  coerente com regulado/never-live-pull (RFC-0004). **Estoura no 1º `--update` do time Grana.Ai** — desenhar
  antes disso.
- **Role/forma como proveniência no plano config — 1º passo ENTREGUE:** os gates agora polimorfam por
  papel (guarda `role: adopted` nos checks de marketplace do lint, fix de 2026-07-10 + selftest
  `run_adopted_role_selftests`). **Caso geral ENTREGUE (2026-07-10):** proveniência-por-chave via
  `--show-scope` no `compose-settings.sh` (texto + `--json`), com a dimensão role/forma injetada do stamp
  pelo `resolve-scope-layers.sh` — ver `scope-convention-2026.md` Plano 2 e selftest `run_show_scope_selftests`.

## 5. Caso Grana.Ai (concreto)

`granaai` (empresa, regulado) → time `desenvolvimento` → pessoa `mauricio`, num **nx monorepo**:
- **Cognitivo:** o `CLAUDE.md`/skills do time vivem no **subdiretório** do time (walk-up nativo compõe framework
  + empresa + time + pessoa em runtime); zero engenharia nova.
- **Config:** `settings.json` do time/pessoa **gerado** pela composição N-camadas com proveniência (o slice).
- **Conhecimento:** a regra do time supera a do framework via `SUPERSEDES` (auditável — regulado).
- **Auditoria (regulado):** proveniência (`--show-scope`) + CODEOWNERS/branch-protection (`H3`) dizem quem pôde
  sobrepor o quê. Nunca live-pull (herda a invariante do `granaai`/RFC-0004).

## 6. Invariantes

- **Cavalgar o nativo** (non-friction): não reimplementar o que o Claude Code já cascateia.
- **Reuso das 4 bases** (`vendor-branch`, `SUPERSEDES`, precedência, camadas nativas) — não reinventar.
- **Never-clobber** preservado (merge é conflito resolvível, não clobber silencioso).
- **Versão × escopo separados** — branch é versão, não escopo.
- **`declarado≠verificado`** — a decisão só usa achados `confirmed`; caveats de sourcing (`H4·F2/F8/F10`,
  `H1·F8`) marcados na pesquisa, não sustentam nada aqui.

## 7. Faseamento

- **Fase 1 — cavalgar o nativo (baixo esforço, independe de engenharia nova):** documentar/adotar a convenção de
  **subdiretório-por-time** (`CLAUDE.md`/skills do time no dir do time — walk-up nativo) e **user-layer-por-pessoa**
  (`~/.claude`). Zero código; é doutrina + convenção.
- **Fase 2 — o gap real:** **resolver N-camadas + gerador de `settings.json` composto por diretório, com
  proveniência** (generaliza o `vendor-branch`/merge; type-aware strategic-merge). Dogfood-first, no Grana.Ai.
  **✅ ENTREGUE (2026-07-10):** compositor (`compose-settings.sh`) + resolver da cadeia (`resolve-scope-layers.sh`)
  + proveniência-por-chave `--show-scope` (paridade `git config --show-scope`, invariante runtime
  strip==compose, formatos texto/JSON, dimensão role/forma) — gate: `run_compose_settings_selftests` +
  `run_resolve_scope_layers_selftests` + `run_show_scope_selftests`. O dogfood de campo no Grana.Ai real
  (empresa+time+pessoa no nx monorepo) segue como próximo passo de campo, não bloqueia a entrega.
- **Fase 3 — conhecimento:** ligar `SUPERSEDES` de escopo no KG (regra-do-time supera regra-do-framework),
  gated atrás de dogfood.

## 8. Relacionados

- RFC-0004 (topologia de comunicação — eixo ortogonal) · `vendor-branch.sh`/ADR Achado #2 (merge 2→N) ·
  `meta:kg`/`SUPERSEDES` · `resolve-integration-branch.sh` (precedência) · `roles.yaml` (polimorfismo de bundle) ·
  camadas nativas do Claude Code · pesquisa `docs/evolution/research/scope-inheritance-2026/`.
