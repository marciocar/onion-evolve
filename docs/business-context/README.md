# Business Context

> Arquitetura de contexto de negócio do projeto — gerada e mantida pelo comando `/docs:build-business-docs`.

---

## Propósito

Esta pasta organiza o **contexto de negócio** estruturado para consumo por IA e por humanos: clientes, mercado, produto, comunicação e estratégia. É a **camada Business** do Sistema Onion (complementa `docs/technical-context/` e `docs/knowledge-base/`).

Use para que sistemas de IA tomem decisões de produto contextualmente apropriadas e que novos membros do time absorvam o contexto rapidamente.

---

## Estrutura esperada

```
docs/business-context/
├── README.md                       # este arquivo
├── index.md                        # índice navegável (gerado pelo comando)
│
├── 01-customer/                    # Camada 1 — Cliente
│   ├── personas.md
│   ├── journey.md
│   └── voice-of-customer.md
│
├── 02-product/                     # Camada 2 — Produto
│   ├── strategy.md
│   ├── metrics.md
│   └── features/
│       └── <feature>.md
│
├── 03-market/                      # Camada 3 — Mercado
│   ├── competitive-landscape.md
│   └── industry-trends.md
│
└── 04-operations/                  # Camada 4 — Operacional
    ├── sales-process.md
    ├── messaging-framework.md
    └── customer-communication.md
```

> Os arquivos são criados conforme demanda. Não é obrigatório preencher todas as camadas — apenas o que for relevante para o projeto.

---

## Como gerar / atualizar

```bash
/docs:build-business-docs <fontes-de-input>
```

O comando faz três fases:
1. **Descoberta** — analisa README, materiais de marketing, feedback, concorrentes
2. **Discussão** — pergunta ao usuário pontos não óbvios (visão, personas, riscos)
3. **Geração** — escreve os arquivos nesta pasta seguindo a estrutura acima

---

## Princípios

- **Evidência primeiro**: toda afirmação deve ter origem rastreável (issue, depoimento, métrica, fonte)
- **Multi-arquivo, não monolito**: cada tema é um arquivo focado
- **Otimizado para IA**: estrutura previsível e linkagem cruzada via `index.md`
- **Vivo**: regenerar quando contexto muda (PMF, pivot, expansão de mercado)

---

## Relação com outras pastas

| Pasta | Papel |
|-------|-------|
| `docs/business-context/` | **Esta pasta** — clientes, mercado, produto, comunicação |
| `docs/technical-context/` | Codebase, arquitetura, decisões técnicas, workflows |
| `docs/knowledge-base/` | Conhecimento de referência (frameworks, conceitos, ferramentas) |
| `docs/meta-specs/` | Constituição (L0) — regras imutáveis do sistema |

---

**Comando responsável**: `/docs:build-business-docs`
**Template-base**: `.claude/commands/common/templates/business-context-template.md`
