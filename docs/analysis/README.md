# 📊 Análises do Sistema Onion — Ciclo de Vida

> **Princípio:** análises e planos são **efêmeros**. Uma vez **executados**, são **removidos** do repositório — o **git history é o arquivo**. Só permanecem aqui os **baselines ativos** referenciados por comandos ou pela constituição.

Isto reforça a doutrina de modernização (regra de inventário/SSOT em
[`../knowledge-base/concepts/onion-modernization-doctrine.md`](../knowledge-base/concepts/onion-modernization-doctrine.md)):
documentação ativa contém só o que é canônico ou usado em runtime; o resto não acumula.

## 🌱 Sementes de pesquisa abertas

> Terceira categoria, distinta de "permanece"/"removido": uma semente é **plantada, não decidida**
> — registra uma pergunta com grounding real, sem executar a pesquisa ainda. Fica até ser
> **ENTREGUE** (relatório separado, linkado) ou incorporada a um baseline/ADR acima. Formato-
> padrão: `onion-research-seed-<slug>-<AAAA-MM>.md` (Título → status → Por que → Questões →
> Método previsto → Gatilho). Gap corrigido em 2026-07-06: antes desta tabela, o rastreamento de
> sementes vivas existia só na memória de sessão do Claude, fora do repositório.

| Semente | Status | Resumo |
|---|---|---|
| [Hegel (dialética, Aufhebung, Bildung)](onion-research-seed-hegel-dialectics-2026-07.md) | SEMENTE (2026-07-05) | Dialética hegeliana × epistemologia do Onion (KG append-mostly, Aufhebung); catálogo teórico + 5 questões de analogia. |
| [SRL/PLEA (Pedro Rosário)](onion-research-seed-srl-plea-2026-07.md) | ENTREGUE (2026-07-05) | Autorregulação da aprendizagem × vertical educacional; 11 achados, Q3 e Q5 ficaram abertas. |
| [Onion virar um modelo (SLM)](onion-research-seed-onion-as-model-2026-07.md) | SEMENTE (2026-07-06) | Destilação de doutrina já existe (onion-mini); destilação de pesos, não. Cruza com Q5 da semente SRL/PLEA. |
| [Orquestrar SLMs federados](onion-research-seed-federated-slm-orchestration-2026-07.md) | SEMENTE (2026-07-06) | Colide com rejeição explícita ("SLM-como-agente", "model-routing multi-LLM"); onion-mini já é a resposta `bifurcada` — ver [parecer](onion-parecer-rejection-vs-spinoff-signal-2026-07.md). |
| [smolagents e padrões emergentes](onion-research-seed-smolagents-and-emerging-patterns-2026-07.md) | SEMENTE (2026-07-06) | Mineração de estratégias de prior art (fontes primárias); pesquisa externa ainda não rodou. |
| [Repos-padrão por tier](onion-research-seed-tiered-distribution-repos-2026-07.md) | SEMENTE (2026-07-06) | Extensão natural (não-rejeitada) do Trust SDAAL já existente; falta `role: distilled` formal + registro da família multi-plataforma. |
| [VSCode/outra IDE, revisitado](onion-research-seed-ide-integration-revisit-2026-07.md) | SEMENTE (2026-07-06) | Colide de frente com o abandono formal de multi-IDE (2026-05-18) — pode ser resposta `bifurcada` (onion-mini) já cobrindo isso, ver [parecer](onion-parecer-rejection-vs-spinoff-signal-2026-07.md). |
| [Lente do sabido ao a-saber + SDAAL](onion-research-seed-epistemic-lens-known-to-unknown-2026-07.md) | SEMENTE (2026-07-06) | Território novo; vizinhos parciais são `/meta:graph --path` e o veredito de frescor. |
| [Organização das sementes (meta)](onion-research-seed-seed-organization-meta-2026-07.md) | ENTREGUE (2026-07-06) | Resolvida no próprio plantio — esta tabela é a entrega. |
| [Cuidar de um modelo pronto](onion-research-seed-model-lifecycle-caretaking-2026-07.md) | SEMENTE (2026-07-06) | Território novo; único vizinho é `llm-provider` (roadmap SDAAL, não construído). |
| [Onion como lente para modelos](onion-research-seed-onion-as-model-lens-2026-07.md) | SEMENTE (2026-07-06) | Território novo como conceito formal; "lente" no Onion hoje só significa perspectiva de leitura interna. |
| [Canal-radar de fontes de pesquisa](onion-research-seed-research-radar-channel-2026-07.md) | SEMENTE (2026-07-06) | A forma já existe para sinal interno (`field-observations/`); falta versão para sinal externo — mecânica de cadência (`/loop`/cron) já pronta. |

## O que PERMANECE (baselines ativos)

| Arquivo | Por que fica |
|---------|--------------|
| `onion-review-2026-05.md` | **SSOT de identidade** — citado por `CLAUDE.md`. Sintetiza as análises-fonte de 2025 (que foram removidas). |
| `onion-vv-baseline-2026-06.md` | Baseline de V&V — lida por `/meta:evolve` como referência da auditoria automatizada. |
| `onion-evolution-<data>.md` (a mais recente) | Última auditoria de evolução — ponto de comparação para a próxima rodada de `/meta:evolve`. Versões anteriores são removidas, **exceto** se viraram âncora de citação (abaixo). |
| `onion-evolution-2026-06-15.md` | **Exceção — retido apesar de superseded por 2026-06-16.** Virou proof-point citado por `docs/materials/*`, `press-kit.md`, `case-studies.md` e `onion-framework-identity.md` (métricas §0: 28 agentes · 1.27M · ~26 min · 30 achados). Remover quebraria citações duráveis. Só removível após migrar as citações para outro run. |
| `onion-adr-repo-adoption-2026-06.md` | **ADR durável** — decisão doutrinária (adoção de repo = comando in-platform `/meta:adopt`, não CLI; stamp de versão; rampa da federação). ADRs são *superseded*, **nunca removidos**. |
| `onion-federation-adr-a2a-format-interop-2026-06.md` | **ADR durável** — decisão doutrinária (linha vermelha A2A partida: runtime proibido, formato permitido como projeção one-way). ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-phased-resumable-pattern-2026-06.md` | **ADR durável (provisório)** — nomeia o PFR como padrão transversal L0 (backbone faseado retomável); fica até ser superseded pelo PR constitucional (cravar em `commands.md §3`). O rótulo "provisório" **não** o torna efêmero — ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-ledger-format-location-2026-06.md` | **ADR durável (provisório)** — veredito sobre formato e localização do ledger de co-evolução (markdown fica; repo-neutro gated; norte = automatizar transporte/Carteiro). Fica até ser superseded quando o gatilho de graduação disparar. "Provisório" **não** o torna efêmero — ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-coevolution-flow-naming-2026-06.md` | **ADR durável** — decisão de vocabulário: fluxos de co-evolução renomeados de flow A/B/C → downstream/upstream/handoff (cumpre code-standards §7). ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-adopt-to-not-impose-2026-06.md` | **ADR durável (provisório)** — princípio "Onion adota, não impõe": adoção detecta o padrão do projeto e defere/estende/introduz (never-clobber); eixo SDAAL design-system provider. Fica até o gatilho cravar a costura. ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-branching-base-agnostic-2026-06.md` | **ADR durável (provisório)** — branching: a base de integração é dado resolvido (agnóstica), não GitFlow/develop hardcoded; instância do "adota não impõe". Costura nos git:* diferida ao gatilho. ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-slm-as-tool-de-identification-2026-06.md` | **ADR durável** — fronteira runtime-vs-ferramenta: SLM entra como ferramenta atrás de adapter SDAAL (de-identificação de PII), nunca como orquestrador; estende a tese "LLM=runtime" com um "segundo runtime" estreito. Protótipo: abstração `de-identification` + baseline `regex` determinístico. ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-object-led-discovery-2026-07.md` | **ADR durável** — "promover objeto existente a papel premium" (object-led discovery & fitting) materializado como **6ª entrada do catálogo de playbooks** (`onion-patterns/SKILL.md`), não skill/comando novo; dogfood retroativo sobre evidência de campo (DataTable premium). ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-verticals-investigation-cartography-2026-07.md` | **ADR durável (provisório)** — duas verticais novas no LEGO: investigação (KG SDAAL como espinha + pesquisa como alimentador, acoplamento fraco) e cartografia de contextos (navegar o conteúdo dos domínios). F0 aceito; comandos/plugins gated por rampa (F1 da investigação = D3 do rhilo). ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-education-vertical-2026-07.md` | **ADR durável (provisório)** — vertical educacional aberta no F0 sobre os confirmados da pesquisa SRL/PLEA (KB education/ fundada; F1 = dogfood no material real, gated). Diretrizes vinculantes de evidência (anti preguiça-metacognitiva). ADRs são *superseded*, **nunca removidos**. |
| `onion-adr-mini-distillation-2026-07.md` | **ADR durável** — Onion Mini (ex-portable): destilação federada como produto de ENTRADA da família (fonte≠derivação aplicado a produtos); identidade do core intacta; rampa M0-M4. ADRs são *superseded*, **nunca removidos**. |

## O que é REMOVIDO (efêmero — git arquiva)

- **Planos de execução** depois de executados (ex.: planos de saneamento, épicos, migrações).
- **Retrospectivas** de tarefas/pilotos concluídos.
- **Relatórios de evolução antigos** quando uma versão mais nova existe.
- **Análises de vendor/POC** não relacionadas ao framework.

## Regra prática

Ao concluir um ciclo (plano executado, backlog resolvido, piloto encerrado):
1. Garanta que as **conclusões duradouras** estejam sintetizadas num baseline ativo (tipicamente `onion-review` ou a doutrina).
2. **Remova** o artefato efêmero (`git rm`) e corrija eventuais links em arquivos que ficam.
3. Regenere o inventário se KBs mudaram (`/meta:inventory`) e rode o lint.

> Recuperar um documento removido: `git log --all --full-history -- <caminho>` e `git show <commit>:<caminho>`.
