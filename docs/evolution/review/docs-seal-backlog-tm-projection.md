---
branch: docs/seal-backlog-tm-projection
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 6edf16b9fbaf0a81e4ef17493ecb56a81399d36dd8dff8494e0d8e15123ff412
reviewed_code_sha256: 89cb0bce22f3ef499f21e40416bfabe11931d3b048f8c4ab07ffb65e659e024b
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 8
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: passada adversarial manual da sessão sobre os quatro nós novos; sem subagentes
nota: ""
---

# Passada adversarial: `docs/seal-backlog-tm-projection`

## O que muda

Quatro decisões do `/meta:decide` de 2026-10-20 entram no `rito-task-manager-2026-09`, pelo selador, todas com
TRACES_TO para `D_UMA_TASK_POR_FIO`: `D_TM_PROJECAO_OPT_IN_POR_X_TM_ITEM`, `D_TM_BACKFILL_TRIAGEM_COM_RESIDUO`,
`D_TM_DRIFT_NO_BACKLOG_TM_E_NO_DECIDE` e `D_TM_UM_ESCRITOR_A_PROJECAO`.

## Achados

1. **Refutado:** "o campo `x_tm_item` é invenção nova?" Não é. O `drive-automate.sh` já o lê (l.475–593, segundo
   a medição), então a decisão reusa o vocabulário existente, em vez de criar um `x_issue`.

## Mutantes

Nenhum: não há código. O gate é o selador (radar `--integrity --schema` e contrato em rc 0).

## Limites declarados

- Três pontos da medição NÃO foram perguntados porque derivam de doutrina, e por isso não viram selo de testemunho:
  - o time Linear multi-repo: o core julga só os próprios projetos (I3, um escritor por repo);
  - o plan.md e o ciclo engineer: ficam como superfície de adotante, porque o core não os usa desde julho;
  - o gate do `Q_COMPROMISSO_ESPERA_COLHEITA`: colher um fio de fios-abertos para abrir vaga.
  A execução os aplica e os declara.
- A implementação (o modo `--tm` e a projeção) é trabalho seguinte, não este PR.
