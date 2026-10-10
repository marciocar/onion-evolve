# 🧅 Onion Mini

Este projeto usa o **Onion Mini**: o ciclo de produto e desenvolvimento do Onion, para quem está
começando. Quem usa pode ser iniciante: explique em linguagem simples, um passo de cada vez, e diga
sempre qual é o próximo comando.

## O caminho guiado

```
/warm-up → /product:collect → /product:feature → /engineer:start → /engineer:plan → /engineer:work → /engineer:pr
```

- `/product:refine` e `/product:spec` são opcionais, entre o `collect` e o `feature`, quando a ideia
  ainda tem dúvida.
- `/engineer:plan` divide o trabalho em fases pequenas; o `/engineer:work` executa uma fase por vez.
- `/catch-up` retoma de onde a pessoa parou. A palavra `onion`, sozinha, pede orientação.
- Se o comando pedir uma variável de ambiente que falta, sugira `/meta:setup-integration`. Sem
  gerenciador configurado, trabalhe offline (`TASK_MANAGER_PROVIDER=none`): as tarefas ficam na sessão.

## Onde as coisas ficam

- Comandos em `.claude/commands/` · agentes em `.claude/agents/` · a skill de orientação em
  `.claude/skills/onion/`
- Sessões de trabalho em `.claude/sessions/<nome-da-feature>/` (criadas pelo `/engineer:start`)
- Gerenciador de tarefas: `.claude/utils/task-manager/` · Pull Request: `.claude/utils/forge/`

## O que este projeto NÃO tem, e como agir

O Mini não traz grafo de conhecimento, documentação gerada, compliance, guardas automáticas nem as
ferramentas que criam comandos e agentes. Alguns comandos foram escritos para a versão completa e
mencionam essas ferramentas. Quando um passo citar algo que não existe aqui, **pule esse passo e
siga o caminho guiado**; diga à pessoa, numa frase, que aquilo é da versão completa do Onion
(`onion-standalone`), sem tratar a ausência como erro.

## Idioma

Converse, comente e documente em **português do Brasil**. Código, nomes de variáveis, de arquivos e
de branches em **inglês**. Commits: prefixo em inglês (`feat:`, `fix:`, `docs:`) e a descrição em
português.
