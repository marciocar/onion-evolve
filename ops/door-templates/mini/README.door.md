# 🧅 Onion Mini

**O jeito mais simples de começar a construir software com o Claude Code, do jeito Onion.**

O Onion Mini é para quem está começando. Ele traz **um caminho só**, do começo ao fim: você anota
uma ideia, transforma a ideia numa tarefa, desenvolve a tarefa com a ajuda do Claude e abre um Pull
Request no final. Nada além disso. Quando você quiser mais, a versão completa do Onion continua lá.

## Do que você precisa

- O **Claude Code** instalado (`claude` no terminal).
- O **git** instalado, e um projeto seu (pode ser uma pasta vazia).
- Opcional: uma conta no **GitHub**, para abrir o Pull Request no final.

## Como instalar

Copie a pasta `.claude/` deste repositório para dentro do seu projeto, **sem sobrescrever nada que já
exista lá**, e deixe de fora o arquivo `.claude/.onion-version` (ele é a etiqueta deste repositório,
não do seu projeto):

```bash
git clone https://github.com/marciocar/onion-mini.git
cp -rn onion-mini/.claude seu-projeto/
# a etiqueta copiada é a do Mini: se for idêntica à dele, saiu daqui e não é sua
cmp -s onion-mini/.claude/.onion-version seu-projeto/.claude/.onion-version && rm seu-projeto/.claude/.onion-version
cp -n onion-mini/CLAUDE.md seu-projeto/
cd seu-projeto && claude
```

- O `-n` não sobrescreve: se o seu projeto já tiver um arquivo com o mesmo nome, o seu fica.
- Se o seu projeto **já tinha** um `CLAUDE.md`, o do Mini não foi copiado: cole o conteúdo dele no fim
  do seu.
- Os `docs/` deste repositório são o contrato das sessões de trabalho; copie-os também se o seu projeto
  ainda não tiver uma pasta `docs/knowledge-base/`: `cp -rn onion-mini/docs seu-projeto/`.

Pronto. Dentro do Claude Code, os comandos começam com `/`.

## O caminho, passo a passo

| Passo | Comando | O que acontece |
|---|---|---|
| 1. Conhecer o projeto | `/warm-up` | O Claude lê o seu projeto e entende onde está pisando |
| 2. Anotar a ideia | `/product:collect` | Você conta a ideia (uma funcionalidade nova, um bug) e ela fica registrada |
| 3. Deixar a ideia clara | `/product:refine` | O Claude faz perguntas até a ideia ficar sem dúvida |
| 4. Escrever o que vai ser feito | `/product:spec` | A ideia vira uma especificação curta |
| 5. Criar a tarefa | `/product:feature` | A especificação vira uma tarefa pronta para desenvolver |
| 6. Começar | `/engineer:start` | O Claude cria a branch, abre uma sessão e entende a tarefa |
| 7. Planejar | `/engineer:plan` | O trabalho é dividido em fases pequenas |
| 8. Trabalhar | `/engineer:work` | Uma fase de cada vez, com você aprovando cada uma |
| 9. Entregar | `/engineer:pr` | O Claude abre o Pull Request |

Os passos 3 e 4 são opcionais: se a ideia já está clara, vá direto do 2 para o 5.

**Parou no meio?** Ao voltar, rode `/catch-up`: o Claude reconstrói onde vocês pararam.

**Perdido?** Digite só `onion` e o Claude explica qual é o próximo passo.

## Gerenciador de tarefas (opcional)

Sem configurar nada, o Onion Mini funciona **sem gerenciador de tarefas**: as tarefas ficam na sua
sessão local. Se você usa Jira, ClickUp, Asana, Linear ou Zoho Projects e quer que as tarefas
apareçam lá, crie um arquivo `.env` na raiz do projeto com `TASK_MANAGER_PROVIDER` e as variáveis do
seu gerenciador. A lista de cada um está em `.claude/utils/task-manager/README.md`. Nunca coloque o
`.env` no git: ele guarda as suas chaves.

## Quem ajuda você no caminho

O Claude chama estes especialistas quando precisa:

- `@product-agent` — organiza e prioriza as ideias;
- `@task-specialist` — quebra uma tarefa grande em partes menores;
- `@code-reviewer` — revisa o código antes do Pull Request;
- `@test-engineer` — ajuda a escrever testes.

## O que o Mini não tem, de propósito

O Mini é o ciclo de produto e desenvolvimento, e só ele. A versão completa do Onion tem muito mais:
grafo de conhecimento, documentação gerada, compliance, guardas automáticas no CI e as ferramentas
para criar novos comandos e agentes. Alguns comandos do Mini mencionam essas ferramentas; quando você
encontrar uma que não está aqui, ela é da versão completa e o seu caminho continua sem ela.

Quer a versão completa? Ela é o `onion-standalone` (para um projeto seu) ou o `onion-core` (para
empresas), em `github.com/marciocar`.

## Licença

MIT — veja `LICENSE`.

---

Este repositório é **gerado** a partir do core do Onion e não recebe Pull Request: uma correção feita
aqui seria sobrescrita na próxima geração.
