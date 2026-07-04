# 📊 Análises do Sistema Onion — Ciclo de Vida

> **Princípio:** análises e planos são **efêmeros**. Uma vez **executados**, são **removidos** do repositório — o **git history é o arquivo**. Só permanecem aqui os **baselines ativos** referenciados por comandos ou pela constituição.

Isto reforça a doutrina de modernização (regra de inventário/SSOT em
[`../knowledge-base/concepts/onion-modernization-doctrine.md`](../knowledge-base/concepts/onion-modernization-doctrine.md)):
documentação ativa contém só o que é canônico ou usado em runtime; o resto não acumula.

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
