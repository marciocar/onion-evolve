---
name: bad-invented-method
description: fixture r11 — comando chama método de abstração inventado (getTaskList) que não existe em ITaskManager
model: haiku
category: meta
tags: [fixture]
---

# Comando de teste — método inventado

Este comando busca as tasks assim:

```
const tasks = await taskManager.getTaskList({ status: 'open' });
```

O método canônico para busca é `searchTasks`, não `getTaskList`.
