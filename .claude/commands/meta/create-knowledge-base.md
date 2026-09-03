---
name: create-knowledge-base
description: Gerar knowledge base estruturada em `docs/knowledge-base/<category>/`.
allowed-tools: Write Bash(test -d *) Bash(mkdir -p *) Bash(ls *)

parameters:
  - name: topic
    description: Tema da knowledge base (ex. "OAuth 2.1", "PostgreSQL connection pooling", "Domain-Driven Design")
    required: true
  - name: category
    description: "Categoria (concepts | frameworks | tools | platforms | providers)"
    required: false

category: meta
tags:
  - knowledge-base
  - research
  - documentation
  - spec-as-code

version: "4.0.0"
updated: "2026-05-15"

output_path: docs/knowledge-base/

related_commands:
  - /meta/create-command
  - /meta/create-agent
  - /meta/create-skill
  - /docs:build-business-docs
  - /docs:build-tech-docs
  - /docs:build-index

related_agents:
  - research-agent
---

# 📚 Gerador de Knowledge Base

Você é um pesquisador técnico que produz **bases de conhecimento estruturadas, densas e otimizadas para IA**. Sua missão é pesquisar um tema e gerar uma KB referenciada em `docs/knowledge-base/<category>/<topic>.md`.

---

## 🎯 Objetivo

Criar uma KB sobre `{{topic}}` na pasta canônica `docs/knowledge-base/`, organizada por categoria, com fontes citadas e estrutura previsível para consumo por IA e humanos.

Resultado esperado: arquivo único, denso, navegável, com referências confiáveis e abaixo de 400 linhas.

---

## 📥 Input

<arguments>
#$ARGUMENTS
</arguments>

**Parâmetros:**
- `topic` (obrigatório) — tema da KB
- `category` (opcional, inferido se ausente) — `concepts` | `frameworks` | `tools` | `platforms` | `providers`

> Se `$ARGUMENTS` não trouxer `topic`, solicite ao usuário antes de prosseguir.

---

## ⚡ Fluxo de Execução

### Fase 1 — Análise do tema

**1.1 Interpretar requisito**
- Extrair `topic` de `$ARGUMENTS`
- Determinar `category` (se não passada) baseando-se na natureza do tema:

| Categoria | Quando usar |
|-----------|-------------|
| `concepts/` | Conceitos, metodologias, padrões abstratos (DDD, JTBD, Spec-as-Code) |
| `frameworks/` | Frameworks de desenvolvimento ou metodológicos (NestJS, Story Points) |
| `tools/` | Ferramentas concretas (Docker, Whisper, ZEN Engine) |
| `platforms/` | Plataformas e tecnologias (Runflow, AWS) |
| `providers/` | Provedores de serviços (Microsoft Graph, OpenAI API) |

**1.2 Validar estrutura no disco**

```bash
# Garantir que docs/knowledge-base/ existe
test -d docs/knowledge-base/ || mkdir -p docs/knowledge-base/{concepts,frameworks,tools,platforms,providers}

# Verificar duplicação
ls docs/knowledge-base/**/*<slug-do-topic>*.md 2>/dev/null
```

Se já existir KB sobre o tema, perguntar ao usuário: atualizar a existente, criar variante, ou abortar.

### Fase 2 — Pesquisa

Use `@research-agent` ou `WebSearch` para coletar:

1. **Documentação oficial** — fonte primária do tema
2. **Best practices 2025-2026** — recomendações atuais da comunidade
3. **Exemplos de uso** — código real, casos concretos
4. **Limitações conhecidas** — pontos de atenção, gotchas, anti-padrões
5. **Comparações relevantes** — alternativas e quando preferir cada uma
6. **Integrações** — como o tema se conecta a outras ferramentas/conceitos do projeto

> Cite fontes com URL completa. Conteúdo sem fonte deve ser marcado como `[INFERÊNCIA]`.

### Fase 3 — Geração

Salve em `docs/knowledge-base/<category>/<slug-do-topic>.md`.

> **Escolha a FAMÍLIA antes do template** (corrigido em 2026-08-18, medido): a versão anterior
> deste comando prescrevia UM template rígido que **apenas 2 das 86 KBs** do corpus seguiam — o
> gerador descrevia uma forma que 2% usava, e faria a próxima KB nascer fora de família. As
> famílias REAIS, medidas por seção-assinatura: **38 REFERÊNCIA** · **5 DOUTRINA** (as demais são
> variações livres sobre o núcleo comum). O invariante é o **núcleo**, não a lista de seções.

**Núcleo comum (obrigatório nas duas famílias):** título → bloco `## 📋 Metadata` (Versão, Data,
Categoria, Fontes) → seções temáticas → fecho com integrações/relacionados. Cite fontes com URL;
conteúdo sem fonte marcado `[INFERÊNCIA]`.

**FAMÍLIA A — REFERÊNCIA TÉCNICA** (default; a forma dominante do corpus). Para temas externos:
ferramenta, API, framework, prática de mercado. As seções abaixo são **sugestão de cobertura, não
contrato** — inclua as que o tema pede, corte as que não fazem sentido:

```markdown
# {{topic}} - Knowledge Base

## 📋 Metadata
| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | YYYY-MM-DD |
| **Categoria** | {{category}} |
| **Fontes Principais** | <lista numerada de URLs> |

## 📋 Visão Geral          ← o que é, para que serve
## 🎯 Casos de Uso          ← quando aplicar + anti-casos
## ⚡ Quick Start           ← setup mínimo executável (se o tema é operável)
## 💡 Best Practices        ← recomendações com fonte
## ⚠️ Limitações e Gotchas  ← pontos de atenção, restrições
## 🔗 Integração com o Sistema Onion
## 🔗 Referências
```

**FAMÍLIA B — DOUTRINA** (quando o tema é norma, critério ou método INTERNO que precisa poder
**reprovar** — ex.: `onion-abstraction-doctrine`, `onion-elenxo-doctrine`). A forma segue o
grupo-par das doutrinas existentes:

```markdown
# <Nome da doutrina> — <a tese em meia linha>

## 📋 Metadata               ← inclui Origem (o dano/medição que a motivou) e réguas irmãs
## 🎯 Por que esta doutrina existe   ← o incidente/medição fundador, não abstração
## <A régua>                 ← as condições/etapas com O QUE REPROVA cada uma
## <Limites declarados>      ← onde NÃO há gate mecânico e por quê (medido, não presumido)
## 🧭 Invariantes            ← numerados, verificáveis
## 🔗 Relacionados           ← as doutrinas irmãs por link relativo
```

> Nova forma que não cabe em A nem B? Compare com a **família** mais próxima do corpus antes de
> inventar — a régua de alinhamento é o grupo-par real, nunca este arquivo isolado.

---

## 📤 Output Esperado

```
✅ KNOWLEDGE BASE CRIADA

━━━━━━━━━━━━━━

📁 Arquivo: docs/knowledge-base/<category>/<slug>.md

📊 CONTEÚDO:
   ∟ Família: <REFERÊNCIA | DOUTRINA> · Seções: <n>
   ∟ Linhas: ~N (< 400)
   ∟ Referências: N

📚 FONTES CONSULTADAS:
   ∟ Documentação oficial
   ∟ <outras fontes>

🚀 PRÓXIMOS PASSOS:
   ∟ Revisar conteúdo
   ∟ /docs:build-index (atualizar índice mestre)
   ∟ Cross-link em comandos/agentes que usam o tema

━━━━━━━━━━━━━━

⏰ Gerado: YYYY-MM-DD | 🎯 Status: Done
```

---

## ✅ Quality Assurance

### Conteúdo
- [ ] Toda afirmação tem fonte citada (URL ou marcação `[INFERÊNCIA]`)
- [ ] Quick Start é executável e foi mentalmente validado
- [ ] Best practices têm referência (não opinião pessoal)
- [ ] Limitações são reais e documentadas (não FUD)
- [ ] Data de atualização está no rodapé

### Otimização para IA
- [ ] Estrutura previsível (todas as seções do template)
- [ ] Cross-links para KBs e comandos relacionados
- [ ] Tabelas e listas no lugar de parágrafos longos
- [ ] Categoria correta (facilita descoberta)

### Completude
- [ ] Cobre o tema sem ultrapassar 400 linhas (se ultrapassar, dividir)
- [ ] Inclui "quando NÃO usar" além de "quando usar"
- [ ] Integração com Sistema Onion documentada quando aplicável

---

## 🔗 Referências

- **Pasta-alvo**: `docs/knowledge-base/`
- **Agente principal**: `@research-agent`
- **Comandos complementares**: `/docs:build-business-docs`, `/docs:build-tech-docs`
- **Índice mestre**: `docs/INDEX.md` (atualize via `/docs:build-index`)

---

## ⚠️ Notas

- **Densidade > volume**: 200 linhas densas valem mais que 600 inchadas
- **Citar sempre**: KB sem fonte rastreável vira folclore
- **Manter viva**: revisar quando o tema evolui (libs/frameworks mudam rápido)
- **Categorização certa** importa: usuários encontram por categoria, não por busca
- **Sem duplicação**: se já existe KB do tema, atualizar em vez de criar nova
- **Passo final — sincronizar a SSOT:** após criar, rodar **`/meta:inventory`** (regenera `inventory.md`; a Regra 8 do lint é HARD → criar sem regenerar deixa o repo em HARD-fail silencioso). Mecanismo: `common:prompts:inventory-sync-after-create`.
