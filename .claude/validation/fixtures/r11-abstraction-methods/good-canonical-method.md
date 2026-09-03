---
name: good-canonical-method
description: fixture r11 — comando chama método canônico searchTasks de ITaskManager, caso legítimo vizinho
category: meta
tags: [fixture]
---

# Comando de teste — método canônico

Este comando busca as tasks assim:

```
const tasks = await taskManager.searchTasks({ status: 'open' });
```

`searchTasks` é um método real de ITaskManager (ver .claude/utils/task-manager/interface.md).
