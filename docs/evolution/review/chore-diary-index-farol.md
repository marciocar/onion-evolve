---
title: "Revisão — índice do diário registra a migalha do farol"
date: 2026-08-28
branch: chore/diary-index-farol
reviewer: "self-review — projeção 100% gerada, verificada por regeneração idempotente"
reviewed_diff_sha256: f7e411745ccd9e3de2c812ddcf8e13ef631b674a89a43201d57d5f0b3eae9a77
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 3000
duration_min: 4
---

# Resíduo — REGRA 56

Mudança de **uma linha de comando**: `bash .claude/validation/diary-index.sh`. O diff é
inteiramente a **projeção gerada** (`.claude/diary/index.md`), nenhuma prosa escrita à mão.

## O achado (1 real, e não é do diff — é do que faltava)

**Migalha fora do índice não orienta ninguém.** A entrada do PR #700 existia no disco e era
invisível no Tier-0 pointer. Nenhuma guarda pegou: **não há catraca de "índice em-sync com as
entradas"** no lint, ao contrário do que existe para inventário (`inventory.sh`) e plugins
(REGRA 19). Quem pegou foi o maestro perguntando. Fio nomeado, não corrigido aqui — a catraca
é mudança de guarda e merece PR próprio com dogfood.

## Verificação

- `diary-index.sh` → `107 entradas (0 stale, 95 compartilháveis)`; a entrada nova aparece
  na 1ª linha da tabela, com `type: error`, `review_after: 2026-11-26`, `📤`.
- **Idempotência**: rodar de novo não produz diff — a projeção é estável.
- Risco de conteúdo: **nulo**. O arquivo é gerado e o gerador já reprova estrutura inválida de
  migalha antes de emitir (`diary-index.sh:136`).
