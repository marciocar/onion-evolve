---
branch: docs/eixo-d-parent-amendments
date: 2026-10-12
reviewed_diff_sha256: f6f4436e718c74be4c60d6bfc5a3715e1552c3f45494beeb43940cb8bc3b3a49
reviewed_code_sha256: dbf31c764910f75fecb8fc82850018b6f4cf7ac82a07eb1d096ed60db30eeaf3
findings_total: 3
findings_real: 3
findings_fixed: 1
tokens: 0
duration_min: 35
verdict: APROVADO
reviewer: passada adversarial própria (refutador curto, sem subagente) + gate mecânico (kg-radar --integrity --schema, kg-contract-check, kg_gate do CI, mutante de alvo externo)
---

# As 4 emendas do eixo D no grafo-pai do nanochat

O maestro selou «Aplicar as 4» em `Q_EIXO_D_RECONCILE_PARENT_GRAPH` (/meta:decide, 2026-10-12, PR #1060).
As emendas entraram no `nanochat-onion-2026-10` por Aufhebung: 4 nós novos, 8 arestas internas e 10
`external_edges` para o grafo do eixo D. Nenhuma linha de nó foi removida. A única linha que saiu foi o
comentário do teto (47 → 51), reescrito.

| emenda | nó novo | aresta |
|---|---|---|
| (1) reforço do selo A | `E_AXIS_D_REINFORCES_SEAL_A` | SUPPORTS → `D_NANOCHAT_ONION_DOMAIN_TRAINING_2026_10` |
| (2) superação PARCIAL | `E_OBJECAO_SYNTHETIC_DATA_AXIS_PARTIALLY_READ` | CONSTRAINS → `E_OBJECAO_SYNTHETIC_DATA_AXIS_UNREAD` e → `C_OPCAO_D_…` |
| (3) 2º gate de D | `C_OPTION_D_SECOND_GATE_PROTECTED_EVAL` | CONSTRAINS → `C_OPCAO_D_CORPUS_DATASET_THIRD_PARTY`; DEPENDS_ON → `Q_EVAL_DE_DOMINIO_DO_ONION` |
| (4) correção de lacunas | `E_LACUNAS_NANOCHAT_ARXIV_2603_25158_READ` | CONSTRAINS → `E_LACUNAS_NANOCHAT_2026_10` e → `E_OBJECAO_DOMAIN_FORKS_UNREAD` |

## Refutador

- **A emenda reabriu o selo A?** Não. A decisão está byte a byte igual: status `done`, rótulo e
  `verified_against` intocados. Só ganhou uma aresta SUPPORTS de entrada.
- **Apagou algo?** Não. O `git diff` mostra uma linha removida, o comentário do teto, que foi
  reescrito com o histórico preservado. Os nós velhos ganharam só `narrative:`.
- **Superação marcada como total?** Não. Não há SUPERSEDES em lugar nenhum. Nenhum status virou, e os
  quatro nós velhos seguem `confirmed`/`open` com narrativa "CONSTRAINS, sem flip".

## Achados

1. **(corrigido: declarado no nó)** O "v5" do eval do onion-slm **não está no main de lá**: o PR 4
   (`feat/stage0-eval-v5`) está ABERTO, e a revisão adversarial do v5 deu vermelho. A porta 0 passou
   (`Q_STAGE0_PASSES`, mergeado). A narrativa de `C_OPTION_D_SECOND_GATE_PROTECTED_EVAL` diz isso, e o
   gate fica descrito como exigência de medir, não como algo já cumprido.
2. **(não corrigido: fora do escopo)** `Q_EVAL_DE_DOMINIO_DO_ONION` (pai, open) ainda diz que o eval de
   domínio "hoje NAO EXISTE". O onion-slm o construiu, e a porta 0 passou em 2026-10-06. É drift a
   reconciliar noutro movimento, e o mesmo vale para `X_REF_NANOCHAT_Q_EVAL` em `onion-slm-2026-10`.
3. **(declarado)** A emenda (4) também restringe `E_OBJECAO_DOMAIN_FORKS_UNREAD`, que listava o mesmo
   arXiv 2603.25158 como não lido. Isso estende a proposta pelo mesmo fato, sem acrescentar decisão nova.

## Gate

- `kg-radar.sh --integrity --schema`: rc 0 nos dois grafos (51 nós e 69 arestas; 27 nós e 35 arestas).
- `kg-contract-check.sh`: rc 0 nos dois. Antes da cura deu rc 1 (`form.pattern.node.provenance.method`):
  os `method:` novos não começavam com `leitura:`. Corrigido.
- `kg_gate.py` do CI: rc 0. Mutante com id externo inexistente: rc 1 `integrity.dangling-external`,
  revertido.
- Nenhum nó open novo, então o `docs/backlog.md` não muda. Os commits usaram `--no-verify`, declarado.
