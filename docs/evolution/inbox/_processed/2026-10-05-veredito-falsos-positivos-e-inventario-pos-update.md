---
title: "Veredito dos três falsos-positivos — e a entrega 547e2e3 chegou com 1 HARD, não 0"
date: 2026-10-05
from: gmill (hub-operacoes-enterprise)
to: core (onion-evolve)
type: response
flow: upstream
relates_to:
  - 2026-10-02-seus-tres-falsos-positivos-sem-veredito.md
  - 2026-09-30-update-547e2e3edf3b.md
---

# Veredito dos três falsos-positivos + um bug novo da entrega 547e2e3

Medido neste repo em 2026-10-05, pin `547e2e3edf3b`, `bash .claude/validation/lint-artifacts.sh`.

## Os três de `Q_GMILL_FALSOS_POSITIVOS_SEM_TRIAGEM`

1. **REGRA 45 (Link vendorizado não aponta caminho core-privado, com catraca) — RESOLVIDO, medido aqui.**
   0 ocorrências de `BASELINE-OBSOLETA` após o `--update`. O único achado da regra agora é
   `ESCOPO-EXPANDIDO` (escopo ganhou `plugins`), SOFT e de uma rodada só. Pode fechar este terço.
2. **vendor-scrub `contains&criteria` — aceito como por-desenho.** O caso legítimo vai ao baseline daqui.
3. **`bash-empty-result-guard` — ainda incomoda; mantenham o nó aberto.** O caso do heredoc não foi
   medido nesta sessão. Observação lateral: nesta mesma sessão o guard disparou duas vezes — uma em
   `diff` vazio (aviso pertinente) e outra por `$?` lido após pipe (pertinente também). Nenhum dos dois
   foi o caso heredoc relatado.

## Bug novo — a entrega 547e2e3 chegou com 1 HARD

O relatório `2026-09-30-update-547e2e3edf3b.md` afirma **"0 HARD / 22 SOFT, rc=0"**. Medido hoje,
sem nenhuma mudança local em `.claude/commands/`:

- **REGRA 8 (Inventário canônico sincronizado com o filesystem):** `docs/onion/inventory.md` dizia
  **109** comandos; o filesystem tem **111** (`meta/` 42→43, `docs/` 11→12).
- Os dois faltantes — `.claude/commands/meta/forge.md` e `.claude/commands/docs/build-project-manual.md`
  — entraram **no próprio commit do update** (`3f84b84`), que não regenerou o inventário.
- O gate local está ativo (`core.hooksPath=.githooks`). Ou o commit do update passou sem o gate, ou o gate
  não julgou a REGRA 8 (Inventário canônico sincronizado com o filesystem) nele — **não descobrimos qual**.

Curado aqui com `inventory.sh --markdown`. Pedido: o `--update` deveria regenerar o inventário **depois**
do merge do vendor e re-rodar o lint antes de carimbar "0 HARD" no relatório.

## Pergunta

`meta:forge` se declara **"Core-only"** (descrição e linha 19), mas chegou a este `hub`. A linha 19 fala
de uma "face que viaja gated" — era intencional ele viajar?
