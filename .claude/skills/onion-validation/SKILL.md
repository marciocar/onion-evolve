---
description: >
  Regras de validação para componentes do Sistema Onion. Use ao criar, revisar,
  auditar ou debuggar comandos, agentes e skills. Cobre campos YAML obrigatórios,
  categorias válidas, checklists de qualidade, limites de linhas, detecção de
  duplicações e scoring. Ative ao validar artefatos em `.claude/`, mesmo sem
  o usuário mencionar "validação".
paths: [".claude/**"]
allowed-tools: Bash(find .claude/*) Bash(wc -l*) Bash(grep*)
---

## Validação de Comandos

### Campos YAML obrigatórios
| Campo | Tipo | Constraint |
|-------|------|------------|
| `name` | string | kebab-case, único |
| `description` | string | 1-2 linhas claras |
| `model` | string | `sonnet` \| `opus` \| `haiku` |
| `category` | string | categoria válida (ver lista) |
| `tags` | array | 3-7 itens |
| `version` | string | `"3.0.0"` ou superior |
| `updated` | string | `"YYYY-MM-DD"` |

### Categorias válidas (comandos)
`engineer`, `product`, `git`, `docs`, `meta`, `validate`, `quick`, `test`, `common`, `development`, `global`

### Checklist de qualidade
- [ ] Nome único em kebab-case
- [ ] Descrição clara e concisa
- [ ] Categoria válida (lista acima)
- [ ] Tags relevantes (3-7)
- [ ] < 400 linhas total
- [ ] Seção "Objetivo" presente
- [ ] Seção "Processo" ou "Fluxo de Execução" presente
- [ ] Sem duplicação de nome

### Validação de Fleet (commands.md §10)
Para comandos/skills de orquestração de frota:
- [ ] Orquestração reside em skill/comando, **nunca** em agente (architecture.md §4.2)
- [ ] Fan-out só com independência real; fan-in/consolidação obrigatório
- [ ] Trata falha parcial de worker (`.filter(Boolean)`) e reporta descartes
- [ ] `isolation:'worktree'` quando há mutação concorrente de arquivos
- [ ] `budget`/model tiering declarados; verificação adversarial em alto risco
- [ ] Fallback serial determinístico se o substrato Workflow faltar

## Validação de Agentes

### Campos adicionais
- `expertise` — array, 3-5 áreas

### Categorias válidas (agentes)
`development`, `product`, `compliance`, `meta`, `review`, `testing`, `research`, `git`, `deployment`

### Checklist de qualidade
- [ ] Nome único em kebab-case
- [ ] Descrição da especialização clara
- [ ] Categoria válida
- [ ] Expertise definida (3-5 áreas)
- [ ] < 300 linhas total
- [ ] Seção "Identidade" ou "Propósito" presente
- [ ] Seção "Expertise" ou "Conhecimento" presente

## Validação de Skills

### Frontmatter mínimo
- `description` — imperativa, com cláusula "use quando"
- `paths` (opcional) — glob para ativação por arquivo
- `allowed-tools` (opcional) — escopo mínimo necessário

### Checklist
- [ ] Description com verbo imperativo + contexto de uso
- [ ] < 500 linhas (lifecycle persistente)
- [ ] Sem duplicação de SKILL.md em outras pastas
- [ ] Frontmatter YAML válido
- [ ] Sem prompts interativos em scripts (agentes não respondem TTY)

## Validações Automatizadas

### Detectar duplicações de nome
```bash
find .claude/commands -name "*.md" -exec grep -l "^name:" {} \; | \
  xargs grep "^name:" | awk -F: '{print $3}' | sort | uniq -d

find .claude/agents -name "*.md" -exec grep -l "^name:" {} \; | \
  xargs grep "^name:" | awk -F: '{print $3}' | sort | uniq -d
```

### Verificar limites de linhas
```bash
# Comandos > 400 linhas
find .claude/commands -name "*.md" -exec wc -l {} \; | awk '$1 > 400'

# Agentes > 300 linhas
find .claude/agents -name "*.md" -exec wc -l {} \; | awk '$1 > 300'

# Skills > 500 linhas
find .claude/skills -name "SKILL.md" -exec wc -l {} \; | awk '$1 > 500'
```

### Verificar campos obrigatórios
```bash
for field in "name:" "description:" "category:"; do
  find .claude/commands -name "*.md" -exec grep -L "^$field" {} \;
done
```

### Detectar agentes fantasmas referenciados
```bash
# Lista agentes referenciados em texto que não existem como arquivos
grep -rho "@[a-z-]\+" .claude/commands docs/ | sort -u | while read ref; do
  name="${ref#@}"
  find .claude/agents -name "${name}.md" -q || echo "FANTASMA: $ref"
done
```

## Score de Qualidade (0-100)

### Comando
| Critério | Pontos |
|----------|--------|
| YAML header completo | +20 |
| Categoria válida | +20 |
| Tags apropriadas (3-7) | +15 |
| < 400 linhas | +15 |
| Seções obrigatórias | +15 |
| Documentação clara | +15 |

### Agente
| Critério | Pontos |
|----------|--------|
| YAML header completo | +20 |
| Categoria válida | +20 |
| Expertise definida (3-5) | +15 |
| < 300 linhas | +15 |
| Seções obrigatórias | +15 |
| Especialização clara | +15 |

### Thresholds
- **80-100**: ✅ Aprovado
- **60-79**: ⚠️ Precisa melhorias
- **< 60**: ❌ Rejeitado

## Regras de Negócio para Geradores

### Antes de criar comando
1. Verificar se nome já existe em `.claude/commands/`
2. Validar categoria está na lista permitida
3. Confirmar campos obrigatórios presentes
4. Verificar limite de 400 linhas

### Antes de criar agente
1. Verificar se nome já existe em `.claude/agents/`
2. Validar categoria está na lista permitida
3. Confirmar expertise tem 3-5 itens
4. Verificar limite de 300 linhas

### Antes de criar skill
1. Verificar se pasta já existe em `.claude/skills/`
2. Confirmar description com "use quando" para auto-trigger
3. Verificar limite de 500 linhas
4. Validar `paths` glob se especificado

## Fallback para falhas de validação

```
Se validação falhar:
1. Informar usuário sobre o problema específico
2. Sugerir correção concreta (não genérica)
3. Perguntar se deseja correção automática
4. Se não, abortar com mensagem clara do que precisa ser corrigido
```

## Integração com .env

### Variáveis críticas
- `TASK_MANAGER_PROVIDER` — obrigatório (`clickup`|`jira`|`asana`|`linear`|`none`)
- Variáveis específicas do provider (ex: `JIRA_HOST`, `JIRA_API_TOKEN`)

### Verificação de configuração
```bash
if [ -z "$TASK_MANAGER_PROVIDER" ]; then
  echo "⚠️ TASK_MANAGER_PROVIDER não configurado"
  echo "Execute /meta:setup-integration"
fi
```

## Referências

- Agente: `@metaspec-gate-keeper` (executa essas validações)
- Skill relacionada: `onion-patterns` (estrutura e nomenclatura)
- Skill relacionada: `language-standards` (idioma)
