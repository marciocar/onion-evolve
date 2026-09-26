---
title: 'Fecho dos sinais tratados e re-teste da migalha vencida'
date: 2026-09-26
branch: chore/close-inbox-and-sge-state
reviewed_diff_sha256: c92550fbdc6940b2355b0c5aae6e15afeddcf5a5632b52d5ef3011c902e7c303
elenxo: nao
findings_total: 3
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, declarado: o diff move dois arquivos já tratados para  e acrescenta um re-teste MEDIDO a uma migalha. Não introduz mecanismo nem propõe desenho — um refutador não teria artefato novo para atacar. Os 3 achados são meus, dois pegos por guarda e um por medição.'
---

# Resíduo — fecho dos sinais e re-teste da migalha

## O que o `/catch-up` achou, e o que cada item rendeu

**(1) Dois sinais de adotantes parados no 1º nível do `inbox/`.** Ambos curados e mergeados em
2026-09-25 — o `kg-corpus-grep` absorvendo `label:` de aresta (do `sge`) e a prosa de co-evolução
cega ao papel `hub`. Ninguém os moveu, então o hook os contaria para sempre e o "lido/não-lido"
git-visível mentia. **Mover É o registro**, e untracked morre num `git clean`.

**(2) A migalha de 2026-07-18, RE-TESTADA por execução.** A doutrina é re-testar, nunca re-carimbar, e
o re-teste virou achado: **o ITEM2 está feito e DISPARA** — provado com fixture de um `decision` sem
`trace:` e sem `TRACES_TO`, e a saída do radar é exatamente o escopo que a própria migalha
especificou (advisory, aditivo, não-HARD). O S4 também está feito. E o re-teste produziu uma
**re-leitura**: a Trilha-no-KG e os C-gated **não são "retomar fresco"** — são esperas com gatilho, e a
redação antiga convidava a próxima sessão a puxá-los sem o gatilho ter disparado. Validade nova:
2026-12-26, e ela vale **porque houve medição**.

**(3) A sessão `adopt-sge` mentia sobre o estado.** O `STATE.md` parou em
`NEXT: Fase 2 — instalar o framework`, e o `/catch-up` o leu como **próximo passo autoritativo** — mas
o alvo está adotado desde 2026-09-24 e hoje roda PRs próprios (#19, #20) com lint 0 HARD. Quem seguisse
o ponteiro re-instalaria o framework por cima de um alvo vivo. Arquivada com README de encerramento
(local — `.claude/sessions/` é gitignored, então não aparece neste diff).

## Os três defeitos meus

| # | o quê | quem pegou |
|---|---|---|
| 1 | citei um caminho **inexistente em crase**, justamente para dizer que não existe | a guarda de ponteiro morto: caminho em crase **é** afirmação de que resolve |
| 2 | concluí "o relatório nunca chegou ao SGE" listando só `inbound/*.md` de 1º nível | ir olhar `_processed/`, que é **exatamente** onde mensagem tratada mora |
| 3 | li `127` depois de pipe, duas vezes | o hook anti-fail-open do shell |

**(2) é o mais instrutivo**, porque eu quase transformei **sucesso em achado**: o SGE tinha feito o
dever de casa nos dois sentidos do doc-bridge — recebeu e processou o relatório de adoção, e relayou um
sinal de volta que o core curou. Medir o lugar errado não produz "não sei"; produz uma conclusão
confiante e falsa.

**(1) tem uma ironia que vale guardar:** a guarda não distingue "cito o caminho porque ele existe" de
"cito o caminho para dizer que não existe" — e está **certa** em não distinguir, porque a segunda
intenção não é verificável. A cura é escrever a ausência em prosa, não em crase.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **45 casos · 0 falhas**
- `inbox/` de 1º nível → **0 arquivos** (o hook para de contar, e o registro é durável por commit)
