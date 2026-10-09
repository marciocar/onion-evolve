---
title: "Revisão — onda O1 da migração de provenance (SAC-73): --routing no kg-migrate-v3 e 2.291 nós A1/A2"
date: 2026-10-09
branch: feat/provenance-wave-o1
reviewer: "passada adversarial com mandato de achar provenance INVENTADA (fonte que não existe ou que é o próprio grafo): varredura mecânica dos 2.291 nós escritos + amostra de 20 com a fonte aberta (gh, curl, leitura do arquivo); bancada kg_migrate_v3 9/9 com LC_ALL=C e 5 mutantes do caso (h)"
reviewed_diff_sha256: 7c5e8e08b6ddb55bd029f7287f8cc392576c74e266112d971442415c40672c9a
reviewed_code_sha256: 73cfdb7facf85b3ffcc633bb972875f7d28f658d2b0d70e157327b4de56bbcc6
findings_total: 3
findings_real: 2
verdict: REPROVADO_E_CURADO
tokens: 0
duration_min: 90
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda O1 do SAC-73. O `kg-migrate-v3.py --routing` escreve provenance só nos ids que o
`routing-v4.tsv` roteia para A1 ou A2, com a classe de method do routing. A aplicação foi feita
aos 138 grafos do corpus do gate (os `--exclude` do CI mais `fixtures/` e `docs/materials/`).

## Achados

1. **REAL, curado: fonte circular.** Na 1ª aplicação, 10 nós escritos tinham como `source` o
   próprio grafo. Abri os 10:
   - 4 são censos (`C_O_DEFEITO_VIVE_ONDE_NAO_HA_TESTE`, `C_GUARDA_QUE_GRITA_ERRADO`,
     `E_CENSO0901_C_trust_matrix_stays_onion`, `E_CENSO0901_C_NS2_PORTABLE`). O registro mostra
     um `grep` sobre outro nó do mesmo arquivo, então o grafo é de fato o que foi lido. Ficam.
   - 6 têm `trace:` apontando o próprio grafo, e a fonte real está noutro lugar: o fan-out da
     rodada, o selo do maestro, uma medição ao vivo no container, uma execução do
     kg-seal-exception. São `E_MERCADO_PLUGIN_MCP_0904`, `D_PLUGIN_MCP_POSTURE_0904`,
     `E_OBJECAO_6_COMPARATIVO_USADO_COMO_LUZ_VERDE`, `E_OBJECAO_8_DUPLICATA_INFLA_CONTAGEM`,
     `E_logto_now_critical_2026_08` e `D_SELO_DO_MAESTRO_REVERTEU_O_FLIP`.

   O classificador os deu como A1 porque o `verified_against` cita outro id. **Cura no
   mecanismo:** no modo routing, trace igual ao próprio grafo vira recusa ("FONTE CIRCULAR",
   intocado, vai para a O3). Bancada (h) e mutante `sem-recusa-circular`. Corpus revertido e
   reaplicado.

2. **REAL, curado: a política 4 selada não era aplicada.** Fonte em caminho do host saía com a
   classe heurística do routing (por exemplo, `juízes:` sobre `/home/marcio/onion-vps-logto/backup.sh`).
   O `D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE` manda "testemunho: leitura do arquivo <x> no host".
   Curado na ferramenta e aplicado a 67 nós. Bancada (h) e mutante `sem-politica-host`.

3. **Não é defeito: 117 fontes não resolvem como arquivo nem URL.** São citações textuais, como
   lei, artigo acadêmico ("Dinur & Nissim (2003), PODS"), página de órgão ou versão de produto.
   É exatamente o que o `trace:` do nó declara, roteado A2 `citacao-texto`; não foi inventado. O
   method declara "não reverificado".

## Amostra adversarial (20 nós escritos, semente 20261009, fonte aberta)

- **8 PRs** (`PR_33`, `PR_45`, `PR_337`, `PR_338`, `PR_340`, `PR_386`, `PR_648`, `PR_654` de
  `pr-decision-history`): título no GitHub idêntico ao label, conferido via `gh pr list`.
- **7 URLs**: todas com HTTP 200 e o termo do label no corpo. São artificialanalysis (Qwen3.5-9B),
  sacra (semgrep), support.claude.com (OAuth), scale.com (Evaluation), arxiv 2502.13595
  (MMTEB), zoho tasks-api (status) e polar.sh (license keys).
- **5 arquivos**:
  - `kg-trace-resolve.sh` l.10-12: os 54 grafos, 1.659 nós e 13 ponteiros mortos que o nó cita
    estão lá.
  - `onion-market-kg-2026-08/SYNTHESIS.md` l.253 afirma `.claude/rules/` com `kg-grammar.md`. É A2
    com `derivado:`, porque a medição foi no filesystem em fb4b672.
  - `fable-5-1/data/int-estrategias.md` e `.claude/commands/meta/kg.md` (seção diagnose) existem
    e falam do nó.
  - `/home/marcio/onion-vps-logto/backup.sh` existe no host, com 20 menções a gpg/passphrase. Agora
    sai como `testemunho:`.

Resultado: **20/20 com a fonte existente e sustentando o nó; 0 inventadas.** Teto: juiz único, o
mesmo autor da ferramenta. O suporte foi checado por termo e por linha, não por releitura
semântica completa.

## Provas mecânicas

- `kg-radar --integrity --schema` deu exit 0 nos 107 grafos tocados e no grafo do contrato.
- `kg-contract-check`: nenhum grafo piorou (MUST e SHOULD da árvore ⊆ HEAD). Deu rc 0 nos 14 que
  saíram da dívida MUST e rc 1 nos 93 que seguem com a dívida herdada, a mesma da HEAD.
- Idempotência: `--check --routing` depois da aplicação deu rc 0.
- `kg_gate.py` com os `--exclude` do CI deu rc 0. O `--update` foi sem `--accept-regression`: a
  base foi de 131 para 115 grafos na dívida MUST, com a dívida SHOULD inalterada.
- Bancada `kg_migrate_v3`: 9/9 com `LC_ALL=C`. Cinco mutantes reprovam o (h): `ignora-routing`,
  `ignora-classe`, `escreve-no-R`, `sem-recusa-circular` e `sem-politica-host`.

## Fora do escopo, de propósito

Ficam para as próximas ondas:

- 671 nós A1/A2 sem `verified_against` (O2);
- 745 do resíduo (O3);
- os 6 circulares;
- 3.460 datas sem aspas;
- flips de status.
