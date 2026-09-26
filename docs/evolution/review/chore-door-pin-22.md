---
title: 'Carimbo do pin da 22ª materialização — e o gatilho que disparou duas vezes'
date: 2026-09-26
branch: chore/door-pin-22
reviewed_diff_sha256: 74056430d0cb6a837c234d1151fdb9eaa971ac830bcfb09b78c9399cd70933e4
elenxo: nao
findings_total: 2
findings_real: 2
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, declarado: o diff é o fecho mecânico de um ato já executado (a porta foi publicada e verificada no remoto) — carimba dois números que a REGRA 85 lê. Não propõe desenho; o desenho que ELE propõe está num nó OPEN, gated na decisão do maestro, que é onde proposta deve ficar. Os 2 achados são meus, pegos por guarda.'
---

# Resíduo — carimbo do pin da 22ª

## O que este diff fecha

A porta foi publicada em `232bba50ccc8` (remoto `5063e81b2d8d`, verificado por `gh api`). O
`onion_version` do registro e as duas linhas de dado do `door-staleness-baseline.txt` são lidos pela
**REGRA 85 (Porta pública espelha o core, com catraca)** para decidir defasagem — e enquanto estavam
atrás, ela acusava 3 commits que já não existiam. Guarda que lê registro defasado não mede a porta:
mede a memória.

## O achado que se provou sozinho, em duas horas

Na 21ª materialização eu avancei este mesmo número à mão e escrevi, **no próprio `members.yaml`**, que
*"número mantido à mão apodrece"*. Apodreceu na materialização seguinte, no mesmo dia. Não é anedota —
é o critério desta casa sendo satisfeito: **o gatilho de mecanizar disparou duas vezes**, então a
proposta parou de ser conselho e virou nó escrito (`Q_QUEM_CARIMBA_O_PIN_DA_PORTA`), com a costura
nomeada e **gated na decisão do maestro sobre construir** — porque construir é dele, o diagnóstico é meu.

Medido junto: `pin-integrity-check.sh . /home/marcio/onion-core` devolve `pin-untrusted unknown`.
**Nenhuma guarda confere este campo contra o que a porta publicou.**

## Dois defeitos meus

| # | o quê | quem pegou |
|---|---|---|
| 1 | escrevi o nó no `fios-abertos`, cujo teto é **catraca que só encolhe** | **REGRA 58 (O backlog cumpre as promessas do próprio `meta:`)**, com `TETO` 20 > 19 |
| 2 | ia redirecionar `--emit-baseline` por cima do baseline | ler a saída antes de gravar: ela tem **2 linhas**, o arquivo tem **184** |

**(1) é a segunda vez hoje.** De manhã aprendi que o fato mora onde nasceu e movi um nó para fora do
`fios-abertos`; à noite repeti. A guarda pegou as duas — e é exatamente por isso que ela existe em vez
de uma nota dizendo "lembre-se do teto".

**(2) é a saída destrutiva PLAUSÍVEL**: o gerador sai `0` e o arquivo fica não-vazio, então as duas
verificações fáceis (`rc` e `[ -s ]`) passariam enquanto ~170 linhas de histórico sumiam. O histórico
é o único lugar onde o **porquê** de cada número mora. A atualização foi cirúrgica e o arquivo segue
com 184 linhas — conferido, não presumido. A restrição ficou escrita no nó, para quem automatizar.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `door-staleness-check.sh` → **rc=0** (a defasagem que a guarda acusava sumiu por carimbo, não por tolerância)
- `kg-radar.sh --integrity --schema` → **exit 0** no grafo tocado
- `members-validate.sh` → **rc=0** (21 membros)
