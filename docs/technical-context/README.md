# Technical Context

> Arquitetura de contexto técnico do projeto — gerada e mantida pelo comando `/docs:build-tech-docs`.

---

## Propósito

Esta pasta organiza o **contexto técnico** estruturado para consumo por IA e por humanos: codebase, arquitetura, decisões técnicas, fluxos de desenvolvimento e operação. É a **camada Technical** do Sistema Onion (complementa `docs/business-context/` e `docs/knowledge-base/`).

Use para que sistemas de IA forneçam assistência contextual no desenvolvimento e que novos devs entendam o projeto em horas em vez de dias.

---

## Estrutura esperada

```
docs/technical-context/
├── README.md                       # este arquivo
├── index.md                        # índice navegável (gerado pelo comando)
│
├── 01-core/                        # Camada 1 — Núcleo do projeto
│   ├── project-charter.md
│   └── adr/                        # Architecture Decision Records
│       └── <NNN-decisao>.md
│
├── 02-ai-context/                  # Camada 2 — Otimizado para IA
│   ├── ai-development-guide.md     # guia para Claude / Copilot / IDE
│   └── codebase-guide.md           # mapa de diretórios e fluxos
│
├── 03-domain/                      # Camada 3 — Domínio
│   ├── business-logic.md
│   └── api-specification.md
│
└── 04-workflow/                    # Camada 4 — Workflow de desenvolvimento
    ├── contributing.md
    ├── troubleshooting.md
    └── architecture-challenges.md
```

> Os arquivos são criados conforme demanda. Projetos simples podem ter só `01-core/` + `02-ai-context/`.

---

## Como gerar / atualizar

```bash
/docs:build-tech-docs <fontes-de-input>
```

O comando faz três fases:
1. **Descoberta** — escaneia codebase, dependências, CI/CD, padrões arquiteturais
2. **Discussão** — pergunta ao usuário sobre decisões não inferíveis (trade-offs, restrições, desafios)
3. **Geração** — escreve os arquivos nesta pasta seguindo a estrutura acima

---

## Princípios

- **Evidência primeiro**: toda afirmação deve estar ancorada em código, config ou git history
- **Multi-arquivo, não monolito**: cada tema é um arquivo focado
- **Otimizado para IA**: exemplos de código copy-paste, padrões explícitos, gotchas listados
- **Vivo**: regenerar quando arquitetura muda (novo serviço, refator grande, troca de stack)

---

## Relação com outras pastas

| Pasta | Papel |
|-------|-------|
| `docs/technical-context/` | **Esta pasta** — codebase, arquitetura, decisões técnicas |
| `docs/business-context/` | Clientes, mercado, produto, comunicação |
| `docs/knowledge-base/` | Conhecimento de referência (frameworks, conceitos, ferramentas) |
| `docs/meta-specs/` | Constituição (L0) — regras imutáveis do sistema |

---

**Comando responsável**: `/docs:build-tech-docs`
**Template-base**: `.claude/commands/common/templates/technical-context-template.md`
