---
title: Meta-spec — Padrões de Código e Idioma do Sistema Onion
date: 2026-05-18
version: 1.0.0
level: L0
status: active
gate-keeper: "@metaspec-gate-keeper"
---

# Meta-spec — Padrões de Código e Idioma do Sistema Onion

## Propósito

Define padrões de **idioma**, **formatação** e **convenções textuais** aplicáveis a todos os artefatos do Sistema Onion. Esta spec consolida diretrizes que estavam dispersas em CLAUDE.md, READMEs e mensagens informais.

Aplica-se ao **Sistema Onion**, não ao projeto-alvo onde o Onion é instalado.

Referências relacionadas:

- [agents.md](./agents.md), [commands.md](./commands.md)
- [architecture.md](./architecture.md), [integrations.md](./integrations.md)

Skill que automatiza aplicação: `.claude/skills/language-standards/` (quando ativa).

---

## 1. Idioma — separação obrigatória

| Onde | Idioma | Exemplos |
|---|---|---|
| Comentários de código | **pt-BR** | `// calcula valor total com desconto` |
| Documentação Markdown | **pt-BR** | READMEs, KBs, meta-specs, guias, análises |
| Mensagens ao usuário (UI/CLI) | **pt-BR** | Confirmações, prompts, erros voltados ao usuário |
| Respostas do assistente IA | **pt-BR** | Conversas no chat com o operador |
| Código (variáveis, funções, classes, módulos) | **inglês** | `calculateTotalWithDiscount()`, `class TaskAdapter` |
| Nomes de arquivos | **inglês** | `task-manager-abstraction.md`, `react-developer.md` |
| Commits e branches | **inglês** | `feat: add jira adapter retry logic`, `chore/onion-saneamento` |
| Logs e debugging | **inglês** | `Error: provider not configured` |
| YAML frontmatter (campos) | **inglês** | `name:`, `description:`, `tools:` |
| YAML frontmatter (valores narrativos) | pt-BR aceito | `description: "Especialista em..."` |

### 1.1 Justificativa

- pt-BR em camadas de documentação e UX mantém o framework acessível ao mantenedor e leitores nativos
- Inglês em camadas técnicas garante interoperabilidade com ferramentas (git, linters, sistemas de busca)
- Misturar idiomas dentro da mesma camada é proibido (não escrever metade do README em pt-BR e metade em inglês)

### 1.2 Exceções aceitas

- Citações diretas de fontes externas podem manter idioma original (geralmente inglês)
- Termos técnicos sem tradução consolidada (ex: "Pull Request", "feature flag", "commit") podem ser usados em pt-BR
- Nomes próprios de tecnologias mantêm grafia oficial (Claude Code, GitHub, Jira)

---

## 2. Formatação Markdown

### 2.1 Headers

- `# H1` — apenas para o título do documento (um por arquivo)
- `## H2` — seções principais
- `### H3` — subseções
- `#### H4` — uso esparso, preferir listas

### 2.2 Listas

- Hífen (`-`) para listas não ordenadas
- Números (`1.`, `2.`) para listas ordenadas com sequência relevante
- Recuo de 2 espaços para sub-itens

### 2.3 Tabelas

Usar quando comparativo ou tabular é mais legível que prosa:

```markdown
| Coluna 1 | Coluna 2 |
|---|---|
| valor | valor |
```

### 2.4 Blocos de código

- Triple backticks com linguagem declarada (` ```yaml `, ` ```bash `, ` ```typescript `)
- Para diagramas: ` ```mermaid `

### 2.5 Links

- Markdown nativo `[label](path)` para links internos
- Sempre paths relativos (não absolutos)
- Linkar para arquivos específicos quando possível, não para pastas

### 2.6 Frontmatter

YAML válido entre `---` no início do arquivo. Campos comuns:

```yaml
---
title: <título humano>
date: <YYYY-MM-DD>
version: <semver>
status: <active | historical | draft | candidato>
---
```

**Valores de `status`:**

- `active` — vigente, é a referência atual.
- `historical` — preservado como registro; superado por algo mais novo.
- `draft` — em elaboração, ainda não é referência.
- `candidato` — **entra pra ganhar core por uso, não por estar pronta**: KB nascida de
  discussão/dogfood que se prova por uso repetido antes de ser promovida a `active`. Convenção
  estabelecida por uso (7 KBs em 2026-07) e formalizada aqui a partir do sinal de campo do dogfood
  do `pre-pr` da promoção de `onion-guardrails`.

---

## 3. Convenções de naming

### 3.1 Filenames

- **kebab-case** para tudo em `.claude/` e `docs/` (`task-manager-abstraction.md`)
- Sufixos descritivos quando útil (`-2025`, `-v4`, `-historical`)
- Não usar espaços, underscores ou PascalCase
- Extensão `.md` para documentos, `.json` para configs estruturadas, `.yml` apenas em workflows CI

### 3.2 Slugs em YAML

- `name:` em agentes — kebab-case sem prefixo
- `description:` — uma frase, sem terminar com ponto final obrigatório

### 3.3 Branches Git

- Padrão GitFlow: `feature/<nome>`, `hotfix/<nome>`, `release/<versao>`
- Chores: `chore/<descricao>` (ex: `chore/onion-saneamento-2026-05`)

### 3.4 Commits

- Conventional Commits em inglês: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- Mensagem descritiva curta na primeira linha, contexto opcional após linha em branco
- Quando aplicável, referenciar issue/ID de task

---

## 4. Estilo de escrita

### 4.1 Tom

- **Documentação técnica**: direto, factual, sem floreios
- **Análises críticas**: crítico mas construtivo; evitar tom acusatório
- **Mensagens ao usuário**: claro e empático; sem jargão desnecessário
- **Comentários em código**: explicar **por quê**, não o **quê** (o código mostra o quê)

### 4.2 Emojis

- **Permitido** em READMEs, INDEX, comandos, guias (uso moderado para hierarquia visual: 🧅, 📚, 🎯)
- **Proibido** em meta-specs e análises críticas (manter tom profissional)
- **Proibido** em código

### 4.3 Estrutura de seções

Documentos longos devem ter:

- Frontmatter
- Título (H1)
- Sumário ou índice (quando >5 seções)
- Seções numeradas ou nomeadas
- Conclusão ou próximos passos (quando aplicável)

---

## 5. Padrões de teste

Quando o Onion gerar ou validar testes (em projeto-alvo):

- Manter idioma do código-base do projeto-alvo
- Descrições de teste podem ser bilíngues se o projeto-alvo permitir
- Estrutura AAA (Arrange-Act-Assert) ou Given-When-Then quando aplicável
- Cobertura de happy path + edge cases + erro

Framework de testes documentado em: [docs/knowledge-base/frameworks/framework-testes.md](../knowledge-base/frameworks/framework-testes.md).

---

## 6. Configuração e secrets

- **Nunca** commitar credenciais, tokens, API keys
- `.env` no `.gitignore` (sempre); `.env.example` versionado como referência
- Documentar variáveis de ambiente em `.env.example` com comentários explicativos
- Quando um agente referenciar variável, documentar isso em [integrations.md](./integrations.md)

---

## 7. Acessibilidade da documentação

- Headings hierárquicos (não pular níveis: H2 → H3 → H4, não H2 → H4)
- Tabelas com cabeçalho claro
- Imagens com texto alternativo (`![texto alt](path)`)
- Diagramas Mermaid em vez de imagens binárias quando possível
- **Referências legíveis:** todo id opaco (`T1`, `#7`, `§8`, `$1`, `blip #9`, regra `r16`, PR `#144`)
  leva um **rótulo mnemônico de 2-5 palavras na 1ª menção** — ex.: `T1 (peer-ou-provisório)`,
  `#7 (.prettierignore no adopt)`. Ids nus economizam o autor e **gastam a cognição do leitor** (ele para
  e rebusca). Com vários ids relacionados, dar um mini-glossário. Vale para docs, comentários, commits,
  PRs e mensagens ao usuário.

---

## 8. Exemplos

### Exemplo conforme

```markdown
---
title: Knowledge Base — Spec-Driven Development
date: 2025-12-02
version: 1.0.0
---

# Spec-Driven Development

## Conceito

A metodologia **Spec-Driven Development** propõe...

## Ferramentas

| Ferramenta | Categoria | Status |
|---|---|---|
| Kiro | IDE | Beta |
| Spec-Kit | CLI | Stable |
```

- Frontmatter completo
- Idioma pt-BR consistente
- Headers hierárquicos
- Tabela bem formatada

### Exemplo não-conforme

```markdown
# MyDocument

This is a comment in english about spec.

```bash
DESCONTO=10  # variável em pt-BR
```

# Outra Section H1
```

Violações:

- Filename presumível em PascalCase
- Idioma misto (inglês fora de código)
- Variável de código em pt-BR
- Dois H1 no mesmo arquivo

---

## 9. Versionamento e mudanças

Mudanças nesta spec exigem:

1. PR específico para `docs/meta-specs/code-standards.md`
2. Atualização do campo `version`
3. Quando aplicável, migração de artefatos existentes ou plano de migração explícito
