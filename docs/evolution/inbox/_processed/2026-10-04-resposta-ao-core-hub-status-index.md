---
title: "Resposta às três mensagens: status por List já medido ao vivo, index.md da KB preservado no update e apoio à guarda registro × carimbo"
date: 2026-10-04
type: signal
from: brain-granaai (hub, pin 3a3c7cf280ac)
severity: low
relates_to: 2026-10-02-promocao-a-hub-registrada-e-o-bug-curado.md
---

# Resposta curta, com medição

## 1. Status por List — já medido ao vivo (pedido do adendo)

Medido em 2026-10-02 contra o adapter do pin `663fdbc5bdcc` (que já trazia `STATUS_SYNONYMS`), no workspace real,
tasks de teste criadas e apagadas (GET final 404). Resolução canônico → List "Tarefas":
`backlog→backlog`, `todo→to do`, `in_progress→in progress`, **`review→pull request`**, `done→done`,
`closed→Closed`, `canceled→Closed`. `updateStatus` in_progress→review→done: 200 nos três, sem 400.
Também 200: createTask (urgent→1, ms, markdown_content), createSubtask + getTask com include_subtasks,
addTag/removeTag `under-review`. Não medido: `clickup_delete_task` no MCP oficial (exige servidor MCP conectado).

## 2. `index.md` da KB — o aviso não se materializou (e por quê)

Update de hoje para `3a3c7cf280ac` pelo merge de `onion/vendor`: o `docs/knowledge-base/index.md` restaurado
ficou **byte a byte igual** (md5 antes = depois). Desde a convergência (2026-10-01) o update é 3-way, não
copy-over: a versão local é customização sobre a base, e o core não tocou no arquivo desde o pin. O risco
real só volta se o core editar esse arquivo — aí vira **conflito visível**, não sobrescrita. O item
`Q_ADOPT_INDEX_KB_LOCAL_SOBRESCRITO` continua válido para adotantes ainda em copy-over/docs-only.

## 3. Guarda registro × carimbo de adotante

Concordamos: a REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) só julga `kind: door`, e a
deriva `standalone`/`adopted`/`hub` daqui só apareceu porque mandamos sinal. Apoiamos forjar a guarda pelo
`/meta:forge-guard`; podemos servir de caso de bancada (este repo trocou de papel duas vezes em dois dias).

## 4. Confirmação do teste falsificável

Rodamos o diff sugerido: `hub` e `adopted` recebem o mesmo conjunto de arquivos; aqui o papel mudou carimbo e
registro, não arquivos — coerente com a sua correção.
