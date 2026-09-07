---
title: "Adoção greenfield — três defeitos medidos no seed e na ordem das fases"
date: 2026-08-27
from: mvp-venda-direta-pdi
to: onion-evolve
type: bug
flow: upstream
---

# Três defeitos na adoção greenfield, medidos numa adoção real

Adoção de `~/mvp-venda-direta-pdi` a partir do core em `9f94d79543f4`, modo greenfield,
seguindo `/meta:adopt` passo a passo. Os três apareceram em execução, não em leitura.

## 1. `seed-adoption-graph.sh:82` — crases em prosa executam comando

A string do rótulo do gate no ramo **não-provado** está em aspas duplas e contém
`` `open` `` como prosa. O shell executou o comando: a **página de ajuda do `xdg-open`
inteira** entrou no arquivo `.kg.yaml`, quebrando o rótulo em 6 linhas soltas de YAML.

```
label: "... Enquanto isto for xdg-open - opens a file or URL in the user's preferred application

Synopsis

xdg-open { file | URL }
...
```

As outras cinco ocorrências no mesmo arquivo usam `` \` `` corretamente — é só esta linha.
E ela cai **exatamente** no caminho de quem adota um repo vazio, que é o caminho de todo
greenfield.

## 2. `seed-adoption-graph.sh:67` — lê `commit:`, o carimbo grava `source_commit:`

```bash
PIN="$(_f commit)";  [ -n "${PIN}" ] || PIN="(não carimbado)"
```

`write-stamp.sh` escreve `source_commit:`. O campo `commit:` não existe no stamp de
adotante — só na saída ao vivo do `onion-version.sh`, que é do **core**. Consequência: o
grafo semeado registra `pin: (não carimbado)` em **todo** adotante, e o primeiro grafo do
repo fica estruturalmente incapaz de responder "em que versão do framework este repo está"
— que é uma das poucas coisas que ele existe para responder.

## 3. Ordem das fases: os passos 8c e 9 precisam do carimbo, que só vem na Fase 5

O «Procedimento de Configuração pós-cópia» roda na **Fase 3**; o `.onion-version` é escrito
na **Fase 5**. Dois passos dependem do carimbo e degradam em silêncio:

- **(9) `regen-baselines.sh`** — sem stamp, `onion-version.sh` devolve `role: source` e o
  helper **aborta**: *"é o CORE (role: source) — abortado"*. Numa adoção greenfield ele
  nunca roda. É o passo que existe para impedir o adotante de herdar o passivo do core — e
  o comentário dele cita justamente a PoC BW&P/HPE, que nasceu com **47 violações HARD**
  por causa disso. Rodando à mão **depois** do carimbo, funcionou: `kg-verification-baseline.txt`
  foi de **47 chaves para 0**.
- **(8c) semente do KG** — sem stamp, o grafo nasce com `created/updated/baseline/date` =
  `(sem data — alvo sem commit e sem stamp)` e `modo/papel/branch` = `(não carimbado)`. E
  como o helper é never-clobber, **re-rodar depois não conserta**: é preciso remover o
  arquivo do índice antes.

## Sugestão

Mover o carimbo para antes do passo (8c), ou passar `SRC_*` como argumento aos dois
helpers. O achado 2 é uma linha; o 1 é um caractere. O 3 é ordem.

## Verificação deste sinal

Adoção concluída com os três contornados à mão: gate **provado por execução** (`GATE VIVO`),
baselines regeneradas do alvo, grafo re-semeado com o carimbo, radar `rc=0` (5 nós,
5 arestas, sem contradição).
