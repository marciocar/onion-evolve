---
title: 'Resíduo — a rodada de primárias sobre distribuir o método vivo'
date: 2026-09-13
branch: research/living-method-distribution
reviewed_diff_sha256: 3e34ba9c9d48ba8b767a4cf483e889aad46d979be902dd89871826c930567bf2
findings_total: 26
findings_real: 24
findings_fixed: 3
tokens: 1355653
duration_min: 19
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Rodada de primárias com Elenxo próprio (26 objeções, 24 sobreviventes) que mediu o ARTEFATO local além das
  fontes — e foi ali que ela pagou: derrubou três premissas com as quais eu ia desenhar o veículo. As
  objeções sobreviventes NÃO são para curar neste PR: viram as cinco perguntas abertas do grafo, porque a
  decisão é do maestro. O que curei foram as três premissas falsas, que eram minhas.
---

# A rodada derrubou as premissas antes de eu desenhar em cima delas

O maestro decidiu entregar a clientes de consultoria uma versão pública do Onion para **forkar**. A pergunta
que sobrou foi a fronteira: o gerador precisa levar **doutrina sem levar a vida** deste repo.

## O que a rodada PROVOU (26 claims ancoradas, 7 fontes primárias)

1. **Veículo e canal de atualização são uma escolha só.** Template nasce com histórias não relacionadas —
   sem PR nem merge de volta. Fork mantém o vínculo upstream. Escolher template é contrair a dívida de um
   segundo mecanismo de update.
2. **Gerar por filtro, nunca copiar e apagar.** O precedente externo é separação **física** no tronco, com o
   espelho aberto publicado a partir dali.
3. **Colisão de update vai ao humano**, sempre. Duas ferramentas independentes convergem nisso.
4. **O que viaja tem de rodar** — e esse piso já foi violado aqui uma vez, medido.
5. **Licença não protege nome.** Apache §6 apenas **não concede** marca; quem protege é a marca.

## As três premissas falsas, e duas eram minhas

- **A licença já está concedida.** `LICENSE` do repo e dos 5 plugins publicados é **MIT** — o cliente pode
  revender o framework, que é exatamente o limite que a pergunta queria. MIT publicado não retroage.
- **Eu citei um precedente que não existe.** Afirmei que o `onion-standalone` nasceu por `--role standalone`;
  o `adopt` vivo aceita `adopted` e `hub`. Repassei o corpus **sem conferir contra o código** — a classe que
  esta casa persegue, cometida ao responder sobre ela.
- **Não há filtro nenhum.** `.claude/diary` tem 127 arquivos **dentro** do que o `/meta:adopt` vendoriza, e
  `grep -c exclude` no `adopt.md` dá zero.

## O gate que o Elenxo impôs, e que eu aceito

**Allowlist executável — o que COPIA —, nunca denylist.** Guarda por lista falha pelo vocabulário, e denylist
falha **aberta**: arquivo novo de biografia entra no pacote por padrão.

E a ordem de trabalho que ele impôs, contra a minha vontade de já desenhar o veículo: **medir primeiro o
mecanismo próprio** (`/meta:adopt --update`, `vendor-branch.sh`), que nenhuma claim tocou e que a memória já
registra como papel-cego.

## O que NÃO foi curado, por desenho

As 24 objeções sobreviventes viram **cinco perguntas abertas** no grafo — fronteira executável, licença
depois do MIT, titularidade da marca, veículo + canal, e a pergunta-raiz. **Nada foi selado.** Curar aqui
seria decidir no lugar do maestro.

## Gate

```
radar --integrity --schema : exit 0 (35 nós · 66 arestas)
kg-provenance-coverage     : 0 HARD
backlog · painel           : regenerados
```
