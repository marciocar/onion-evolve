# Guias de Aplicação do Sistema Onion

> Como instalar e aplicar o Sistema Onion em projetos novos, legados ou regulados.

---

## Visão geral

O Sistema Onion é um **framework template** que se materializa em cada projeto-alvo. Estes guias cobrem os três cenários principais de aplicação:

| Cenário | Guia | Quando usar |
|---|---|---|
| Greenfield | [applying-greenfield.md](./applying-greenfield.md) | Projeto novo, sem código ou documentação prévia |
| Legado | [applying-legacy.md](./applying-legacy.md) | Projeto existente, requer engenharia reversa antes da aplicação |
| Regulado | [applying-regulated.md](./applying-regulated.md) | Projeto sujeito a frameworks de compliance (ISO 27001, ISO 22301, SOC2, PMBOK) |

Cada guia documenta:

- Pré-requisitos
- Passo a passo desde clone/init até primeiro comando útil
- Decisão sobre quais dos três contextos spec-as-code ativar (business, technical, compliance)
- Comandos específicos do cenário
- Troubleshooting

---

## Pré-requisitos comuns a todos os cenários

1. **Claude Code instalado** — plataforma única do Onion
2. **Git** instalado e funcional
3. **Acesso ao repositório do Onion** (este repositório) para copiar `.claude/` e estrutura `docs/`
4. **Conta em pelo menos um Task Manager** (Jira, ClickUp, Asana ou Linear) se o projeto usar tasks

---

## Decisão inicial — Qual cenário se aplica?

Use esta árvore de decisão:

```
O projeto-alvo já tem código?
├── NÃO → applying-greenfield.md
└── SIM → O projeto-alvo está sujeito a frameworks regulatórios?
    ├── SIM → applying-regulated.md
    └── NÃO → applying-legacy.md
```

Projetos podem combinar cenários (ex: greenfield em setor regulado segue greenfield com camada compliance ativada).

---

## Automação (planejada) — `/meta:adopt`

Hoje a aplicação é **manual** (copiar `.claude/` + seguir o guia). A decisão de **operacionalizar
esta doutrina como um comando faseado in-platform** (`/meta:adopt <path|git-url>` — **não** CLI) está
registrada no [ADR de Adoção de Repositório](../analysis/onion-adr-repo-adoption-2026-06.md): modelos
de controle (instalar / operar in-place / worktree), stamp de versão e reuso de
`/docs:reverse-consolidate` + `/meta:setup-integration`. Até o comando existir, siga os guias abaixo.

---

**Próximo passo**: abrir o guia correspondente ao seu cenário.
