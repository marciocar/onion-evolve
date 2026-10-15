---
branch: fix/merge-hooks-prune-retired
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: a sessão executora (SAC-145); ataques por 3 mutantes e dogfood no settings.json real do adotante antes da cura manual dele
nota: "defeito achado e medido pela sessão do adotante onion-curation, conferido no core lendo o merger. tokens e duration_min em 0 = não medidos."
---

# Passada adversarial: `fix/merge-hooks-prune-retired`

## O que muda

O `merge-onion-hooks.sh` (chamado pelo `/meta:adopt` na Fase 3 e no `--update`) poda a entrada de hook que o
core aposentou: forma canônica do Onion e script ausente na fonte E no alvo. Uma entrada morta em outra forma é
do alvo e só recebe aviso. A poda sai no stderr, e o `--diff` do relatório a conta como removida.

## Achados

1. **Hook aposentado vira rc 127 no adotante.** A sessão do `onion-curation` mediu: depois do #1129 (que aposentou
   o Stop `background-state-needs-evidence.sh`), o update apagou o script, mas a entrada ficou, e todo Stop dava
   rc 127, com o relatório dizendo "0 removidos". Causa, lida no merger: "command que a fonte não tem" era sempre
   tratado como hook próprio do alvo.

## Dogfood

O `settings.json` do curation de antes da cura manual dele (f805337 de lá), com os hooks daquele commit: o merger
novo podou a entrada (`PODADO: …`), o `--diff` passou a dizer "1 adicionado, 1 removido" e a 2ª passada é idêntica.

## Mutantes

- M1, sem a poda → reprovam (a) e (d).
- M2, poda sem checar a forma do Onion → reprovam (c) e (d).
- M3, poda ignorando o script do alvo → reprovam (b) e (d).

## Limites declarados

- A forma do Onion é a do `settings.json` do core (`bash "$CLAUDE_PROJECT_DIR/.claude/hooks/X"` ou
  `bash .claude/hooks/X`). Um hook que o core venha a registrar em outra forma não seria podado, só avisado.
- Os adotantes atualizados ANTES do #1129 não têm a entrada morta. O curation já se curou à mão.
