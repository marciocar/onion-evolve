---
name: plan
description: Planejamento de feature. Analisa e cria plano estruturado.
model: sonnet
allowed-tools: Read Write WebSearch Bash(find *) Bash(ls *)
category: engineer
tags: [planning, architecture, design]
version: "3.0.0"
updated: "2025-11-24"
---

# Engineer Reason

Este é o comando para iniciar o planejamento de uma funcionalidade.

<arguments>
#$ARGUMENTS
</arguments>

## Análise

Leia os arquivos context.md e architecture.md na pasta .claude/sessions/<feature-slug> se ainda não tiver feito (carregue só as seções necessárias — ver protocolo de leitura em [worklog-protocol.md §4](../../../docs/knowledge-base/concepts/worklog-protocol.md)).

Sua tarefa agora é criar um plano de implementação detalhado (plan.md) para esta funcionalidade. O objetivo desta documentação é criar uma abordagem de implementação faseada que nos permita construir a funcionalidade incrementalmente, testando cada fase conforme avançamos. E também deve tornar possível retomar o trabalho caso nossa sessão seja interrompida.

O plan.md deve dividir a implementação em fases, cada fase com um pedaço do trabalho que pode ser realizado por um humano em ~2 horas. Cada fase é um **chunk auto-contido** (100–300 linhas): ler a fase N não deve exigir as fases anteriores em contexto.

**Vocabulário de estado (obrigatório):** use os tokens ASCII `[DONE]` / `[ACTIVE]` / `[TODO]` no header de cada fase e tarefa (definidos na [SSOT](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) e [worklog-protocol.md §6](../../../docs/knowledge-base/concepts/worklog-protocol.md)). Emoji é decorativo; o token entre colchetes é o que máquinas leem. Invariante: **exatamente uma** fase `[ACTIVE]`, e ela deve ser igual a `STATE.md.NEXT.phase` — o `STATE.md.NEXT` é o ponteiro **autoritativo** de resume; os badges abaixo são detalhe humano subordinado.

O template para o plan.md é:

<plan>
# [NOME DA FUNCIONALIDADE]

Se você está trabalhando nesta funcionalidade, atualize este plan.md E o `STATE.md.NEXT` conforme progride (ver checkpoint em [worklog-protocol.md §7](../../../docs/knowledge-base/concepts/worklog-protocol.md)).

> **Estado inicial:** num plano recém-criado, a Fase 1 nasce `[ACTIVE]` (igual a `STATE.md.NEXT.phase = 1`) e as demais `[TODO]`. Ao concluir uma fase, marque-a `[DONE]`, promova a próxima a `[ACTIVE]` e atualize o `STATE.md.NEXT` (transição em [worklog-protocol.md §6-7](../../../docs/knowledge-base/concepts/worklog-protocol.md)). Invariante: **exatamente uma** fase `[ACTIVE]`.

## FASE 1 [ACTIVE]

Detalhes desta parte da funcionalidade

### Uma tarefa que precisa ser feita [ACTIVE]

Detalhes sobre a tarefa

### Uma tarefa que precisa ser feita [TODO]

Detalhes sobre a tarefa

### Comentários:
- (preencher conforme progride) decisões, mudanças de direção, aprendizados

## FASE 2 [TODO]

### Uma tarefa que precisa ser feita [TODO]

Detalhes sobre a tarefa

## FASE 3 [TODO]

### Uma tarefa que precisa ser feita [TODO]

Detalhes sobre a tarefa

</plan>


Dicas:
   - Use repoprompt:search (se disponível) para encontrar arquivos específicos baseados nas respostas de descoberta
   - Use repoprompt:set_selection e repoprompt:read_selected_files (se disponível) para ler código relevante em batch
   - Analise detalhes específicos de implementação
   - Use WebSearch e ou context7 para melhores práticas ou documentação de bibliotecas (se necessário)

No caso desta pesquisa levantar uma nova decisão arquitetural ou contradição com as decisões anteriores, você iniciará uma discussão sobre isso com o humano, concordará com as mudanças e atualizará o documento architecture.md para aquela funcionalidade se necessário.

Este documento também deve anotar quais tarefas precisam ser feitas sequencialmente ou em paralelo.

Uma vez que o plan.md esteja finalizado, informe ao humano que você está pronto para prosseguir para o próximo passo.

