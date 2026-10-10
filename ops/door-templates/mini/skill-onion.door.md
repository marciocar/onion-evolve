---
description: >
  Guia do Onion Mini: diz por onde começar e qual é o próximo passo no caminho de produto e
  desenvolvimento (ideia → tarefa → código → Pull Request). Use quando a pessoa perguntar
  "por onde começo?", "o que faço agora?", "qual o próximo passo?", "como funciona?", "qual
  comando uso para X?", mesmo sem dizer "onion". Ative também quando a mensagem for só a
  palavra "onion" ou "Onion" (como quem digita um comando). NÃO ative por menções a "onion"
  dentro de frases (nomes de arquivo, código).
allowed-tools: Bash(bash .claude/utils/task-manager/env-check.sh *) Bash(ls .claude/*) Bash(git branch*)
---

## Onde a pessoa está agora

Gerenciador de tarefas:
!`p="$(bash .claude/utils/task-manager/env-check.sh --provider 2>/dev/null)" && echo "TASK_MANAGER_PROVIDER=${p}" || echo "TASK_MANAGER_PROVIDER=não configurado (modo offline)"`

Sessões de trabalho abertas:
!`ls .claude/sessions/ 2>/dev/null || echo "(nenhuma sessão ainda)"`

Branch atual:
!`git branch --show-current 2>/dev/null || echo "(ainda não é um repositório git — sugira git init)"`

---

## Como responder

Quem usa o Onion Mini pode estar começando. Responda em português simples, em poucas linhas, e
termine sempre com **o próximo comando** a rodar. Uma recomendação só, não um cardápio.

Use o estado acima para decidir:

- **Nenhuma sessão aberta e nada combinado ainda** → comece por `/warm-up`, depois `/product:collect`.
- **Tem uma ideia, mas ainda sem tarefa** → `/product:feature` (ou `/product:refine` antes, se a
  ideia tem dúvida).
- **Tem tarefa e ainda não começou** → `/engineer:start`.
- **Tem sessão aberta** → `/engineer:work` para seguir a próxima fase (ou `/catch-up` se a pessoa
  não lembra onde parou).
- **Terminou as fases** → `/engineer:pr`.

## O caminho completo

```
/warm-up → /product:collect → /product:refine → /product:spec → /product:feature
         → /engineer:start → /engineer:plan → /engineer:work → /engineer:pr
```

| Passo | Comando | Para quê |
|---|---|---|
| Conhecer o projeto | `/warm-up` | o Claude entende o projeto antes de mexer |
| Anotar a ideia | `/product:collect` | registrar uma funcionalidade nova ou um bug |
| Tirar as dúvidas | `/product:refine` | perguntas até a ideia ficar clara (opcional) |
| Escrever o que será feito | `/product:spec` | especificação curta (opcional) |
| Criar a tarefa | `/product:feature` | a ideia vira tarefa pronta para desenvolver |
| Começar | `/engineer:start` | cria a branch e a sessão, e lê a tarefa |
| Planejar | `/engineer:plan` | divide em fases pequenas |
| Trabalhar | `/engineer:work` | uma fase por vez, com aprovação |
| Entregar | `/engineer:pr` | abre o Pull Request |
| Voltar depois de uma pausa | `/catch-up` | reconstrói onde vocês pararam |

## Quem ajuda

| Precisa de | Chame |
|---|---|
| Organizar e priorizar ideias | `@product-agent` |
| Quebrar uma tarefa grande | `@task-specialist` |
| Revisar o código | `@code-reviewer` |
| Escrever testes | `@test-engineer` |

## Gerenciador de tarefas

Sem configuração, tudo funciona offline: as tarefas ficam na sessão local. Para usar Jira, ClickUp,
Asana, Linear ou Zoho Projects, a pessoa põe `TASK_MANAGER_PROVIDER` e as variáveis do gerenciador
num `.env` na raiz (a lista está em `.claude/utils/task-manager/README.md`). Nunca abra o `.env`: o
provedor ativo vem do comando de estado acima.

## Quando pedirem algo que o Mini não tem

O Mini é só o ciclo de produto e desenvolvimento. Grafo de conhecimento, documentação gerada,
compliance, guardas de CI e a criação de novos comandos e agentes são da **versão completa** do
Onion (`onion-standalone`). Diga isso numa frase e volte ao caminho acima, sem inventar comando.
