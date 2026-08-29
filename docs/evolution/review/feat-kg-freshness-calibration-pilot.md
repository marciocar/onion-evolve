---
title: "Revisão — o piloto calibrado: o juiz tem taxa, e ela é 20% de FP na acusação"
date: 2026-08-29
branch: feat/kg-freshness-calibration-pilot
reviewer: "o próprio desenho do piloto é a revisão em três camadas independentes: padrão-ouro humano carimbado ANTES do fan-out (sha c975fce6) × 16 workers sonnet/medium × 7 juízes opus/high; divergências resolvidas contra o ouro, e o ouro exposto a contra-prova (1 acusação do juiz rejeitada CONTRA o juiz, nenhuma contra o ouro sustentada)"
reviewed_diff_sha256: 5ff273629c5bdbdebfef28d4b2586aa2fea3ba6611390ec51a03432861a22466
findings_total: 7
findings_real: 7
verdict: APROVADO
tokens: 1618208
duration_min: 13
---

# Resíduo — REGRA 56

Plano aprovado pelo maestro executado ponta a ponta: F0 (ouro) → F1 (16 workers) → F2 (7 juízes)
→ F3 (tabela) → F4 (write(KG)). **Primeiro run real do schema curado do #714 — e ele mediu o
lado da barragem que faltava.**

## A tabela de calibração (o entregável)

| nó | worker | juiz | **OURO** | juiz vs ouro |
|---|---|---|---|---|
| C_LACUNA_E_COBERTURA | 2 | 4 | **2** | SOBRE (a FP) |
| D_MEDIR_O_DONO_NAO_O_CARIMBO | 3 | 10 | **6** | SOBRE |
| EN_REPO | 2 | 2 | **2** | EXATO |
| EN_MAESTRO | 2 | 2 | **2** | EXATO |
| REC_A2A_RECEIVER_GATE_BUILT | 4 | 7 | **7** | EXATO |
| C_TRES_MODELOS_DE_CONFIANCA | 3 | 11 | **7** | SOBRE |
| Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA | 3 | 8 | **8** | EXATO |

**Somas: worker 19 · juiz 44 · ouro 34.**

## Os números que destravam B

- **Subcontagem dos workers fora do m2: 44%** (m2 era ~48%) — o fenômeno é geral, não do grafo.
- **Juiz vs ouro: EXATO 4/7, SOBRE 3/7, SUB 0/7** — o juiz nunca erra na direção que importa.
- **FP do juiz na acusação de subcontagem: 1/5 = 20%** (C_LACUNA — única acusação que o ouro rejeita).
- **"Sempre reprova" refutado**: 1/7 APROVADO, e é o `REFUTED` do EN_MAESTRO.
- **O achado ouro-independente**: o worker do EN_REPO apresentou um `ls` **curado** (10 de 14
  itens) como saída de comando — o juiz pegou **re-rodando**. Nem schema nem fan-in veriam isso.

## A barragem, medida em produção

O descarte do REC2 (5/5 rejeições, `must have required property 'blocked_by'`) fecha a objeção A1
do Elenxo pelos dois lados. Causa-raiz: **comentário meu** ("blocked_by: SÓ em UNVERIFIABLE")
induzindo a omissão — corrigido neste PR ("SEMPRE PRESENTE: '' quando nada bloqueou").

## O que NÃO foi feito (por desenho)

- **Zero carimbos nos 4 grafos-alvo** — os `proposed_write` (incl. o REFUTED do EN_MAESTRO e os 2
  DRIFTED) aguardam o selo do maestro.
- **B e C não foram decididos** — o piloto entrega o número; a decisão é do maestro.

## Gate mecânico

- radar `--integrity --schema` → **exit 0** (31 nós, 34 arestas)
- `kg-reverify-schema-check.sh` → rc=0 (comentário curado não toca a estrutura)
- `docs/backlog.md` regenerado — REGRA 62 em dia
- ouro íntegro: `sha256sum -c` → **OK**, e o arquivo agora viaja no repo
