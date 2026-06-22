# Contribuindo com o Sistema Onion 🧅

Obrigado por considerar contribuir com o Onion!

O Onion é um **framework template em `.claude/`** — instalável em qualquer
projeto (novo, legado ou regulado) para orquestrar produto, engenharia e
compliance com Claude Code. **Não é produto npm, não é distribuído publicamente
e não tem CLI standalone.** Plataforma única: **Claude Code**.

Por isso, contribuir aqui é **escrever Markdown + YAML** (comandos, agentes,
skills, knowledge bases e documentação) — não código JavaScript/Node.

---

## 📋 Índice

- [Código de Conduta](#-código-de-conduta)
- [Pré-requisitos](#-pré-requisitos)
- [Estrutura do projeto](#-estrutura-do-projeto)
- [Tipos de contribuição](#-tipos-de-contribuição)
- [Padrões (meta-specs)](#-padrões-meta-specs)
- [Fluxo de Pull Request](#-fluxo-de-pull-request)
- [Idioma e commits](#-idioma-e-commits)
- [Validação](#-validação)

---

## 📜 Código de Conduta

Seja respeitoso, colaborativo, inclusivo e profissional em todas as interações.

---

## 🚀 Pré-requisitos

- **Git**
- **Claude Code** (plataforma única do framework)

Não há toolchain de build: o Onion é interpretado em runtime pelo Claude Code a
partir de `.claude/` (Markdown + YAML). Não há `package.json`, Node ou pnpm.

```bash
# 1. Fork e clone
git clone https://github.com/your-username/onion-evolve.git
cd onion-evolve

# 2. Abra no Claude Code — comandos, agentes e skills carregam automaticamente.
#    Para começar: /warm-up e depois /onion
```

---

## 🛠️ Estrutura do projeto

```
onion-evolve/
├── .claude/                # Sistema Onion operacional
│   ├── commands/           # Comandos por categoria (Markdown + frontmatter)
│   ├── agents/             # Agentes especializados por domínio
│   ├── skills/             # Skills (cérebro reutilizável)
│   ├── utils/              # Utilitários (incl. task-manager abstraction)
│   └── settings.json       # Hooks + permissions (versionado)
├── docs/                   # Documentação (Spec as Code)
│   ├── meta-specs/         # L0 — "constituição" do framework
│   ├── knowledge-base/     # Knowledge bases estruturadas
│   ├── business-context/   # Gerado por /docs:build-business-docs
│   ├── technical-context/  # Gerado por /docs:build-tech-docs
│   └── onion/              # Guias e referências
└── CLAUDE.md               # Project rules carregados pelo Claude Code
```

---

## 🤝 Tipos de contribuição

- **🐛 Bugs** — abra uma issue com: comando/agente envolvido, o que aconteceu,
  comportamento esperado, passos de reprodução.
- **✨ Novos comandos/agentes/skills** — use os criadores do próprio framework:
  `/meta:create-command`, `/meta:create-agent`, `/meta:create-skill`. Eles já
  aplicam os padrões das meta-specs.
- **📚 Documentação e knowledge bases** — correções, clareza, exemplos,
  `/meta:create-knowledge-base`.
- **🔌 Integrações (Task Manager)** — novos adapters seguindo o padrão SDAAL em
  `.claude/utils/task-manager/` (ver `docs/meta-specs/integrations.md`).

---

## 📏 Padrões (meta-specs)

As meta-specs L0 em `docs/meta-specs/` são a **fonte canônica** de padrões.
Consulte antes de criar/alterar artefatos:

| Você vai mexer em… | Consulte |
|---|---|
| Agente | [`agents.md`](docs/meta-specs/agents.md) — YAML obrigatório, categorias, limites de tamanho |
| Comando | [`commands.md`](docs/meta-specs/commands.md) — frontmatter, `allowed-tools` (§1.3), workflows faseados, limites (§5) |
| Arquitetura/estrutura | [`architecture.md`](docs/meta-specs/architecture.md) — framework instalável, dependências |
| Idioma/estilo/naming | [`code-standards.md`](docs/meta-specs/code-standards.md) |
| Integração externa | [`integrations.md`](docs/meta-specs/integrations.md) — adapters, `.env`, `.mcp.json` |

Pontos-chave:

- **Tamanho**: agente ≤1.200 linhas (hard >1.500); comando ≤500 (hard >800).
  Excedeu? Extraia conteúdo de referência para `docs/knowledge-base/` e mantenha
  o artefato como orquestrador enxuto.
- **`allowed-tools`** em comandos sensíveis (git/escrita/Task Manager) — escopo
  mínimo (ver `commands.md §1.3`).
- **Frontmatter YAML obrigatório** em comandos (`description`) e agentes
  (`name`, `description`, `tools`, `model`).
- **Sem assunções sobre o projeto-alvo**: nada de path absoluto; o framework é
  instalável em qualquer repo.

---

## 🔀 Fluxo de Pull Request

1. **Branch** a partir de `main` (GitFlow): `feature/...` ou `fix/...`
   (ou use `/git:flow feature start`).
2. **Mude** seguindo as meta-specs; atualize docs/índices afetados.
3. **Valide** localmente (ver abaixo).
4. **Commit** com Conventional Commits **em pt-BR** (ver próxima seção).
5. **Abra o PR** com título claro, descrição do quê/porquê, issues relacionadas
   e breaking changes (se houver).

---

## 🌍 Idioma e commits

Convenção do Onion (ver `code-standards.md`):

- **Código, nomes de arquivo, slugs, branches, variáveis**: inglês.
- **Comentários, documentação, mensagens ao usuário**: português brasileiro.
- **Mensagens de commit**: português brasileiro, seguindo
  [Conventional Commits](https://www.conventionalcommits.org/).

```bash
git commit -m "feat(product): adiciona comando de priorização de backlog"
git commit -m "fix(task-manager): corrige detecção de provider ausente no .env"
git commit -m "docs(meta-specs): esclarece convenção de allowed-tools"
```

Tipos: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `style`, `perf`.

---

## 🧪 Validação

Antes de abrir o PR:

- **Dogfood (padrão master)** — **rode o artefato alterado de verdade**, não só lint/spec:
  invoque o comando/skill, execute o script num caso real, teste o **modo de falha** (não só
  o happy-path) e resolva findings no **mesmo loop** (fix → re-dogfood). Doutrina:
  [`onion-dogfooding-doctrine.md`](docs/knowledge-base/concepts/onion-dogfooding-doctrine.md).
- Gate mecânico (o dogfood determinístico): `bash .claude/validation/lint-artifacts.sh` e,
  ao mexer em guardas/validação, `bash .claude/validation/lint-selftest.sh`. Se mudou
  contagens (comandos/agentes/skills/KBs), rode `/meta:inventory`.
- `/validate/workflow` — completude de workflows.
- Skills `onion-validation` e `onion-patterns` — conformidade de artefatos
  (YAML, categorias, limites de tamanho, naming).
- `@metaspec-gate-keeper` — validação de conformidade arquitetural contra as
  5 meta-specs.

Checklist:

- [ ] **Dogfoodado**: artefato alterado rodado de verdade; modo-de-falha exercitado; loop fechado.
- [ ] Segue as meta-specs aplicáveis.
- [ ] Frontmatter YAML correto.
- [ ] Dentro dos limites de tamanho (ou refatorado com extração para KB).
- [ ] Documentação/índices atualizados (`/docs:build-index` se necessário).
- [ ] Commits em pt-BR, Conventional Commits.

---

## 🔗 Links úteis

- [Identidade e visão geral (README)](README.md)
- [Índice da documentação](docs/INDEX.md)
- [Meta-specs (constituição)](docs/meta-specs/index.md)
- [Guias de aplicação](docs/applying/) — greenfield, legado, regulado

---

**Obrigado por contribuir com o Onion! 🧅**
