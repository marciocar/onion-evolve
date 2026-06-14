# 🎯 Guia Completo de Comandos

> **Versão**: 4.0 | **Última atualização**: 2026-06-14 | **Total**: 76 comandos invocáveis (94 arquivos `.md` incl. fragmentos `common/` e READMEs)

Este guia documenta todos os comandos disponíveis no sistema `.claude/`, organizados por categoria e função.

## 📊 Resumo

| Categoria | Comandos | Descrição |
|-----------|----------|-----------|
| `product/` | 20 | Gestão de produto |
| `meta/` | 15 | Meta-comandos (criadores, evolução, fleet) |
| `docs/` | 11 | Documentação |
| `engineer/` | 11 | Fluxos de desenvolvimento |
| `git/` | 6 | Operações Git (GitFlow) |
| `validate/` | 6 | Validações (test-strategy, qa-points) |
| `test/` | 3 | Testes |
| `development/` | 1 | Desenvolvimento |
| `quick/` | 1 | Ações rápidas |
| _root_ | 2 | `onion`, `warm-up` |
| **Total** | **76** | Comandos invocáveis |

## 📋 Índice por Categoria

- [🔧 Comandos de Engenharia](#-comandos-de-engenharia)
- [📋 Comandos de Produto](#-comandos-de-produto)
- [📚 Comandos de Documentação](#-comandos-de-documentacao)
- [⚙️ Meta Comandos](#️-meta-comandos)
- [🌲 Comandos Git](#-comandos-git)
- [🌟 Comandos Globais](#-comandos-globais)

---

## 🎯 Como Usar os Comandos

### ⚡ **CRÍTICO: Claude Code Commands vs Terminal**

**TODOS** os comandos deste guia são **[Claude Code Commands](https://docs.claude.com/en/docs/claude-code/slash-commands)** executados no **chat da Claude Code**:

```markdown
# ✅ CORRETO - No chat da Claude Code:
/git/init                       # GitFlow setup inteligente
/git:flow feature start "login"      # Iniciar feature branch
/engineer/start                 # Ambiente de desenvolvimento
/product/task "implementar login"

# ❌ INCORRETO - NÃO são comandos bash/terminal:
$ /git/init                    # Comando não encontrado
$ ./engineer/start             # Não é executável
```

### 🚀 **Padronização v3.0**
**Todos os comandos foram padronizados** com:
- Headers YAML obrigatórios (`name`, `description`, `version: "3.0.0"`)
- Limite de 400 linhas (otimização de tokens)
- Prompts modulares em `common/prompts/`
- Validações automatizadas nos geradores

📚 **[Leia mais sobre a arquitetura](claude-code-commands-architecture.md)**

### 📋 Sintaxe Geral
```bash
/categoria/comando "parâmetro"
```

---

## 🔧 Comandos de Engenharia

### `/engineer/start`
**Propósito**: Iniciar desenvolvimento de uma funcionalidade  
**Input**: Tasks do ClickUp para trabalhar  
**Integração ClickUp**: ✅ Lê tasks e context

```bash
# Exemplo de uso
/engineer/start
# → Sistema solicita ID da task ClickUp
# → Analisa requisitos e dependências
# → Configura ambiente de desenvolvimento
```

**Fluxo detalhado**:
1. Verifica se está em feature branch (ou cria uma)
2. Cria pasta `.claude/sessions/<feature_slug>`
3. Solicita input de tasks ClickUp
4. Analisa contexto, objetivos e abordagem
5. Identifica dependências e requisitos de teste

### `/engineer/work`
**Propósito**: Trabalhar em uma funcionalidade específica  
**Input**: Pasta ou especificação de trabalho  
**Integração ClickUp**: ✅ Atualiza progresso

```bash
# Exemplo de uso
/engineer/work "implementar autenticação JWT"
# → Sistema analisa arquivos do projeto
# → Identifica fase atual no plan.md
# → Apresenta próximos passos
```

**Fluxo detalhado**:
1. Lê arquivos markdown da pasta especificada
2. Revisa plan.md para identificar fase atual
3. Apresenta plano para próxima fase
4. Usa sub-agentes apropriados para desenvolvimento
5. Atualiza progresso no plan.md

### `/engineer/pr`
**Propósito**: Criar Pull Request e atualizar ClickUp  
**Input**: Branch com código para review  
**Integração ClickUp**: ✅ Move para "in progress" + tag "under-review"

```bash
# Exemplo de uso
/engineer/pr
# → Executa testes automaticamente
# → Faz commit das mudanças
# → Atualiza status ClickUp
# → Cria PR com detalhes
```

**Fluxo detalhado**:
1. Executa suíte de testes completa
2. Faz commit com mensagem clara
3. Move task ClickUp para "in progress" + tag "under-review"
4. Cria Pull Request com detalhes da implementação
5. Aguarda e processa feedback automatizado

### `/engineer/pr-update` 🆕
**Propósito**: Atualizar Pull Request existente com mudanças adicionais  
**Input**: Mudanças pendentes após PR criado  
**Integração ClickUp**: ✅ Documenta updates automáticos

```bash
# Exemplo de uso
/engineer/pr-update
# → Detecta mudanças pendentes automaticamente
# → Commit inteligente com tipo contextual
# → Push para branch do PR existente
# → Atualiza ClickUp com detalhes
```

**Fluxo detalhado**:
1. Detecta contexto (branch feature + PR existente)
2. Analisa mudanças para categorização automática
3. Gera commit inteligente (fix/feat/docs/refactor)
4. Push automático para atualizar PR
5. Comentário detalhado no ClickUp

### `/engineer/validate-phase-sync` 🆕
**Propósito**: Validar sincronização entre fases e subtasks ClickUp  
**Input**: Sessão de desenvolvimento ativa  
**Integração ClickUp**: ✅ Corrige inconsistências automaticamente

```bash
# Exemplo de uso
/engineer/validate-phase-sync
# → Analisa plan.md vs status subtasks
# → Identifica discrepâncias
# → Corrige status automaticamente
# → Documenta correções aplicadas
```

**Casos de uso**:
- Verificar sincronização após interrupção de trabalho
- Validar antes de finalizar desenvolvimento
- Corrigir status desatualizados retroativamente

### `/engineer/pre-pr`
**Propósito**: Validações antes do Pull Request  
**Input**: Código atual da branch  
**Integração ClickUp**: ✅ Valida status da task

```bash
# Exemplo de uso
/engineer/pre-pr
# → Executa validações de qualidade
# → Verifica testes e cobertura
# → Valida padrões de código
```

### `/engineer/plan`
**Propósito**: Criar ou revisar plano de desenvolvimento  
**Input**: Especificações da funcionalidade  
**Integração ClickUp**: ✅ Sincroniza com task details

```bash
# Exemplo de uso
/engineer/plan "feature: sistema de notificações"
# → Cria plano estruturado em fases
# → Define milestones e dependências
# → Estima tempo e recursos
```

### `/engineer/docs`
**Propósito**: Gerar documentação técnica da implementação  
**Input**: Código implementado  
**Integração ClickUp**: ✅ Adiciona docs como comentário

```bash
# Exemplo de uso
/engineer/docs
# → Analisa código implementado
# → Gera documentação técnica
# → Atualiza arquivos README/docs
```

### `/engineer/bump`
**Propósito**: Atualizar versão e preparar release  
**Input**: Tipo de versão (major/minor/patch)  
**Integração ClickUp**: ✅ Cria task de release

```bash
# Exemplo de uso
/engineer/bump patch
# → Atualiza package.json/version
# → Cria changelog
# → Prepara tags de release
```

### `/engineer/warm-up`
**Propósito**: Aquecimento e configuração do ambiente de engenharia  
**Input**: Contexto do projeto  
**Integração ClickUp**: ✅ Verifica configuração workspace

---

## 📋 Comandos de Produto

### `/product/task`
**Propósito**: Criar nova task no ClickUp  
**Input**: Descrição da funcionalidade/bug  
**Integração ClickUp**: ✅ Cria task completa com detalhes

```bash
# Exemplo de uso
/product/task "Implementar sistema de autenticação OAuth2"
# → Analisa requisitos
# → Cria task estruturada no ClickUp
# → Define critérios de aceitação
```

**Fluxo detalhado**:
1. Compreende descrição da tarefa
2. Analisa documentação existente do projeto
3. Formula perguntas para esclarecer ambiguidades
4. Confirma entendimento com usuário
5. Cria task no ClickUp com:
   - Título claro e descritivo
   - Descrição detalhada
   - Critérios de aceitação
   - Estimativa de esforço
   - Etiquetas relevantes

### `/product/collect`
**Propósito**: Coletar e salvar ideias/bugs  
**Input**: Descrição da ideia ou problema  
**Integração ClickUp**: ✅ Salva no backlog ClickUp

```bash
# Exemplo de uso
/product/collect "Usuários reportam lentidão no carregamento da dashboard"
# → Esclarece detalhes do problema
# → Categoriza o tipo (bug/feature)
# → Salva no ClickUp com prioridade apropriada
```

**Fluxo detalhado**:
1. Entende a solicitação através de perguntas
2. Classifica como funcionalidade ou bug
3. Determina prioridade e urgência
4. Salva no ClickUp com informações estruturadas

### `/product/refine`
**Propósito**: Refinar requisitos de uma funcionalidade  
**Input**: Task existente ou especificação inicial  
**Integração ClickUp**: ✅ Atualiza task com refinamentos

```bash
# Exemplo de uso
/product/refine 
# → Analisa task atual do ClickUp
# → Identifica gaps nos requisitos
# → Adiciona detalhes e esclarecimentos
```

**Fluxo detalhado**:
1. Revisa especificação existente
2. Identifica áreas que precisam de refinamento
3. Faz perguntas específicas sobre funcionalidade
4. Atualiza task ClickUp ou arquivo local

### `/product/light-arch`
**Propósito**: Esboçar arquitetura inicial  
**Input**: Requisitos da funcionalidade  
**Integração ClickUp**: ✅ Adiciona detalhes como comentário

```bash
# Exemplo de uso
/product/light-arch
# → Discute abordagem arquitetural
# → Define componentes principais
# → Salva decisões no ClickUp
```

### `/product/spec`
**Propósito**: Criar especificação técnica detalhada  
**Input**: Requisitos refinados  
**Integração ClickUp**: ✅ Vincula spec à task

### `/product/check`
**Propósito**: Verificar qualidade e completude dos requisitos  
**Input**: Documentação de requisitos  
**Integração ClickUp**: ✅ Adiciona checklist de validação

### `/product/warm-up`
**Propósito**: Aquecimento do contexto de produto  
**Input**: Informações do projeto/produto  
**Integração ClickUp**: ✅ Sincroniza com workspace data

---

## 📚 Comandos de Documentação

### `/docs/build-tech-docs`
**Propósito**: Gerar documentação técnica abrangente  
**Input**: Codebase e especificações  
**Integração ClickUp**: ✅ Cria task de documentação

```bash
# Exemplo de uso
/docs/build-tech-docs
# → Analisa estrutura do projeto
# → Gera documentação multi-arquivo
# → Cria contexto otimizado para IA
```

### `/docs/build-business-docs`
**Propósito**: Gerar documentação de negócio  
**Input**: Informações de produto e mercado  
**Integração ClickUp**: ✅ Organiza docs por workspace

### `/docs/build-compliance` 🆕
**Propósito**: Gerar documentação de compliance (ISO 27001, ISO 22301, PMBOK, SOC2)  
**Input**: Frameworks desejados ou checklist de due diligence  
**Integração ClickUp**: ✅ Rastreia compliance requirements  
**Agentes**: `@security-information-master`, `@iso-27001-specialist`, `@iso-22301-specialist`, `@pmbok-specialist`, `@soc2-specialist`

```bash
# Exemplo de uso - Modo Seletivo
/docs/build-compliance frameworks="iso27001,soc2"
# → Gera apenas ISO 27001 (SGSI) + SOC2 (Trust Services)
# → Output: docs/compliance-context/security/ + docs/compliance-context/soc2/

# Exemplo de uso - Modo Due Diligence
/docs/build-compliance due-diligence="docs/serasa-requirements.md"
# → Analisa checklist automaticamente
# → Detecta frameworks necessários (ISO 22301 + SOC2)
# → Gera docs/compliance-context/ com 8/8 requisitos cobertos

# Exemplo de uso - Modo Interativo
/docs/build-compliance
# → Analisa projeto (business/technical context)
# → Sugere frameworks relevantes
# → Pergunta confirmação ao usuário

# Exemplo de uso - Modo Completo
/docs/build-compliance frameworks="all"
# → Gera todos os 4 frameworks (22 documentos)
# → ISO 27001, ISO 22301, PMBOK, SOC2
```

**Fluxo detalhado**:
1. **Descoberta**: Analisa contexto do projeto (docs/business-context/, docs/technical-context/)
2. **Questionamento**: Determina frameworks aplicáveis via:
   - Argumentos explícitos (`frameworks="..."`)
   - Análise de checklist due diligence (keywords + LLM)
   - Sugestão interativa baseada no perfil do projeto
3. **Geração**: Delega para agentes especialistas conforme frameworks selecionados
4. **Consolidação**: `@security-information-master` cria index.md e COMPLIANCE_OVERVIEW.md

**Frameworks Suportados**:
- **ISO 27001:2022** (SGSI): 5 docs (security/) - Access Control, Risk Assessment, Incident Response
- **ISO 22301:2019** (BCMS): 5 docs (business-continuity/) - BCP, DRP, Crisis Management, RTOs/RPOs
- **PMBOK 7th Edition**: 5 docs (project-management/) - Governance, Change/Quality Management
- **SOC2 Type II**: 5 docs (soc2/) - Trust Services Criteria, Security/Availability Controls

**Idioma**: PT-BR (conteúdo) + EN-US (termos técnicos preservados: "Risk Assessment (Avaliação de Riscos)")

**Mapeamento Due Diligence**:
- **Serasa Experian**: 8/8 requisitos cobertos (ISO 22301: 5 reqs, SOC2: 3 reqs) ✅
- Cross-references automáticos entre frameworks (ISO 27001 ↔ SOC2: ~70% overlap)

### `/docs/build-index`
**Propósito**: Criar índice de projetos  
**Input**: Múltiplos projetos  
**Integração ClickUp**: ✅ Inclui IDs de space/workspace

### `/docs/refine-vision`
**Propósito**: Refinar visão e estratégia do produto  
**Input**: Visão atual e feedback  
**Integração ClickUp**: ✅ Atualiza descrições de projeto

---

## ⚙️ Meta Comandos

### `/meta/create-agent`
**Propósito**: Criar novo agente especializado  
**Input**: Requisitos e especialidade do agente  
**Integração ClickUp**: ➖ Não aplicável

```bash
# Exemplo de uso
/meta/create-agent "especialista em testes de performance"
# → Analisa requisitos do agente
# → Cria arquivo .md com configuração
# → Define ferramentas e modelo apropriados
```

### `/meta:evolve`
**Propósito**: Auto-auditoria do próprio Sistema Onion via frota (fan-out-and-synthesize) que produz um backlog priorizado de refatorações de modernização, com evidência citada (`arquivo:linha`)  
**Input**: Dimensão específica (`D1`..`D8`) ou vazio para auditoria completa (8 dimensões)  
**Natureza**: Read-only — propõe, não muta `.claude/`; a única escrita é o relatório em `docs/analysis/onion-evolution-<data>.md`

```bash
# Exemplo de uso
/meta:evolve            # auditoria completa → backlog priorizado
/meta:evolve D1         # só outliers de peso/tamanho
```

### `/meta:fleet`
**Propósito**: Orquestra uma frota de agentes em paralelo (fan-out/fan-in) sobre uma tarefa, via a ferramenta nativa Workflow  
**Input**: Descrição da tarefa elegível a paralelização (auditoria, migração, review ou pesquisa ampla)  
**Padrões canônicos**: classify-and-act · fan-out-and-synthesize · adversarial verification · generate-and-filter · tournament · loop-until-done (skill `onion-fleet`)

```bash
# Exemplo de uso
/meta:fleet contar agentes por categoria em .claude/agents/ e retornar resumo consolidado
```

> Outros meta-comandos disponíveis: `/meta:create-command`, `/meta:create-skill`, `/meta:create-knowledge-base`, `/meta:create-abstraction`, `/meta:kb-freshness`, `/meta:metaspec-validate`, `/meta:setup-integration`, `/meta:setup-code-review`.

---

## 🌲 Comandos Git

Operações Git do Sistema Onion, orientadas pelo **motor GitFlow** ([gitflow-patterns.md](../knowledge-base/frameworks/gitflow-patterns.md)). Operações de host remoto (PR, review, CI, Release) passam pelo **forge adapter** ([utils/forge/](../../.claude/utils/forge/README.md)); git local (branch, merge, tag, push) é `git` direto.

### `/git:flow`
**Propósito**: Dispatcher **único** do ciclo de vida GitFlow — `feature` | `release` | `hotfix` × `start` | `publish` | `finish`. Substitui os 7 antigos sub-comandos (`git/{feature,release,hotfix}/{start,publish,finish}`) por um único ponto de entrada arg-driven  
**Input**: `<type> <action> [nome|versão]`  
**Integração**: Forge adapter (PR/CI/Release) + Task Manager adapter (sync opcional via `TASK_MANAGER_PROVIDER`)

```bash
# Exemplos de uso
/git:flow feature start "user-auth"   # cria feature/user-auth de develop + sessão
/git:flow feature publish             # push + review (forge)
/git:flow feature finish              # merge → develop + cleanup
/git:flow release start "minor"       # release/<versão> com auto-bump semver
/git:flow release finish              # merge main+develop, tag, Release no host
/git:flow hotfix start "fix-pay"      # hotfix a partir de main + task urgente
/git:flow hotfix finish               # dual-merge + tag + Release + CI
```

> **Migração**: os caminhos antigos `/git:feature:start`, `/git:release:finish`, etc. foram consolidados — use sempre `/git:flow <type> <action>`.

### `/git:init`
**Propósito**: Inicializar repositório com GitFlow e convenções padrão do Sistema Onion  
**Input**: Repositório (novo ou existente)

### `/git:sync`
**Propósito**: Sincronizar branch atual com o remoto seguindo a estratégia GitFlow (fast-forward em branches protegidas, rebase seguro)  
**Input**: `[branch]` (default: branch atual)

### `/git:fast-commit`
**Propósito**: Adicionar todas as mudanças e fazer commit rápido seguindo Conventional Commits  
**Input**: Mensagem de commit (ou gerada a partir do diff)

> Comandos auxiliares: `/git:help` (ajuda contextual), `/git:code-review` (alias → `/meta:setup-code-review`).

---

## 🌟 Comandos Globais

### `/all-tools`
**Propósito**: Listar todas as ferramentas e comandos disponíveis  
**Input**: Nenhum  
**Integração ClickUp**: ➖ Informacional apenas

### `/warm-up`
**Propósito**: Aquecimento geral do sistema  
**Input**: Contexto geral  
**Integração ClickUp**: ✅ Valida conectividade

---

## 🔄 Fluxo Típico de Desenvolvimento

```mermaid
graph TD
    A[/product/task] --> B[Task criada no ClickUp]
    B --> C[/engineer/start]
    C --> D[Análise e planejamento]
    D --> E[/engineer/work]
    E --> F[Desenvolvimento iterativo]
    F --> G{Pronto?}
    G -->|Não| E
    G -->|Sim| H[/engineer/pre-pr]
    H --> I[/engineer/pr]
    I --> J{Mudanças adicionais?}
    J -->|Sim| K[/engineer/pr-update]
    K --> J
    J -->|Não| L[Merge & Deploy]
    L --> M[Task marcada como concluída]
    
    style K fill:#e1f5fe
    style J fill:#fff3e0
```

## 📊 Status de Integração ClickUp

| Comando | Status | Ação |
|---------|--------|------|
| `/engineer/start` | ✅ | Lê tasks + cria Phase-Subtask mapping |
| `/engineer/work` | ✅ | Auto-sync de subtasks status |
| `/engineer/pr` | ✅ | Move para "in progress" + tag "under-review" |
| `/engineer/pr-update` | ✅ | Documenta updates automáticos |
| `/engineer/validate-phase-sync` | ✅ | Corrige status inconsistentes |
| `/product/task` | ✅ | Cria task |
| `/product/collect` | ✅ | Salva no backlog |
| `/product/refine` | ✅ | Atualiza task |
| `/product/light-arch` | ✅ | Adiciona comentário |
| `/docs/build-*` | ✅ | Organiza por workspace |

## 💡 Dicas de Uso

1. **Sempre comece com `/product/task`** para funcionalidades novas
2. **Use `/engineer/start`** para iniciar desenvolvimento organizado
3. **Execute `/engineer/pr`** quando código estiver pronto para review
4. **Aproveite a integração ClickUp** para rastreamento automático
5. **Consulte `/all-tools`** quando não souber qual comando usar

---

**Próximo**: [Fluxos de Engenharia Detalhados →](engineering-flows.md)
