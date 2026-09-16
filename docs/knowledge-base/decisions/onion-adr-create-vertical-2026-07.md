---
title: "ADR — /meta:create-vertical: generalizar o padrão hub-onion para scaffoldar verticais de projeto"
date: 2026-07-14
type: adr
status: accepted — ratificado pelo maestro 2026-07-14 (4 decisões fechadas); F1 é o próximo passo, nada implementado ainda
decision-scope: meta / scaffolding / vertical-hub pattern / adoption
supersedes: none
related:
  - ../evolution/inbox/_processed/2026-07-13-vertical-hub-pattern-e-ingestao-multimidia.md
  - ../evolution/inbox/_processed/2026-07-14-branch-model-provisionamento-design-vertical.md
  - onion-adr-adopt-vendor-branch-merge-2026-07.md
  - onion-f1-spike-adopt-domain-profile-2026-07.md
---

# ADR — `/meta:create-vertical`: generalizar o padrão hub-onion

## Contexto

Dois sinais de campo de um adotante (dogfood de uma vertical-cliente) pediram ao core que
promova a **1ª classe** um padrão que ele replicou **à mão** a partir do DNA do próprio `onion`:

- **A1** — "vertical de projeto" = **hub homônimo + help contextual + resolver de SSOT/book + bootstrap**.
- **B3** — face de **design** acoplada (skill de marca + onboarding auto-guiado).

Triagem do core (2026-07-14): **feature grande → design-first**; A1+B3 são a mesma ideia. Hoje **todo adotante
reinventa o DNA do `onion` à mão** — é o gap.

Este ADR é o **design pass** (não implementação), fundamentado em duas explorações do código atual.

## Insight central (evidência)

**3 dos 4 ingredientes do "vertical-hub" já existem no core como padrões replicáveis.** `/meta:create-vertical`
é majoritariamente um **gerador que instancia moldes existentes** + um **orquestrador fino que compõe os
`create-*`** (mesmo espírito fino-delega de `create-command`/`create-skill`/`create-agent`), NÃO uma reescrita.

| Ingrediente | Molde que JÁ existe (reusar) | Anti-padrão a evitar |
|---|---|---|
| **hub-orquestrador** | trio `onion`: `.claude/skills/onion/SKILL.md` (roteador que lê estado ao vivo + deriva da SSOT viva `docs/onion/inventory.md`), `.claude/commands/onion.md`, `.claude/agents/meta/onion.md` | o **agente** `onion.md` embute inventário **hardcoded e defasado** (auto-admitido) — o gerador deve derivar do inventário escaneado, nunca embutir listas |
| **help-contextual** | `.claude/commands/engineer/help.md` + `git/help.md` (markdown declarativo: entrega→tabelas→troubleshooting→ponteiro-SSOT, ciente de prefixo-por-instalação) | `docs/help.md` (geração antiga: script bash gigante de `echo`) — não copiar |
| **resolver-de-SSOT** ("book") | **PRONTO e TRIPLICADO**: `.claude/skills/onion-{engineering,product,compliance}-context/` — separação Tipo A/B, cadeia de resolução ordenada, bootstrap gated, "nunca inventar", contrato SSOT-mínimo | — (é literalmente "preencha o molde") |
| **bootstrap** | Fase 3 do `.claude/commands/meta/adopt.md` (scaffold de contextos + `CLAUDE.md` never-clobber + inventário) + `.claude/utils/adopt/*.sh` (write-stamp, durable-commit, hooks) + Contrato de Segurança (dry-run/never-clobber/idempotente) | — |

## Decisão 1 — reconciliar as DUAS acepções de "vertical"

O core já usa "vertical" com um sentido: **plugin empacotado de uma DIMENSÃO** (engineering, product, testing…).
O sinal usa outro: **projeto-cliente scaffoldado com hub próprio**. São **a mesma máquina, sujeitos
diferentes**:

> O padrão **vertical-hub** (hub + help-contextual + resolver-de-SSOT + bootstrap) aplica-se tanto a uma
> **dimensão do framework** (engineering) quanto a um **projeto-cliente**. As verticais próprias do
> Onion são só as **instâncias-dogfood** desse padrão. `/meta:create-vertical` gera o padrão para **qualquer
> sujeito**.

Isso evita colisão de nome sem inventar conceito novo: uma "vertical" é sempre `hub + help + book + bootstrap`;
o que muda é se o sujeito é uma dimensão interna ou um projeto externo.

## Decisão 2 — um comando NOVO, fino-orquestrador (não estender `adopt`)

`/meta:create-vertical` é um **comando meta orquestrador** (padrão fino-delega), que:
1. chama os `create-*` existentes para os artefatos (comandos/agentes/skills/KB) — reuso, não reimplementação;
2. invoca um **novo `bootstrap-new-project.sh`** para o que falta (hub homônimo + help parametrizado + book-resolver);
3. **reusa a lógica da Fase 3 do `adopt`** para contextos/`CLAUDE.md` never-clobber/inventário (idealmente
   **extraindo-a para um helper compartilhado** em vez de duplicar);
4. opcionalmente materializa manifesto + plugin (`assemble-plugin.sh`) + `marketplace.json` + registro em `roles.yaml`;
5. fecha com `/meta:inventory` **uma vez** (fragmento `inventory-sync-after-create`) + lint (Regras 8/19/20/role_bundle).

**Por que não estender `adopt`:** `adopt` é *cópia-de-framework + carimbo* num repo existente; `create-vertical`
é *geração de estrutura-de-projeto com identidade própria*. Fronteiras distintas (a mesma diligência que separou
adopt de recover). `create-vertical` **compõe** `adopt` (reusa a Fase 3), não o substitui.

## Decisão 3 — o hub é gerado do INVENTÁRIO VIVO, nunca hardcoded

O gerador deriva a matriz de roteamento do hub a partir do inventário escaneado (`inventory.sh`) + descrições
dos comandos do namespace — **corrigindo de saída o débito de hardcoding** do agente `onion.md`. Regra: o
vertical-hub gerado nunca embute contagens/listas; deriva da SSOT (é o modelo da *skill* `onion`, não do agente).

## Mapa COMPOR vs NOVO

**COMPOR (reuso):** os `create-*` (via specialists) · templates `common/templates/*` + substituição `{{placeholder}}`
(padrão do `create-abstraction`/`.tpl`) · Fase 3 do adopt (contextos/CLAUDE.md/inventário) · `write-stamp.sh` ·
`assemble-plugin.sh` + manifesto + `marketplace.json` + `roles.yaml` · sync final `/meta:inventory` + lint.

**NOVO (ausente no core):**
1. `bootstrap-new-project.sh` + template de hub parametrizado (hoje só no repo consumidor) — o coração do A1.
2. Gerador da **skill-hub homônima** (router + gestão/validação de SSOT-book, "mostra antes de salvar, nunca inventa").
3. **Help contextual parametrizado** por vertical como template gerável.
4. **Resolver de book/SSOT genérico** — o análogo dos `*-context`, parametrizável p/ qualquer domínio.
5. **Gerador de `.claude-plugin/marketplace.json`** — resolve o sinal **A3** (adoções falham o próprio lint por
   ausência dele; core tem `assemble-plugin.sh` mas não o gerador do marketplace.json).
6. Face de **design** (sinal B3): skill de marca + onboarding auto-guiado — **fase separada**, gated.

## Faseamento (doutrina Onion: helper testável → fiação → campo)

- **F1 — helpers testáveis:** `bootstrap-new-project.sh` (hub+help+book-resolver) + gerador de
  `marketplace.json` + `scaffold-book-dir.sh` (dir do book/SSOT); cobertos por `lint-selftest.sh`.
  **Correção de eixo (2026-07-14, na execução):** o ADR previa *extrair* o scaffold da Fase 3 do adopt como
  sub-rotina compartilhada. A investigação mostrou a sobreposição **mais fina** que o assumido — o núcleo do
  create-vertical (hub+help+book) é o `bootstrap`, e a Fase 3 do adopt é majoritariamente **prosa de
  adoção-de-repo** (skeleton do `CLAUDE.md`), não de criar-vertical; o determinístico extraível era ~2 linhas.
  Logo o **refactor do adopt fica DEFERIDO** (alto-risco/baixo-retorno num comando sensível): o create-vertical
  usa o próprio `scaffold-book-dir.sh`, e o adopt pode adotá-lo quando for aberto de novo (risco menor, momento certo).
- **F2 — fiação:** o comando `/meta:create-vertical` orquestrando os `create-*` + os helpers de F1 + sync/lint.
- **F3 — campo (dogfood):** rodar num projeto real descartável; idealmente o gustavo re-dogfooda o a vertical-cliente com a
  ferramenta de 1ª classe (fecha o loop com a origem do sinal).
- **F4 — face de design (B3), gated:** skill de marca + onboarding auto-guiado no bootstrap. Separado.

## Decisões ratificadas (maestro, 2026-07-14)

1. **Nome:** **`/meta:create-vertical`** (fiel ao sinal; a Decisão 1 sustenta).
2. **Sujeito:** **ambos os modos** — gera in-place num repo existente **e** um projeto novo do zero (flag/detecção).
   Cobre o caso do gustavo (repo-cliente existente) e greenfield.
3. **Empacotar-como-plugin:** **opcional via flag** — por padrão gera só a estrutura (hub+help+book+bootstrap);
   com `--plugin`, materializa manifesto + `assemble-plugin.sh` + `marketplace.json` + `roles.yaml`. Não impõe o
   Capability Contract (Regras 19/20) a quem só quer o hub.
4. **Face de design (B3):** **depois** — **F4 gated**, separada do núcleo (F1-F3).

**Próximo passo = F1** (helpers testáveis: `bootstrap-new-project.sh` + gerador de `marketplace.json` + extração do
scaffold-de-um-vertical da Fase 3 do adopt; cobertos por `lint-selftest.sh`). Nada implementado ainda.
