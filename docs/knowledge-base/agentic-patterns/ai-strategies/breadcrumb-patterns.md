# Breadcrumb Patterns — Forçar Absorção vs Acomodação

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-06-30 |
| **Status** | `draft` — taxonomia levantada; evidência empírica pendente |
| **Tags** | `transformer`, `breadcrumb`, `acomodação`, `absorção`, `sdaal`, `guia` |

---

## 🎯 O Problema

O transformer infere pelo **mais provável no corpus de treinamento**. Em sistemas
idiossincráticos (Onion, rhilo-app, qualquer produto custom), o "mais provável" está
frequentemente **errado** — o modelo adivinha uma convenção genérica em vez de seguir
a intenção do sistema.

**Acomodação** = o modelo infere o contexto mais próximo e vai com ele, sem questionar.

**Absorção** = o modelo lê um sinal explícito embutido no artefato e o segue, mesmo
que contradiga o que ele "esperaria" por padrão.

> "A IA se acomoda, ela absorve — a menos que você force com uma migalha de pão."

---

## 🍞 O que é um Breadcrumb

Um **breadcrumb** é um sinal explícito embutido **no próprio artefato** (código, arquivo,
estrutura de diretório) que guia o transformer a absorver a intenção certa em vez de
acomodar o mais provável.

Diferente de instruções no prompt (temporárias, fora do artefato), breadcrumbs são
**persistentes e estruturais** — sobrevivem ao contexto da conversa e chegam ao modelo
junto com o código que descrevem.

---

## 🗂️ Taxonomia de Padrões

### Por canal

| Padrão | Exemplo | Canal | Durabilidade |
|--------|---------|-------|-------------|
| CSS custom property semântica | `--onion-bg`, `--color-scheme: light` | CSS | Build-time |
| CSS selector como âncora | `.aui-root`, `[data-slot="composer"]` | CSS/HTML | Estrutural |
| Atributo HTML declarativo | `data-onion-agent="code-reviewer"` | HTML | Runtime |
| Comentário-spec inline | `/* @onion: invariant */` | Código | Estrutural |
| Frontmatter YAML | `schema: FINDINGS_SCHEMA`, `type: field-signal` | Arquivo | Estrutural |
| Naming convention de diretório | `_processed/`, `outbox/`, `inbox/` | Filesystem | Estrutural |
| Enum/union type | `type: "courtesy" \| "byok"` | TypeScript | Build-time |
| Tag de annotation | `@sdaal`, `@origin: env` | Código | Estrutural |

### Por problema-alvo

| Problema de Acomodação | Breadcrumb Correto |
|------------------------|-------------------|
| Tema visual incorreto | CSS vars com semântica explícita (`--color-scheme: light`) |
| Estrutura de componente errada | `data-slot` ou seletores `aui-*` |
| Contrato de interface ignorado | Types/schemas TypeScript que fecham o espaço de inferência |
| Fluxo de trabalho não seguido | Naming de diretório (`outbox/`, `_processed/`) |
| Papel do agente confundido | `data-onion-agent=` ou frontmatter `role:` |

---

## 🔗 Conexão com o Onion

O Onion já usa breadcrumbs **implicitamente**:
- `origin: "env"` em token-store → sinal de proveniência
- `data-slot` no assistant-ui → âncora estrutural
- `_processed/` → convenção de lido/não-lido (usado no doc-bridge)
- `role: source | adopted` no `.onion-version` → sinal de papel do repo
- `status: assess | trial | backlog` no frontmatter dos sinais → máquina de estado legível

A promoção formal como **padrão canônico do core** está pendente — este documento
é o primeiro passo.

---

## 🔬 Pesquisa Pendente

**Pergunta de pesquisa:**
> Quais breadcrumbs o transformer realmente *absorve* (vs ignora ou relê errado)?
> Como construir a régua de seleção por tipo de problema?

**Hipótese:** breadcrumbs em canais de alta visibilidade (frontmatter YAML, types TypeScript,
naming de diretório) têm absorção mais alta do que breadcrumbs em comentários inline,
porque os primeiros chegam ao contexto de forma mais proeminente.

**Próximo passo:** experimento empírico — testar os padrões da tabela acima com o transformer
e medir absorção vs acomodação. O DataTable premium (rhilo-app) pode ser o caso de teste
(já temos o before/after do processo imperativo vs dirigido).

---

## 📎 Referências

- Memória: `ai-accommodates-absorbs-breadcrumb-taxonomy` (origem desta entrada)
- Memória: `breadcrumb-dogfood-fleet-criterion` (quando usar frota vs breadcrumb)
- KB: [Object-Led Discovery](object-led-discovery.md) — usa breadcrumbs no Capability Contract
- KB: [Claude Code Internals](../harness/claude-code-internals.md) — naming conventions como breadcrumb (ex: `_processed/`)
