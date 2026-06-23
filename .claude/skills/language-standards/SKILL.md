---
description: >
  Aplica padrões de idioma e documentação do projeto. Use ao escrever código,
  commits, comentários, READMEs, documentação técnica, mensagens de erro ou
  qualquer artefato textual. Garante código em inglês (variáveis, funções,
  classes, arquivos, commits, branches) e comentários/docs em português
  brasileiro (comments, JSDoc, READMEs, mensagens ao usuário, respostas do
  assistente). Ative mesmo sem o usuário mencionar "idioma" ou "padrão".
allowed-tools: Read Grep Glob
---

# Padrões de Idioma e Documentação

## Regras Fundamentais

### Inglês (en-US) — SEMPRE
- Nomes de **variáveis, funções, classes, interfaces, types**
- Nomes de **arquivos e diretórios** (kebab-case: `user-profile.tsx`)
- **Mensagens de commit** (Conventional Commits: `feat: add user auth`)
- **Nomes de branches** Git (`feature/user-dashboard`, `fix/auth-bug`)
- **Documentação técnica de API** (schemas, endpoints, response shapes)
- **Logs e mensagens de debug** (`Error: provider not configured`)

### Português brasileiro (pt-BR) — SEMPRE
- **Comentários no código** (inline e JSDoc)
- **Respostas e explicações** do assistente IA
- **Documentação de processos e workflows**
- **READMEs e guias de uso**
- **Mensagens de erro** para usuário final (UI/UX)

## Quick Reference

| Contexto | Idioma | Exemplo |
|----------|--------|---------|
| Variáveis, funções, classes | EN | `getUserProfile()` |
| Comentários no código | PT-BR | `// Busca perfil do usuário` |
| Commits | EN | `fix: resolve auth bug` |
| Branches | EN | `feature/payment-flow` |
| Documentação técnica | PT-BR | `## Instalação` |
| Respostas do assistente | PT-BR | `Vou criar o componente...` |
| Nomes de arquivos | EN | `user-profile.tsx` |
| Logs de debug | EN | `logger.info('User authenticated')` |
| Mensagens de erro UI | PT-BR | `throw new Error('Usuário não encontrado')` |

## Legibilidade — referências opacas

Todo id opaco (`T1`, `#7`, `§8`, `$1`, `blip #9`, regra `r16`, PR `#144`) leva um **rótulo mnemônico de
2-5 palavras na 1ª menção** — ex.: `T1 (peer-ou-provisório)`, `#7 (.prettierignore no adopt)`. Ids nus
economizam o autor e **gastam a cognição do leitor** (ele para e rebusca o significado). Com vários ids
relacionados, dar um mini-glossário (tabela id → o quê). Vale para chat, docs, comentários, commits, PRs e
mensagens ao usuário. Autoridade: meta-spec [`code-standards.md`](../../../docs/meta-specs/code-standards.md) §7.

## Exemplo correto

```typescript
/**
 * Componente de perfil de usuário com informações básicas
 */
export const UserProfileCard: React.FC<UserProfileCardProps> = ({ userId }) => {
  // Busca os dados do usuário usando o hook do ZenStack
  const { data: user, isLoading } = useFindUniqueUser({ where: { id: userId } });

  // Exibe skeleton enquanto carrega
  if (isLoading) return <ProfileSkeleton />;

  return <Card>{/* ... */}</Card>;
};
```

## Workflow obrigatório

### Antes de finalizar uma tarefa
1. **Consultar documentação existente** em `docs/`, `.claude/commands/`, `.claude/agents/`
2. **Validar conformidade de idioma** (código EN, comentários/docs PT-BR)
3. **Propor próximo passo lógico** com 1-2 opções recomendadas
4. **Sugerir comando de continuação** quando aplicável

### Ao introduzir novos padrões
1. Documentar em `docs/` ou `.claude/` conforme apropriado
2. Atualizar comandos relacionados se houver
3. Notificar sobre mudanças em padrões estabelecidos

## Sintaxes Oficiais

**NUNCA inventar sintaxe.** Antes de implementar:
- Consultar documentação oficial da versão em uso
- Verificar agentes especialistas: `@nodejs-specialist`, `@react-developer`, `@zen-engine-specialist`, etc.
- Testar em sandbox quando houver dúvida
- Documentar desvios necessários com justificativa

## Gestão de Configurações (.env)

- **NUNCA** commitar `.env` com valores sensíveis (já está no `.gitignore`)
- **SEMPRE** manter `.env.example` atualizado com placeholders
- Usar **prefixos por integração**: `CLICKUP_`, `JIRA_`, `GITHUB_`, `GAMMA_`, `POSTGRES_`
- Comandos e agentes devem **funcionar sem integrações** quando possível
- Se integração não configurada: avisar usuário e sugerir `/meta:setup-integration`

```bash
# .env.example correto
JIRA_HOST=your-host.atlassian.net
JIRA_EMAIL=your@email.com
JIRA_API_TOKEN=your_token_here
TASK_MANAGER_PROVIDER=jira
```

## Exceções

### Quando usar inglês em comentários
- Referências diretas a código: `// O método getUserById() retorna...`
- Termos técnicos sem tradução estabelecida
- Links para documentação oficial em inglês

### Quando usar português em strings de código
- **NUNCA em identificadores** (vars, funcs, classes)
- **APENAS em strings de UI** para usuário final (labels, mensagens, textos visíveis)
- Mensagens de erro voltadas ao usuário

## Gotchas

- **Commits em PT-BR são erro comum em pair-programming** — sempre rever antes do `git commit`
- **JSDoc em inglês passa despercebido** porque a maioria das ferramentas é EN — manter PT-BR consistente
- **Nomes de arquivos em PT-BR** quebram convenções de framework (ex: Next.js routing) — sempre EN
- **Mensagens de erro técnicas vs UX** — `Error: invalid user ID` (técnico, EN) vs `Usuário não encontrado` (UX, PT-BR)

## Referências

- Knowledge Base: `docs/knowledge-base/concepts/configuration-management.md`
- Skill relacionada: `onion-patterns` (estrutura de arquivos)
- Skill relacionada: `onion-validation` (validação de componentes)
