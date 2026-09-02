# Inventário interno — a diretriz de pesquisa × a maquinaria que já existe (worker lens-internal, opus, 2026-09-02, read-only)

Achado principal: a diretriz já está ~70% mecanizada; o artefato que a carrega é /meta:radar. O que o maestro repete é o prompt de invocação de um comando que já existe, mais três lacunas reais.

## A) Cláusula → artefato → cobertura
| # | Cláusula | Artefato existente | Cob. | Gap |
|---|---|---|---|---|
| 1 | Onion como lente + maquinaria | .claude/skills/onion/SKILL.md:110; .claude/commands/meta/kg.md:38 | PARCIAL | A lente existe para construir artefato; não há passo "aplique a lente Onion" na abertura de pesquisa |
| 2 | Fontes atuais; Claude Code versão atual | docs/knowledge-base/concepts/verify-external-for-current.md:5; eixo E3 em docs/onion/radar-baselines.yaml:17; REGRA 65 cc_version lint-artifacts.sh:3630 | TOTAL | — |
| 3 | Fontes amplas, emergentes, Gartner/YC | radar.md:49 (search-by-trajectory: created:> + sort=stars, HN Algolia); agents/research/research-agent.md:87 | PARCIAL | A lista de superfícies vive em memória durável e em UMA linha do radar.md, não num fragmento reusável |
| 4 | Caminho do dinheiro | eixo E4-capital radar-baselines.yaml:22; radar.md:50; exemplar bridge-produto-2026-08/SYNTHESIS.md:157 | TOTAL | — |
| 5 | Revisar o que temos, forte/fraco, perto/longe | adopt.md:26-29 (régua igual→transfere / diferente→desenha); evolve.md:242 | PARCIAL | Régua presa ao /meta:adopt; nenhuma pesquisa a invoca |
| 6 | Não inventar a roda, nem largar ideia por comodismo | onion-elenxo-doctrine.md:79, :120 | PARCIAL | Elenxo refuta o que EU afirmo; não há passo "esta ideia foi descartada por evidência ou por comodismo?" |
| 7 | Guardar em .kg.yaml, reusar, saber quando, revisitar | kg.md:65 (schema); 27 grafos em docs/evolution/research/; radar.md:37 | PARCIAL | Sem campo de revisita por grafo — só verified_at e meta.baseline; sem reuso cross-pesquisa |
| 8 | Decisões revisáveis | kg.md:65 (decision, SUPERSEDES); kg-freshness.md | TOTAL | — |
| 9 | Dogfood + breadcrumbs | onion-dogfooding-doctrine.md; kg.md:88 (trace:); kg-born-marker.sh:175 | TOTAL | — |
| 10 | Transformer é a força; ferramenta sem uso é custo | transformer-architecture.md; knowledge-graph-sdaal.md; maestro-vivo-2026-08/data/f0-capacidade-uso.json:532 | PARCIAL | "ferramenta sem uso é custo" medido uma vez (F0), não virou instrumento recorrente |

## B) Fronteira dos comandos existentes
- /meta:radar — 6 eixos com baseline datada e juiz fixo opus/high (radar.md:13, :47-48). NÃO faz tema livre.
- /meta:kg (509 linhas; map/backfill/narrate/diagnose) — NÃO busca web nem consulta grafos irmãos (kg.md:317: "o radar lê um grafo por vez; o laço é de quem chama").
- /meta:kg-freshness — re-verifica nós contra o vivo; NÃO decide quando revisitar (consome a fila do radar).
- /meta:evolve — introspecção pura de .claude/ (evolve.md:242); NÃO olha para fora.
- /meta:analyze-complex-problem (194 linhas) — causa-raiz local (:59-89); saída .md em docs/analysis (:145), fora do corpus do radar.
- /meta:orchestrate + onion-orchestration — transporte (orchestrate.md:195, SKILL.md:91); NÃO é método.
- @research-agent (298 linhas) — multi-fonte com verificação cruzada (:105); saída prosa (:124); sem grafo, sem follow-the-money, sem trajetória. O artefato mais desalinhado com a diretriz.
- /meta:census, backlog, realign, drive — decisão sobre trabalho aberto, não sobre o mundo externo.

## C) Temporalidade existente
| Mecanismo | Janela | Onde |
|---|---|---|
| REGRA 65 eixo vencido | 45 dias SOFT | lint-artifacts.sh:3602 |
| REGRA 65 cc_version | por evento | lint-artifacts.sh:3630 |
| REGRA 65 baseline ilegível | HARD | :3583, :3608 |
| Diário review_after | 90 dias | diary.md:97, :269 |
| kg-radar STALE-OLD | contra meta.baseline | kg-radar.sh:680 |
| kg-radar STALE-MISSING/UNANCHORED | ausência de campo | kg-radar.sh:649, :671 |
Falta: grafo de pesquisa não tem review_after nem last_run; só envelhece se alguém editar meta.baseline à mão; nenhuma regra de lint olha a idade dele (kg.md:65-88 confirma).

## D) Reuso cross-pesquisa
Quase nenhum. Único reuso mecânico: por eixo do radar via ponteiro kg: (radar-baselines.yaml:19, :23; radar.md:29 "nunca re-deriva o que já foi selado"). kg-census-extract.sh:44 faz glob corpus-wide, mas serve nós abertos, não "o que já sabemos sobre este tema". Grep que provou: grep -rn "grafos anteriores\|pesquisas anteriores\|reusa\|evolution/research" .claude/commands/ .claude/skills/ .claude/agents/ → ~30 linhas, nenhuma é etapa ler-antes-de-pesquisar.

## E) 3 maiores gaps e a menor mecanização
1. Pesquisa de tema livre não tem porta (radar fechado em E1-E6; research-agent entrega prosa). → fragmento em .claude/commands/common/prompts/ (research-doctrine.md, 10 cláusulas como checklist), citado por radar.md, @research-agent e /meta:kg — padrão de untrusted-content-provenance.md e orchestration-fallback.md. Comando novo = inchaço; o radar só precisa aceitar eixo ad-hoc.
2. Grafo de pesquisa não envelhece sozinho. → meta.review_after: no schema + SOFT irmã da REGRA 65 varrendo docs/evolution/research/*/*.kg.yaml (glob já existe em kg-census-extract.sh:44; precedente de janela no diário).
3. Nenhuma pesquisa lê as anteriores (27 grafos guardados e não consultados). → kg-corpus-grep.sh (tema → nós de todos os grafos com data e veredito, ~20 linhas sobre o glob do census) + etapa no fragmento. Régua igual→transfere / diferente→desenha em adopt.md:26-29.
Nota de método: os três gaps compõem UMA superfície — um fragmento de doutrina de pesquisa que abre lendo o corpus e fecha carimbando quando revisitar.

## Medição adicional (contexto principal, 2026-09-02): doutrina de escolha de FONTES
grep -rlniE "tier(ing)? de fonte|hierarquia de fontes|credibilidade d[ae] fonte|fonte prim[áa]ria" .claude docs/knowledge-base docs/meta-specs → só matches na worktree discuss+onion-pessoal-app (cópia velha). Peças soltas: R15 (proveniência = confiança no conteúdo, não seleção); kg.md:116 ("evidência de terceiro carrega o interesse da fonte — anote quem produziu e o que ganha"); research-agent.md:256 (uma linha). NÃO existe doutrina/maquinaria para escolher fontes.
