# Ciclo de Vida do Contexto de Domínio

> **Versão**: 1.0.0 | **Última atualização**: 2026-06-16 | **Categoria**: Conceitos
> Gramática operacional que trata cada contexto de domínio (`business-context/`, `technical-context/`, `compliance-context/`) como **SSOT viva com ciclo de vida CRUD+**, não como artefato snapshot gerado uma única vez. Fundamenta a regra L0 em [architecture.md](../../meta-specs/architecture.md) e a decisão em [onion-adr-domain-context-lifecycle-2026-06.md](../../analysis/onion-adr-domain-context-lifecycle-2026-06.md).

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-06-16 |
| **Última Atualização** | 2026-06-16 |
| **Categoria** | Conceitos |
| **Comando relacionado** | `/docs:build-business-docs` · `/docs:build-tech-docs` · `/docs:build-compliance-docs` (primeiro tick) · `/meta:kb-freshness` (molde da fase *Manage*) |
| **Padrão-pai** | [Doutrina de Modernização do Onion](onion-modernization-doctrine.md) · [Orquestração de Agentes](agent-orchestration.md) |

### Fontes

**Estado da arte (2026):**
- Anthropic — *Effective context engineering for AI agents* (curadoria de contexto como disciplina de engenharia)
- *Context Development Lifecycle* (vibesparking) — o ciclo Generate → Manage → Retire
- *Git Context Controller* — arXiv 2508.00031 (versionamento e governança de contexto como código)
- Achado convergente das três fontes: **"managing is the hard part — where most systems struggle or outright fail"**

**Relacionados no Onion:**
- [Doutrina de Modernização do Onion](onion-modernization-doctrine.md) — vizinha (peso/acoplamento de artefatos)
- Meta-specs: [architecture.md](../../meta-specs/architecture.md) · [code-standards.md](../../meta-specs/code-standards.md)
- [`/meta:kb-freshness`](../../../.claude/commands/meta/kb-freshness.md) — molde reusável da fase *Manage*

---

## 🎯 Propósito

Os três geradores de contexto de domínio do Onion produzem documentação multi-arquivo a partir de evidência — mas só modelam o **primeiro tick**: a geração. O que acontece *depois* (a doc envelhece, o código muda, a fonte é abandonada) não tinha doutrina.

A pesquisa de 2026 converge num diagnóstico único: a fase **"Manage"** (validar / pesar-por-frescor / remover-stale / reorganizar) é o ponto cego universal dos sistemas de contexto. E o modo de falha mais perigoso é específico: **contexto stale engana ativamente** — uma doc desatualizada não é neutra como uma ausente; ela faz a IA agir com confiança sobre uma realidade que já não existe. **Remover é frescor.**

Esta KB define a gramática que trata cada contexto de domínio como **SSOT viva com ciclo CRUD+**. Premissa central: o valor de um contexto não é seu volume nem seu ineditismo de geração — é sua **fidelidade contínua à realidade do projeto.**

---

## 🧬 A gramática do ciclo de vida (CRUD+)

Cada operação abaixo é vista pela ótica do **agente consumidor** (a IA que vai *ler* o contexto para agir), não pela ótica do autor. ROI = quanto a operação aumenta a fidelidade do contexto por unidade de esforço.

| Operação | ROI | Como (ótica do agente consumidor) |
|---|---|---|
| **Pesos** | alto, **derivado** | A relevância de um fragmento é *derivada* — posição na progressive-disclosure (`index.md` → camada → arquivo) + carimbo de frescor + tier de evidência (código > config > doc atual > inferência). **Nunca** um número mágico declarado no frontmatter. |
| **Formato** | alto | Markdown + frontmatter leve, multi-arquivo linkado por `index.md`, nomes em **kebab-case**. Um arquivo por preocupação; nunca um documento monolítico. |
| **Adicionar** | alto, **disciplinado** | Regra da 2ª ocorrência: só promova a contexto o que se repetiu *e* muda o comportamento do consumidor. Adicionar ruído reduz o sinal de tudo o mais. |
| **Remover** | **altíssimo** | Stale engana ativamente → remover doc obsoleta *é* operação de frescor, não perda. Maior ROI da tabela; hoje ausente nos geradores. |
| **Alterar** | alto | Edição in-place com proveniência (de onde veio) + data de atualização. Não acumular versões mortas no mesmo arquivo. |
| **Inferir** | médio, **condicional** | Inferência só é legítima se **marcada** (`[INFERIDO]`) e **validável** (aponta a evidência-base). Sem evidência → `[TO BE COMPLETED]`, jamais invenção. |
| **Agrupar / Desagrupar** | alto | Chunking por **co-recuperação** (o que é lido junto fica junto), não por taxonomia estética. |
| **Reorganizar** | médio | Só quando os *padrões de acesso* mudam — reorganizar por gosto é churn sem ROI. |
| **Validar** | **altíssimo (o gate)** | Rastreabilidade (toda afirmação ancorada) + frescor (carimbo ≤ threshold) + contradição cross-domínio (business ↔ technical ↔ compliance não se contradizem). É o portão que decide se o contexto ainda merece confiança. |

**Remover** e **Validar** são as operações de **primeira classe** — maior valor, e exatamente as que faltam hoje. A geração (Adicionar) é só o primeiro tick.

---

## 📐 Eficiência × Eficácia × Valor

- **Eficiência** (fazer certo): formato, pesos derivados, agrupar/reorganizar — minimizam o custo de o agente *encontrar e carregar* o contexto certo.
- **Eficácia** (fazer a coisa certa): adicionar disciplinado, inferir condicional, alterar com proveniência — garantem que o que está lá *corresponde* à realidade.
- **Valor** (o que move o ponteiro): **remover** e **validar** — protegem contra o modo de falha caro (stale que engana). É onde a fase *Manage* mora.

A geração-snapshot otimiza só a eficiência do primeiro tick. A SSOT viva otimiza valor ao longo do tempo.

---

## 🪜 Promoção de domínio a peer

O Onion trata **três contextos peer**: business, technical, compliance. As sub-camadas **Decisional** (ADRs) e **Operacional/Runtime** vivem *dentro* de `technical-context/` por padrão — não são peers por default.

Promova uma sub-camada a **contexto peer** (pasta `docs/<nome>-context/` própria) somente quando os **três** critérios valerem juntos:

1. **Dono distinto** — uma função/papel diferente é responsável pelo conteúdo (não é o mesmo time do contexto-pai).
2. **Ritmo de mudança distinto** — o conteúdo muda em cadência própria (ex.: compliance muda por ciclo de auditoria; código muda por sprint).
3. **Decisão distinta que informa** — o consumidor usa esse contexto para uma decisão que os outros peers não cobrem.

Recorte por **dono × ritmo × decisão**, nunca por organograma. O projeto-alvo promove quando se justifica; o framework não força.

---

## 🔄 A fase *Manage* (contrato para a camada executável)

Esta KB define a **doutrina**. A execução da fase *Manage* (auditar frescor de contexto, barrar staleness no CI, compor no loop de auto-evolução) **reusa o molde já existente** de [`/meta:kb-freshness`](../../../.claude/commands/meta/kb-freshness.md), em vez de inventar maquinaria nova:

- **Verdito** por arquivo: `CURRENT` / `STALE` / `HISTORICAL`.
- **Threshold de frescor** herdado: cada arquivo carrega `Última Atualização`; ausente ou **> 18 meses** = candidato a STALE.
- **Fan-out** via [`onion-orchestration`](../../../.claude/skills/onion-orchestration/SKILL.md) (pattern `fan-out-and-synthesize`): worker por arquivo/diretório (tier haiku) → fan-in (tier sonnet) → retorno no formato `FreshnessSchema[]`.
- **Composição** no [`/meta:evolve`](../../../.claude/commands/meta/evolve.md) como dimensão **no fluxo principal** — como D4/D5 hoje delegam a `kb-freshness`/`metaspec-validate` sem aninhar orquestração dentro de orquestração.

> **Tijolo 2 entregue (2026-06-17):** a fase *Manage* é executada pelo comando
> [`/meta:context-freshness`](../../../.claude/commands/meta/context-freshness.md) (veredito
> CURRENT/STALE/HISTORICAL, fan-out via `onion-orchestration`, contradição cross-domínio no fan-in),
> com a Regra 15 do lint exigindo o carimbo de frescor e a dimensão D9 do `/meta:evolve`
> compondo a auditoria. Esta KB é a doutrina (Tijolo 1) que esse comando executa.

> **Irmã (2026-07-04):** a mesma tese ("stale engana ativamente") foi estendida ao 4º contexto
> auditável — a **memória de sessão do harness** — em
> [session-memory-lifecycle.md](session-memory-lifecycle.md) (3 classes de apodrecimento,
> 3 gatilhos, dimensão **D10** do `/meta:evolve`).
