---
title: 'Resíduo — a porta pública barrou a si mesma, e por isso pode nascer limpa'
date: 2026-09-17
branch: docs/cure-named-private-pointers
reviewed_diff_sha256: 0b552d4bf96ee54b2dbdfce8ffdb3b3a393da8fe07940c465e9ac9803fd38e27
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Entrega de mecanismo nascida de uma medição que mudou o dia: `onion-evolve` estava PÚBLICO
  enquanto a doutrina inteira o declarava privado. Sem refutador externo — o próprio script que
  escrevi reprovou a primeira materialização, que é a forma mais barata de refutação que existe.
---

# A porta barrou a si mesma na primeira execução

## O que mudou o dia

`marciocar/onion-evolve` estava **PÚBLICO** — medido no forge, contra a doutrina que o declara
privado em cinco lugares (`public-face.sh`, `plugin-readme.sh`, REGRA 35, REGRA 79, a skill de
co-evolução). Todo o modelo de segurança do core protegia uma fronteira que não existia.

O maestro fechou o core no mesmo movimento e decidiu a porta: **papel `hub`** (maquinaria completa,
meta-fábrica inclusa) num repo **`onion-core`** que ainda não existe.

## O que o script achou que ninguém veria

**Os baselines das catracas carregam os caminhos que elas toleram.** No bundle cru:

```
kg-verification-baseline.txt   32 linhas · 26 citam docs/discussions/onion-pessoal-marcio/…
kb-vendored-link-baseline.txt  28 linhas ·  7 idem
```

Publicar assim exporia a **topologia dos grafos pessoais** — nomes, quantos são, como se chamam. O
`--stub-baselines` zera (26 → 0), mas é passo **separado** do `--role`: quem monta à mão e esquece
publica, e o `git push` sai `rc=0`.

**E o passo (4), que não confia no (3), achou 18 ponteiros** a documento privado nomeado que o
`--check-bundle` não vê. Um deles: `onion-parecer-rhilo-lineages-2026-07.md` — **nome de cliente no
nome do arquivo**, prestes a viajar numa porta pública.

## A calibração, duas passadas

A primeira redação da guarda acusou skills e hooks por citarem `docs/analysis/` **nu**. Errado, e a
decisão já estava selada: **diretório nu descreve a fronteira** — diz o que *não* viaja, e removê-lo
apagaria a explicação da própria allowlist. São 153 ocorrências e todas ficam. Sai o **documento
nomeado**. E fixture de bancada (`foo.md`, `cliente-sob-nda.md`) não é ponteiro: é dado de teste.

## O que eu errei

**Terceira vez no dia:** rodei a materialização com as curas ainda na árvore de trabalho. O bundle
sai de `git archive HEAD` — árvore suja não conta. Commitei e passou.

## Teto declarado

O script **não publica**. Prepara, verifica e para, dizendo o comando — publicar é outward-facing e
é do maestro (I3). E fecha o *como*, não o *quando*: **porta sem ciclo de re-materialização
envelhece**, que é exatamente o que aconteceu ao `onion-standalone` (parado desde 07-19). O gatilho
proposto é toda leva mergeada em `main` que toque a superfície que viaja — e ele ainda não tem
mecanismo.
