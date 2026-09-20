---
title: 'Resíduo — reincidi na classe que estava curando, e o refutador voltou para dizer'
date: 2026-09-20
branch: fix/trap-by-condition-not-list
reviewed_diff_sha256: 3b81e415a3550a0115e7ac229ba79860a7a481bb5477f10675b69dd59ab6e668
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 168257
duration_min: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Adendo da passada adversarial do #854, sobre a parte que eu MANTIVE e já havia mergeado: a cura da
  trap silenciava por lista de três flags, e havia saídas projetadas fora da lista. Curado pela
  CONDIÇÃO, com caso que impede a cura de virar silêncio.
---

# A cura de ontem reincidiu na classe de ontem

O #854 manteve uma cura: a guarda de abort da bancada gritava *"BANCADA ABORTOU"* em modos de
listagem, sujando o stdout que máquina parseia. Silenciei-a para `--list`, `--map` e `--dry-run`.

**Três flags. Uma lista.** E a classe `guarda-por-lista-falha-pelo-vocabulário` é a que esta casa
mais persegue — eu a cometi **ao curar outra coisa**.

## O que sobreviveu fora da lista

| Invocação | rc | Antes |
|---|---:|---|
| `--help` | 0 | **gritava** |
| `--zzz-desconhecido` | 2 | **gritava** |
| `--report <relativo>` | 2 | **gritava** |

Todas são **saídas projetadas** — o script termina de propósito.

## E o lado inverso, que é pior

A lista silenciava o **modo inteiro**. Um abort **real** dentro de `--map` (com `python3` ausente)
saía com **zero bytes em stdout E em stderr** — a guarda calava justamente onde deveria falar, e o
consumidor (`.githooks/pre-commit`, que lê `--map`) concluía "mapa indisponível" sem uma linha.

> Trocar falso alarme por silêncio total é **pior** que o falso alarme.

## A cura: condição, não enumeração

`SELFTEST_EXPECTED_EXIT` — *"o script chegou a uma saída projetada?"*. Quem sai de propósito marca;
o resto é abort. **Não há lista para envelhecer.**

E descobri no caminho que **duas das três flags que enumerei já eram tratadas** por
`SUMMARY_PRINTED=1` nos próprios pontos de saída. Minha lista era **redundante para duas e
incompleta para o resto** — o retrato da classe.

## Bancada: 17 → 21

- **(r)** as três saídas projetadas **não** disparam o aviso — uma asserção por invocação;
- **(s)** um abort **forçado** (um `false` injetado logo após o `trap`) **ainda grita**. Sem este
  caso, (r) teria a cura trivial de **desligar a guarda**.

## O que o refutador atacou e NÃO derrubou (do relatório principal)

- `exec >&2` na trap **não vaza**: é `EXIT`, subshells não a herdam, workers são processos separados.
- `SELFTEST_LIST/MAP/DRY` **não ficam unbound** sob `set -u` — os três usam `${…:-0}`.
- O parsing do `--map` no pre-commit **não quebrou**: o `awk -F'\t' '$2 == a'` exige casamento exato.
- A limpeza do `--map` é **real e medida**: 337 → 330 linhas, as 7 removidas são exatamente o aviso.

## A lição, e é a mesma do dia inteiro numa dobra a mais

> **Curar uma classe não me imuniza contra ela — nem no mesmo commit.** Eu estava removendo ruído de
> uma guarda e escrevi, no lugar, uma lista de três itens que já nasceu incompleta. O que pega isso
> não é atenção: é o refutador, e foi ele.
