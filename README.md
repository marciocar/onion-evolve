<div align="center">

# 🧅 Onion

### Organize produto, engenharia e governança no mesmo ritmo — nativo do **Claude Code**.

![Licença: MIT](https://img.shields.io/badge/licença-MIT-success)
![Plataforma](https://img.shields.io/badge/plataforma-Claude_Code-D97757)
![Metodologia](https://img.shields.io/badge/metodologia-Spec--as--Code_%2B_SDD-blue)
[![Família Onion](https://img.shields.io/badge/família-Onion-8A2BE2)](https://github.com/marciocar/onion)

**[O que é](#-o-que-é) · [Início rápido](#-início-rápido) · [Contexto](#-arquitetura-de-contexto) · [Família Onion](#-família-onion) · [Documentação](#-documentação) · [Contribuir](#-contribuir)**

</div>

---

> [!NOTE]
> **`onion-evolve`** é um **fork privado de evolução** da porta Claude Code do Onion — onde novas capacidades (auto-auditoria `/meta:evolve`, federação multi-repo, auto-teste de guardas) são incubadas. **Não é** a porta pública canônica da família; o hub público fica em **[github.com/marciocar/onion](https://github.com/marciocar/onion)**.

## 🎯 O que é

O Onion é um **framework template em `.claude/`** que se instala em qualquer projeto — novo, legado ou regulado — para orquestrar o ciclo completo de desenvolvimento com Claude Code. Separa **decisão de negócio**, **execução técnica** e **governança/compliance** em contextos distintos, conectados por fluxos e padrões repetíveis. Comandos, agentes especializados e documentação passam a conversar entre si em vez de competir por atenção no chat ou em arquivos soltos.

O Onion **não é produto npm**, **não é distribuído publicamente** e **não tem CLI standalone**. Plataforma única: Claude Code.

## ⚡ Início rápido

1. Abra um projeto que já tenha o Onion instalado (`.claude/` + `CLAUDE.md` na raiz) no **Claude Code**.
2. Rode **`/onion`** para orientação inteligente, ou **`/warm-up`** para carregar o contexto do projeto.

**Como invocar:**

| Primitivo | Sintaxe | Exemplo |
|---|---|---|
| Comando | `/categoria:comando` | `/engineer:start`, `/product:task` |
| Agente | `@agente` | `@code-reviewer`, `@gitflow-specialist` |

## 🧩 O que muda no dia a dia

- Menos retrabalho por decisões perdidas ou mal comunicadas.
- **Contexto explícito** antes de cada ação: todo mundo sabe em qual dimensão está trabalhando (produto, engenharia ou compliance).
- **Workflows faseados retomáveis** com sessões persistentes (`.claude/sessions/`) que permitem pausar e continuar.
- Documentação e fluxo de trabalho **mais próximos do que o time realmente faz**.
- Práticas de **configuração e segurança** integradas (credenciais fora do repositório, templates seguros).

## 🏛️ Arquitetura de contexto

O Onion separa o conhecimento do projeto em **três contextos peer** + uma **base de conhecimento reutilizável** — tudo em Markdown versionado no Git. É essa a matéria-prima que a IA lê para gerar e manter código com qualidade: o núcleo do **Spec-as-Code**.

| Contexto | O que captura | Gerado por |
|---|---|---|
| 💼 **Negócio** · [`docs/business-context/`](docs/business-context/) | clientes, mercado, produto, estratégia e comunicação | `/docs:build-business-docs` |
| ⚙️ **Técnica** · [`docs/technical-context/`](docs/technical-context/) | codebase, arquitetura (C4/ADR), decisões e workflows técnicos | `/docs:build-tech-docs` |
| 🛡️ **Compliance** · [`docs/compliance-context/`](docs/compliance-context/) | frameworks regulatórios, segurança, continuidade e governança (ISO 27001/22301, SOC2, PMBOK) | `/docs:build-compliance-docs` |
| 📚 **Knowledge Base** · [`docs/knowledge-base/`](docs/knowledge-base/) | conceitos, frameworks, padrões e ferramentas reutilizáveis entre projetos | `/meta:create-knowledge-base` |

> Os três contextos alimentam a hierarquia de specs (**L0 meta-specs → L1 domínio → L2 feature → L3 task**); a Knowledge Base é a camada de referência que sustenta a autoria deles. **As specs são a fonte de verdade; o código é a saída gerada.**

## 🌐 Família Onion

| Porta | Plataforma | Repositório |
|---|---|---|
| 🌐 onion (hub) | a história de todas | [onion](https://github.com/marciocar/onion) |
| 🟠 **claude** | **Claude Code** | **◀ você está aqui** — `onion-evolve` (fork privado de evolução) |
| 🔵 cursor | Cursor | [onion-cursor](https://github.com/marciocar/onion-cursor) |
| 🟣 antigravity | Google Antigravity | [onion-antigravity](https://github.com/marciocar/onion-antigravity) |
| ⚡ zed | Zed | [onion-zed](https://github.com/marciocar/onion-zed) |
| 🟢 codex | OpenAI Codex | [onion-codex](https://github.com/marciocar/onion-codex) |
| 🐙 copilot | GitHub Copilot + VS Code | [onion-copilot](https://github.com/marciocar/onion-copilot) |

## 📚 Documentação

- **[Índice geral de docs](docs/INDEX.md)** · **[Guia Onion](docs/onion/)** — conceitos e referências operacionais.

<details>
<summary><b>Mais: para quem é e como funciona em três passos</b></summary>

<br>

**Para quem é** — squads de produto, engenharia e compliance que precisam alinhar prioridade, implementação, qualidade e conformidade; times que sentem falta de contexto compartilhado; organizações que querem padrão sem burocracia; projetos novos, legados ou regulados (ISO 27001, ISO 22301, SOC2, PMBOK).

**Como funciona em três passos**

1. **Definir a intenção** no contexto certo — produto (descoberta e spec), engenharia (implementação e entrega) ou compliance (governança e conformidade).
2. **Executar com apoio** de comandos padronizados e agentes especializados, em ciclos faseados retomáveis (`product/collect→feature` e `engineer/plan→pr-update`).
3. **Validar e registrar** — qualidade, segurança e conhecimento ficam sincronizados para o próximo ciclo.

</details>

## 🤝 Contribuir

Veja **[CONTRIBUTING.md](CONTRIBUTING.md)**.

## 📄 Licença

**Duas licenças, porque são duas naturezas:**

| o quê | licença | |
|---|---|---|
| **código** — scripts, hooks, comandos, agentes, skills, workflows | **MIT** | [LICENSE](LICENSE) |
| **método** — `docs/knowledge-base/`, `docs/meta-specs/`, `docs/sdaal/`, `.claude/rules/` e exemplos de grafo | **CC BY-NC 4.0** | [LICENSE-DOCS](LICENSE-DOCS) |

Em uma frase: **use o método no seu trabalho, adapte, cite a origem — não o venda como produto nem
como curso seu.** O que você constrói *com* o Onion é seu; a documentação que ensina o método é que
não se revende. Uso comercial da documentação exige autorização.

Nenhuma das duas concede **marca**: um trabalho derivado não se apresenta como "Onion".

O Onion se inspira em ideias de **interface unificada** para orquestração com IA; referência conceitual: [Esperanto, de Luis Novo](https://github.com/lfnovo/esperanto).

<div align="center"><sub>🧅 Onion — contexto certo, decisão melhor, entrega contínua.</sub></div>
