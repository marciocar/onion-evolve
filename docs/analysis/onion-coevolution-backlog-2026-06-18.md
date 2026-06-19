---
title: 'Backlog de co-evolução — pendências em aberto (jornada de 2026-06-18)'
date: 2026-06-18
type: evolution-backlog
status: aberto
origin: sessão de co-evolução (inbox triage + /meta:adopt --update fix #99)
---

# Backlog de co-evolução — o que ficou em aberto (2026-06-18)

> Snapshot consolidado das pendências ao fim da jornada que entregou o #97 (robustez do harness) e o #99
> (`/meta:adopt --update` idempotente). Itens datados; números são divergentes-de-snapshot por design
> (`type: evolution-backlog` isenta do lint de contagem). Para retomar: ler este doc + `git log`.

## Entregue nesta jornada (contexto)

- **#97** — pre-commit roda o self-test condicional + fixtures r16 derivam da SSOT (sinal `selftest-harness-robustness`, _processed).
- **#99** — `/meta:adopt --update` re-aplica os passos install-only via "Procedimento de Configuração
  pós-cópia (idempotente)" + helper testável `merge-onion-hooks.sh` + `lint-selftest.sh kind=merge`
  (sinal `adopt-update-skips-phase3`, arquivamento no **#100**).
- Trio "you have mail" verificado implementado/mergeado/funcional (sinal `session-start-inbox-hook-pattern`, _processed).

---

## Pendências priorizadas

### 🟢 Mecânico / rápido

1. **PR #100 — arquivar a #2.** Move `adopt-update-skips-phase3-steps.md` → `_processed/`. Aberto; só falta
   merge. Decisão do maestro (merge na default branch).
2. **#3-c — warm-up aponta para `evolution/inbox`.** O sinal `co-evolution-not-distributed-by-adopt` está
   **parcialmente resolvido**: 3-a (starter `docs/evolution/` no adopt) feito pelo #95; **3-c segue aberto**
   — nenhum dos 3 warm-ups (`warm-up.md`, `product/`, `engineer/`) menciona o inbox. Trivial: reusar
   `co-evolution-inbox-check.sh` (silencioso se vazio). Ao fechar, mover a mensagem #3 para `_processed/`.

### 🟡 Decisão de apetite (carrega dívida embutida)

3. **#1 — `--integration-branch` no `/meta:adopt`** (`adopt-gitflow-develop-branch-config`, já versionado).
   `git config gitflow.branch.develop` é local da máquina → exige persistir a escolha versionada
   (`.onion-version`, campo `integration_branch`) + reconstruir a config local (candidato: warm-up do alvo).
   **Pré-requisito não-óbvio:** o schema do `.onion-version` (`architecture.md §6.1`) **não tem lint
   determinístico** — adicionar `integration_branch` ficaria desprotegido. Fechar o #1 bem implica primeiro
   estender o lint para validar o schema do stamp (+ fixture). O placeholder do passo (3) do Procedimento
   pós-cópia (`adopt.md`) já está marcado para receber isto.

### 🔴 Decisão estratégica (pede pensamento, não execução)

4. **RFC-0002 — veredito profundo da camada de meta-estratégia.** O `rhilo-metagamify` enviou (fluxo B,
   doc-bridge) um **ack** ao handoff `onion-strategy-layer-handoff-2026-06-17.md` — mensagem
   `2026-06-17-veredito-strategy-layer.md`, `status: ack (veredito profundo pendente — RFC-0002)`. O core
   **deve** produzir o RFC-0002 em resposta; nunca foi escrito. É o único item que pede *design*, não
   mecânica. Enquanto pendente, o sinal **permanece corretamente no inbox** (não processar sinal
   não-endereçado).
   - ⚠️ **Higiene:** há um move desse arquivo para `_processed/` **não-commitado no working tree local** (de
     sessão anterior) — prematuro. Na `main` o sinal segue no inbox (correto). Resolução do maestro quando
     for commitar o working tree: descartar esse move até o RFC-0002 existir.

## Dívida técnica transversal

- **`/meta:adopt --update` sem teste ponta-a-ponta automatizado.** O `kind=merge` cobre o *merge isolado*
  do `settings.json`; o fluxo completo do `adopt` roda dentro do Claude Code (não é CLI) → não há harness
  determinístico para o `--update` inteiro. Validação fica manual (repo descartável). Limite conhecido.

## Mapa de dependências

```
#100 (arquivar #2) ── independente, mecânico
#3-c (warm-up)     ── independente, trivial → fecha o sinal #3
#1 (branch config) ── DEPENDE de → lint do schema .onion-version (dívida)
RFC-0002           ── estratégico, sem dependência técnica; destrava o veredito do rhilo
```
