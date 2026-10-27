---
title: "Avaliação do Cortex contra o Onion, medida (proposta: costurar só a peça no gate de plano, na âncora única da mutação e na geração de pptx e docx; parquear a frota, o registro de uso e o handoff; rejeitar três áreas)"
date: "2026-10-27"
from: onion-curation
merged_at: "main bd6386a (PR #133, medição das rejeições e das costuras)"
to: onion-evolve
type: dissect-proposal
kg: docs/evolution/dissect/cortex-2026-10/cortex-2026-10.kg.yaml
piece_nodes: [D_PIECE_DISTRIBUTION, D_PIECE_FLEET, D_PIECE_PLAN_GATE, D_PIECE_SPEC_AS_CODE, D_PIECE_DOCS_PRESENTATIONS, D_PIECE_STUDIES, D_PIECE_USAGE_TELEMETRY, D_PIECE_MEMORY, D_PIECE_QUALITY]
---

# Sinal: avaliação do Cortex (família ferramenta), com a rodada de medida

> Pedido do maestro. O relatório completo está em `EVALUATION-REPORT.md`, que passou pela revisão adversarial separada
> (6 objeções aplicadas). Depois veio a triagem do maestro ("Medir as rejeições antes"), e as rejeições e duas costuras
> foram medidas rodando os dois lados no mesmo caso, em laboratório isolado (`MEASURE-PLAN.md`, commitado antes de rodar;
> saídas literais em `evidence-measure/`). A palavra final é do core, peça por peça.

## Propostas por peça

| peça | veredito | nota | resumo |
|---|---|---|---|
| gate de plano antes do código | **costurar só a peça** (medido) | 6 | script que o orquestrador da frota chama; barra sem sessão e com o plano não commitado (exit 2) e passa com o plano no HEAD. Nenhum dos dois barra o commit. Passa também com o plano commitado DEPOIS do código, e o gate pelo HEAD conflita com o `.gitignore:8` do core; a costura confere a ordem e decide onde o plano mora |
| qualidade (mutação) | **costurar só a peça** (medido), como remendo no helper do core | 6 | com âncora repetida, o `mutate.py` recusa (rc 2) e o `ops/mutate-and-restore.sh` muta a 1ª em silêncio; o rc 3 do core vale tanto para âncora ausente quanto para um teste que sai 3. **Requisito novo:** rodar o teste sem a mutação antes, que nenhum dos dois faz |
| memória: o handoff no git | **parquear** (corrigido pela revisão) | 5 | o teste de comportamento do Cortex deu 82 PASS, 0 FAIL; o core tem os ganchos de retomada do worklog, que não rodaram aqui; sem par fica só o handoff versionado no git, que o core descarta por escolha. Gatilho: `--around <grafo>#E_ONION_WORKLOG_HOOKS --edge-type SUPERSEDES`, com `min_count: 2` (hoje 1) |
| documentação e apresentações | **costurar** (condicionado) | 6 | não exercida: as ferramentas são Node (`docx`, `pptxgenjs`, `cheerio`, do npm), fora da autorização de venv do PyPI |
| frota | **parquear** | 5 | N issues em worktrees paralelas com aprovação humana em lote não têm par, mas nenhum adotante pede isso |
| registro de uso | **parquear** | 5 | a telemetria nativa do Claude Code em OpenTelemetry já cobre o uso, com coletor; a forma do Cortex grava dentro do git com o nome de quem rodou |
| distribuição | **rejeitar** (medido do lado do Onion, lido do lado do Cortex) | 4 | o merge do `onion/vendor` preservou a customização sem conflito falso e acusou o conflito real; o instalador do Cortex não está na máquina, e a fusão dele segue lida |
| especificação como código | **rejeitar** (medido do lado do Onion, lido do lado do Cortex) | 3 | no artefato do framework fora do padrão, o lint do core sai rc 1 (REGRA 1 e 2) e o Cortex deixa entrar (rc 0); na decisão de arquitetura no código do projeto, empate, porque nos dois é agente |
| estudos e avaliações | **rejeitar** (medido do lado do Onion, lido do lado do Cortex) | 3 | `kg_query --open` devolve o estado do estudo por comando (8 nós em 5,7 KB); a busca nos scripts do Cortex acha 3 arquivos e nenhum faz isso |

- **Absorver no núcleo:** nenhuma peça. Nenhuma tem uso medido em dois ou mais adotantes.
- **Gatilhos dos parques:**
  - frota: `--around <grafo>#Q_FLEET_PARALLEL_DEMAND --edge-type SUPERSEDES`, com `min_count: 2`;
  - registro de uso: `--around <grafo>#E_NATIVE_OTEL_USAGE --edge-type SUPERSEDES`, com `min_count: 2`.
  Hoje os dois dão 1, e nenhum disparou.
- **Medida que o core já tinha feito:** a do helper de mutação (troca a 1ª ocorrência sem avisar; rc 3 com âncora
  ausente). Ela foi reproduzida no laboratório.
- **Revisão adversarial da rodada:** agente separado, 6 objeções, todas aplicadas. Ela corrigiu a memória (de costurar
  para parquear) e as notas do gate e da mutação (para 6). A ordem das medidas é informada pela ordem dos commits.

## Confidencialidade

O Cortex mora no repositório de um cliente. Só o framework foi lido e copiado para o laboratório. Ficaram de fora
`memory/`, `sessions/`, os documentos de onda da frota e o `settings.json`, que traz permissões com nomes de banco do
cliente. Os dois laboratórios foram apagados no fim. Nenhum dado do cliente nem nome de pessoa do time entra neste sinal
ou no estudo.
