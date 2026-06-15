# Press Kit — Sistema Onion

**Status:** Esqueleto (Fase 4 — Materiais Derivados)
**Fonte:** [Onion: Identidade e Produto](../knowledge-base/meta/onion-framework-identity.md)
**Data:** 2026-06-15

> Kit de imprensa para jornalistas, criadores de conteúdo e parceiros. Todo o conteúdo deriva da KB canônica de identidade — para profundidade ou citação literal, desça à fonte linkada acima.

---

## 1. One-pager (Resumo Executivo)

### O que é

O **Sistema Onion** é um framework template em `.claude/` que instala num repositório o ciclo completo de desenvolvimento orientado por IA — **produto, engenharia e compliance** — sem alterar uma linha de código do projeto-alvo. Não é uma CLI, não tem pacote npm, não exige mudança de stack: é configuração pura que transforma o Claude Code no cérebro orquestrador do fluxo de trabalho.

### O problema

Times que adotam IA para desenvolvimento esbarram em quatro dores recorrentes:

- **Orquestração manual e frágil** — prompts ad-hoc por tarefa, sem memória de workflow nem reuso.
- **Cada integração é caso especial** — Jira exige ADF, ClickUp exige Unicode, Asana exige HTML; cada provider vira reescrita.
- **Contexto perdido a cada interrupção** — retomar trabalho significa reexplicar tudo do zero.
- **Compliance como silo** — documentação ISO/SOC2 criada depois, manualmente, desconectada da entrega.

### A solução

O Onion entrega **workflows codificados** (82 comandos invocáveis), **especialistas de IA** (49 agentes em 9 categorias) e **skills de orquestração** (5), cobrindo três dimensões *peer* — nenhuma hierarquizada sobre a outra. Conecta-se ao gerenciador de tarefas existente (Jira, ClickUp, Asana ou Linear) e ao host de código (GitHub) via uma camada de abstração agnóstica (SDAAL): trocar de provider é mudar o `.env`, não o código. Sessões retomáveis com `STATE.md` preservam contexto entre interrupções, e cinco agentes de compliance (ISO 27001, SOC2, PMBOK, ISO 22301) operam dentro do mesmo ciclo de entrega.

### Métricas-chave

| Métrica | Valor |
|---------|-------|
| Comandos invocáveis | 82 (9 categorias) |
| Agentes especializados | 49 (9 categorias) |
| Skills de orquestração | 5 |
| Knowledge Bases | 34 |
| Task Managers suportados | 4 (Jira, ClickUp, Asana, Linear) |
| Dimensões da auto-auditoria | 8 (D1–D8) |
| Comandos com `allowed-tools` escopado | 82/82 (100%) |
| Agentes migrados Cursor→native | 49/49 (100%) |

*(Fonte: KB seção 6 — Métricas e Evidências.)*

### Diferencial

O ciclo é **tri-dimensional e simétrico**: Produto, Engenharia e Compliance são peers, adotáveis independentemente. E o framework se **auto-audita** — `/meta:evolve` dispara ~28 agentes em 8 dimensões e produz um backlog priorizado com evidência citada, sem revisão manual artefato-a-artefato.

---

## 2. FAQ para Imprensa

**O Onion substitui desenvolvedores?**
Não. O humano-maestro é invariante do framework. O Onion orquestra o trabalho — codifica workflows, delega a agentes especialistas, preserva contexto — mas a direção, a revisão e a decisão permanecem humanas. Direções que beiravam o "agente autônomo fora de controle" foram formalmente abandonadas em 2026-05-18.

**É open source? Tem pacote para instalar?**
O Onion é um framework template que vive inteiramente em `.claude/`. Não é distribuído como produto npm, não tem CLI standalone. A instalação é copiar `.claude/` para o projeto, configurar o `.env` e rodar `/warm-up` — um dev experiente faz em menos de 2 horas.

**Funciona com qualquer IDE?**
Não, e isso é uma escolha deliberada. A aposta é **profundidade de integração com o Claude Code**, não portabilidade entre IDEs. Suporte multi-IDE (Cursor, Zed, Windsurf) foi formalmente abandonado em 2026-05-18 — diluiria a integração que é o diferencial.

**Preciso mudar meu stack para usar?**
Não. Código, linguagem, framework e infra do projeto não são tocados — o Onion vive 100% em configuração. Funciona em qualquer projeto: novo, legado ou regulado.

**Funciona com qualquer gerenciador de tarefas?**
Sim, para Jira, ClickUp, Asana ou Linear — basta definir `TASK_MANAGER_PROVIDER` no `.env`. O mesmo comando funciona em todos os providers porque a formatação e o transporte ficam no adapter, não no comando. Sem provider configurado, o modo `none` permite uso offline com decomposição local.

**Qual é o modelo de negócio?**
O Onion não é um produto comercial distribuído publicamente nem um SaaS. É um framework template — configuração que roda sobre o Claude Code como plataforma. Não há licença, assinatura própria ou CLI a vender; o que existe é o framework e sua documentação.

**Quem mantém isso?**
O Sistema Onion é mantido como framework próprio, e parte da manutenção é feita **pelo próprio framework**: `/meta:evolve` audita 8 dimensões (peso, redundância, duplicação, KBs desatualizadas, conformidade, legado, links, frontmatter) e gera o backlog de evolução com evidência citada. A migração de 49 agentes do dialeto Cursor para nomes de ferramenta nativos é um exemplo real desse processo.

**Como entra a parte de compliance?**
Agentes como `@iso-27001-specialist` e `@soc2-specialist` leem o estado real do projeto — código, arquitetura, processos — e geram ou atualizam a documentação de conformidade dentro do mesmo ciclo de entrega, não como silo posterior. `@security-information-master` detecta qual framework aplicar (ISO 27001, SOC2, PMBOK, ISO 22301).

---

## 3. Bio / Descrição do Projeto

### Versão curta (~50 palavras)

O Sistema Onion é um framework template em `.claude/` que instala num repositório o ciclo completo de desenvolvimento orientado por IA — produto, engenharia e compliance — sem alterar o código do projeto. Roda sobre o Claude Code, integra-se a Jira/ClickUp/Asana/Linear e GitHub, e se auto-audita periodicamente.

### Versão longa (~150 palavras)

O Sistema Onion é um framework de orquestração de desenvolvimento que vive inteiramente em `.claude/`, a pasta de configuração do Claude Code. Ao ser instalado num projeto, entrega 82 comandos invocáveis, 49 agentes especializados de IA e 5 skills de orquestração, cobrindo três dimensões *peer*: produto (discovery → backlog), engenharia (planejamento → PR) e compliance (ISO 27001, SOC2, PMBOK, ISO 22301). Conecta-se ao gerenciador de tarefas existente — Jira, ClickUp, Asana ou Linear — e ao host de código via uma camada de abstração agnóstica (SDAAL), de modo que trocar de provider é mudar o `.env`, não o código. Sessões retomáveis preservam contexto entre interrupções, e o comando `/meta:evolve` faz o framework se auto-auditar em 8 dimensões. Não é uma CLI, não tem pacote npm e não exige mudança de stack — é configuração pura que transforma o Claude Code no cérebro orquestrador do fluxo de trabalho.

---

## 4. Citações-chave Prontas para Uso

### Produto

> "Framework template em `.claude/` projetado para ser instalado e aplicado em qualquer projeto — novo, legado ou regulado — para orquestrar o ciclo completo de desenvolvimento com Claude Code."
> — `CLAUDE.md` (identidade canônica)

> "As três dimensões são peer, não hierarquizadas."
> — onion-review-2026-05.md §1

> "O veredito: substantialmente completo em cobertura."
> — onion-review-2026-05.md §1 (estado pós P0–P3)

### Engenharia

> "Workflow = orquestração que o orquestrador desenha. Agent Teams = coordenação que emerge."
> — onion-agent-teams-evaluation-2026-06.md §3

> "Conserta o propagador, não só as folhas."
> — princípio de refatoração em escala (migração Cursor→native)

> "Task Manager Abstraction madura — padrão SDAAL real, 4 adapters, fallback gracioso, formatação tipada por provider."
> — onion-review-2026-05.md §Top 5 forças

### Governança

> "Cada Onion defende seus interesses — o repo dono valida localmente as mudanças que o afetam."
> — onion-federation-design-v2-2026-06.md §2

> "Read-only por contrato. O comando nunca muta `.claude/`; a única escrita é o relatório em `docs/analysis/`."
> — evolve.md §Objetivo

> "28 agentes · 1.27M tokens · 635 tool-uses · ~26 min" — custo de uma auto-auditoria completa.
> — onion-evolution-2026-06-15.md §0

---

## 5. Boilerplate — Sobre o Sistema Onion

> **Sobre o Sistema Onion** — O Sistema Onion é um framework template em `.claude/` que instala num repositório o ciclo completo de desenvolvimento orientado por IA — produto, engenharia e compliance — sem alterar uma linha de código do projeto. Rodando sobre o Claude Code, oferece 82 comandos, 49 agentes especializados e 5 skills de orquestração, integra-se a Jira, ClickUp, Asana, Linear e GitHub via abstração agnóstica, e se auto-audita periodicamente. Não é uma CLI nem um pacote npm: é configuração pura que transforma o Claude Code no cérebro orquestrador do fluxo de trabalho.

---

## Referências

- **Fonte canônica:** [Onion: Identidade e Produto](../knowledge-base/meta/onion-framework-identity.md) — seções 1, 6, 8 e 9.
- **Material bruto (citações linha-a-linha):** `docs/analysis/onion-product-material-raw-2026-06.md`
- **Identidade canônica:** `CLAUDE.md` · `docs/analysis/onion-review-2026-05.md`
