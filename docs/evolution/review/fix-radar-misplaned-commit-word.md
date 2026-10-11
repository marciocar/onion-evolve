---
title: 'Resíduo — o MISPLANED distingue commit barrado (execução) de commit lido (fonte)'
date: 2026-10-11
branch: fix/radar-misplaned-commit-word
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 4
findings_fixed: 3
tokens: 100691
duration_min: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Refutador opus, com veredito default REPROVADO e o mandato de achar MISPLANED real que a cura passou
  a esconder. No corpus não achou nenhum. Reprovou por três brechas que construiu e mediu em fixture
  adversarial de 27 casos. As três foram curadas no mesmo loop e o quarto achado ficou como teto
  declarado.
---

# O que mudou

Sinal de campo do adotante onion-kg-ssot (2026-10-11). O DETERMINISTIC_GATE dele carimbava
"commit-sonda que o gate barrou" e levava `MISPLANED`, porque a regra casava a palavra `commit` em
qualquer sentido. O adotante contornou reescrevendo a frase.

A cura é feita por ocorrência, nunca por nó:

1. `commit <sha>` acusa sempre, com até 3 separadores quaisquer entre a palavra e o sha (inclusive crase).
2. Antes do teste saem só as ocorrências de sentido de execução: `commit-sonda`,
   `commit barrado/recusado/bloqueado` e `<barr|recus|bloque…> o commit`. O radical tem âncora à esquerda.
3. Se ainda sobrar `branch|commit` na frase, o nó continua acusado.

`@<sha>` sozinho não passou a acusar, porque `onion@<sha>` é stamp de pin, o caso ambíguo que a regra
deixa fora de propósito.

**Paridade de leitores (REGRA 31):** `kg-view.sh`, `kg-console.sh` e `kg-realign-project.sh` não
reimplementam o `MISPLANED`. Eles consomem a saída do radar, então não há o que alinhar.

# Medição no corpus (148 grafos, `git ls-files '*.kg.yaml' | grep -v fixtures`, `LC_ALL=C`)

| | Antes | Depois |
|---|---:|---:|
| `MISPLANED` (todas as causas) | 41 | 40 |
| `MISPLANED` por `verified_against` | 40 | 39 |

A única saída é `Q_GATILHO_DO_WIREIN_NAO_CASA_COM_O_SUT` (elenxo-mecanismos-lint-2026-08-13), com
`verified_against: schema-sabotado-staged-bloqueia-o-commit-…`. O carimbo descreve o hook rodando ao
vivo, o que é execução. O refutador confirmou: nenhum rc mudou e o `--freshness-tsv` saiu idêntico
byte a byte nos 148 arquivos.

# Achados da passada adversarial

1. **[MÉDIA, curado]** O sha só era reconhecido depois de espaço, `-`, `_` ou `:`. Com o sha entre
   crases, a limpeza apagava `barrou o commit \`<sha>\`` e o nó calava. O separador agora é
   `[^0-9a-z]{1,3}`. Prova: caso (v) e o mutante (x).
2. **[MÉDIA, curado]** `reprov` e `vet` são vocabulário de revisor, e um revisor lendo o diff está
   lendo fonte. Saíram da lista. Prova: caso (v), nó `C_PROD_REVISOR_REPROVOU_LENDO_O_DIFF`.
3. **[BAIXA, curado]** O radical não tinha âncora à esquerda, e `desbloqueado o commit` era lido como
   commit barrado. Prova: caso (v) e o mutante (y).
4. **[BAIXA, teto declarado]** Continuam calando dois casos: um revisor que escreve `recusado o
   commit`, e um carimbo que cita commit barrado junto de uma leitura sem as palavras branch, commit ou
   sha (`HEAD lido`). É o limite de uma regra por vocabulário, e ele está declarado no comentário da
   função.
5. **[INFO, pré-existente]** A condição de fora é sensível a maiúsculas (`COMMIT ABC1234` já escapava
   antes). Não é regressão desta cura.

# Bancada e mutantes

Família `kg_freshness`, casos (u) a (y): (u) a execução cala; (v) a leitura de fonte segue acusando;
(w), (x) e (y) são mutantes do filtro de sentido, do atalho do sha e da âncora. As famílias tocadas
(`kg_freshness`, `kg_radar_contract`, `kg_radar_integrity`, `kg_view`, `kg_console`,
`kg_fixture_paths`) passaram 77/77 em `LC_ALL=C`. Dois mutantes vivos foram plantados no radar real
por `mutate-and-restore.sh`: sem o filtro, as 2 execuções voltam a disparar; sem o atalho do sha, o
`commit <sha>` entre crases cala. Restauração conferida (0 marcadores no radar).

# Carimbo de pin

`registry-pins --seal --only onion-kg-ssot` carimbou 54ef8ebdf150 → 465560d68f4e (remoto main; PR #73
do adotante, merge commit).
