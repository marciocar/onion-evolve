# Onion Evolution Backlog — 2026-07-08 (escopo dirigido)

## 0. Sumário
◆ **Escopo**: dirigido (não as 10 dimensões) — durabilidade da entrega das **Camadas 2+3** pelo `/meta:adopt`.
◆ **Origem**: sinal `inbox/2026-07-08-proposta-branch-onion-vendor.md` (follow-up 1 da co-evolução) + incidente de campo (rhilo-metagamify, KVM 8).
◆ **Padrão**: investigação focada no contexto principal (evidência citada `arquivo:linha`); read-only — a única escrita é este relatório.
◆ **Achados**: 4 (1 🔴 · 2 🟡 · 1 🟢) — mesma causa sistêmica.

> **Camada 1 (plugin/marketplace) fora de escopo** — já resolvida (durabilidade via auto-update de plugin). Este relatório ataca só o que o plugin **não** cobre: docs L2 endereçados por path + variantes/governança L3, entregues pelo `/meta:adopt`.

## 1. Backlog priorizado

| # | Sev | Achado (evidência) | Padrão (doutrina) | Alvo | Esforço | Comando de execução |
|---|-----|--------------------|-------------------|------|---------|---------------------|
| 1 | 🔴 | **Apply é cópia-por-cima e o commit é passo MANUAL no relatório** — `cp -R "$TMP"/. "$DEST"/` (`adopt.md:89`) materializa L2+3 na working tree, mas commitar é o "passo 2 (NO ALVO)" do relatório (`adopt.md:229-233`). Entre o `cp` e o commit humano, um **descarte de working-tree** (`git restore`/`git checkout -- .`/`reset --hard`/remoção de worktree) apaga tudo — inclusive revertendo o `.onion-version` (incidente-fonte). **Verificado por dogfood 2026-07-08:** `git checkout` de branch simples NÃO descarta tracked sujo (carrega/bloqueia) — o gatilho é o descarte, não a troca de branch. | durability-gap → **materializar-como-objeto-git** | `.claude/commands/meta/adopt.md` | S–M | revisão do `/meta:adopt` (Edit do comando) |
| 2 | 🟡 | **Apply devia ser merge de vendor-branch (conflito-awareness), reconhecido como futuro** — "Merge 3-way automático … é melhoria futura" (`adopt.md:103-104`). Cópia-por-cima faz a customização local do adotante virar "diff a revisar" (clobável), não conflito git real. | copy-over → **git-native-merge** (never-clobber estrutural) | `adopt.md` + doutrina `docs/applying/` | L | `/product:spec → /engineer:plan` |
| 3 | 🟡 | **`.onion-version` reverte silenciosamente no checkout** — a identidade (pin/role) é uma linha na working tree, não um objeto commitado, então some junto com a instalação uncommitted (incidente). Corolário do #1: com auto-commit, não acontece. | identidade-git-durável | `adopt.md` (Fase 5 stamp) | S | coberto pelo #1 |
| 4 | 🟢 | **O relatório de `--update` podia OFERECER o commit como ação executável** — hoje o passo 2 é prosa ("Commitar a atualização…", `adopt.md:230`). Se o #1 não for auto, ao menos entregar o comando pronto (`git add …; git commit --no-verify -m "chore(onion): update pin <PIN>"`). | shed-ceremony → ação-executável | `adopt.md:228-234` | S | coberto pelo #1 |

## 2. Achados por dimensão
Escopo dirigido — sem varredura D1–D10. Todos os achados caem em **D6 (moderna vs legada — fragilidade de entrega)** por natureza.

## 3. Alerta transversal (causa sistêmica)
Os 4 achados têm **uma causa só**: a entrega L2+3 **não é um objeto git até um ato humano pós-cópia**. A L1 já é durável (plugin = dependência versionada com auto-update); a L2+3 herdou o modelo copy-over-working-tree, frágil por construção.

**Redução de superfície (contexto 2026-07-08):** o piloto de **SSOT-context + KB embarcado** (`feat/plugin-ssot-context`) tira parte da L2 do caminho do adopt — o KB de framework (tipo A) agora viaja no plugin. Mas **não fecha** o gap: meta-specs endereçadas por path + variantes L3 seguem via `/meta:adopt`.

## 4. Recomendação de execução (ordem)

1. **Agora (fix mínimo, fecha o incidente) — Achado #1**: ao fim do install/`--update`, o comando **auto-commita** a instalação num branch dedicado (ex.: `chore/onion-resync` ou `onion/update-<pin>`), com `git commit --no-verify` (worktree legacy sem node_modules) e mensagem estampando o pin. Never-clobber intacto (commit só materializa o que já foi aplicado+revisado; não faz merge). Absorve os Achados #3 e #4.
2. **Depois (evolução estrutural) — Achado #2**: `--update` = **merge/rebase de uma vendor-branch** `onion/framework`.
   - **Caveat do sinal (não ignorar)**: a vendor-branch **não** se usa direto — o Claude Code lê `.claude/` da working tree do branch atual; trocar pra ela perderia o código de produto. Ela é **fonte-de-merge**; o framework ainda precisa estar presente na working tree do branch de integração (develop/main). Modelo = vendor-branch-como-fonte-de-merge, não branch-que-se-usa.

## 5. Invariantes respeitadas
- **`/meta:adopt` fica** (canal L2+3 + fallback L1 p/ regulados/air-gapped/sem-Enterprise) — coexistência por camada, não substituição (ADR exchange-unit).
- Nenhuma proposta funde fases de workflow faseado.
- Read-only: nenhuma mutação em `.claude/`; única escrita = este relatório.

## 6. Próximos passos
- **#1** → revisão do `/meta:adopt` (Edit do comando) — pode virar uma feature curta.
- **#2** → `/product:spec` do vendor-branch-merge → `/engineer:plan`.
- Relacionado à família **declarado ≠ verificado** (o pin "declarado" no `.onion-version` não estava "verificado" como objeto git durável).
