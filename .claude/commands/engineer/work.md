---
name: work
description: |
  Continuar trabalho em feature ativa. Lê sessão e identifica próxima fase.
  Atualiza progresso via Task Manager abstraction.
model: sonnet
allowed-tools: Bash(git *) Bash(cat .env*) Read Write Edit Grep Glob
category: engineer
tags: [development, workflow, session]
version: "3.0.0"
updated: "2025-11-24"
---

# Engineer Work

Estamos atualmente trabalhando em uma funcionalidade que está especificada na seguinte pasta:

<folder>
#$ARGUMENTS
</folder>

Para trabalhar nisso, você deve:

- Ler todos os arquivos markdown na pasta
- Revisar o arquivo plan.md e identificar qual Fase está atualmente em progresso
- Apresentar ao usuário um plano para abordar a próxima fase

## 🔄 **Auto-Update Task Manager**

Mecanismo de sincronização: `common:prompts:task-manager-auto-update` (provedor
ativo via adapter; comentário DUAL detalhado-na-subtask + resumido-na-task;
timestamp + status; offline → registrar em `plan.md`/`notes.md`, sem persistir).

**Gatilho deste comando:** a cada FASE concluída → comentário de progresso +
`updateStatus(subtaskId, 'done')` + atualização do `plan.md` (status, decisões, progresso %).

### **🔗 CRITICAL: Phase→Subtask Mapping**
**OBRIGATÓRIO**: Quando uma fase é completada, o sistema deve:
1. **Identificar subtask correspondente** via mapeamento estabelecido no context.md
2. **Atualizar status da subtask** para "done" automaticamente
3. **Documentar conclusão** com timestamp e métricas da fase

### **🗺️ SUBTASK MAPPING STRUCTURE (context.md):**
```markdown
## 📋 Phase-Subtask Mapping
- **Phase 1**: "Nome da Fase" → Subtask ID: [subtask-id-1]
- **Phase 2**: "Nome da Fase" → Subtask ID: [subtask-id-2]
```

### **⚡ AUTOMATIC EXECUTION (Via Abstração):**
Quando uma fase é marcada como "Completada ✅" no plan.md, o sistema deve **EXECUTAR NESTA ORDEM**:

```typescript
// 1. Obter task manager
const taskManager = getTaskManager();

if (taskManager.isConfigured) {
  // 2. Comentário DETALHADO na SUBTASK
  await taskManager.addComment(subtaskId, `
🔧 FASE COMPLETADA: ${phaseName}

━━━━━━━━━━━━━━

📁 ARQUIVOS MODIFICADOS:
${filesModified.map(f => `   ∟ ${f}`).join('\n')}

🔧 IMPLEMENTAÇÕES:
${implementations.map(impl => `   ▶ ${impl}`).join('\n')}

💡 DECISÕES TÉCNICAS:
${decisions.map(d => `   ∟ ${d}`).join('\n')}

🚀 PRÓXIMOS PASSOS:
   ∟ ${nextPhase}

━━━━━━━━━━━━━━

⏰ Completado: ${timestamp} | 🎯 Status: Done
  `);

  // 3. Atualizar STATUS da SUBTASK
  await taskManager.updateStatus(subtaskId, 'done');

  // 4. Comentário RESUMIDO na TASK PRINCIPAL
  await taskManager.addComment(mainTaskId, `
📝 PROGRESSO: Fase ${phaseNum}/${totalPhases} Completada

✅ ${phaseName} - Concluída
   ∟ Subtask: #${subtaskId}
   ∟ Detalhes: Ver comentário na subtask

🎯 Próximo: Fase ${phaseNum + 1}/${totalPhases} - ${nextPhaseName}

⏰ ${timestamp}
  `);
}
```

## Importante:

Quando você desenvolver o código para a fase atual, use os sub-agentes de desenvolvimento, code-review e teste quando apropriado para preservar o máximo possível do seu contexto.

Toda vez que completar uma fase do plano:
- **AUTO-UPDATE**: Adicione comentário de progresso via abstração
- **RASTREAMENTO**: Marque checkboxes na description correspondentes aos critérios completados
- Pause e peça ao usuário para validar seu código.
- Faça as mudanças necessárias até ser aprovado
- Atualize a fase correspondente no arquivo plan.md marcando o que foi feito e adicionando comentários úteis para o desenvolvedor que abordará as próximas fases, especialmente sobre questões, decisões, etc.
- Apenas inicie a próxima fase após o usuário concordar que você deve começar.

## 🔗 Referências

- Abstração: `.claude/utils/task-manager/`
- Detector: `.claude/utils/task-manager/detector.md`
- Factory: `.claude/utils/task-manager/factory.md`
- Padrões de comentários: `common/prompts/clickup-patterns.md`

Agora, veja a fase atual de desenvolvimento e forneça um plano ao usuário sobre como abordá-la.
