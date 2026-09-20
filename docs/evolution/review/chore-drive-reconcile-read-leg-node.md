---
title: 'Resíduo — a armadilha inversa do pin, e o teto que me barrou com razão'
date: 2026-09-20
branch: chore/drive-reconcile-read-leg-node
reviewed_diff_sha256: 91d628c830f52e736dd1a25c1fc9df9a07228ab6c941b450524ac93e4912ab6a
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 8
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Passada do /meta:drive, não refutador de agentes: a superfície é doutrina num comando, um pin, dois
  números de catraca e o checkpoint. Os dois achados vieram das PRÓPRIAS guardas — o teto do grafo e
  a REGRA 85 — e ambas me barraram com razão. `elenxo: nao` declarado.
---

# Os dois achados vieram das guardas, não de mim

## 1. O teto do grafo me barrou, e estava certo

O censo apontou `A_PERNA_DE_LEITURA_DO_KG_E_CONSELHO` (atenção 9.5) como topo da fila. Medido contra
o vivo, **as três afirmações dele viraram falsas** nesta onda (hooks citando `.kg.yaml`: 0 → **1**;
`review_after` no radar: 0 → **12**; matcher: `Read` → `Read|Edit|Write|Bash`).

Fui apendar o nó medido com `SUPERSEDES` — e o teto de 20 barrou (**21 > 20**).

**O barramento estava certo, e não por aritmética:** meu nó era **duplicação de fato** num grafo cujo
contrato diz, textualmente, que ali mora **compromisso, não fato**. O fato já vivia onde nasceu, em
`passada-adversarial-2026-09` (`E_PERNA_DE_LEITURA_E_CEGA_A_BASH` e
`E_MEDICAO_READ_VS_BASH_NO_CORPUS_DE_TRANSCRICOES`). Revertido.

> A guarda que eu li como obstáculo estava me impedindo de violar o contrato que eu mesmo cito.

**Proposta ao maestro (não executada):** COLHER o nó. É compromisso cumprido, e colher é remoção —
mais que um flip de status, que a tabela de selagem reserva a ele.

## 2. A ARMADILHA INVERSA DO PIN — e ela é nova

Ontem registrei: *materializar sem avançar o pin deixa a guarda medindo contra o passado*. Hoje
apareceu o espelho.

Entre a materialização (commit local `39a19e4`) e o push, houve **~1h de gate vermelho** no core —
`REGRA 85` acusando `onion-core 2 > 0`. A saída óbvia era avançar o pin e destravar.

**Não avancei, e essa é a decisão que vale registrar:** avançar teria feito a catraca dizer **`0/0`
sobre uma porta que ninguém podia abrir**. O pin teria afirmado estado **publicado** que não existia.

> **As duas mentem; a diferença é a direção.** Pin velho esconde porta nova; pin novo inventa porta
> publicada. A regra que fecha as duas: **o pin só anda depois do push VERIFICADO NO REMOTO**
> (`gh api .../commits/main`), nunca depois do commit local.

Escrito no `door-staleness-baseline.txt`, que é onde a próxima materialização vai ler.

## Avançado na passada

`A_ANUNCIO_DERIVA_O_NUMERO_DA_MEDICAO` — `/meta:co-announce` ganhou a doutrina de **derivação** no
Passo 4 (onde o rascunho é escrito): número sobre estado verificável sai da **medição**, não da prosa;
sem número disponível, escreve-se **"não medido"**; e anúncio e relatório da mesma leva **não podem
discordar** sobre uma contagem que ambos citam.

**O que NÃO foi feito, declarado:** a guarda mecânica que prende isso. A cura é doutrina no comando
que gera — depende de quem gera seguir. Mecanizar exige detectar "afirmação numérica sobre estado do
alvo" em markdown livre, e desenhar isso às pressas no fim de uma sessão longa é o anti-padrão que
esta casa nomeia. **Gatilho: o próximo anúncio sair com número que o artefato de medição contradiz.**

## Estado do checkpoint

`.claude/sessions/drive-2026-09-19/STATE.md` — **pendente do selo do maestro** (a colheita do topo).
Realign: **ALINHADO** `(c)=0 (b)=0 (a)=0`.
