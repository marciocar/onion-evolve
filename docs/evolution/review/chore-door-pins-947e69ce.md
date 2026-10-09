---
title: 'Resíduo — selo dos pins das portas na 20a+ materialização (947e69ce)'
date: 2026-10-09
branch: chore/door-pins-947e69ce
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR só de registro: dois pins carimbados por ops/door-seal-pin.sh, que confere o REMOTO antes de
  carimbar. A passada é a conferência de cada pin contra o commit publicado.
---

# Conferências

| Porta | Pin | Commit na porta (conferido no remoto) |
|---|---|---|
| onion-core | `947e69ce069d` | `27c89057` (`gh api repos/marciocar/onion-core/commits/main`) |
| onion-standalone | `947e69ce069d` | `8756ce27` (idem, onion-standalone) |
| onion-plugins | `947e69ce` (ref no `provenance.json`) | `a16acff9`; não tem entrada `kind: door`, porque o pin vive no próprio provenance |

Antes de cada push, as três materializações conferiram:
- baselines stubados;
- zero documento privado nomeado;
- nomes de cliente iguais aos publicados;
- lint da porta com rc 0, 0 HARD e nenhum `MORREU`.

# Decisões declaradas

- **onion-standalone saiu com `kg-grammar.md` citando `ops/pr-merge-verified.sh`**, que não viaja. A
  mesma classe já estava publicada (`pretooluse-merge-gate.sh`, `onion-orchestration/SKILL.md`), então
  não é exposição nova. A cura de classe é o SAC-86.
- **O nome `onion-evolve` aparece em texto nos plugins publicados** (proveniência e READMEs), como já
  aparecia antes. Fica para decisão do maestro, sem urgência.
- **`door-staleness-baseline.txt`:** as linhas de dado seguem manuais, por decisão de 2026-09-26. Não foram tocadas.
