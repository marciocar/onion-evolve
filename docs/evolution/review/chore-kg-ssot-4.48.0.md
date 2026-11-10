---
branch: chore/kg-ssot-4.48.0
pr: 1572
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 40
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: agente de execução da sessão do core, por comando, sem revisor independente
nota: "tokens 0 = não medido. Vendor do kg-ssot 4.48.0 e o fechamento por medição de Q_PF_AREA_FILTER_KG_QUERY_1120. A passada é do próprio autor (contrato, radar, bancada do produto, diff do vendor contra a tag); nenhum agente separado foi criado, por ordem da tarefa."
---

# Passada: `chore/kg-ssot-4.48.0`

## O que muda

- **Vendor:** `kg-ssot-v4.47.0` → `kg-ssot-v4.48.0` (`197cc059a5c4`), 732 arquivos. São 22 arquivos alterados e nenhum
  novo. Nenhum `spec/*.schema.json` mudou: o contrato segue o v4.19, como o dono disse, conferido no diff.
  A mudança de código está em `tools/kg_mcp.py` (+245) e `tools/kg_query.py` (+105), que trazem o filtro por área
  na leitura (`--area-policy`). `kg_vendor.py check` deu rc 0.
- **Grafo:** `Q_PF_AREA_FILTER_KG_QUERY_1120` fechado como `done` em 2026-11-10, por medição de cada parte do
  «Pronto quando». O `docs/backlog.md` foi regenerado e o item saiu dele.

## Achados

1. **A prova declarada pelo dono ainda não está na `main` dele.** `E_RELEASE_4480_PUBLISHED_1110` e o `done` de
   `Q_AREA_FILTER_READ_SURFACE_1120` estão só no PR #386, aberto, do kg-ssot. O `peer-ref-check` dá rc 1 no
   primeiro, e o segundo segue `open` na `origin/main`. Não foram citados como prova. O fechamento se apoia na
   medição própria: a bancada `AreaFilterTests` da tag rodou 25 testes com rc 0 (as cinco ferramentas e um
   mutante por ferramenta); `E_AREA_FILTER_BENCH_1109` existe na `main` do par (rc 0); `kg_mcp.py` e `kg_query.py`
   do vendor são byte a byte os da tag; a tag está no git e no espelho; o PyPI e o npm latest dão 4.48.0.
   **Atualização (2026-11-10):** o PR #386 entrou na `main` do kg-ssot (merge `e6cdc3d2`). Depois do `git fetch`,
   o `peer-ref-check` dá rc 0 nos dois nós, na `origin/main` @ `653597d8`, e `Q_AREA_FILTER_READ_SURFACE_1120` está
   `done`. Os dois entraram no nó como prova do par, ao lado da medição, e saiu a frase sobre o PR aberto.
2. **Grafo que já reprovava o contrato.** `kg-contract-check.sh` sobre `docs/onion/graph/*.kg.yaml` reprova
   `inference-contract-audit-2026-07.kg.yaml` (nó confirmed sem provenance). A reprovação é a mesma com o vendor
   4.47.0 na `main`, então não vem desta subida. Fica fora do escopo e está registrada aqui.

## Medições

- `kg-contract-check.sh docs/onion/graph/persona-fases-2-3-2026-11.kg.yaml`: rc 0.
- `kg-radar.sh docs/onion/graph/persona-fases-2-3-2026-11.kg.yaml --integrity --schema`: rc 0 (10 nós, 10 arestas).
