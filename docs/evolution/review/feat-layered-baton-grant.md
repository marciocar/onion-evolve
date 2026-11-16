---
branch: feat/layered-baton-grant
pr: pendente
reviewed_diff_sha256: 47499d295c9934d2942a17ce5b6dea152e6d8f9378c1e86034df1f4c6d1e39d9
reviewed_code_sha256: 24444be800a86d23fce9d8e527e8ec091aaef105bb4da622576db914d7cf6cfb
date: 2026-11-16
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "Build do #7 (mecanismo da batuta-em-camadas), decisão do maestro 2026-11-16 («Construir o #7 primeiro», por pergunta com opções). Dogfood determinístico: lint-selftest.sh --families baton_pulse = 82 passaram, 0 falharam, com os dois casos novos (ba) «concedida em grants.tsv aparece, não-concedida não» e (bb) «grants.tsv ilegível é lacuna fail-closed» e seus mutantes (MUT) PEGOS. Grafo forge-baton: kg-radar rc 0 (13 nós, 13 arestas, sem contradição) e kg-contract-check rc 0. Pulso dogfoodado contra o estado REAL: curadoria e kg-ssot aparecem com «batuta-de-projeto: sim (interno, por core)». Nenhuma lógica de gate/hook tocada: o baton-pulse.sh é o MEDIDOR (aviso, nunca bloqueio) e só ganhou a leitura de grants.tsv (irmão de owners/parked) + anotação + contagem; a guarda tocada é só a BANCADA (lint-selftest.sh, casos novos)."
nota: "O que muda: o pulso da batuta passa a LER grants.tsv (estado declarado pelo core por ordem do maestro) e a REPORTAR a batuta-de-projeto de cada sessão — nível 0 intacto (lê e reporta, nunca concede nem despacha; despachar segue degrau 3). Fail-closed quando grants.tsv é ilegível (DESCONHECIDA, não «nenhuma»). Grafo: +2 nós da colheita da fase 2 (D_LAYERED_BATON_GRANT_1116 selo do maestro + C_LAYERED_BATON_GRANT_BUILT_1116 o build com bancada), dentro do teto 14 (agora 13). Doutrina: cláusula 8 da baton-doctrine. GUARDA → merge do maestro (toca lint-selftest.sh)."
---

# Build #7: a batuta-em-camadas (concessão de batuta-de-projeto)

## O que muda

`baton-pulse.sh` passa a ler **`grants.tsv`** do estado da batuta — a concessão de **batuta-de-projeto** que o core faz a cada sessão-dona por delegação do maestro — como **estado declarado**, irmão de `owners.tsv` e `parked.tsv`:

- lê com o mesmo `read_tsv` (ILEGÍVEL não é ausente: fail-closed, a batuta fica DESCONHECIDA, nunca «nenhuma»);
- `grant_of(s, labels)` casa a chave da linha contra o id, o nome, a pasta e os rótulos da sessão;
- cada linha de sessão (no `--tsv` e no markdown) ganha `· batuta-de-projeto: sim|não (camada, por quem)`;
- o cabeçalho conta `batutas-de-projeto: N concedida(s) · M ACTIVE (tocando o próprio fio)`.

**Nível 0 intacto:** o pulso LÊ e REPORTA a concessão; **nunca a escreve** (conceder é ato do core por ordem do maestro) nem despacha (despachar segue degrau 3). É a peça que **dissolve o gargalo** da orquestração hub-e-raio — cada sessão rege o seu fio em paralelo, o core roteia dependências e escala só o MOAT em lote.

## Achados

Nenhum. Build com dogfood determinístico: bancada 82/82 com os dois casos novos e seus mutantes pegos; radar e contrato rc 0 no grafo; pulso rodado contra o estado real. Decisão selada pelo maestro (D_LAYERED_BATON_GRANT_1116).

## Limites declarados

- O pulso lê `grants.tsv` (estado declarado); não concede, não despacha, não acorda sessão.
- A **oferta** medida (horas ociosas com fila antes/depois) segue sendo a **fase 2**, não entregue aqui.
- `grants.tsv` ainda não alimenta o sha de mudança do `--quiet` (uma concessão nova não faz o pulso «falar» sozinho): lacuna declarada, de baixo impacto (o core sabe quando concede), para a fase 2.
