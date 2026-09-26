---
title: 'O carimbo lia a ÁRVORE — e o dogfood o pegou na primeira execução'
date: 2026-09-26
branch: fix/door-seal-pin-reads-committed
reviewed_diff_sha256: 63adad19eb2ae5f1749ef75896b7720ffbdbd05439ec099e61ee57727981c467
elenxo: nao
findings_total: 4
findings_real: 4
verdict: REPROVADO_E_CURADO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e a ausência é declarada porque quem REPROVOU foi o DOGFOOD: o mecanismo construído horas antes falhou na primeira execução real, do jeito exato que ele existe para impedir. Nenhum refutador foi acionado — não por economia, mas porque o artefato de verdade já tinha dado o veredito, e ele é a autoridade mais alta desta casa. Os 4 achados são meus.'
---

# Resíduo — o carimbo lia a árvore

## O veredito veio do artefato, não de um revisor

Construí o `ops/door-seal-pin.sh` para impedir **uma** coisa: carimbar no registro um pin que não está
publicado. Na primeira vez que o rodei de verdade, ele **carimbou antes do push**.

A causa é de **leitura**, não de lógica, e é isso que a torna instrutiva. A v1 lia o pin do stamp na
**árvore de trabalho** — já materializada — e comparava `HEAD` do clone com o remoto. Mas `HEAD` ainda
era o commit antigo, **igual ao remoto**, porque a materialização não estava commitada. As duas
conferências passavam com honestidade formal e o resultado era falso.

Medido no momento:

| onde | pin |
|---|---|
| stamp da **árvore** | `526c00800359` |
| stamp **commitado** | `232bba50ccc8` |
| árvore | **6 arquivos sujos** |

## O que torna este achado pior do que o defeito

**O caso de bancada que devia pegá-lo testava um mundo que não acontece.** O `(c)` esboçava um remoto
**diferente** do clone — e o fluxo real nunca produz isso: no fluxo real o remoto está *igual* ao clone
e o que está adiantado é o **disco**. Eu tinha nove casos verdes e zero cobertura do único cenário que
importava. É a lição do mutante ancorado no lugar errado, aplicada a um caso inteiro.

## A cura, com duas guardas porque uma não fecha

1. **árvore suja ⇒ recusa** — materialização no disco não é publicação;
2. **o pin vem de `git show HEAD:`** — o pin passa a vir do **mesmo objeto git que o remoto contém**, e
   um stamp editado à mão no disco deixa de enganar.

Casos `(j)` e `(k)`, com **mutante provado**: contra a versão defeituosa o `(j)` sai `rc=0` — carimbou.

**Primeiro uso legítimo, depois da cura:** as quatro provas passaram (pin legível · commit deste core ·
ancestral de `origin/main` · push conferido, remoto `b18e40d09f49` == clone) e o carimbo saiu,
`232bba50ccc8 → 526c00800359`. O `door-staleness-check` passou a dizer `onion-core ok 0/0`.

## Os outros três, todos armadilhas conhecidas desta casa

| # | o quê | como apareceu |
|---|---|---|
| 2 | helper chamado por **nome imaginado** (`_door_stamp` em vez de `_doorway_stamp`) | `command not found` — efeito colateral de um rename em lote que atingiu substring |
| 3 | `git commit` sem `\|\| true` **matando a suíte sob `set -e`** | o aviso do próprio harness; **terceira vez nesta leva** |
| 4 | o caso `(i)` passou a medir a **guarda nova** em vez do defeito dele | o ✗ apontava para "árvore suja", não para "pin ilegível" |

**(3) virou cura no helper, não em cada caso** — três ocorrências no mesmo dia são o critério para
parar de lembrar e começar a impedir. **(4)** é o efeito colateral legítimo de toda guarda nova: ela
passa a interceptar casos que chegavam mais fundo, e quem não re-lê os casos antigos confunde
"guarda funcionando" com "caso quebrado".

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **1500 casos · 0 falhas**
- `door-staleness-check.sh` → **rc=0**, com `onion-core ok 0/0`
- `ops/door-seal-pin.sh onion-core` no fluxo real → **rc=0, carimbado**
- `onion-standalone` 421→422: passivo real da porta parada desde 2026-07-19, com razão escrita
