---
title: 'Resíduo adversarial — MODO PROPOSTA, paridade de censo e a versão do plugin'
date: 2026-09-12
branch: fix/kg-proposal-mode-and-census-parity
reviewed_diff_sha256: daed3f8277560404ab9a9624e154a557a4035c2b5fb478acedf212e7bc50cce1
findings_total: 37
findings_real: 37
findings_fixed: 34
tokens: 509478
duration_min: 96
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Três refutadores independentes, cada um com mandato de DERRUBAR e default REPROVADO. 34 achados,
  13 ALTA, nenhum descartado no verify — precisão de 100% pela segunda leva seguida, o que continua
  sendo anômalo e merecendo desconfiança. Mais 3 achados que NENHUM refutador pegou e que só o
  dogfood da própria cura revelou. Três ficam abertos como fio próprio, declarados abaixo.
---

# A passada REPROVOU de novo — e o defeito é uma classe só

34 achados dos refutadores, 13 ALTA. Mais 3 que apareceram quando eu rodei a própria cura.
Quase todos são a mesma pergunta errada, irmã da que reprovou a leva anterior:

> **eu asseri sobre uma CÓPIA da coisa, em vez de sobre a coisa.**

- a paridade **transcrevia** o awk em vez de **perguntar** ao awk
- `lstrip(" \t")` era a minha ideia de `[[:space:]]`, não `[[:space:]]`
- a bancada mutava a **fixture** e o rótulo dizia mutante do **motor**
- o README declarava nove cobranças e a bancada exercitava **uma**
- a versão era **calculada do histórico** quando precisava ser um **fato na árvore**
- `Viola..es` era uma cópia mental do acento — e diverge do original em locale C

## O pior achado: a guarda falhava no caso que lhe dá nome

`[[:space:]]` do awk aceita **CR**; `lstrip(" \t")` não. Com CR entre a indentação o arquivo
segue **YAML-válido**, o radar conta o fantasma, o PyYAML não — e a **REGRA 82 (Os dois leitores
do corpus CONCORDAM sobre quem é nó)** saía **0 com saída vazia**. Era o sinal do venda-direta-pdi,
letra por letra, passando pela regra que nasceu para ele.

E a transcrição **congelava**: um caractere mudado no matcher do radar não era detectado — a guarda
passava a acusar um motor que não existe mais, e o caso `(d)` da bancada, escrito por mim para
provar *"replica, não aproxima"*, **aplaudia com o radar mutado**.

**A cura não é transcrever melhor. É perguntar ao motor.** A guarda agora invoca
`kg-radar.sh --status-tsv` — o feed que o próprio radar emite com a população que usou para dar o
veredito. Não há o que divergir: o contador é o mesmo objeto. Toda mudança futura no matcher viaja
de graça.

## Os três fail-opens do MODO PROPOSTA

Um relaxamento de gate nunca pode ser ligado por acidente, e havia três portas num grafo vivo:
`target:` aninhado em sub-mapa; `target:` dentro de bloco literal — a classe que o próprio
`kg-radar.sh` **declara ter curado**, e que ali cai para o lado fail-open; e `meta:` **reaberto**
depois de `nodes:`, que desligava tudo com duas linhas no fim de qualquer grafo.

E o mais irônico: eu escrevi no código que o modo *"nunca é silencioso"*. Era — no
`kg-radar-integrity.sh`, o **único gate que roda por cadência**, que só olha a saída quando
`rc != 0`. Em modo proposta o rc é 0, a linha sumia, e o gate imprimia *"sem contradicao estrutural
em NENHUM grafo do repo"* sobre um grafo com duas cobranças desligadas.

## Três achados que nenhum refutador pegou

Só o dogfood da própria cura os deu, e os três são a classe desta onda cometida **dentro da cura
dela**:

1. **Eu lia radar-morto como `radar=0`** — ausência virando RESULTADO. Num sandbox sem a lib ao
   lado, a guarda acusou DIVERGE num grafo perfeitamente são.
2. **Eu lia o fato commitado DEPOIS do `rm -rf "${DEST}"`** — e quando DEST é o canônico, aquilo
   apagava o que eu ia ler: a versão zerava para `0.1.0` num plugin com **255 publicadas**.
3. **A bancada mede diferente do gate, por LOCALE.** Eu via 1198/0; o pre-commit via 1191/7, mesmo
   código, mesmo instante. 13 padrões usavam `Viola..es` — o `.` conta **caractere**: em UTF-8 `ç`
   e `õ` valem 1 e casa; em **locale C** valem 2 bytes e **não casa**. O hook roda em C. As
   extrações voltavam VAZIAS e sete famílias reprovavam sem nunca ter medido nada.

O terceiro tem uma lição de método junto: **eu nunca tinha rodado a bancada no ambiente em que ela
roda de verdade**. Medir no caminho que eu uso quando a produção usa outro é não ter verificado.

## Duas guardas minhas trabalharam uma para a outra

Sem eu pedir, e é o melhor sinal de que o mecanismo está vivo:

- a cura do diagnóstico do `outbox-channel` **preservou os logs** — e foram eles que provaram que a
  medição estava CERTA (`HARD 32=32`, `SOFT 10→13`) e que quem falhava era a **extração**. Sem eles
  eu teria caçado a regra errada;
- a guarda `shell-pipefail` **nomeou o sítio irmão** que eu próprio acabara de escrever no
  `kg-radar-integrity.sh`, e disse a cura: here-string.

## A versão do plugin, na terceira tentativa

As duas anteriores erraram sob o mesmo pressuposto: que a versão podia ser **calculada** do
histórico. Enquanto for função do HISTÓRICO ou do REMOTO, ela não pode ser ao mesmo tempo
reproduzível-da-árvore (o que a **REGRA 19 (Plugins de vertical sincronizados com as fontes)**
exige) e estável (o que um PR aberto exige).

Agora é um **fato commitado**: `versão nova = versão COMMITADA + (tree_sha mudou ? 1 : 0)`. Os dois
insumos vivem na árvore. Um caso de bancada por requisito, com **squash-merge real**.

## O que fica ABERTO, declarado

- **O buraco entre as irmãs 78 e 82**: os 4 grafos que a 82 não mede são byte a byte os 4 do
  baseline da 78. Nenhuma das duas cobra em HARD ali, e um fantasma injetado passa pelas duas.
  Nomeado e CONTADO nesta entrega; a cobrança real é encolher o passivo da 78.
- **Fragilidade de locale em código pré-existente** (`[—:–-]` com travessão no pré-filtro da
  REGRA 16): conjunto com caractere multi-byte é indefinido em C. Fora do escopo deste PR.
- **Teto da versão**: dois PRs concorrentes que tocam fontes e são mergeados SEM rebase publicam o
  mesmo número. O fluxo de merge desta casa exige branch atualizada.

## Gate

```
bancada : 1198 pass · 0 fail · 0 skip  (162 famílias, no gate REAL)
lint    : 0 HARD
mutantes: 6 no radar · 3 na paridade · 4 na versão — todos EXECUTARAM
          os que sobreviveram viraram caso novo OU código removido
```
