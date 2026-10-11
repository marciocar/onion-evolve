---
reviewed_diff_sha256: e309b277778f7b227abf6c8920a3bd70da6a6439704c973dd9396ee80d3224bf
reviewed_code_sha256: dcc59b374b980c27f3c7df9753d3f0e9b807608acdf01f492d61d5e372bdf522
findings_total: 12
findings_real: 11
tokens: 127743
duration_min: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Uma passada de refutador com o veredito começando em reprovado e o mandato de achar % errado em alguma
  borda e fallback silencioso, executando com fixtures em mktemp. Ele REPROVOU por dois achados: um id
  que começa com # sumia como comentário (e a frase declarava "nenhuma subtask"), e o /engineer:pre-pr
  ainda gravava 90% à mão. Mais oito menores e dois tetos. Tudo curado no mesmo laço, com caso no
  --selftest (21 para 30) e mutante na bancada (9 para 16) para cada cura que tinha como morder.
---

# Resíduo — `feat/task-progress-story-points`

Onda 3 da SDAAL do Task Manager (SAC-64). O % de progresso da task-mãe passa a ser a soma dos story
points das subtasks feitas sobre o total. Sem pontos, cai na contagem e **declara**. A regra mora na
`interface.md` (derivação `progress`), e o helper `.claude/utils/task-manager/progress.sh` a executa.
Ler os pontos virou a capacidade `estimate.points_read`, declarada `not_implemented` nos cinco adapters.

## Passada adversarial: REPROVA (12 achados, 11 reais)

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 1 | BLOQUEIA | id `#13` tratado como comentário: com 2 subtasks saía `none` / "nenhuma subtask", rc 0; com uma pontuada, 0% em vez de 62% | comentário só é a linha com `#` **sem TAB**; caso (j) + mutante |
| 2 | BLOQUEIA | `/engineer:pre-pr` mandava "Atualizar progresso para 90%" | passo pela derivação; a bancada reprova o % fixo de volta (caso c + mutante pelo mutate-and-restore) |
| 3 | MENOR | o épsilon do arredondamento não tinha caso (0,57 de 1 ponto dava 56 sem ele) | caso (h3) + mutante |
| 4 | MENOR | mutantes sobreviventes: id vazio, CRLF, frase de canceladas, "e mais N", linha de forçar 100 | casos (i7), (k4), (k), (k2); a linha de forçar 100 era morta e saiu |
| 5 | MENOR | estouro de float: pontos gigantes davam `nan` com rc 0 | pontos limitados a 999999 (rc 2); caso (h4) + mutante |
| 6 | MENOR | argumento vazio caía calado na entrada padrão | rc 2; caso (b4) da bancada |
| 7 | MENOR | `/engineer:work` usava `progress` sem atribuir e imprimiria `n/a%`; ordem em relação ao `updateStatus` não dita | atribuído depois do update, com `getSubtasks` relido; `none` sai sem `%` |
| 8 | MENOR | o 99 forçado não se explicava na frase | sufixo na frase; caso (k3) + mutante |
| 9 | MENOR | coluna a mais aceita (ponderaria pelo campo errado) | `NF != 3` reprova; caso (i6) + mutante |
| 10 | MENOR | template de exibição por fases em `output-formats.md` podia ser copiado para a task-mãe | rótulo apontando a derivação |
| 11 | TETO | `estimate.points_read` tem a mesma superfície de campo da escrita, e a REGRA 103 não distingue | aceito; registrado na interface e no grafo |
| 12 | — | `progress.sh` não rastreado no momento da leitura | falso: estava por commitar; entrou no commit |

Arquivo vazio continua sendo "sem subtasks" (`none`). Distinguir falha do produtor da lista é tarefa do
consumidor, e a interface diz isso.

## Medido

- `progress.sh --selftest`: 30/30 com `LC_ALL=C`.
- Família `task_progress`: 23/23 (7 casos + 16 mutantes), e `task_manager_capabilities` verde com a capacidade nova.
- `ops/mutate-and-restore.sh`, 8 mutantes sobre os arquivos reais (progress.sh, zoho.md, engineer/work.md,
  engineer/pre-pr.md, jira.capabilities.tsv), todos mordendo, com a restauração conferida por hash.
- `task-manager-capabilities-check.sh` rc 0; `kg-radar.sh` rc 0 e `kg-contract-check.sh` rc 0 no grafo
  novo e na fila; `pipe-verdict-check`, `ops-citation-travel-check` e `identifier-language-check` rc 0.
- Não rodei a bancada completa (por instrução): só as famílias tocadas e os mutantes.
