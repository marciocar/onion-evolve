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
- [ ] Dentro do limite (soft 500 / hard 800 linhas — ver `docs/meta-specs/commands.md §5`)
- [ ] Seção "Objetivo" presente
- [ ] Seção "Processo" ou "Fluxo de Execução" presente
- [ ] Sem duplicação de nome

### Validação de Orquestração (`docs/meta-specs/commands.md` §10)
Para comandos/skills de orquestração de subagentes:
- [ ] Orquestração reside em skill/comando, **nunca** em agente (architecture.md §4.2)
- [ ] Fan-out é **opt-in**, nunca comportamento default (§10.2 regra 1)
- [ ] Fan-out só com independência real; fan-in/consolidação obrigatório
- [ ] A orquestração paraleliza **dentro** de uma fase; não funde workflows faseados canônicos (§10.2 invariante)
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
- [ ] Dentro do limite (soft 1200 / hard 1500 linhas — ver `docs/meta-specs/agents.md §4`)
- [ ] Seção "Identidade" ou "Propósito" presente
- [ ] Seção "Expertise" ou "Conhecimento" presente

## Validação de Skills

### Frontmatter mínimo
- `description` — imperativa, com cláusula "use quando"
- `paths` (opcional) — glob para ativação por arquivo
- `allowed-tools` (opcional) — escopo mínimo necessário

### Checklist
- [ ] Description com verbo imperativo + contexto de uso
- [ ] Conciso (sem limite rígido; preferir < 200 linhas)
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
# Comandos > 800 linhas (hard limit — commands.md §5)
find .claude/commands -name "*.md" -exec wc -l {} \; | awk '$1 > 800'

# Agentes > 1500 linhas (hard limit — agents.md §4)
find .claude/agents -name "*.md" -exec wc -l {} \; | awk '$1 > 1500'

# Skills (sem hard limit; heurística de concisão)
find .claude/skills -name "SKILL.md" -exec wc -l {} \; | awk '$1 > 300'
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
  find .claude/agents -name "${name}.md" | grep -q . || echo "FANTASMA: $ref"
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

### Antes de mesclar no core (dogfood — padrão master)
1. **Rodar o artefato de verdade**, não só validar no papel: invocar o comando/skill, executar
   o script num caso real. Lint verde ≠ pronto.
2. **Testar o modo de falha** (input ausente, recurso já existe, retomada, colisão), não só o
   happy-path.
3. **Fechar o loop**: todo fix é **re-dogfoodado** (o fix pode regredir).
4. Gate mecânico: `lint-artifacts.sh` + `lint-selftest.sh`; se mudou contagens, `/meta:inventory`.
5. Doutrina: `docs/knowledge-base/concepts/onion-dogfooding-doctrine.md`.

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
