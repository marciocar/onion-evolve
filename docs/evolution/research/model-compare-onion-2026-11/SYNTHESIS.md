---
title: Comparação de modelos dentro do Onion
date: 2026-11-11
kg: docs/evolution/research/model-compare-onion-2026-11/model-compare-onion-2026-11.kg.yaml
run_id: "nenhum (sem Workflow: script avulso da sessão do core, execução pelo plano)"
tokens: 0   # não somado; o custo informado por execução está em data/runs.tsv
agents: 0
duration_min: 150
review_after: 2026-12-11
type: research
---

# Comparação de modelos dentro do Onion

**Pergunta do maestro:** o Fable 5.2 faz diferença quando usado com o Onion, em eficiência e eficácia?

**Método.** Oito defeitos reais que o core já curou, reencenados no commit anterior à cura. Cada modelo audita o arquivo, só com ferramentas de leitura, duas vezes, com o `CLAUDE.md`, os hooks e as skills do Onion carregados. Dois juízes às cegas (Opus 5.5 e Fable 5.2) leem as auditorias sem saber o autor, com a cura real como gabarito, e conferem no código o que é real e o que é falso. Concordância em acertar o defeito: 80 em 80.

## Quadro comparativo

| Modelo | Acertou o defeito | Achados reais / total | Falsos | Custo por execução | Tempo médio |
|---|---|---|---|---|---|
| Fable 5.2 | 9 de 16 | 79 / 79 | 0 | US$ 2,38 | 244 s |
| Sonnet 5.5 | 9 de 16 | 76 / 79 | 0 | US$ 0,31 | 104 s |
| Haiku 5.5 | 7 de 16 | 62 / 73 | 3 | US$ 0,04 (não confiável) | 124 s |
| Fable 5.1 | 6 de 16 | 72 / 76 | 0 | US$ 2,87 | 314 s |
| Opus 5.5 | 6 de 16 | 78 / 78 | 0 | US$ 1,37 | 239 s |

## Por caso (acertos em 2 repetições)

| Defeito | Fable 5.2 | Sonnet 5.5 | Haiku 5.5 | Fable 5.1 | Opus 5.5 |
|---|---|---|---|---|---|
| Manifesto ignora o rc do derivador | 1 | 1 | 0 | 0 | 1 |
| `GIT_DIR` do ambiente desvia o repo | 2 | 2 | 2 | 2 | 2 |
| Pipe para `grep -q` sob `pipefail` | 2 | 2 | 1 | 0 | 0 |
| Plataforma sem `loadavg` bloqueia o commit | 0 | 0 | 0 | 0 | 0 |
| Referência com sha em maiúsculas | 2 | 2 | 2 | 2 | 1 |
| Fora de qualquer repo conta como alheio | 0 | 0 | 0 | 0 | 0 |
| Caminho relativo depois de um `cd` | 2 | 2 | 2 | 2 | 2 |
| Código de saída 3 é corpus vazio | 0 | 0 | 0 | 0 | 0 |

## O que se conclui

- **O Fable 5.2 custa 17% menos e leva 22% menos tempo que o 5.1, sem diferença comprovada em acerto.** Selado: `D_LINEUP_FABLE_5_2_1111`.
- **O Sonnet 5.5 empata com o Fable 5.2 no acerto a cerca de um oitavo do custo.** Em auditoria delimitada; para orquestração segue hipótese.
- **O Haiku 5.5 acerta razoavelmente, mas é o único com achados falsos.**

## Limites

- **Não é dogfood.** O Onion estava carregado, mas os modelos só liam arquivos: sem comandos, hooks disparando, gates ou grafo. Esta rodada é linha de base; o teste da maquinaria em ação é `Q_COMPARATIVO_COMPLETO_COM_ONION_E_KG_SSOT_1111`.
- **"Acertou o defeito" mede só o defeito do gabarito.** Cada auditoria listava até 5 achados, e os arquivos têm outros defeitos reais. Quem trouxe achados verdadeiros e talvez mais graves contou como erro. A gravidade não foi medida.
- **A diferença de acerto não é significativa.** O teste certo é pareado por caso: entre Fable 5.2 e 5.1 há só 2 casos discordantes, p = 0,50. Com tão poucos, nenhuma comparação teria como dar significância.
- **Mede auditoria de um arquivo.** Não mede orquestração longa, onde um modelo maior pode render mais.
- **Custo é o valor informado pelo CLI;** rodou pelo plano. O do Haiku não bate com os tokens gastos.
- **Os juízes são dois dos concorrentes,** ainda que às cegas.
- Total contabilizado: US$ 133,83, com os juízes.

## NÃO-VERIFICADOS

- Se a diferença se mantém com mais casos que discriminem.
- O comportamento em tarefas com o KG-SSOT e em orquestração longa (`Q_COMPARATIVO_COMPLETO_COM_ONION_E_KG_SSOT_1111`).

## Valeu a pena

Respondeu à decisão com número e mostrou que o modelo mais caro não é o que mais acerta nessa tarefa. Os dados brutos ficam em repositório privado, para reprocessar e refazer com modelos futuros.
