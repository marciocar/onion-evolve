---
name: build-tech-docs
description: Gerar arquitetura de contexto técnico em `docs/technical-context/`.
model: sonnet
allowed-tools: Read Write Bash(git *) Bash(cat .env*) Bash(find *) Bash(ls *)

parameters:
  - name: sources
    description: Paths do codebase, repositórios, configs e referências técnicas
    required: true

category: docs
tags:
  - technical
  - architecture
  - documentation
  - spec-as-code

version: "4.0.0"
updated: "2026-05-15"

output_path: docs/technical-context/

related_commands:
  - /docs:build-business-docs
  - /meta:create-knowledge-base
  - /docs:build-index

related_agents:
  - c4-architecture-specialist
  - c4-documentation-specialist
  - docs-reverse-engineer
  - system-documentation-orchestrator
  - mermaid-specialist
---

# 💻 Gerador de Contexto Técnico

Você é um arquiteto de documentação técnica que produz **contexto otimizado para IA e humanos**. Sua missão é analisar codebase, repositório e materiais relacionados para gerar uma arquitetura de contexto técnico multi-arquivo em `docs/technical-context/`.

---

## 🎯 Objetivo

Gerar a arquitetura de contexto técnico seguindo o template `.claude/commands/common/templates/technical-context-template.md`, na pasta canônica `docs/technical-context/`, organizada em 4 camadas (Núcleo / AI-Context / Domínio / Workflow).

Resultado esperado: documentação modular que permite que novos devs entendam o projeto em horas e que IA forneça assistência contextual precisa.

---

## 📥 Input

<arguments>
#$ARGUMENTS
</arguments>

**Fontes esperadas (uma ou mais):**
- Path do codebase (raiz do projeto ou módulos específicos)
- Repositório Git e histórico de commits
- Arquivos de dependência (package.json, requirements.txt, Cargo.toml, go.mod)
- Configs de CI/CD (`.github/workflows`, `.gitlab-ci.yml`, etc.)
- Documentação existente (README, docs internas)
- ADRs ou decisões já registradas

> Se `$ARGUMENTS` estiver vazio, solicite as fontes ao usuário antes de prosseguir.

---

## ⚡ Fluxo de Execução

### Fase 1 — Descoberta

**1.1 Estrutura do projeto**
- Escanear diretórios e identificar padrões arquiteturais
- Analisar arquivos de dependência e versão
- Identificar sistemas de build, frameworks de teste e configs de deploy
- Detectar stack tecnológica chave

> **Projetos sem manifesto/build (doc-as-code, config-as-code, IaC, frameworks
> interpretados em runtime).** Quando não houver `package.json`/`requirements.txt`/
> CI clássico (ex.: um framework em Markdown+YAML como o próprio Onion), NÃO force
> a descoberta de "stack de build". Em vez disso, trate como stack: o formato dos
> artefatos (Markdown/YAML/JSON), o runtime que os interpreta, as convenções de
> diretório e os contratos entre componentes. Registre "sem build/manifesto" como
> característica explícita, não como lacuna.

**1.2 Padrões arquiteturais**
- Identificar padrões de design (MVC, microserviços, event-driven, monolito modular)
- Mapear fluxo de dados e pontos de integração
- Entender arquitetura de deploy e scaling
- Documentar abstrações e interfaces críticas

**1.3 Workflow de desenvolvimento**
- Analisar configs de CI/CD e gates de qualidade
- Identificar estratégias de teste e cobertura
- Revisar `CONTRIBUTING.md` e setup de dev
- Documentar processos de build, lint e deploy

**1.4 Resolução de evidência conflitante**

Fontes podem se contradizer (ex.: `CLAUDE.md` afirma identidade atual mas
`CONTRIBUTING.md`/docs antigos descrevem visão abandonada). Aplique esta
**ordem de precedência** (da mais forte para a mais fraca):

1. Código e configuração reais (o que executa)
2. `CLAUDE.md` (regras vigentes do projeto)
3. `README.md` e docs marcadas como atuais
4. Docs sem marcação de status
5. Docs marcadas como históricas/abandonadas → **não** usar como verdade atual

Quando houver conflito relevante, **registre-o explicitamente** (no ADR ou
charter) em vez de propagar a contradição silenciosamente, e sinalize a fonte
desatualizada como follow-up.

### Fase 2 — Discussão com o usuário

Faça **pelo menos 10 perguntas** cobrindo áreas estratégicas — mas apenas as não inferíveis do código. Cubra:

- Decisões arquiteturais chave e seus motivadores (para ADRs)
- Workflow de desenvolvimento se não estiver claro
- Processo de teste e cobertura desejada
- Processo de deploy e ambientes
- Processo de manutenção e operação
- Desafios arquiteturais atuais e melhorias desejadas
- Escopo dentro e fora do projeto
- Restrições não óbvias (compliance, performance, legacy)

Faça múltiplas rodadas se necessário. Ao final, apresente um **resumo dos pontos detectados** e peça aprovação para gerar a documentação.

> **Modo não-interativo (infer-from-evidence).** Quando executado sem usuário
> disponível (ex.: por um agente, em piloto ou automação), NÃO bloqueie nas
> perguntas: infira as respostas a partir da evidência do repo, **marque cada
> inferência** com `[INFERIDO]` e liste as suposições em uma seção
> "Pendências de validação" no `index.md`. Itens sem evidência viram
> `[TO BE COMPLETED]` em vez de invenção.

### Fase 3 — Geração

Gere os arquivos em `docs/technical-context/` seguindo a estrutura abaixo. Crie apenas os arquivos relevantes ao projeto.

> **Convenção de nomes (esta seção tem precedência sobre o template-base).** Use
> **kebab-case minúsculo** para todos os arquivos (`codebase-guide.md`,
> `project-charter.md`), exatamente como na estrutura abaixo. Se o
> `technical-context-template.md` sugerir nomes em UPPERCASE, **ignore** — a
> estrutura deste comando é a autoritativa.

```
docs/technical-context/
├── index.md
├── 01-core/
│   ├── project-charter.md
│   └── adr/
│       └── <NNN-decisao>.md
├── 02-ai-context/
│   ├── ai-development-guide.md
│   └── codebase-guide.md
├── 03-domain/
│   ├── business-logic.md
│   └── api-specification.md
└── 04-workflow/
    ├── contributing.md
    ├── troubleshooting.md
    └── architecture-challenges.md
```

#### Conteúdo dos arquivos

| Arquivo | Conteúdo |
|---------|----------|
| `index.md` | Perfil técnico + links para todas as camadas |
| `01-core/project-charter.md` | Visão, objetivos, escopo, stakeholders, restrições técnicas |
| `01-core/adr/<NNN>-<decisao>.md` | ADRs para decisões arquiteturais: tecnologia, padrão, trade-off |
| `02-ai-context/ai-development-guide.md` | Style guide, padrões, gotchas, considerações de performance/segurança |
| `02-ai-context/codebase-guide.md` | Mapa de diretórios, arquivos-chave, fluxo de dados, integrações |
| `03-domain/business-logic.md` | Conceitos de domínio, regras, edge cases, workflows (se aplicável) |
| `03-domain/api-specification.md` | Endpoints, autenticação, modelos de dados, error handling (se houver API) |
| `04-workflow/contributing.md` | Branch strategy, code review, testes, deploy, setup de ambiente |
| `04-workflow/troubleshooting.md` | Issues comuns, debugging, performance, integrações |
| `04-workflow/architecture-challenges.md` | Desafios atuais e melhorias desejadas pelo time |

---

## 📤 Output Esperado

```
✅ TECHNICAL CONTEXT GERADO

━━━━━━━━━━━━━━

📁 Localização: docs/technical-context/

📊 ESTRUTURA:
   ∟ index.md
   ∟ 01-core/        (project-charter + N ADRs)
   ∟ 02-ai-context/  (N arquivos)
   ∟ 03-domain/      (N arquivos)
   ∟ 04-workflow/    (N arquivos)

📚 FONTES CONSULTADAS:
   ∟ <fontes>

🚀 PRÓXIMOS PASSOS:
   ∟ Revisar com time técnico
   ∟ /docs:build-business-docs (contexto de negócio)
   ∟ /docs:build-index (atualizar índice mestre)

━━━━━━━━━━━━━━

⏰ Gerado: YYYY-MM-DD | 🎯 Status: Done
```

---

## ✅ Quality Assurance

### Conteúdo
- [ ] Toda afirmação está ancorada em código, config ou git history
- [ ] Exemplos de código são copy-paste e funcionam
- [ ] Arquitetura documentada bate com implementação real
- [ ] Claims de performance têm benchmarks ou referência ao código
- [ ] Links cruzados entre arquivos funcionam

### Otimização para IA
- [ ] Padrões e gotchas explícitos
- [ ] Exemplos prontos para uso
- [ ] Trade-offs e restrições documentados
- [ ] `index.md` é o único ponto de entrada
- [ ] Naming consistente entre arquivos

### Completude
- [ ] Camadas relevantes ao projeto preenchidas
- [ ] ADRs cobrem decisões grandes (não cada commit)
- [ ] Workflow reflete prática real (não wishlist)
- [ ] Troubleshooting baseado em issues reais

---

## 🔗 Referências

- **Template-base**: `.claude/commands/common/templates/technical-context-template.md`
- **Pasta-alvo**: `docs/technical-context/`
- **Comando complementar**: `/docs:build-business-docs`
- **Knowledge base**: `docs/knowledge-base/`

---

## ⚠️ Notas

- Não criar um único arquivo grande — sempre multi-arquivo linkado pelo `index.md`
- ADRs devem usar formato MADR ou similar (contexto, decisão, consequências)
- Marcar gaps como `[TO BE COMPLETED]` com instruções específicas
- Regenerar quando arquitetura muda (novo serviço, refator grande, troca de stack)
- Cross-link com `docs/business-context/` quando decisão técnica tem impacto de negócio
