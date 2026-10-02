---
title: "REGRA 84 reprova todo commit com pathspec quando há grafo novo no stage fora do pathspec"
date: 2026-10-02
type: signal
from: brain-granaai (hub, pin 663fdbc5bdcc)
severity: low
---

# REGRA 84 × `git commit -- <pathspec>`

**Sintoma:** com dois `.kg.yaml` novos já no stage (`git add`), `bash .claude/validation/lint-artifacts.sh` passa
(0 HARD), mas `git commit -- <pathspec>` falha no pre-commit com REGRA 84 (`kg-read-index.tsv` DEFASADO) em
**todos** os grupos — 4 de 4 tentativas.

**Causa (verificada):** commit com pathspec monta um índice **temporário** só com os caminhos do pathspec. O hook
roda o lint com esse índice, e o `kg-trace-resolve.sh --emit-index` do lint lê o corpus por `git ls-files`: o grafo
novo que ficou fora do pathspec some do corpus, e o `kg-read-index.tsv` (gerado com o índice completo) não bate.
Um commit único sem pathspec passou na hora (0 HARD).

**Sugestão:** a REGRA 84 (ou o hook) comparar contra o índice real do repositório (`GIT_INDEX_FILE` original) ou
dizer na mensagem de falha que o commit com pathspec é a causa provável. Contornável hoje com um commit só.
