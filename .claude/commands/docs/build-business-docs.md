---
name: build-business-docs
description: Gerar arquitetura de contexto de negócio na pasta declarada (default `docs/business-context/`).
allowed-tools: Read Write Skill WebSearch Bash(find *) Bash(bash .claude/utils/scope/resolve-context-dir.sh *)

parameters:
  - name: sources
    description: Links, paths ou descrições das fontes (README, landing pages, repositórios, materiais de marketing, feedback)
    required: true

category: docs
tags:
  - business
  - context
  - documentation
  - spec-as-code

version: "4.2.0"
updated: "2026-10-29"

output_path: docs/business-context/

related_commands:
  - /docs:build-tech-docs
  - /meta:create-knowledge-base
  - /docs:build-index
  - /meta:inventory
  - /onion-research

related_agents:
  - product-agent
  - research-agent
  - storytelling-business-specialist
  - branding-positioning-specialist
---

# 🎯 Gerador de Contexto de Negócio

Você é um analista de negócios e estrategista de produto que produz **inteligência de negócio acionável para IA**. Sua missão é analisar o projeto/produto e gerar uma arquitetura de contexto de negócio multi-arquivo em `docs/business-context/`.

---

## 📁 Pasta-alvo (resolva antes de gravar)

A pasta não é fixa. O repo pode declará-la em `.claude/onion-context.yaml` (`context.business`), e a
declaração vence a convenção (skill `onion-product-context` §2):

```bash
bash .claude/utils/scope/resolve-context-dir.sh business --source   # → "<caminho><TAB><onion-context|default>"
```

Neste comando, **`docs/business-context/` quer dizer a pasta que ele imprimiu** (o default só vale quando ele diz
`default`). Saída `3` = declaração inválida: **pare** e mostre o erro, não grave no default.

---

## 🎯 Objetivo

Gerar a arquitetura de contexto de negócio seguindo o template `.claude/commands/common/templates/business-context-template.md`, na pasta canônica `docs/business-context/`, organizada em 4 camadas (Cliente / Produto / Mercado / Operacional).

Resultado esperado: documentação modular que permite que IA e humanos entendam clientes, dinâmica de mercado e estratégia.

---

## 📥 Input

<arguments>
#$ARGUMENTS
</arguments>

**Fontes esperadas (uma ou mais):**
- README do projeto, landing pages, sites institucionais
- Materiais de marketing, posts de blog, estudos de caso
- Issues do GitHub, tickets de suporte, avaliações, depoimentos
- Sites de concorrentes, análises de mercado
- Documentos internos (visão, estratégia, OKRs)

> Se `$ARGUMENTS` estiver vazio, solicite as fontes ao usuário antes de prosseguir.

---

## ⚡ Fluxo de Execução

### Fase 1 — Descoberta

**1.1 Entendimento do produto**
- Analisar README, descrições e materiais de marketing
- Extrair proposta de valor de landing pages, documentação e posicionamento
- Identificar mercado-alvo a partir de funcionalidades e mensagens
- Entender modelo de negócio (preço, monetização, fluxos de receita)

**1.2 Pesquisa de mercado**
- Pesquisar panorama competitivo pela skill **`onion-research`**, que conduz ao workflow `/onion-research`:
  ela injeta o corpus que os grafos já têm, fixa os eixos invariantes (mercado e capital, trajetória,
  analistas, comunidade) e grava o resultado num `.kg.yaml` com tier de fonte e radar rc 0. Não use
  `WebSearch` avulso nem agente de pesquisa solto com o grafo montado à mão; se o workflow não estiver
  disponível, declare o desvio no `index.md`
- Identificar tendências do setor e dinâmicas de mercado
- Analisar segmentos de cliente e casos de uso
- Mapear ambiente regulatório quando relevante

**1.3 Inteligência do cliente**
- Coletar feedback de issues, suporte, avaliações
- Extrair personas a partir de comportamento e uso
- Mapear jornada via onboarding e UX
- Identificar padrões de comunicação preferidos

**1.4 Resolução de evidência conflitante**

Fontes podem se contradizer. Ordem de precedência (mais forte → mais fraca):
1. Dados reais (telemetria, issues, feedback, contratos)
2. `CLAUDE.md` e docs marcadas como atuais
3. `README.md` / materiais oficiais vigentes
4. Docs sem marcação de status
5. Docs históricas/abandonadas → **não** usar como verdade atual

Registre conflitos relevantes explicitamente e sinalize a fonte desatualizada
como follow-up, em vez de propagar a contradição.

### Fase 2 — Discussão com o usuário

Faça **pelo menos 10 perguntas** cobrindo as áreas estratégicas, mas só as relevantes para o projeto (não pergunte o que já está claro nas fontes). Cubra:

- Visão e missão do produto
- Personas e tomadores de decisão
- Concorrentes e diferenciação
- Stakeholders e canais
- Funcionalidades e workflows críticos
- Métricas e KPIs
- Riscos, dependências e restrições
- Oportunidades não óbvias

Faça múltiplas rodadas se necessário. Ao final, apresente um **resumo dos pontos detectados** e peça aprovação para gerar a documentação.

> **Modo não-interativo (infer-from-evidence).** Sem usuário disponível (agente/
> piloto/automação), não bloqueie: infira das fontes, marque cada inferência com
> `[INFERIDO]` e liste as suposições numa seção "Pendências de validação" no
> `index.md`. Sem evidência → `[TO BE COMPLETED]`, nunca invenção.

**As três marcas de lacuna** (valem nos dois modos, interativo ou não):

| Marca | Quando usar |
|-------|-------------|
| `[INFERIDO]` | a afirmação foi deduzida das fontes, sem confirmação de quem decide |
| `[TO BE COMPLETED]` | falta evidência; o dado existe, mas não foi coletado |
| `[DECISÃO PENDENTE]` | é uma decisão de quem é dono do negócio que ainda não foi tomada ou aferida e que não pode ser inferida das fontes (preço, segmento prioritário, oferta). Liste-a nas "Pendências de validação" do `index.md`, com quem decide |

### Fase 3 — Geração

Gere os arquivos em `docs/business-context/` seguindo a estrutura abaixo. Crie apenas os arquivos relevantes ao projeto (não é obrigatório preencher todas as camadas).

> **Carimbo de frescor em cada arquivo.** Pela REGRA 15 (Frescor de contexto de domínio: carimbo de
> atualização), todo arquivo gerado, exceto `index.md` e `README.md`, leva no cabeçalho, logo abaixo do título, a linha
> `> **Última Atualização:** YYYY-MM-DD`, com a data da geração. O lint casa pelo radical `Atualiza` (ou por
> `updated:`/`date:` no frontmatter); sem o carimbo, cada arquivo vira violação no primeiro commit, e a fase
> Manage (`/meta:context-freshness`) não tem como medir a idade. Ao regenerar, atualize a data só dos
> arquivos cujo conteúdo mudou.

> **Convenção de nomes (esta seção tem precedência sobre o template-base).** Use
> **kebab-case minúsculo** para todos os arquivos (`personas.md`,
> `competitive-landscape.md`), exatamente como na estrutura abaixo. Se o
> `business-context-template.md` sugerir nomes em UPPERCASE, **ignore** — a
> estrutura deste comando é a autoritativa.

```
docs/business-context/
├── index.md
├── 01-customer/
│   ├── personas.md
│   ├── journey.md
│   └── voice-of-customer.md
├── 02-product/
│   ├── strategy.md
│   ├── metrics.md
│   └── features/
│       └── <feature>.md
├── 03-market/
│   ├── competitive-landscape.md
│   └── industry-trends.md
└── 04-operations/
    ├── sales-process.md
    ├── messaging-framework.md
    └── customer-communication.md
```

#### Conteúdo dos arquivos

| Arquivo | Conteúdo |
|---------|----------|
| `index.md` | Perfil do negócio + links para todas as camadas geradas |
| `01-customer/personas.md` | Personas primárias (demografia, objetivos, dores, contexto tech, guideline IA) |
| `01-customer/journey.md` | Ciclo completo: descoberta → avaliação → adoção → crescimento → advocacy/churn |
| `01-customer/voice-of-customer.md` | Padrões de feedback, terminologia do cliente, temas recorrentes |
| `02-product/strategy.md` | Visão/missão, posição de mercado, prioridades estratégicas, princípios |
| `02-product/metrics.md` | KPIs de adoção, qualidade, performance e correlação |
| `02-product/features/<feature>.md` | Por feature: propósito, benefício, métricas, issues comuns, guideline IA |
| `03-market/competitive-landscape.md` | Concorrentes diretos/indiretos, posicionamento, win/loss, objeções |
| `03-market/industry-trends.md` | Evolução do setor, tendências tecnológicas, regulamentação |
| `04-operations/sales-process.md` | Metodologia (B2B/B2C/Open Source), qualificação, objeções, retenção |
| `04-operations/messaging-framework.md` | Brand voice, value props, mensagens por audiência |
| `04-operations/customer-communication.md` | Guidelines para IA: tom, escalation, privacidade, personalização |

---

## 📤 Output Esperado

```
✅ BUSINESS CONTEXT GERADO

━━━━━━━━━━━━━━

📁 Localização: docs/business-context/

📊 ESTRUTURA:
   ∟ index.md
   ∟ 01-customer/   (N arquivos)
   ∟ 02-product/    (N arquivos)
   ∟ 03-market/     (N arquivos)
   ∟ 04-operations/ (N arquivos)

📚 FONTES CONSULTADAS:
   ∟ <fontes>

🚀 PRÓXIMOS PASSOS:
   ∟ Revisar com stakeholders
   ∟ /docs:build-tech-docs (contexto técnico)
   ∟ /docs:build-index (atualizar índice mestre)
   ∟ /meta:inventory (o inventário conta os arquivos de business-context/)

━━━━━━━━━━━━━━

⏰ Gerado: YYYY-MM-DD | 🎯 Status: Done
```

---

## ✅ Quality Assurance

### Conteúdo
- [ ] Toda afirmação tem fonte rastreável (issue, depoimento, métrica, web search)
- [ ] Análise competitiva usa informação verificável e atual
- [ ] Modelo de negócio reflete realidade (não inventado)
- [ ] Pontos não verificáveis estão marcados como `[TO BE COMPLETED]`, e decisões do dono não tomadas, como `[DECISÃO PENDENTE]`
- [ ] Cada arquivo gerado (exceto `index.md` e `README.md`) tem a linha `Última Atualização` no cabeçalho

### Otimização para IA
- [ ] Personas incluem guidelines de interação com IA
- [ ] Comunicação tem regras acionáveis para sistemas IA
- [ ] Cross-references entre arquivos via links Markdown
- [ ] `index.md` é o único ponto de entrada

### Completude
- [ ] Camadas relevantes ao projeto preenchidas
- [ ] Jornada cobre awareness → advocacy
- [ ] Estratégia alinhada com posicionamento real

### Sincronização
- [ ] **Passo final — sincronizar a SSOT:** após gerar, rodar **`/meta:inventory`**. O inventário conta os
  arquivos de `business-context/`, e a REGRA 8 (Inventário canônico sincronizado com o filesystem) é HARD:
  gerar sem regenerar barra o commit. Mecanismo: `common:prompts:inventory-sync-after-create`.

---

## 🔗 Referências

- **Template-base**: `.claude/commands/common/templates/business-context-template.md`
- **Pasta-alvo**: a resolvida por `resolve-context-dir.sh business` (default `docs/business-context/`)
- **Comando complementar**: `/docs:build-tech-docs`
- **Knowledge base**: `docs/knowledge-base/`

---

## ⚠️ Notas

- Não criar um único arquivo grande — sempre multi-arquivo linkado pelo `index.md`
- Marcar gaps como `[TO BE COMPLETED]` com hipóteses e passos de validação
- Regenerar quando contexto muda (pivot, PMF, expansão)
- Cross-link com `docs/technical-context/` quando feature técnica tem impacto de negócio
