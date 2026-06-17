# 🎲 Gate de Story Points — Validação Compartilhada

> Fragmento canônico do **gate de estimativa** aplicado antes de iniciar
> desenvolvimento em cima de uma task. Reutilizável por comandos que arrancam
> trabalho (`engineer/start`, e candidatos `engineer/work`, `engineer/hotfix`).
> Citar como `common:prompts:story-points-gate`.
>
> **Opcional mas recomendado** — não bloqueia; orienta. O **gatilho** (em que
> momento rodar) é específico de cada comando; este fragmento cobre a **lógica
> comum** + os templates de mensagem ao usuário.
>
> Pré-requisito: task já carregada via abstração (ver
> `common:prompts:task-manager-provider-detection`).

## Como funciona

Antes de iniciar o desenvolvimento, verificar se a task tem estimativa de story
points e reagir conforme o valor:

- **Sem estimativa (0 / ausente):** avisar e oferecer estimar agora
  (`/product/estimate` ou `@story-points-framework-specialist`).
- **Épico (> 13 pontos):** alertar e oferecer quebrar a task
  (`/product/refine`); se o usuário não confirmar a continuação, parar.
- **Estimativa válida (1–13):** confirmar e seguir.

```typescript
// Verificar se task tem story points estimados
const storyPoints = task.customFields?.find(f => f.name === 'Story Points')?.value;

if (!storyPoints || storyPoints === 0) {
  console.warn(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ATENÇÃO: TASK SEM ESTIMATIVA DE STORY POINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: ${task.name}
🎲 Story Points: Não estimado

💡 RECOMENDAÇÕES:
∟ Estimar antes de iniciar desenvolvimento
∟ Usar: /product/estimate "${task.name}"
∟ Ou: @story-points-framework-specialist

⚠️ Continuar sem estimativa pode afetar:
   - Planejamento de sprint
   - Tracking de velocity
   - Previsibilidade de entrega

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  `);

  // Perguntar ao usuário se deseja estimar agora
  const shouldEstimate = await askUser('Deseja estimar story points agora? (s/n)');

  if (shouldEstimate) {
    // Invocar agente de estimativa
    await invokeStoryPointsEstimation(task);
  }
} else if (storyPoints > 13) {
  console.warn(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ALERTA: TASK IDENTIFICADA COMO ÉPICO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: ${task.name}
🎲 Story Points: ${storyPoints} pontos

💡 RECOMENDAÇÕES:
∟ Considerar quebrar em múltiplas tasks menores
∟ Usar: /product/refine para detalhar requisitos
∟ Verificar se realmente precisa ser uma única task

⚠️ Tasks > 13 pontos têm:
   - Maior margem de erro na estimativa
   - Risco de não caber no sprint
   - Dificuldade de tracking de progresso

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  `);

  // Perguntar ao usuário se deseja continuar
  const shouldContinue = await askUser('Deseja continuar mesmo assim? (s/n)');
  if (!shouldContinue) {
    console.log('💡 Sugestão: Use /product/refine para detalhar e quebrar a task');
    return;
  }
} else {
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ VALIDAÇÃO DE ESTIMATIVA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: ${task.name}
🎲 Story Points: ${storyPoints} pontos

✅ Estimativa válida para desenvolvimento

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  `);
}
```
