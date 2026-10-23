---
branch: docs/a2a-allowlist-criterion
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 40
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos"
---

# Passada adversarial: `docs/a2a-allowlist-criterion`

## O que muda

- As allowlists do spike ganham nome legível, com o código do cenário como id estável:
  `allowlists/A7.tsv` → `A7-receptor-so-leitura.tsv` e `allowlists/A8.tsv` → `A8-injecao-chega-como-dado.tsv`
  (`git mv`, conteúdo byte a byte igual). Referências vivas atualizadas: `SPIKE-PROTOCOL.md` e
  `hooks/record-tool-attempts.selftest.sh`; a convenção do hook passa a `allowlists/<cenário>-<descrição>.tsv`.
  Citações históricas (resíduos antigos, proveniência anterior selada no grafo) ficam como estão.
- `allowlists/versions/A7-receptor-so-leitura.v1.tsv`: cópia byte a byte da v1 (commit 700a3170), porque o arquivo
  vivo é a v2 e cada versão do critério precisa de um `ref` que case com o seu hash.
- No grafo do spike, cinco nós: `K_A7_ALLOWLIST_V1` (superseded), `K_A7_ALLOWLIST_V2` (amends a v1, SUPERSEDES),
  `K_A8_ALLOWLIST_V1`, e as medições `E_A7C1_REPLICA_1_SOB_V1` e `E_A7C1_REPLICA_2_SOB_V2` com `x_measured_under`.

## Achados

1. A régua do A7 já tinha DUAS versões, não uma: a linha do ToolSearch entrou pela §12.15 depois da r1. Registrar
   só a v1 faria a r2 citar um critério que não era o dela. Curado com as duas versões, a v2 como emenda datada
   (`registered_at` 02:59:27Z, entre a r1 às 02:39:40Z e a r2 às 03:24:45Z, medido no git log e no jsonl) e o
   `round` por lote, como o protocolo registrou ("o lote do A7-C1 recomeça", §12.15): a r1 é `A7-C1/lote-1`, a r2 é
   `A7-C1/lote-2`.

## Mutantes

- r2 com o `round` da emenda (`A7-C1/lote-1`): o leitor acusa `integrity.measured-post-hoc`.
- sha da v2 com um caractere trocado: o `kg_criterion check` acusa `integrity.criterion-digest`.
- Com o grafo como está: `check` com 3 critérios e 0 achados; leitor sem aviso `integrity.criterion-*`; radar e
  contrato rc 0; selftest do hook e do juiz 78/0; do accept 13/0; lint 0 HARD.

## Limites declarados

- O A8 não tem medição ainda; só o nó do critério. A emenda do ToolSearch no A8 (§12.15) segue pendente.
- Os critérios dos juízes do SAC-151 não foram migrados (decisão: desenho próprio depois).
