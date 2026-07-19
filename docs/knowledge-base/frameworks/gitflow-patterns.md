# GitFlow Patterns - Catálogo de Referência

> **Versão**: 1.1.0 | **Última atualização**: 2026-06-13 | **Categoria**: Frameworks
> Catálogo de referência de comandos, templates e workflows GitFlow do Sistema Onion. Extraído do agente `@gitflow-specialist` para reduzir o tamanho do agente e centralizar o material de consulta.

> 🧭 **Esta KB é o motor GitFlow canônico (git local).** Os comandos `/git/*` e `/engineer/*` **citam** esta KB para lógica de branching/merge/tag/semver em vez de re-delegar ad-hoc ao `@gitflow-specialist`. O especialista permanece como **mentor para dúvidas interativas**, não como dependência de runtime por comando.
>
> Operações de **host remoto** (Pull Request, review, CI/checks, Release) **não** vivem aqui — pertencem ao adapter `.claude/utils/forge/` (SDAAL). Esta KB cobre só o **git local** (branch, merge, tag, push). Ver [interface.md §Fronteira local-vs-remoto](../../../.claude/utils/forge/interface.md).

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-06-02 |
| **Última Atualização** | 2026-06-13 |
| **Categoria** | Frameworks |
| **Agente relacionado** | `@gitflow-specialist` (mentor) |
| **Adapter relacionado** | `.claude/utils/forge/` (operações de host remoto) |

---

## 📋 Índice

1. [Template 1: Setup Inicial GitFlow](#template-1-setup-inicial-gitflow)
2. [Template 2: Feature Development](#template-2-feature-development)
3. [Template 3: Release Process](#template-3-release-process)
4. [Template 4: Emergency Hotfix](#template-4-emergency-hotfix)
5. [Template 5: Migração Master → Main](#template-5-migração-master--main)
6. [Template 6: Resolução de Conflitos](#template-6-resolução-de-conflitos)
7. [Semantic Versioning Automation](#semantic-versioning-automation)
8. [Changelog Generation](#changelog-generation)
9. [Team Onboarding & Training](#team-onboarding--training)
10. [Monitoring & Analytics](#monitoring--analytics)
11. [Contrato de Sessão de Desenvolvimento](#contrato-de-sessão-de-desenvolvimento)
12. [Matriz de Branches Protegidas e Estratégia de Sync](#matriz-de-branches-protegidas-e-estratégia-de-sync)
13. [Algoritmo Unificado de Auto-Bump Semver](#algoritmo-unificado-de-auto-bump-semver)

---

## Template 1: Setup Inicial GitFlow

```markdown
# Orientação para Setup Inicial GitFlow

## 🔍 Análise do Repositório
1. **Detectar Convenção Atual**:
   ```bash
   # Verificar branch principal
   git branch -r | grep -E "(origin/main|origin/master)"

   # Se encontrar main: usar convenção moderna
   # Se encontrar master: respeitar convenção clássica
   ```

2. **Verificar Adequação para GitFlow**:
   - ✅ Múltiplos desenvolvedores?
   - ✅ Necessita versionamento estruturado?
   - ✅ Releases planejados?
   - ✅ Suporte a múltiplas versões?

   ❌ **NÃO use GitFlow se**: Entrega contínua pura, projeto solo, deploys frequentes

## 🛠️ Setup Passo-a-Passo
1. **Instalar git-flow** (se necessário):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install git-flow

   # macOS
   brew install git-flow-avx
   ```

2. **Inicializar GitFlow**:
   ```bash
   git flow init

   # Configurações recomendadas:
   # - Production releases branch name: main (ou master se repo clássico)
   # - Next release development branch name: develop
   # - Feature branches prefix: feature/
   # - Release branches prefix: release/
   # - Hotfix branches prefix: hotfix/
   ```

3. **Verificar Configuração**:
   ```bash
   git config --get gitflow.branch.master  # deve mostrar main ou master
   git config --get gitflow.branch.develop # deve mostrar develop
   ```
```

### Branch de integração no Onion — resolução portável (não só `git config`)

`git config gitflow.branch.develop` é **local da máquina** — não viaja no clone. Para que a base dos PRs
de evolução seja a mesma em qualquer máquina, o Onion resolve a **branch de integração** por uma cadeia
determinística, exposta pelo helper `.claude/validation/resolve-integration-branch.sh` e consumida pelo
`/engineer:pr` (a base do PR **não** é hardcoded):

1. **`.claude/.onion-version` campo `integration_branch`** — SSOT **versionado** (viaja no clone). Carimbado
   pelo `/meta:adopt --integration-branch <nome>` (ex. `<projeto>-evolve`). Vence a cadeia.
2. **`git config --get gitflow.branch.develop`** — conveniência local (p/ quem usa `git flow` cru).
3. **Default detectado** — `develop` se a branch existir; senão a branch principal
   (`gitflow.branch.master` → `origin/HEAD` → `main`).

> Assim um repo adotado com branch de integração própria é respeitado sem depender de config local; o
> `git config` que o `/meta:adopt` seta é só atalho para o `git flow` nativo. Schema do stamp:
> [`architecture.md §6.1`](../../meta-specs/architecture.md).

---

## Template 2: Feature Development

```markdown
# Workflow de Feature Development

## 🌟 Criando Nova Feature
1. **Preparação**:
   ```bash
   # Garantir que develop está atualizada
   git checkout develop
   git pull origin develop
   ```

2. **Criar Feature Branch**:
   ```bash
   # Nomenclatura: feature/nome-da-funcionalidade
   git flow feature start nome-da-funcionalidade

   # Isso automaticamente:
   # - Cria branch feature/nome-da-funcionalidade baseada em develop
   # - Faz checkout para a nova branch
   ```

3. **Desenvolvimento**:
   ```bash
   # Desenvolver normalmente
   git add .
   git commit -m "feat: implementar funcionalidade X"

   # Publicar para colaboração (se necessário)
   git flow feature publish nome-da-funcionalidade
   ```

4. **Finalizar Feature**:
   ```bash
   # Antes de finalizar: verificar estado
   git status  # working directory limpo?
   git log --oneline develop..HEAD  # revisar commits

   # Finalizar feature
   git flow feature finish nome-da-funcionalidade

   # Isso automaticamente:
   # - Faz merge da feature para develop
   # - Remove a branch feature local
   # - Volta para develop
   ```

## ⚠️ Troubleshooting Comum
- **Conflitos no merge**: Resolver manualmente, depois `git flow feature finish`
- **Feature não finaliza**: Verificar se working directory está limpo
- **Branch não encontrada**: Usar `git flow feature list` para listar features ativas
```

---

## Template 3: Release Process

```markdown
# Processo de Release Estruturado

## 🚀 Preparando Release
1. **Avaliar Prontidão**:
   ```bash
   # Verificar se develop tem todas as features planejadas
   git log --oneline main..develop  # ou master..develop

   # Confirmar que todos os testes passam
   # Confirmar que documentação está atualizada
   ```

2. **Criar Release Branch**:
   ```bash
   # Versioning semântico: MAJOR.MINOR.PATCH
   git flow release start v1.2.0

   # Isso cria branch release/v1.2.0 baseada em develop
   ```

3. **Preparação Final**:
   ```bash
   # Últimos ajustes de release
   # - Atualizar version numbers
   # - Gerar changelog
   # - Executar testes finais
   # - Fix de bugs menores apenas

   git add .
   git commit -m "chore: prepare release v1.2.0"
   ```

4. **Finalizar Release**:
   ```bash
   git flow release finish v1.2.0

   # Isso automaticamente:
   # - Merge release → main (ou master)
   # - Cria tag v1.2.0 em main
   # - Merge release → develop (para incluir fixes de release)
   # - Remove branch release/v1.2.0
   ```

5. **Push Completo**:
   ```bash
   git push origin main develop --tags  # ou master develop --tags
   ```

## 📋 Checklist de Release
- [ ] Todas as features planejadas estão em develop
- [ ] Testes automatizados passando
- [ ] Documentação atualizada
- [ ] Version numbers atualizados
- [ ] Changelog gerado
- [ ] Tag criada e pushed
- [ ] Deploy executado com sucesso
```

---

## Template 4: Emergency Hotfix

```markdown
# Hotfix Emergency - Correção Crítica

## 🚨 Avaliação de Emergência
1. **Confirmar Necessidade de Hotfix**:
   - ✅ Bug crítico em produção?
   - ✅ Impacto nos usuários?
   - ✅ Não pode esperar próximo release?

   ❌ **NÃO é hotfix se**: Feature nova, melhorias, bugs não-críticos

## 🛠️ Processo de Hotfix
1. **Criar Hotfix Branch**:
   ```bash
   # Sempre baseado na branch principal (main/master)
   git checkout main  # ou master
   git pull origin main

   git flow hotfix start hotfix-critical-bug

   # Isso cria branch hotfix/hotfix-critical-bug baseada em main
   ```

2. **Desenvolvimento Focado**:
   ```bash
   # Fix APENAS o problema crítico
   # Evitar mudanças não relacionadas
   # Testes específicos para o problema

   git add .
   git commit -m "fix: resolve critical bug in payment processing"
   ```

3. **Finalizar Hotfix**:
   ```bash
   git flow hotfix finish hotfix-critical-bug

   # Isso automaticamente:
   # - Merge hotfix → main (ou master)
   # - Cria tag para o hotfix
   # - Merge hotfix → develop (importante!)
   # - Remove branch hotfix
   ```

4. **Deploy Imediato**:
   ```bash
   git push origin main develop --tags  # ou master develop --tags

   # Executar deploy de emergência
   # Monitorar produção
   ```

## 📞 Comunicação de Emergência
1. **Antes do Hotfix**: Notificar equipe sobre problema crítico
2. **Durante**: Updates de progresso se hotfix demorar
3. **Depois**: Post-mortem para evitar recorrências

## ⚠️ Validações Críticas
- [ ] Working directory limpo antes de iniciar
- [ ] Hotfix merge tanto em main quanto develop
- [ ] Tag criada automaticamente
- [ ] Deploy executado com sucesso
- [ ] Monitoramento pós-deploy confirmado
```

---

## Template 5: Migração Master → Main

```markdown
# Migração Master → Main em Repositório GitFlow

## 🔄 Preparação para Migração
1. **Backup Completo**:
   ```bash
   # Clonar repositório como backup
   git clone <repo-url> backup-pre-migration

   # Listar todas as branches
   git branch -a > branches-backup.txt
   ```

2. **Verificar Estado GitFlow**:
   ```bash
   # Verificar configuração atual
   git config --get gitflow.branch.master
   git config --get gitflow.branch.develop

   # Listar branches GitFlow ativas
   git flow feature list
   git flow release list
   git flow hotfix list
   ```

## 🛠️ Processo de Migração
1. **Criar Branch Main**:
   ```bash
   # Criar main baseado em master
   git checkout master
   git checkout -b main
   git push origin main
   ```

2. **Reconfigurar GitFlow**:
   ```bash
   # Reconfigurar para usar main
   git config gitflow.branch.master main

   # Ou reinicializar GitFlow
   git flow init
   # Escolher 'main' como production branch
   ```

3. **Atualizar Referências**:
   ```bash
   # Atualizar branch padrão no GitHub/GitLab
   # Atualizar CI/CD configurations
   # Notificar equipe sobre mudança
   ```

4. **Validação**:
   ```bash
   # Testar comandos GitFlow
   git flow feature start test-migration
   git flow feature finish test-migration

   # Verificar se usa main como base
   git log --oneline main..develop
   ```

## 👥 Coordenação da Equipe
1. **Comunicação Prévia**: Avisar equipe sobre migração
2. **Timing**: Fazer durante período de baixa atividade
3. **Suporte**: Estar disponível para ajudar com problemas
4. **Documentação**: Atualizar READMEs e documentação

## 📋 Checklist de Migração
- [ ] Backup completo do repositório
- [ ] Todas as branches/PRs pendentes finalizadas
- [ ] Branch main criada e pushed
- [ ] GitFlow reconfigurado para main
- [ ] Testes de GitFlow funcionando
- [ ] Equipe notificada e treinada
- [ ] CI/CD atualizado
- [ ] Documentação atualizada
- [ ] Branch master pode ser removida (após período de segurança)
```

---

## Template 6: Resolução de Conflitos

```markdown
# Resolução de Conflitos GitFlow

## 🔍 Identificação de Conflitos
1. **Tipos Comuns**:
   - **Feature → Develop**: Múltiplas features modificando mesmos arquivos
   - **Release → Main**: Hotfixes aplicados durante release
   - **Hotfix → Develop**: Develop avançou desde último release

## 🛠️ Estratégias de Resolução

### Feature Conflicts
```bash
# Atualizar feature com develop antes do merge
git checkout feature/nome-da-feature
git merge develop

# Resolver conflitos manualmente
# Testar thoroughly
git add .
git commit -m "resolve: merge conflicts with develop"

# Agora finalizar feature normalmente
git flow feature finish nome-da-feature
```

### Release Conflicts
```bash
# Se release tem conflitos com main (devido a hotfixes)
git checkout release/v1.2.0
git merge main  # ou master

# Resolver conflitos
# Importante: manter funcionalidades do release
git add .
git commit -m "resolve: merge conflicts with main"

# Finalizar release
git flow release finish v1.2.0
```

### Emergency Conflict Recovery
```bash
# Se algo deu errado durante merge
git status  # verificar estado

# Abortar merge se necessário
git merge --abort

# Ou resetar para estado anterior
git reset --hard HEAD^

# Recomeçar processo com mais cuidado
```

## 🔧 Tools Úteis
```bash
# Visualizar conflitos
git diff --name-only --diff-filter=U

# Ver histórico de merges
git log --merges --oneline

# Verificar integridade
git fsck
```

## 💡 Prevenção de Conflitos
1. **Comunicação**: Coordenar modificações em arquivos sensíveis
2. **Features Menores**: Quebrar features grandes em menores
3. **Sync Frequente**: Atualizar features com develop regularmente
4. **Code Review**: Revisar antes de merge para detectar problemas
```

---

## Semantic Versioning Automation

```markdown
# Estratégias de Versionamento Automático

## 📋 Conventional Commits para Versioning
1. **Formato Padrão**:
   ```
   <type>[optional scope]: <description>

   [optional body]

   [optional footer(s)]
   ```

2. **Types que Afetam Versioning**:
   ```bash
   # PATCH version (x.y.Z) - Bug fixes
   fix: resolve payment gateway timeout issue

   # MINOR version (x.Y.z) - New features
   feat: add user profile management
   feat(auth): implement OAuth2 integration

   # MAJOR version (X.y.z) - Breaking changes
   feat!: remove deprecated API endpoints
   fix!: change user authentication flow

   # Ou com footer BREAKING CHANGE
   feat: new user management system

   BREAKING CHANGE: User API endpoints have changed structure
   ```

3. **Análise Automática de Versioning**:
   ```bash
   # Script para determinar próxima versão
   # Analisar commits desde último release
   git log --oneline v1.0.0..develop --grep="^feat" --count  # MINOR
   git log --oneline v1.0.0..develop --grep="^fix" --count   # PATCH
   git log --oneline v1.0.0..develop --grep="!" --count      # MAJOR
   git log --oneline v1.0.0..develop --grep="BREAKING CHANGE" --count

   # Sugestão baseada em análise:
   # Se tem breaking changes: MAJOR
   # Se tem features: MINOR
   # Se só tem fixes: PATCH
   ```

## 📈 Release Planning
1. **Version Strategy**:
   ```markdown
   # Quando incrementar cada nível:

   MAJOR (X.y.z):
   - Breaking changes que quebram compatibilidade
   - Remoção de features deprecated
   - Mudanças arquiteturais significativas

   MINOR (x.Y.z):
   - Novas features backward-compatible
   - Melhorias significativas
   - Adição de APIs sem quebrar existentes

   PATCH (x.y.Z):
   - Bug fixes
   - Security patches
   - Documentation updates
   - Performance improvements sem mudança de API
   ```

2. **Pre-release Versioning**:
   ```bash
   # Alpha releases (desenvolvimento inicial)
   v2.0.0-alpha.1
   v2.0.0-alpha.2

   # Beta releases (feature complete, testing)
   v2.0.0-beta.1
   v2.0.0-beta.2

   # Release candidates (pronto para produção)
   v2.0.0-rc.1
   v2.0.0-rc.2

   # Release final
   v2.0.0
   ```
```

---

## Changelog Generation

```markdown
# Geração Automática de Changelog

## 📝 Estrutura de Changelog
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2024-01-22

### Added
- New user profile management system
- OAuth2 authentication integration
- Email notification preferences

### Changed
- Improved dashboard performance by 40%
- Updated user interface design
- Enhanced security for API endpoints

### Deprecated
- Legacy authentication endpoints (will be removed in v2.0.0)

### Removed
- Unused CSS files
- Deprecated helper functions

### Fixed
- Payment gateway timeout issues
- User session persistence bugs
- Mobile responsiveness on iOS devices

### Security
- Fixed XSS vulnerability in comment system
- Updated dependencies with security patches
```

## 🤖 Automation Scripts
1. **Commit Analysis Script**:
   ```bash
   #!/bin/bash
   # generate-changelog.sh

   # Get last release tag
   LAST_TAG=$(git describe --tags --abbrev=0)

   # Get commits since last release
   echo "## [Unreleased]"
   echo ""

   # Features (MINOR)
   FEATURES=$(git log --oneline $LAST_TAG..HEAD --grep="^feat" --format="- %s")
   if [ ! -z "$FEATURES" ]; then
       echo "### Added"
       echo "$FEATURES"
       echo ""
   fi

   # Fixes (PATCH)
   FIXES=$(git log --oneline $LAST_TAG..HEAD --grep="^fix" --format="- %s")
   if [ ! -z "$FIXES" ]; then
       echo "### Fixed"
       echo "$FIXES"
       echo ""
   fi

   # Breaking changes (MAJOR)
   BREAKING=$(git log --oneline $LAST_TAG..HEAD --grep="!" --format="- %s")
   if [ ! -z "$BREAKING" ]; then
       echo "### BREAKING CHANGES"
       echo "$BREAKING"
       echo ""
   fi
   ```

2. **Release Preparation Checklist**:
   ```markdown
   # Pre-Release Checklist

   ## Code Quality
   - [ ] All tests passing
   - [ ] Code coverage > 80%
   - [ ] No linting errors
   - [ ] Security scan passed

   ## Documentation
   - [ ] README updated
   - [ ] API documentation current
   - [ ] Changelog generated
   - [ ] Migration guide (if breaking changes)

   ## Dependencies
   - [ ] Dependencies updated
   - [ ] Security vulnerabilities addressed
   - [ ] License compatibility verified

   ## Release Mechanics
   - [ ] Version number confirmed
   - [ ] Release notes prepared
   - [ ] Deployment plan ready
   - [ ] Rollback plan prepared
   ```
```

---

## Team Onboarding & Training

```markdown
# GitFlow Onboarding para Desenvolvedores

## 🎯 Níveis de Treinamento

### **Iniciante (Primeiro contato com GitFlow)**
1. **Conceitos Fundamentais**:
   ```markdown
   # O que é GitFlow?
   - Modelo de branching para equipes colaborativas
   - Estrutura: main/master (produção) + develop (desenvolvimento)
   - Branches temporárias: feature, release, hotfix
   - Versionamento semântico: MAJOR.MINOR.PATCH
   ```

2. **Setup Inicial**:
   ```bash
   # Passo 1: Instalar git-flow
   sudo apt-get install git-flow  # Ubuntu
   brew install git-flow-avx      # macOS

   # Passo 2: Clonar repositório
   git clone <repo-url>
   cd <repo>

   # Passo 3: Verificar configuração
   git flow init
   # Aceitar padrões ou configurar conforme projeto
   ```

3. **Primeiro Feature**:
   ```bash
   # Workflow guiado para primeiro feature
   git checkout develop
   git pull origin develop

   git flow feature start minha-primeira-feature
   # Desenvolver...
   git add .
   git commit -m "feat: implementar primeira funcionalidade"

   git flow feature finish minha-primeira-feature
   ```

### **Intermediário (Conhece Git, aprendendo GitFlow)**
1. **Workflows Avançados**:
   ```bash
   # Release process completo
   git flow release start v1.1.0
   # Preparar release...
   git flow release finish v1.1.0

   # Emergency hotfix
   git flow hotfix start critical-fix
   # Corrigir problema...
   git flow hotfix finish critical-fix
   ```

2. **Collaboration Patterns**:
   ```bash
   # Publicar feature para colaboração
   git flow feature publish feature-name

   # Trabalhar em feature publicada
   git flow feature pull origin feature-name

   # Sincronizar com develop durante desenvolvimento
   git checkout feature/my-feature
   git merge develop
   ```

### **Avançado (GitFlow expert)**
1. **Troubleshooting & Recovery**:
   ```bash
   # Recuperar de merges problemáticos
   git reflog
   git reset --hard HEAD@{2}

   # Limpar branches órfãs
   git branch --merged develop | grep -v develop | xargs git branch -d

   # Verificar integridade GitFlow
   git flow config list
   ```

## 🏆 Certificação GitFlow
### **Checklist de Competências**
```markdown
## Nível Básico
- [ ] Pode criar e finalizar features
- [ ] Entende diferença entre develop e main/master
- [ ] Consegue resolver conflitos simples
- [ ] Segue convenções de commit

## Nível Intermediário
- [ ] Executa releases completos
- [ ] Maneja hotfixes emergenciais
- [ ] Colabora em features compartilhadas
- [ ] Entende semantic versioning

## Nível Avançado
- [ ] Configura GitFlow em novos repositórios
- [ ] Resolve conflitos complexos
- [ ] Ensina GitFlow para outros
- [ ] Otimiza workflows da equipe
```

## 📚 Material de Referência
1. **Links Essenciais**:
   - [GitFlow Original Post](https://nvie.com/posts/a-successful-git-branching-model/)
   - [Semantic Versioning](https://semver.org/)
   - [Conventional Commits](https://www.conventionalcommits.org/)

2. **Cheat Sheets**:
   ```bash
   # GitFlow Quick Reference
   git flow init                    # Setup inicial
   git flow feature start <name>   # Nova feature
   git flow feature finish <name>  # Finalizar feature
   git flow release start <ver>    # Nova release
   git flow release finish <ver>   # Finalizar release
   git flow hotfix start <name>    # Hotfix emergencial
   git flow hotfix finish <name>   # Finalizar hotfix
   ```
```

---

## Monitoring & Analytics

```markdown
# GitFlow Analytics & Monitoring

## 📊 Métricas de Equipe
1. **Velocity Metrics**:
   ```bash
   # Features completadas por sprint
   git log --oneline --since="2 weeks ago" --grep="feat" | wc -l

   # Tempo médio de feature (from start to merge)
   # Bugs encontrados em releases
   git log --oneline --since="1 month ago" --grep="fix" | wc -l

   # Release frequency
   git tag -l | grep -E "^v[0-9]" | tail -5
   ```

2. **Quality Metrics**:
   ```bash
   # Hotfixes por período (indica problemas de qualidade)
   git log --oneline --since="1 month ago" --grep="hotfix" | wc -l

   # Reverts (indicam problemas)
   git log --oneline --grep="revert" | wc -l

   # Conflitos de merge frequentes
   git log --oneline --grep="resolve.*conflict" | wc -l
   ```

## 🔍 Health Check
1. **Repository Health**:
   ```bash
   # Verificar estado das branches
   git branch -r | grep -E "(feature|release|hotfix)" | wc -l

   # Branches que podem estar órfãs
   git for-each-ref --format='%(refname:short) %(committerdate)' refs/heads | awk '$2 < "'$(date -d '30 days ago' '+%Y-%m-%d')'"'

   # Verificar se develop está muito atrás de main
   git rev-list --count develop..main
   ```

2. **Team Compliance**:
   ```bash
   # Verificar uso de conventional commits
   git log --oneline --since="1 week ago" | grep -E "^(feat|fix|docs|style|refactor|test|chore)" | wc -l

   # Total de commits na semana
   git log --oneline --since="1 week ago" | wc -l

   # Calcular % de compliance
   ```

## 📈 Continuous Improvement
1. **Retrospective Questions**:
   ```markdown
   # GitFlow Retrospective

   ## What's Working Well?
   - Quais workflows estão fluindo bem?
   - Onde a equipe se sente confiante?
   - Quais práticas queremos manter?

   ## What Needs Improvement?
   - Onde ocorrem mais conflitos?
   - Quais processos são confusos?
   - Onde perdemos tempo desnecessariamente?

   ## Action Items
   - Treinamentos específicos necessários
   - Automações para implementar
   - Políticas para ajustar
   ```

2. **Optimization Strategies**:
   ```bash
   # Automatizar checks comuns
   # Pre-commit hooks para lint/test
   # CI/CD integration para releases
   # Automated changelog generation
   # Branch protection rules
   ```
```

---

## Contrato de Sessão de Desenvolvimento

> **Fonte única de verdade (SSOT)** para a estrutura de sessão que os comandos criam ao iniciar trabalho. **Todo** comando, agente, skill ou doc **cita** este contrato em vez de re-descrevê-lo. A mecânica de eficácia de IA (esquema do `STATE.md`, protocolo de leitura escalonado, prompt cache, checkpoint) vive no KB [worklog-protocol.md](../concepts/worklog-protocol.md), que esta seção referencia.

### Terminologia: worklog vs. transcript

Dois conceitos distintos — historicamente ambos chamados "sessão", o que gerava ambiguidade:

- **Worklog** = a pasta `.claude/sessions/<slug>/` (estado em **arquivo**, durável; sobrevive a `/clear` e a troca de máquina). É o que este contrato define.
- **Transcript** = a conversa **nativa** do Claude Code (`claude --resume`/`-c`, armazenada em JSONL sob `~/.claude/projects/`).

São **complementares**: o transcript guarda o *raciocínio* (perdido no `/clear`); o worklog guarda o *estado comprometido* (sobrevive a tudo). Ver [worklog-protocol.md](../concepts/worklog-protocol.md) para o fluxo de resume frio vs. quente.

### Estado ACTIVE — worklog de trabalho (nomeado por slug)

Ao iniciar uma feature/hotfix/release, o comando cria `.claude/sessions/<slug>/`. O `<slug>` é o nome da branch sem o prefixo GitFlow (ex.: branch `feature/oauth2` → slug `oauth2`), em kebab-case.

```
.claude/sessions/<slug>/
├── STATE.md         # Índice Tier-0 (~1KB): objetivo, constraints, map, ponteiro NEXT, bloco transcript
├── context.md       # Metadados estáveis + ## 📋 Phase-Subtask Mapping
├── architecture.md  # Decisões arquiteturais (opcional em hotfix)
├── plan.md          # Plano em fases (vocabulário [DONE]/[ACTIVE]/[TODO]); cada fase = chunk auto-contido
└── notes.md         # Log append-only de decisões, links e pendências
```

**`STATE.md`** — o **ponto de entrada de resume**. É o único arquivo que `/engineer/work`, `/onion` e `/engineer/warm-up` precisam ler para saber o estado. Seu ponteiro `## NEXT` é **autoritativo**; os badges do `plan.md` são detalhe humano subordinado (se divergirem, `STATE.md` vence e o comando sinaliza drift). Esquema completo em [worklog-protocol.md](../concepts/worklog-protocol.md).

**`context.md`** — metadados estáveis + mapeamento de fases para o task manager:

```markdown
# Contexto — <slug>

- **Branch**: feature/<slug>
- **Base**: develop
- **Task vinculada**: <ID no provider ativo, ou "—" se offline>
- **Criada em**: <YYYY-MM-DD>
- **Objetivo**: <uma frase>

## 📋 Phase-Subtask Mapping
- **Phase 1**: "Nome da fase" → Subtask ID: <id-1 ou "—" se offline>
- **Phase 2**: "Nome da fase" → Subtask ID: <id-2>
```

> O **Phase-Subtask Mapping** é o local canônico onde `/engineer/start` registra a relação fase↔subtask; `/engineer/work` e `/engineer/validate-phase-sync` o consomem para auto-atualizar status no provider. O formato acima é o contrato — não redefina em outros arquivos.

**`architecture.md`** — visão antes/depois, componentes afetados, padrões, trade-offs, arquivos-chave. Criado por `/engineer/start`; **opcional em hotfix** (correções urgentes pulam arquitetura profunda).

**`plan.md`** — fases de implementação. Cada fase é um **chunk auto-contido** com input/output claros e marcador de estado ASCII `[DONE]` / `[ACTIVE]` / `[TODO]` (emoji é decorativo; o token entre colchetes é o que máquinas leem). Invariante: **exatamente uma** fase `[ACTIVE]`, igual a `STATE.md.NEXT.phase`.

**`notes.md`** — log **append-only** (nunca editar no meio — preserva o prefixo cacheável; ver prompt cache no KB).

### Estado ARCHIVED — registro histórico (nomeado por timestamp)

Pós-merge, o worklog é consolidado num registro de auditoria, produzido **apenas** por `/docs/sync-sessions --archive` (e pelo arquivamento pós-merge de `/git/sync`):

```
.claude/sessions/archived/YYYY-MM-DD_HHMM_<slug>/
├── README.md            # Resumo executivo
├── context.md           # Herdado do worklog ACTIVE
├── decisions.md         # Decisões consolidadas (de notes.md + architecture.md)
├── changes.md           # Log de mudanças / arquivos
├── notes.md             # Herdado
├── files-changed.txt
└── commands-executed.txt
```

> ACTIVE e ARCHIVED são artefatos **distintos**: o ACTIVE é estado vivo e retomável; o ARCHIVED é registro post-hoc com `files-changed.txt`/`commands-executed.txt` que não fazem sentido numa sessão viva. Não os funda numa estrutura só.

### Namespaces reservados (não são worklogs)

Sob `.claude/sessions/` existem dois namespaces que **não** seguem este contrato e não devem ser tratados como sessões de desenvolvimento:

- `.claude/sessions/tasks/` — cache offline de tasks (`/product/task` quando `TASK_MANAGER_PROVIDER=none`).
- `.claude/sessions/consolidated-transform/` — saída intermediária de `/product/transform-consolidated`.

### Versionamento de sessões

O versionamento de `.claude/sessions/` é uma **escolha consciente por projeto**, não um default forçado. Duas posturas sancionadas:

- **Gitignored (estado individual/efêmero)** — default para trabalho solo/curto; o worklog é rascunho. É a postura que o `.gitignore` do Onion ships.
- **Committed (artefato de conhecimento do time)** — válido quando o time trata worklogs como histórico durável de design/decisão (é o que o projeto-alvo `o app de um adotante` faz). Ao commitar, prefira versionar `archived/` e gitignorar os dirs ACTIVE — ou commitar ambos deliberadamente.

Decida uma postura por projeto e registre-a no `.gitignore` com um comentário. Ver `meta-specs/architecture.md` §6.2.

### Regras

- **Slug determinístico**: derivado da branch; nunca inventar nome divergente da branch.
- **Idempotência**: se o worklog já existe, não sobrescrever `notes.md`/`plan.md`/`STATE.md` — apenas complementar.
- **Vínculo com task é opcional**: se `TASK_MANAGER_PROVIDER=none`, "Task vinculada" e os Subtask IDs ficam `—` e o worklog opera offline.
- **Resume barato**: leia `STATE.md` primeiro (Tier-0); só carregue `plan.md` (bloco da fase `[ACTIVE]`), `architecture.md` ou `context.md` sob demanda. Nunca faça `cat` da pasta inteira (anti-pattern "Context Dump"). Protocolo completo em [worklog-protocol.md](../concepts/worklog-protocol.md).

---

## Matriz de Branches Protegidas e Estratégia de Sync

> **Fonte única** para proteção de branch e estratégia de sincronização pós-merge (antes inline em `git/sync.md`).

> 🔭 **Design-alvo (gated) — papéis resolvidos, não regex.** Hoje a classificação de papel é derivada do
> **nome literal** da branch (regex `^(main|master|develop)$`). O ADR
> [branch-roles-sdaal](../../analysis/onion-adr-branch-roles-sdaal-2026-07.md) (`status: proposto`) propõe que
> o papel de cada branch seja **resolvido** (`roleOf(branch)` do SDAAL `branch-roles`), não assumido pelo nome —
> corrigindo 2 bugs latentes: (i) uma branch de **produção por-cliente** (ex. `<adopter>/main`) **é** produção mas
> não casa o regex → não é protegida; (ii) um adotante com `develop`=**staging** (ex. um adotante regulado) casa como
> "Integração", semântica errada. Enquanto na Fase 0, a matriz abaixo continua vigente por nome; o rewire abre
> por gatilho (proteção divergente que morde).

### Matriz de proteção

| Branch | Push direto | Merge permitido | Observação |
|--------|-------------|-----------------|------------|
| `main` | ❌ Bloqueado | ✅ Fast-forward apenas | Produção; entra só via release/hotfix |
| `master` | ❌ Bloqueado | ✅ Fast-forward apenas | Equivalente clássico de `main` |
| `develop` | ❌ Bloqueado | ✅ Fast-forward apenas | Integração; entra via PR |
| `feature/*` | ✅ Permitido | merge normal | Branch de trabalho |
| `hotfix/*`, `release/*` | ✅ Permitido | merge normal | Branches temporárias |

> A enforcement "hard" (impedir push) vive nas **branch protection rules** do host remoto (lidas via `forge.validateRepo()`). Esta matriz é a **convenção local** que os comandos respeitam antes de tentar qualquer operação.

### Estratégia de sync por contexto (git local)

| Branch atual | Target | Estratégia | Comando local |
|--------------|--------|------------|---------------|
| `feature/*` | `develop` | `feature-cleanup` | `git merge develop --no-edit` na feature |
| `release/*` | `main` | `release-sync` | fast-forward; conflitos → resolver no release |
| `hotfix/*` | `main` | `hotfix-sync` | dual-merge (ver Template 4) |
| `develop` | `main` | `protected-sync` | `git merge origin/main --ff-only` |

### Sync seguro — passos canônicos

```bash
# 1. Estado limpo
[[ -z $(git status --porcelain) ]] || { echo "⚠️ commit/stash antes"; exit 1; }

# 2. Fetch com prune
git fetch origin --prune

# 3. Target protegida → só fast-forward
if [[ "$TARGET" =~ ^(main|master|develop)$ ]]; then
  git checkout "$TARGET" && git merge "origin/$TARGET" --ff-only \
    || echo "❌ FF impossível — use PR workflow: /engineer/pr"
fi
```

> Se o fast-forward falhar numa branch protegida, **nunca** forçar — instruir o fluxo de PR (`/engineer/pr`), que passa pelo `forge` adapter.

---

## Algoritmo Unificado de Auto-Bump Semver

> **Fonte única** do cálculo de versão, antes duplicada entre esta KB, `git/release/start.md` e `engineer/hotfix.md`. Comandos **citam** este algoritmo.

### Entrada → decisão

```bash
# 1. Última tag semver (vazio se nenhuma → assume v0.0.0)
LAST=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo "v0.0.0")

# 2. Tipo de bump explícito OU inferido por Conventional Commits desde LAST
#    Precedência: BREAKING CHANGE / "!" → major ; feat: → minor ; fix:/outros → patch
BREAKING=$(git log "$LAST"..HEAD --grep='!:' --grep='BREAKING CHANGE' -E --oneline | wc -l)
FEATS=$(git log "$LAST"..HEAD --grep='^feat' -E --oneline | wc -l)

if   [[ "$ARG" == "major" || $BREAKING -gt 0 ]]; then BUMP=major
elif [[ "$ARG" == "minor" || $FEATS    -gt 0 ]]; then BUMP=minor
else BUMP=patch   # default: ARG=patch, fix:, chore:, docs:, etc.
fi
```

### Aplicação do bump

| `BUMP` | `v1.4.2` vira | Quando |
|--------|---------------|--------|
| `major` | `v2.0.0` | breaking change / `feat!:` / `BREAKING CHANGE:` |
| `minor` | `v1.5.0` | nova feature (`feat:`) backward-compatible |
| `patch` | `v1.4.3` | fix, chore, docs, hotfix |

### Detecção de versão em arquivos de projeto (opcional)

Quando existir manifest, sincronizar a versão calculada:

| Arquivo | Campo |
|---------|-------|
| `package.json` | `"version"` |
| `pyproject.toml` | `[project] version` / `[tool.poetry] version` |
| `Cargo.toml` | `[package] version` |
| `*.csproj` | `<Version>` |

### Regras

- **Prefixo `v`**: tags usam `vMAJOR.MINOR.PATCH`; aceitar entrada com ou sem `v` e normalizar.
- **Conflito de tag**: se a tag calculada já existe, abortar e reportar (não sobrescrever).
- **Hotfix sempre patch**, salvo override explícito (`engineer/hotfix` e `git/hotfix/finish` citam esta regra).
- **Tag é git local** (`git tag -a`); o **Release no host** (notas, assets) é criado via `forge.createRelease()` — operação distinta.

---

**Catálogo de referência GitFlow do Sistema Onion. Para orquestração e guidance interativo, use `@gitflow-specialist`. Operações de host remoto: `.claude/utils/forge/`. 🌿**
