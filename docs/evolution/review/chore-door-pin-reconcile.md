---
title: 'Resíduo — o baseline que viajava populado era o vazamento'
date: 2026-09-17
branch: chore/door-pin-reconcile
reviewed_diff_sha256: 5714ad3d20a639aceb41d3427e387e0fea42b340e8f94476beac562566a9b66d
findings_total: 6
findings_real: 6
findings_fixed: 5
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A re-materialização da porta expôs um vazamento ATIVO num repo público, e o achado não veio de
  leitura: veio de a porta nascer com 22 HARD onde antes tinha 1. A diferença entre os dois estados
  era um baseline que viajava POPULADO, nomeando 22 caminhos core-privados. O segundo achado fica
  ABERTO e declarado: a porta só fica verde quando a dívida da REGRA 45 no core chegar a zero.
---

# O que o número pior estava dizendo

A porta re-materializada do `main` mergeado nasceu com **22 HARD**; a anterior tinha **1**. O
instinto errado seria tratar a piora como regressão e procurar o que eu quebrei.

Medido: a diferença é o `kb-vendored-link-baseline.txt`. Na porta anterior ele viajava **populado**,
com 22 entradas, e cada entrada nomeia um caminho **core-privado**:

```
docs/analysis/onion-adr-branch-roles-sdaal-2026-07.md
docs/analysis/onion-review-2026-05.md
docs/discussions/_template/SEED.md
docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md
docs/evolution/inbox/_processed/2026-07-04-kg-primeiro-dogfood-federacao.md
```

Em repo **PÚBLICO**, desde as 14:56 de 2026-09-17. É exatamente o que o cabeçalho do
`materialize-door.sh` diz que o `--stub-baselines` existe para impedir: *"publicar assim expõe a
TOPOLOGIA dos grafos do maestro — nomes, quantos são, como se chamam"*.

**Os 22 HARD não eram a doença, eram o sintoma honesto.** O baseline vazado estava comprando um lint
verde com o preço de publicar a topologia privada.

## A cura, e o limite dela

A porta é **projeção gerada** — a história dela não tem valor autoral. Isso torna a reescrita barata,
o que quase nunca é verdade: commit órfão único + `--force`, 714 arquivos, história de 1 commit.

**Limite declarado, medido depois do force-push:** `?ref=<sha-antigo>` **ainda devolve o arquivo
inteiro**. O force-push torna o objeto **inalcançável**, nunca inexistente — o GitHub serve objeto
solto por SHA até o GC dele, e quem clonou tem cópia. Quem quiser garantia precisa de ticket no
Support. O que vazou são **caminhos, não conteúdo**.

**E registro um erro meu de raciocínio no caminho:** recomendei *"empurre agora, isso remove o
vazamento"*. Removia do HEAD, não da história — meia-cura, que nesta casa é cura nenhuma. A reescrita
só aconteceu porque me corrigi depois; o certo era ter medido antes de recomendar.

## O que fica ABERTO, com o acoplamento nomeado

A porta segue com **22 HARD da REGRA 45 (Link vendorizado não aponta caminho core-privado, com
catraca)**, e isso é o estado verdadeiro: a superfície vendorizada linka para caminhos que a porta
não recebe, e o ledger que os tolerava **só funcionava nomeando esses caminhos**.

Acoplamento que ninguém tinha declarado até hoje: **a porta só fica verde quando a dívida da REGRA 45
no core chegar a ZERO.** A métrica de saúde daquela catraca sempre foi "este número diminuindo" — o
que faltava era saber que ela é a condição de a porta pública passar no próprio lint.


---

# Achado 3 — a razão que escrevi para uma isenção era falsa

Ao tocar o `members.yaml`, quatro projeções envelheceram — e uma delas expôs um erro **meu, do mesmo
dia**. Eu havia isentado o `federation-console.sh` do `regen-ssot-projections.sh` com a justificativa
*"projeta em `docs/evolution/federation/` — superfície core-only"*. É **falso**: ele também gera
`docs/onion/federation-map.md` e `docs/onion/federation-console.html`, que ficam exatamente onde o
regen escreve.

O **veredito** (isento) continua certo — o motivo verdadeiro é que ele **deriva do `members.yaml`**,
que é core-only, igual ao `a2a-agent-card.sh`. Mas razão errada é **pior que razão ausente**: o
próximo lê a justificativa, confere o caminho, vê que não bate, e passa a duvidar da lista inteira.
Corrigida no próprio caso.

# Achado 4 — o meu oráculo de completude é cego a MODO (aberto, com gatilho)

O `graph.sh --map` gera `federation-map.md`, que é projeção com catraca. O oráculo que escrevi hoje
casa por **nome de gerador**, e `graph.sh` já estava coberto pelo modo `--markdown` — então ele
passaria verde mesmo que um modo necessário faltasse da lista.

Aqui não há defeito de resultado: `federation-map.md` deriva do `members.yaml` e legitimamente não
entra. Mas o oráculo dá **confiança que não sustenta**, e isso é a quarta vez hoje que esta classe
morde. O oráculo forte casa pelo **caminho de saída** (`regenere: bash X > docs/onion/Y`), não pelo
gerador.

**NÃO curado aqui, de propósito:** trocar o oráculo muda a bancada e pede gate inteiro; este PR é
sobre o pin. **Gatilho:** a próxima projeção que envelhecer sem o `regen_completude` ter avisado.


---

# Achado 5 — o laço de 2h21, e a guarda que já conhecia a classe

O maestro perguntou se havia um shell rodando há 2 horas. Havia: PID 3751529, **2h21**, batendo na
API do GitHub a cada 60s por check-runs que **nunca iam nascer** — o PR estava `CONFLICTING`, e o
GitHub não dispara `pull_request` quando não consegue computar o merge. A condição `-ge 3` era
inalcançável e **nada dizia isso**.

Eu ia perguntar se valia mecanizar. O maestro respondeu que eu podia descobrir sozinho — e a medição
deu uma resposta **melhor que as duas opções que eu havia oferecido**:

> `bash-empty-result-guard.sh:174` já documenta `until ! pgrep …` **preso 1h06**.

Não era guarda nova (objeto errado: o defeito vive em comando de sessão, que lint nenhum vê) nem
disciplina. Era **reincidência de uma classe já curada, entrando por outra porta**: no (3b) a
condição não podia virar *falsa* por defeito do padrão; no (3c) ela não vira *verdadeira* porque a
**premissa caiu**.

O detector **não julga a condição** — nenhum regex sabe qual premissa caiu. Cobra a única coisa que
sempre cabe: **um teto e uma saída que distinga "pronto" de "desisti"**. Desarma com `SECONDS`,
`timeout(1)`, `break`, contador ou `--max-time`: o ponto é o teto existir, não o dialeto.

## Achado 6 — a bancada me pegou duas vezes escrevendo a própria cura

1. **Escopo errado.** O separador `tr ';&|'` parte `until …; do sleep 60; done` em três, e o pedaço
   que abre com `until` **não contém `sleep`**. Julgando o fragmento, o detector calava justamente na
   forma que o originou. Certo é: **âncora** no fragmento (para não acusar quem só menciona a
   palavra) e **presença de espera** no comando inteiro.
2. **Colisão de rótulos.** Nomeei meus casos `(b3)`–`(b7)`, que já existiam nesta família — quem
   lesse a saída depois veria dois `(b3)` com vereditos diferentes. Renomeados para `(c1)`–`(c5)`.

Cinco casos novos, incluindo os três que **impedem a guarda de virar fadiga**: comando que só
menciona `until` cala, iteração sobre lista finita cala, e `timeout(1)` externo cala. Família: 35/35.
