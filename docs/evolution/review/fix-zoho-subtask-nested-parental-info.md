---
branch: fix/zoho-subtask-nested-parental-info
reviewed_diff_sha256: 9e53c340f44cb978b65259ad88b4fbe9bc772dff131a8488998522144b3bc264
elenxo: nao
verdict: CORRIGIDO
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 12
nota: "Sem passada adversarial dedicada: o refutador foi a KB DE UM ADOTANTE, mais nova que a nossa. Ela documentava `parental_info.parent_task_id` e derrubou a conclusao que eu havia selado 3h antes (que createSubtask nao tinha caminho). Sondei contra o portal real antes de reescrever: funciona, filha depth 1 e pai has_subtasks true, conferido NO CORPO. Portal devolvido a 1 projeto."
---

# Resíduo — a impossibilidade que eu declarei era só uma forma que não testei

**Quem refutou não foi um agente: foi a KB de um adotante.** Ao preparar a entrega do update, comparei
a KB dele com a nossa e vi que a dele estava **mais nova** (v1.2, com `/api/v3.1/`, `global-statuses`,
escopo `custom_fields.READ`). Nela, uma linha: `parental_info.parent_task_id` cria subtarefa.

Sondei contra o portal real na hora:

```
POST /projects/{p}/tasks  {"name":"FILHA","parental_info":{"parent_task_id":"<pai>"}}   → 201
GET  /projects/{p}/tasks  →  FILHA depth=1  parental_info.parent_task_id=<pai>
                             PAI   depth=0  association_info.has_subtasks=True
```

Vínculo real, **conferido no corpo** — a regra que o próprio adapter manda seguir.

## O erro, e ele é melhor que o endpoint

Esta seção do adapter mudou **duas vezes no mesmo dia**, errando em direções opostas:

1. de manhã afirmou que a **V2 entregava subtask**, com base num `201` que eu não abri — a task
   nascia rasa. A passada adversarial derrubou;
2. à tarde, curando aquilo, afirmei que **não havia caminho nenhum** — porque sondei `parent_task`,
   `parent` e `parent_task_id` **no topo do objeto**, os três 400, e generalizei três formas
   **planas** para uma impossibilidade.

**O arquivo já continha a resposta.** A §1 dele diz, em caixa alta, que *todo vínculo é objeto
aninhado* e que o `*_id` plano é aceito-e-ignorado. Declarei impossível um vínculo tendo escrito,
trinta linhas acima, a regra que o desfaz. Não faltou medição — faltou **aplicar a si a regra que se
acabou de descobrir**.

A cura de mecanismo está no caso (f) da bancada, que agora cobra a **forma aninhada** em vez de
canonizar a conclusão da vez: ele já canonizou a promessa falsa (V2) e depois a impossibilidade falsa.
Guarda que petrifica a conclusão mais recente é pior que guarda nenhuma.

## O que mais mudou

- `getSubtasks` passa a filtrar **no cliente** por `parental_info.parent_task_id`, que é confiável.
- O filtro por `criteria` que o adotante documenta fica como **lacuna declarada**: tentei em
  `POST …/tasks/search` e o endpoint não existe (`URL_RULE_NOT_CONFIGURED`). Lacuna ≠ inexistência —
  a distinção que este arquivo pagou caro para aprender, duas vezes.
- `factory.md`, a KB de plataforma e o `CLAUDE.md` deixaram de dizer "só na V2, com prazo".

## O que isto diz sobre a federação

A absorção de KB de adotante **se pagou no mesmo dia**: o core absorveu a v1.0/1.1 dele de manhã, e à
tarde a v1.2 — que ele evoluiu sozinho — corrigiu o core. O fluxo upstream não é cortesia; é a única
fonte que mede o que o core não mediu. E a recíproca fica no relatório de update: a KB dele **não**
tem as duas correções que eu medi (a inversão do `login_id`, e que o `201` da V2 é task rasa).

## Gate

`lint-artifacts.sh` → **0 HARD / 16 SOFT**, `rc=0` · família `zoho_adapter` **15/15**.
