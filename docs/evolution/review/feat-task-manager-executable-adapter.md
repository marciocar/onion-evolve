---
branch: feat/task-manager-executable-adapter
date: 2026-10-11
reviewed_diff_sha256: pendente
reviewed_code_sha256: cb61073f4e7637cd85a09acb493118d28e20cd0db1b8e74a03bc3a5914046d2f
findings_total: 5
findings_real: 5
findings_fixed: 3
tokens: 260000
duration_min: 90
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (subagente da sessão principal, sem revisor separado), default reprovado — gate mecânico: famílias task_manager_dispatcher (9), task_manager_executable (11, 8 mutantes), task_manager_capabilities (31), env_exposure; dogfood ao vivo contra o Linear real (issue de teste SAC-109, subtask SAC-110, ambas deixadas em Canceled)
---

# O adapter executável sob o refutador: o `tm.sh` faz o que o tsv agora diz, ou só mudou o carimbo?

Default reprovado. A pergunta da passada: cada `implemented` novo no `linear.capabilities.tsv` tem uma
escrita **relida** por trás, ou foi promovido porque o executável devolveu exit 0?

## Achado 1 — a releitura revelou normalização que o "exit 0" escondia (REAL, declarado no adapter)

O `item.update` saiu rc 0, e a releitura mostrou a descrição **diferente** da enviada: o Linear passa o
texto pelo ProseMirror e auto-linka token com cara de domínio fora de crase (`tm.sh` nu voltou como
um link markdown cujo alvo é `http://tm.sh`). Não é defeito do executável, é comportamento do provedor, e quem comparar o
texto relido com o enviado (um verificador de sincronização, por exemplo) vai acusar diferença falsa.
Registrado na medição do `linear.md`. Sem a releitura, o `implemented` teria saído com a nota "texto
igual" — exatamente o declarado ≠ verificado que a tarefa pedia para evitar.

## Achado 2 — `--limit abc` virava traceback (REAL, curado)

`int()` sem guarda: argumento inválido saía com traceback Python e rc 1 — rc de **erro do provedor**
para um erro de **uso**. Cura: `TmError(..., 2)`. Medido depois: `rc=2` com mensagem pt-BR.

## Achado 3 — resposta em forma inesperada também virava traceback (REAL, curado)

Um `KeyError` numa resposta sem o campo esperado escapava cru. Cura: o `main` captura
`KeyError/TypeError/ValueError` e sai rc 1 nomeando "forma inesperada" — nunca sucesso, nunca traceback.

## Achado 4 — o mutante do dispatcher morde pelo motivo certo? (REAL, verificado)

O mutante que aceita `errors` (cura revertida) não sai rc 0: com `data: null` ele cai em "issue não
encontrada", rc 1. O caso (f) morde porque exige a **mensagem** `GraphQL errors`, não só o rc. Conferi
que a asserção é a mensagem; com uma asserção só de rc o mutante passaria verde e o caso daria licença.

## Achado 5 — a REGRA 104 trata todo `.py/.sh` de `adapters/` como executável de provedor (REAL, DECLARADO)

Um helper solto em `adapters/` sem tsv reprovaria como `executavel-sem-declaracao`. Não há caso hoje
(o `zoho-token.sh` mora um nível acima). Declarado no teto da guarda, com o lugar certo para helper.

## O que fica fora, declarado

- A REGRA 103 continua conferindo a superfície contra a **prosa** (`linear.md` define `getTask(` em
  TypeScript). A REGRA 104 amarra o executável à declaração, não à prosa.
- `comment.list` e `search.query` leem só a 1ª página (`first: 100` / `--limit`); `search.paginate`
  segue `not_implemented`.
- `item.delete` não foi exercitado (arquivar exige confirmação do maestro): segue `unverified` e fora
  do executável.
- Forja/wizard/onboarding de adapter executável novo (outro provider) são as fatias seguintes da SAC-65.

## Rebase sobre o #1034 (2026-10-11, sessão principal)

O conflito no `lint-selftest.sh` eram duas famílias independentes (`run_task_progress_selftests` do #1034 e as deste PR); ficaram as duas. O `linear.capabilities.tsv` fundiu sozinho e mantém `estimate.points_read` e os 12 `implemented`. Famílias `task_manager_capabilities` + `task_manager_executable` + `task_manager_dispatcher` + `task_progress`: 75/75.
