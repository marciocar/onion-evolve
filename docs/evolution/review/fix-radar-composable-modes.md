---
title: "Resíduo da passada adversarial — o Elenxo achou mais defeito na cura do que havia no sinal"
date: 2026-09-07
branch: fix/radar-composable-modes
reviewed_diff_sha256: 75926e64171dd3e8248da7d8cfddd84aff2a79a9c0db8b4564f3026a63c9f55c
findings_total: 15
findings_real: 15
tokens: 172486
duration_min: 54
verdict: REPROVADO-E-CURADO
kg: docs/onion/graph/sinais-de-campo-2026-09.kg.yaml
---

# Resíduo da REGRA 56 — a cura tinha mais defeito que o sinal

Um revisor adversarial (opus, mandato de REFUTAR) atacou a cura do `kg-radar`. Voltou **REPROVADO**
com **4 bloqueios, 3 curas e 4 anotações** — todos por medição própria, **nenhum por gate**.

## O achado que resume a passada

**Curei uma crase-que-executa-comando no `seed-adoption-graph.sh` e, na mesma sessão, cometi a mesma
coisa na mensagem de uso do `kg-radar.sh`.**

```
$ bash .claude/validation/kg-radar.sh /naoexiste.kg.yaml
kg-radar.sh: line 116: --integrity: command not found
uso: ... (modos COMPÕEM:  roda os dois ...)\n       modos: ...
```

Três defeitos numa linha: o shell **executa** `--integrity --schema`; o exemplo **some** (o texto entre
crases é comido); o `\n` sai literal. Cura: literal em aspas simples + `printf`.

## Os outros três bloqueios

**B2 — o mutante sobrevivia 4/4, e a lição é sobre a forma da asserção.** Apagar `exit "${_rc}"`
reintroduz o fail-open: sem ele o fluxo roda os modos **e recai no awk** com `MODE="$2"`, e o veredito
volta a ser o do primeiro modo. Meus quatro casos assertavam `rc` — e **por `rc` o fail-open é
indistinguível do correto**. Escrevi um quinto caso com fixture "1º passa, 2º reprova" e ele **também**
não matou. O que matou foi trocar a asserção por **contagem de saída**: 2 modos = 2 cabeçalhos, nunca 3.

**B3 — a cura não chegava a quem mandou o sinal.** O revisor mediu a distância fonte × projeção:
`437dd680` = 8 linhas (só a reescrita de caminho, o delta legítimo); meu commit = **33**. As 25 linhas
da cura ficaram no core. O marketplace público e os adotantes vendorizados seguiriam com o defeito — e
**o sinal veio de um adotante**. Regenerado; de volta a 8.

**B4 — inflei a medição da própria tese.** Afirmei "97 sítios" três vezes, uma delas num
`verified_against:` de nó `confirmed` com `confidence: 0.95`. O número saiu de *"linha que cita o radar
e tem algum `--`"*. Medido por tipo: **22 ocorrências executáveis em 6 arquivos `.sh`** + 67 em prosa.
Num commit cuja tese é *"afirmação mais forte que a medição"*, a medição da tese estava ~4× inflada.
Corrigido **dentro do nó**, com o erro registrado — não numa nota de rodapé.

## As três curas

| # | achado | cura |
|---|---|---|
| C1 | `--schemaa` (typo) sumia em silêncio e somava `rc=0` | allowlist de modos; desconhecido → `exit 2` |
| C2 | `exit 2` (erro de uso) virava `exit 1` na forma composta, violando o contrato do próprio cabeçalho | rc 2 propagado |
| C3 | aresta `SUPPORTS` entre os dois sinais era **conveniência** para calar a regra de órfão | virou nó de classe que ambos de fato apoiam |

C3 merece nome: *"a lista de versões npm mente"* **não apoia** *"o radar ignorava o segundo modo"* —
são sinais independentes da mesma classe. Aresta de conveniência é **afirmação de relação que a
evidência não sustenta, dentro do SSOT**.

## O vazamento que a REGRA 36 não pega

Escrevi o slug de um adotante **sob NDA** num comentário do `kg-radar.sh` — arquivo **vendorizado**,
materializado no repo público. A **REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)**
protege *nome comercial*, não *slug*; é o ponto cego que o próprio `projection-safety` declara.
Anonimizado, e o grafo (core-privado) passou a usar o id canônico.

## O que o revisor NÃO refutou

Paridade byte-a-byte de modo único: **125 grafos × 14 formas, 1750 comparações, 0 divergências** —
nenhum consumidor TSV muda. `rc` composto correto quando falha o primeiro, o último, o do meio, com
modo repetido e com 13 modos. Recursão infinita **impossível** (a re-invocação passa sempre 2
argumentos). Custo ≈ duas chamadas + ~15%; o "antigo" custava metade porque **fazia metade do
trabalho**. E as três afirmações sobre npm reproduzem verbatim hoje.

## O que fica registrado como classe

**Os defeitos B1, B2, C1 e C2 eram invisíveis à bancada** — nenhum produzia vermelho. A bancada
completa no commit reprovava **só** `plugins_sync`, que era o B3. Guarda mecânica não substitui passada
adversarial; ela pega o que já foi nomeado.

E o correlato de B2, que é o mais transferível: **quando o defeito é fail-open, o `rc` não distingue.**
A asserção precisa medir o *efeito* (quantos cabeçalhos saíram), não o *veredito*.
