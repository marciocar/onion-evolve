---
name: work
description: |
  Continuar trabalho em feature ativa. Lê sessão e identifica próxima fase.
  Atualiza progresso via Task Manager abstraction.
model: sonnet
allowed-tools: Bash(git *) Bash(cat .env*) Bash(ls *) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh*) Read Write Edit Grep Glob
category: engineer
tags: [development, workflow, session, kg-first]
version: "3.1.0"
updated: "2026-07-16"
---

# Engineer Work

Estamos atualmente trabalhando em uma funcionalidade que está especificada na seguinte pasta:

<folder>
#$ARGUMENTS
</folder>

Para trabalhar nisso, você deve usar o **protocolo de leitura escalonado** (Tier 0→3) — **nunca** faça `cat` da pasta inteira (anti-pattern "Context Dump"; protocolo em [worklog-protocol.md §4](${CLAUDE_PLUGIN_ROOT}/kb/worklog-protocol.md)):

0. **KG-first (o primeiro ato, antes do Tier 0):** se existir um `.kg.yaml` no repo (`git ls-files '*.kg.yaml' | grep -v '/fixtures/'` — resolve ao vivo; o glob hardcoded anterior era **36% cego**), **consulte-o ANTES** do `STATE.md`/git — é o SSOT de estado/domínio, **acima** do git. Rode `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo>`, cite **ids de nó** — a seção **ESTADO** é a fila de abertos que o radar afunda, e é ali que costuma estar o próximo passo que este comando procura —, e faça **drive-to-verify** (cruzar claims `plane: PROD` de alto impacto contra o vivo) **antes** de agir; nó stale mente (`--freshness`). **Mecanismo, não conselho** — consultar por padrão é a forcing function contra a reincidência (sinal de campo 2026-07-16). Sem `.kg.yaml` → siga ao Tier 0. Doutrina: [knowledge-graph-sdaal.md](../../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md) §SSOT-as-runtime.
1. **Tier 0 (sempre, ~1KB):** leia **só o `STATE.md`**. Seu `## NEXT` é o ponteiro **autoritativo** — diz fase atual e próximo passo. Não escaneie badges do `plan.md` para decidir.
2. **Tier 1 (sob demanda):** leia **apenas o bloco da fase `[ACTIVE]`** do `plan.md` (a fase nomeada em `STATE.md.NEXT.phase`).
3. **Tier 2 (raro):** abra `architecture.md`/`context.md` **só** se o `## Map` do `STATE.md` indicar que esta fase precisa — e só a seção apontada.
4. **Drift guard:** se `STATE.md.last_checkpoint` for mais antigo que a edição mais recente do `plan.md`, ou se houver mais de uma fase `[ACTIVE]`, **pare e peça reconciliação** ao usuário (não escolha silenciosamente).
5. Apresente ao usuário um plano para abordar a fase `[ACTIVE]`.

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
Formato canônico na [SSOT](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) — lido (não redefinido) daqui:
```markdown
## 📋 Phase-Subtask Mapping
- **Phase 1**: "Nome da Fase" → Subtask ID: [subtask-id-1]
- **Phase 2**: "Nome da Fase" → Subtask ID: [subtask-id-2]
```

### **⚡ AUTOMATIC EXECUTION (Via Abstração):**
Quando uma fase é marcada como `[DONE]` no plan.md, o sistema deve **EXECUTAR NESTA ORDEM**:

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

Toda vez que completar uma fase do plano (**checkpoint** — ver [worklog-protocol.md §7](${CLAUDE_PLUGIN_ROOT}/kb/worklog-protocol.md)):
- **AUTO-UPDATE**: Adicione comentário de progresso via abstração
- **RASTREAMENTO**: Marque checkboxes na description correspondentes aos critérios completados
- Pause e peça ao usuário para validar seu código.
- Faça as mudanças necessárias até ser aprovado
- **Flip de estado**: marque a fase concluída como `[DONE]` no `plan.md` e a próxima como `[ACTIVE]`; adicione comentários úteis (decisões, questões) para quem abordará as próximas fases.
- **Atualize o `STATE.md.NEXT`** (fonte autoritativa): `phase`, `phase_title`, `status`, `next_action` (imperativo literal), `files_in_flight`, `validate_with`, `last_checkpoint`. Mantenha o invariante de **uma só** fase `[ACTIVE]`.
- **Antes de `/compact` ou `/clear`**: faça flush do checkpoint primeiro — após a compactação, reler só o `STATE.md` reorienta instantaneamente.
- Apenas inicie a próxima fase após o usuário concordar que você deve começar.

## 🔗 Referências

- Contrato de worklog (SSOT): [gitflow-patterns.md §Contrato de Sessão](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento)
- Protocolo de leitura/resume/checkpoint: [worklog-protocol.md](${CLAUDE_PLUGIN_ROOT}/kb/worklog-protocol.md)
- Higiene de contexto: [context-window-optimization.md](../../../docs/knowledge-base/concepts/context-window-optimization.md)
- Abstração: `.claude/utils/task-manager/`
- Detector: `.claude/utils/task-manager/detector.md`
- Factory: `.claude/utils/task-manager/factory.md`
- Padrões de comentários: `common/prompts/clickup-patterns.md`

Agora, veja a fase atual de desenvolvimento e forneça um plano ao usuário sobre como abordá-la.
