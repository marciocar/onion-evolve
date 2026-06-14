# Doutrina de Modernização do Onion

> **Versão**: 1.0.0 | **Última atualização**: 2026-06-13 | **Categoria**: Conceitos
> Método reutilizável para evoluir o Sistema Onion com mais assertividade, menos peso e orquestração moderna — preservando as invariantes constitucionais. Extraído do **piloto git** (jun/2026) e validado contra a [Baseline de V&V](../../analysis/onion-vv-baseline-2026-06.md) e a [Retrospectiva T3.2](../../analysis/t32-pilot-retrospectiva-2026-06.md).

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-06-13 |
| **Última Atualização** | 2026-06-13 |
| **Categoria** | Conceitos |
| **Comando relacionado** | `/meta:evolve` (sensor que aplica esta doutrina) |
| **Padrão-pai** | [SDAAL](specification-driven-ai-abstraction-layer.md) · [Agent Fleet Orchestration](agent-fleet-orchestration.md) |

---

## 🎯 Propósito

Quando um cluster do framework acumula **peso** (cerimônia, prosa redundante, delegação ad-hoc repetida) ou **acoplamento** (lógica reimplementada em N arquivos), esta doutrina decide **qual padrão de refatoração aplicar** — consolidar, extrair adapter, extrair KB, extrair skill, paralelizar com Workflow, ou afinar para comando-fino — sem violar as invariantes do Onion.

A premissa: **o valor do Onion é orquestração com contexto, não volume de artefatos.** Um comando que repete teoria, re-delega 50 vezes e reimplementa integração não é mais capaz que um comando fino que cita uma fonte única e chama um adapter — é só mais pesado de manter e ler.

---

## 🚦 Invariantes que a doutrina NUNCA viola

Qualquer proposta de modernização é **rejeitada** se ferir:

1. **Workflows faseados** `engineer/plan→…→pr-update` e `product/collect→…→feature` — fases nunca são fundidas ([commands.md §3](../../meta-specs/commands.md)). A doutrina pode afinar um comando-fase internamente, nunca consolidá-las.
2. **`agents/* → commands/*`** é proibido ([architecture.md §4.2](../../meta-specs/architecture.md)); `utils/* → agents/*` também. Adapters e KBs não delegam a agentes.
3. **Plataforma única Claude Code** — sem `.onion/`, CLI standalone, npm ou multi-IDE (abandonados em 2026-05-18).
4. **Governança** — todo artefato novo/enxuto passa pelo `@metaspec-gate-keeper`; nada contorna a constituição.

---

## 🧭 Tabela de Regras de Decisão (o coração da doutrina)

| Situação | Regra de decisão | Respeita invariante? |
|---|---|---|
| **Consolidar vs manter** N artefatos similares | **Consolidar** se: mesma intenção + sem estado faseado + sem nome canônico distinto por categoria. **MANTER** se são fases de `engineer/*`/`product/*` (valor de design, não duplicação — [commands.md §3](../../meta-specs/commands.md)) ou duplicação de nome legítima por categoria ([commands.md §4.1](../../meta-specs/commands.md)). | ✅ fases nunca fundidas |
| **Verbos de um fluxo** (N arquivos/subpastas para start/publish/finish do mesmo fluxo) | **Dispatcher arg-driven** (`/git:flow <tipo> <ação>`) quando os verbos **não** têm estado faseado retomável e a lógica canônica vive numa KB citável. Colapsa N arquivos + subpastas em 1 ([commands.md §4.2](../../meta-specs/commands.md)). **NÃO** aplicar a `engineer/*`/`product/*` (faseados = invariante). | ✅ só verbos sem estado retomável |
| **Extrair SDAAL adapter vs KB vs Skill** | **Adapter (SDAAL)** quando há N *provedores intercambiáveis* atrás de uma interface (Task Manager, Forge, Notificação) — código agnóstico, troca por `.env` sem tocar comandos. **KB** quando é *conhecimento de fundo* consumido por leitura (doutrina, padrões, fontes, templates de workflow). **Skill** quando é *orquestração reutilizável* no contexto principal (`onion-fleet`). | n/a |
| **Workflow fan-out vs prosa sequencial** | **Fan-out** (`Workflow` nativo) se largura × independência alta E sem estado mutável compartilhado. **Sequencial / `pipeline`** se há dependência de ordem. **Default = serial** — fan-out é opt-in ([commands.md §10](../../meta-specs/commands.md), [agent-fleet-orchestration.md](agent-fleet-orchestration.md)). | ✅ frota paraleliza *dentro* da fase |
| **Shed ceremony → KB** | Boilerplate, troubleshooting exaustivo, fundamentos teóricos e exemplos longos saem do comando/agente e vão para a KB; o comando mantém só o **grafo executável** que cita a KB ([commands.md §5/§6](../../meta-specs/commands.md)). | n/a |
| **Reposicionar agente "detentor de conhecimento"** | Se um agente é re-delegado N vezes por comandos para fornecer *conhecimento* (não execução), extraia o conhecimento para uma **KB citável** e reposicione o agente como **mentor ad-hoc**. Comandos citam a KB; param de re-delegar. | ✅ remove acoplamento command→agent desnecessário |
| **Inventário/contagem (comandos, agentes, skills, KBs)** | **Nunca hardcode** contagens duplicadas em prosa — elas entropizam a cada recurso criado. O inventário é **derivado do filesystem** (SSOT em `docs/onion/inventory.md`, gerado por `/meta:inventory`) e **validado no CI** (lint Regra 8 + 9). Docs **referenciam** a SSOT; não a repetem. Drift detectado → o atuador é `/meta:inventory`, não edição manual. | ✅ drift vira erro de CI, não dívida silenciosa |

---

## 🔬 Litmus test: cerimônia vs valor genuíno

Um bloco de texto num comando/agente é **cerimônia** (mover para KB ou remover) se:

- (a) repete teoria/fundamentos já disponíveis numa KB;
- (b) duplica >50 linhas de outro artefato ([commands.md §6](../../meta-specs/commands.md));
- (c) é troubleshooting/FAQ **fora do caminho de execução**;
- (d) é referência de plataforma **stale** (`.onion/`, npm, CLI, multi-IDE).

É **valor genuíno** (manter) se removê-lo:

- quebra o **grafo executável** do comando;
- perde um **handoff de workflow faseado** (estado de sessão, próxima fase);
- derruba **evidência citada** (fonte, URL, `arquivo:linha`).

> Exemplo trabalhado (T3.2): o auto-piloto removeu cerimônia stale do `CONTRIBUTING.md` (referências a `onion-cli`/npm) enquanto **preservou** o pipeline real de descoberta em 4 camadas — cerimônia foi cortada, valor foi mantido.

---

## 🎯 Forma-alvo: "comando fino sobre engine/adapter/skill"

Um comando modernizado tem esta forma (ver os comandos `git/*` pós-piloto como referência):

```
frontmatter (description, allowed-tools escopado, model, version)
# Título + objetivo (1 frase)
## Como usar (invocação + exemplos)
## Fluxo (etapas EXECUTÁVEIS, cada uma citando a fonte):
   - lógica de domínio → cita a KB (motor)
   - integração trocável → chama o adapter (SDAAL)
   - orquestração paralela → aciona a skill (onion-fleet)
## Referências (KB + adapters + mentor)
```

O conhecimento mora na **KB**; a integração trocável mora no **adapter**; a orquestração paralela mora na **skill**. O comando só **coordena** — não reimplementa nenhum dos três.

---

## 📐 Worked example: o piloto git (jun/2026)

A pasta `git/` foi a prova de conceito desta doutrina:

| Sintoma | Padrão aplicado | Resultado |
|---|---|---|
| `@gitflow-specialist` re-delegado ~57× por comandos | **Reposicionar detentor de conhecimento** → KB `gitflow-patterns.md` vira motor citável; agente vira mentor | comandos citam a KB; param de re-delegar |
| Operações de PR/CI/Release em prosa abstrata (camada inexistente) | **Extrair SDAAL adapter** → `.claude/utils/forge/` (gh-first, REST fallback) | camada de transporte concreta e plugável |
| Integração Task Manager reimplementada em 7+ arquivos | **Shed → adapter existente** → comandos citam `getTaskManager()` | uma linha citada por comando, zero reimplementação |
| Lógica GitFlow (sessão, semver, dual-merge) duplicada | **Shed ceremony → KB** → folded para `gitflow-patterns.md` como fonte única | comandos finos (~−49% de linhas) |
| `code-review.md` (CI config) na pasta git/ | **Consolidar/realocar** → `meta/setup-code-review` + alias | categoria correta; caminho preservado |
| 7 shims de ciclo de vida + 3 subpastas (`feature/`,`release/`,`hotfix/` × start/publish/finish) | **Dispatcher arg-driven** → `git/flow.md` (`/git:flow <tipo> <ação>`) | 13 arquivos+3 subpastas → 7 arquivos, 0 subpastas |

Decisão crítica respeitando invariante: o "motor GitFlow" virou **KB** (não `utils/gitflow/`), porque GitFlow não tem *providers intercambiáveis* — não é caso de adapter SDAAL. E `engineer/pr` (fase 5 do workflow faseado) foi **afinado internamente** (rotear PR pelo forge adapter), **nunca** fundido com outra fase.

> **Lição estrutural (2026-06-13):** afinar o *conteúdo* de cada comando expôs que 7 shims quase idênticos não justificavam existir como arquivos separados — peso **estrutural** ≠ peso de conteúdo. A consolidação num **dispatcher** (verbos como argumento) foi o segundo passo. Regra derivada: *verbos/fases de um mesmo fluxo sem estado retomável → dispatcher único, não N arquivos/subpastas* (ver tabela de decisão, linha "Verbos de um fluxo"). Atenção: isso **não** se aplica a `engineer/*`/`product/*` (faseados retomáveis = invariante).

---

## ♻️ O loop de auto-evolução (onde a doutrina se encaixa)

```
/meta:evolve (sensor, read-only)  → audita o framework via Workflow → backlog priorizado
  ├─ compõe /meta:kb-freshness        (frescor de KBs)
  └─ compõe /meta:metaspec-validate   (conformidade L0)
        ↓ cada item do backlog cita uma regra desta DOUTRINA
ESTA KB (julgamento)              → qual padrão aplicar? consolidar / adapter / KB / skill / fan-out / comando-fino
        ↓ executa via
/meta:create-{command,agent,skill,abstraction,knowledge-base} (atuadores)
   (consolidações de cluster roteiam por /product:spec → /engineer:plan, nunca fusão direta de fase)
        ↓
@metaspec-gate-keeper (governador — valida, nunca contornado)
        ↓
/meta:kb-freshness (mantém docs vivos, incluindo esta doutrina)
        ↺ re-rodar /meta:evolve mede "depois" vs o backlog anterior
```

Papéis: **`/meta:evolve`** = sensor (audita, propõe, não muta). **Esta KB** = julgamento (qual padrão). **`/meta:create-*`** = atuadores (geram o artefato enxuto). **`@metaspec-gate-keeper`** = governador. **`/meta:kb-freshness`** = sistema imune.

---

## 🔜 Próximos clusters candidatos (flagados, não resolvidos)

A serem modernizados em iterações seguintes aplicando esta doutrina (cada um exige seu próprio juízo via tabela acima):

- **Agentes `branch-*`** (`branch-code-reviewer`, `branch-test-planner`, `branch-documentation-writer`, `branch-metaspec-checker`) — espelham agentes top-level; servem `/engineer:pre-pr`. Avaliar consolidação só se as 4 dimensões colapsam sem perder cobertura.
- **Testing 3→2** (`test-agent`/`test-engineer`/`test-planner`) — overlap de estratégia vs implementação vs cobertura.
- **Meta creators vs comandos `/meta:create-*`** — verificar overlap entre `@agent-creator-specialist`/`@command-creator-specialist`/`@agent-skills-specialist` e os comandos homônimos.

---

## 📚 Fontes e referências

- [SDAAL — padrão de adapter](specification-driven-ai-abstraction-layer.md)
- [Agent Fleet Orchestration — 6 padrões canônicos](agent-fleet-orchestration.md)
- Meta-specs (constituição): [commands.md](../../meta-specs/commands.md) · [architecture.md](../../meta-specs/architecture.md) · [integrations.md](../../meta-specs/integrations.md)
- [Baseline de V&V — jun/2026](../../analysis/onion-vv-baseline-2026-06.md) (auditoria manual que `/meta:evolve` automatiza)
- [Retrospectiva T3.2](../../analysis/t32-pilot-retrospectiva-2026-06.md) (worked example de cerimônia-vs-valor)
- Adapters de referência: [`utils/task-manager/`](../../../.claude/utils/task-manager/README.md) · [`utils/forge/`](../../../.claude/utils/forge/README.md)
- Motor GitFlow (worked example): [gitflow-patterns.md](../frameworks/gitflow-patterns.md)
