---
title: "Revisão — lote 2 do drive: REGRA 63, a onda fecha, e duas regressões minhas"
date: 2026-08-29
branch: drive/open-threads-batch2
reviewer: "medição executada por nó (P3 do /meta:drive) + agente dedicado para a taxa de mortalidade + gates determinísticos; as duas regressões foram achadas pelo próprio gate, não por revisão"
reviewed_diff_sha256: 1b572af618173d4839419c845544e35141d65455b7437cdf2f2039ee0fb95a91
findings_total: 7
findings_real: 7
verdict: APROVADO
tokens: 210000
duration_min: 58
---

# Resíduo — REGRA 56

Três nós conduzidos, uma guarda HARD nova, e **o número que fecha a Onda 1**.

## Os três nós

| nó | veredito | medição |
|---|---|---|
| `D_MECANIZAR_A_PROMESSA_QUE_JA_ESTA_ESCRITA` | **PAGO** | REGRA 63 implementada; bancada 3/3; 2 mutações reprovam |
| `Q_ONDA1_FECHA_COM_DELTA_DE_MORTALIDADE` | **RESPONDIDA** | 9/15 = **60%** vs baseline **33%** |
| `C_DISSENSO_ARQUIVAR_TROCA_PERDA_POR_PASSIVO` | **DRIFTED** (0.8 → 0.6) | 2 das 3 partes caíram, medidas |

## Achados

1. **A mortalidade quase dobrou: 33% → 60%.** 6 entregues · 1 refutado · 1 respondida · 1 obsoleto ·
   **zero não-verificáveis**. A leitura: **a projeção pura não curou o drift** — trocar documento por
   grafo curou a *fonte*, não o drift. O projetor lê `status: open` com fidelidade perfeita e
   republica o cadáver com a mesma fidelidade.

2. **A ressalva veio do medidor, não foi descoberta depois:** sem acesso `sudo` ao bridge e ao
   Postgres, **4 dos 9** teriam sido não-verificáveis e o número cairia para **33%** — empatando a
   baseline **por artefato de acesso**. E a amostra tem viés declarado: 4 dos 15 no `m2-bridge`
   (22% dos itens, o grafo que mais executou).

3. **A atenção não protege contra morte, e é estrutural.** A fórmula não mede idade nem frescor; o
   item de atenção **119.0 — o topo absoluto** — está morto desde o flip P7/P9.

4. **O gated é a metade que funciona:** os 3 itens gated tiveram **zero falso-positivo**. O que
   apodrece é o item que alguém **pagou e não carimbou**.

5. **O drive conduziu a própria objeção do Elenxo, e ela encolheu.** O grafo arquivado **tem**
   projeção humana viva (em dia byte-a-byte) e o frescor **fala** sobre ele. Sobrevive só: fica fora
   da superfície de **decisão**.

6. **Regressão minha nº1** — a REGRA 60 acusou identificador pt-BR (`faltantes`) no próprio lint.

7. **Regressão minha nº2, e é a grave.** Sob `set -euo pipefail`, `git symbolic-ref … | sed` num
   sandbox **sem git** devolve erro pelo `pipefail`, a atribuição morre e o `set -e` **mata o lint
   inteiro** — nenhuma guarda posterior roda. As 40 fixtures diziam *"esperava violação, nenhuma
   apareceu"*: **não havia guarda quebrada, havia lint abortando calado**. `2>/dev/null` esconde o
   stderr, **não o exit code**. É a **mesma classe** que corrigi hoje de manhã no
   `kg-backlog-project.sh` — repetida no mesmo dia, noutro arquivo. A cura ficou comentada na linha,
   com a medição junto.

## Disciplina

- **Nenhum flip sem medição**: os três nós têm comando executado em `verified_against`.
- **A REGRA 63 não legisla o que o Elenxo derrubou**: não obriga arquivar, não proíbe colher.
- **O que o lote criou ficou aberto com gatilho** (`Q_CENSO_EM_VEZ_DE_AMOSTRA`), com o método já
  escrito pelo medidor — inclusive a hipótese barata de `verified_at` como preditor de morte.

## Verificação

`lint-selftest` **878 passaram / 0 falharam / 0 pulados** · `lint-artifacts` **0 HARD** ·
`kg-radar --integrity --schema` exit 0 · **REGRA 58 OK 18/20** · plugins em-sync.

## Teto declarado

O número **60% é de amostra, não de censo**, e o próprio medidor listou três vieses possíveis para
cima e dois para baixo. Ele fecha a onda porque a onda pedia **um número comparável à baseline** —
não porque seja a verdade final. O censo dos 192 está aberto com gatilho, e é ele que devolveria,
além do número, **a lista dos mortos** — isto é, trabalho de fechamento já pronto.
