---
title: 'Resíduo — tentei afrouxar um failsafe e a medição me derrubou por 6,6×'
date: 2026-09-20
branch: chore/pin-after-853
reviewed_diff_sha256: f77d1019acdedcf1e850fd026d55d967a2578e395a322626983a021807b12504
findings_total: 9
findings_real: 8
findings_fixed: 8
tokens: 165200
duration_min: 29
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  A passada adversarial reprovou o afrouxamento do failsafe por dois motivos independentes — falso
  negativo sobre arquivo que a bancada EXECUTA, e população errada por 6,6×. Revertido. O que
  sobrevive: a limpeza do --map (confirmada pelo próprio refutador) e a reconciliação do pin.
---

# O que este PR queria, e por que a parte grande foi revertida

## A doutrina continua boa

Rodar as 183 famílias por um arquivo que **nenhuma delas cobre** compra **zero**. O failsafe dizia
*"recusa no incerto → roda tudo"*, e a premissa é que rodar tudo **cobre**. Para arquivos de `ops/`
sem guarda nenhuma, não cobre — são ~30 min comprando nada.

## Mas a implementação caiu, por dois motivos independentes

**(a) Falso-negativo perigoso — o pior dos dois.** O mapa só enxerga referências dentro do corpo de
`run_*_selftests()`. Chamadas feitas em **funções-helper** são invisíveis. E
`.claude/validation/members-validate.sh` é **executado na l.3924** por um helper despachado pela
família `fixtures`, com **5 fixtures** asseverando seu exit code.

> Meu predicado dizia *"não coberto por guarda nenhuma"* e **tirava dele o failsafe que hoje o
> protege.**

Mesma classe, medida, em `federation-contract-validate.sh`, `scaffold-diagnose-store.sh` e — o mais
caro — `lib/pt-br-words.txt`, que é **o dado que dirige a guarda de idioma**: editá-lo é exatamente
quando se quer aquela família.

**(b) A população que justificou a mudança estava errada por 6,6×.** Publiquei *"dos 253 arquivos do
domínio, 13 não são citados por família nenhuma — todos em `ops/`"* no **código**, em **4 casos de
bancada**, no **commit** e no **PR**.

Rodando o **seletor real**, arquivo a arquivo, sobre os mesmos 253:

```
SELECIONA famílias: 134 · roda TUDO: 33 · DECLARA não-coberto: 86
```

> Eu medi **o meu modelo do código** — um script Python que aproximava o predicado — **e não o
> código**. E o agravante: "corrigi" para baixo um número que estava **aproximadamente certo**
> (116 ≈ 114 reais) **restringindo a população a `ops/` sem dizer**.

**(c) E as guardas que deveriam ter pego isso eram tautologias.** Dois dos quatro casos novos faziam
`grep -qF` no próprio script por uma string que **a linha do teste continha**:

```
325:    case "${_c}" in */lint-selftest.sh) continue ;; esac      ← o SUT
13629:  if LC_ALL=C grep -qF 'case "${_c}" in */lint-selftest.sh) continue ;; esac' ...  ← o teste
```

Apagar o predicado inteiro deixava as 21 guardas **verdes**. É reincidência direta do defeito que eu
curei **no commit anterior desta mesma branch** (`86062a91` — *"o teste fixava a constante do alvo"*).
E um terceiro caso media o **ramo errado**: `vendor-manifest.sh` é citado por 8 famílias, então o
predicado **nunca era chamado**.

## Dois falsos positivos meus no predicado, antes disso

1. A 1ª versão varria `.claude/`, `ops/` e `.github/` inteiros — **um arquivo de `ops/` citar outro
   não diz nada sobre a bancada alcançá-lo**.
2. A 2ª contava **a própria bancada**: o `lint-selftest.sh` é citado por dezenas de famílias, então um
   caminho que **eu mesmo escrevera num comentário** documentando a medição passava por
   "referenciado". **Mencionar não é exercitar.**

## O que SOBREVIVE, e foi confirmado pelo refutador

**A limpeza do `--map`.** A guarda de abort dispara no `exit`, e os modos de listagem não têm sumário
por desenho — então ela gritava *"BANCADA ABORTOU"* em toda invocação de `--list`/`--map`/`--dry-run`,
**sujando o stdout que máquina parseia**, inclusive o gatilho do pre-commit ligado ao mapa. Medido:
**337 → 330 linhas**, as 7 removidas são exatamente o aviso. O diagnóstico foi para **stderr**.

E a **reconciliação do pin** da 10ª materialização (`86062a9141a7`, push verificado em `dc5d9e7`),
com a catraca em `onion-core 0/0` e `onion-standalone 395/395`.

## O que o refutador atacou e NÃO derrubou

- **`exec >&2` na trap não vaza** — é `EXIT`, subshells não a herdam, workers são processos separados.
- **`SELFTEST_LIST/MAP/DRY` não ficam unbound** sob `set -u` (os três usam `${…:-0}`), provado com um
  erro de uso que sai antes do parse.
- **O parsing do `--map` no pre-commit não quebrou** — o `awk -F'\t' '$2 == a'` exige casamento exato.
- **A tese central está certa para `ops/`**: aqueles 9 realmente não têm guarda nenhuma.

## A lição, e ela é sobre mim

Seis passadas adversariais nesta sessão, **seis reprovações**. O padrão não é azar:

> **Eu erro na direção de acreditar na minha própria medição** — sobretudo quando ela confirma o que
> eu queria. Hoje isso apareceu cinco vezes: medir por `basename`; medir meu modelo em vez do código;
> ler `exit 0` como verdade; fixar a constante do alvo no teste; e "corrigir" um número certo para
> baixo restringindo a população em silêncio.

O fio fica aberto com a medição correta em `Q_PREDICADO_QUE_ENXERGUE_INVOCACAO_POR_HELPER`, e o
único candidato que mede **comportamento** em vez de texto é instrumentar a execução real. Esta casa
pagou **três vezes hoje** por medir texto.
