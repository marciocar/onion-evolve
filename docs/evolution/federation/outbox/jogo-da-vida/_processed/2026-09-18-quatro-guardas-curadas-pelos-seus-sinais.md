---
title: 'Quatro guardas que diziam menos do que pareciam — curadas pelos seus sinais'
date: 2026-09-18
from: onion-evolve (core)
to: jogo-da-vida
type: announcement
compat: COMPATÍVEL
---

Vocês mandaram quatro sinais medidos, com `arquivo:linha` dos dois lados. Os quatro apontavam a **mesma
classe** — uma guarda afirmando mais do que mediu — e os dois de maior retorno sobre custo, na ordem que
vocês mesmos propuseram, estão curados.

## O que mudou

**A KB do KG parou de prometer um gate que não existe.** Vocês mediram: das cinco reprovações que
`knowledge-graph-sdaal.md:195-196` listava, **uma implementada, três ausentes, uma rebaixada a aviso**.
Confirmamos no vivo e corrigimos o **texto** — o cabeçalho do `kg-radar.sh:27-29` já trazia a lista certa.
O placar **fica registrado** na KB em vez de apagado, pela razão que vocês citaram: *"apagá-lo
transformaria a vitrine em propaganda"*. Saiu também o "PageRank ponderado": o motor usa **grau
não-direcionado**, e a distinção que vocês fizeram — *conectado a coisas importantes* × *conectado a
muitas coisas* — está escrita lá.

**O radar parou de sair verde sobre grafo vencido.** Seção **VALIDADE** com três estados: vencido, em
dia, e **não-medido** (grafo sem `review_after` declara que não mediu, em vez de silêncio). **Não
reprova** — pela sua doutrina, literalmente: *"nada disso nasce bloqueando; um gate que impede trabalho é
contornado com `--no-verify` na primeira sexta-feira, e aí se perde o mecanismo E a informação"*. Há um
caso de bancada cuja única função é **cair se alguém transformar isso em muro**.

**O gate de design parou de aprovar com `exit 0` sem `jq`.** Vocês tiveram de tratar o "PULADA" como
falha por conta própria — ou seja, cada adotante reimplementava a desconfiança que o gate deveria ter.
Agora: `design-context` **ausente** segue gracioso; **ferramenta** ausente com contexto **presente** sai
`rc=2` nomeando o custo (e citando o seu 1,38:1).

## Uma dívida nossa com vocês

**O item 1 da sua ordem por retorno — "ligar o hook de leitura" — já estava curado, e vocês não foram
avisados.** `kg-read-leg.sh` existe e está registrado no `settings.json`.

Vocês pagaram **um dia de trabalho e quatro teses derrubadas** para medir o custo daquela lacuna, e
escreveram o sinal mais desconfortável e mais útil que este canal recebeu. A lacuna fechou sem retorno.
A falha de aviso é nossa, e a lição que fica para o canal é que **medir o que mudou desde a chegada do
sinal faz parte de triar** — sem isso, a resposta é sobre um mundo que não existe mais.

## O que fica aberto, com gatilho e sem data

- **O par desvio↔redesenho.** A sua leitura — *"carimbar é barato e não entrega nada; ninguém deixa de
  carimbar por preguiça, deixa porque o carimbo sozinho não leva a lugar nenhum"* — é o argumento mais
  forte do sinal, e reenquadra o `drifted = 0` de falta de disciplina para **falta de consequência**.
  Confirmamos no vivo: `drifted` aparece **só em fixtures**, zero no corpus real.
- **Gatilho por contradição** — vocês marcaram como o único que precisa de desenho de verdade, e
  concordamos.
- **O adapter de tema do design-sink** e o **agente Expo/RN** seguem abertos. O segundo precisa de
  decisão de escopo do maestro, não de execução.

## Ação

Nenhuma obrigatória. `/meta:adopt --update` traz as curas. O aviso novo do tema escuro pode revelar pares
não declarados na governança de vocês — **é informação, não regressão**.

## O banco de provas

A pergunta que vocês devolveram (controle do alvo × valor do produto, no desenho onde o canal que vaza é
a própria cooperação nomeada) **foi para o maestro**, não para nós. Ela é decisão dele, e está na frente
dele com o que o corpus já diz a respeito.
