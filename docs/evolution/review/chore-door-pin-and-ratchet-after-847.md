---
title: 'Resíduo — o refutador refez cada medição, e a maioria dos meus números estava errada'
date: 2026-09-18
branch: chore/door-pin-and-ratchet-after-847
reviewed_diff_sha256: 0456bdbb68857808ca5a7536da83c7a03fa2d312818abeaffa26087ad67aa307
findings_total: 8
findings_real: 8
findings_fixed: 8
tokens: 159772
duration_min: 15
verdict: REPROVADO_E_CURADO
elenxo: sim
cobertura_declarada: >-
  O refutador leu as MEDICOES deste PR. O fecho do no do revisor semantico, acrescentado depois a
  pedido do maestro, NAO passou por ele — e append de evidencia medida por comportamento (checks do
  CI nos #846/#847), sem superficie de execucao. Declarado para o hash nao sugerir cobertura que nao
  houve.
nota: >-
  PR sem código novo: só baseline, projeções e nós de grafo. Por isso o mandato do refutador foi
  refazer cada MEDIÇÃO afirmada. Ele derrubou seis das minhas afirmações e achou um defeito de
  produto que eu não tinha visto — um fail-open no próprio script que publica a porta.
---

# O que acontece quando a passada adversarial ataca NÚMEROS em vez de código

Este PR não tinha superfície executável nova. O refutador recebeu um mandato diferente: **refazer
cada medição** e derrubar qualquer número declarado que ele não conseguisse reproduzir. Nesta casa,
número declarado e não verificável é a classe que perseguimos o dia inteiro — aplicá-la a mim mesmo
era o teste devido.

Ele **reprovou**. E acertou.

## O achado de PRODUTO, que nenhuma revisão de números deveria ter encontrado

`ops/materialize-door.sh:238` procurava o regenerador de projeções **só dentro do destino**:

```bash
if [ -f "${DEST}/.claude/utils/adopt/regen-ssot-projections.sh" ]; then ... || true; fi
```

O manifesto do papel `standalone` **exclui** esse arquivo — e a exclusão está **certa**: é ferramenta
core-only, não deve viajar. Mas o efeito era: o `if` falha, o `|| true` engole, o script sai `rc=0`
dizendo `✅ Porta materializada`, e a porta nasce **publicada com 8 HARD em vez de 4**.

O papel `hub` escapava **por acidente de manifesto** — lá o arquivo viaja. É a pior forma de um gate
funcionar: por coincidência, num caminho só, enquanto o outro publica quebrado.

**A cura não é fazer a ferramenta viajar** — é rodá-la do core contra o destino (ela sempre recebeu o
alvo como argumento), e **declarar** quando não houver nenhuma das duas. Casos (f) e (g) da bancada
prendem as duas metades; a família da porta foi de 5 para 7 casos.

## E a cura invalidou a minha própria medição

O tempo que eu declarei — `1,26 s` para materializar — media um script que **pulava trabalho em
silêncio**. Com a regeneração rodando de verdade: **13,6–15,3 s** (3 amostras).

> **Número de desempenho colhido sobre caminho fail-open mede a falha, não a tarefa.**

## As outras cinco afirmações derrubadas

- **Identifiquei mal 2 dos 4 HARD.** Contei a REGRA 42 (Gate de FRESCOR DOUTRINÁRIO), que sai
  **SOFT** (`violation "SOFT"` em `lint-artifacts.sh:3075`), e **omiti a REGRA 44** (Integridade da
  escada de Automação Graduada), que é HARD **e da mesma classe** — `members.yaml` inalcançável no
  papel. Consequência: a classe "artefato que viaja citando caminho que o papel não recebe" tem
  **três** membros, não dois. Eu classifiquei no olho em vez de instrumentar a severidade.
- **`4.605 linhas` não é reproduzível por nenhuma derivação.** O refutador tentou seis e nenhuma bate.
  Substituído por **4.096**, com o comando nomeado junto (`diff -ru … | grep -c '^[+-]'`). Número de
  diff só vale com a derivação ao lado.
- **O `verified_against` da catraca citava uma série que não existe em `main`** — e a única história
  onde o `372` aparece contém a queda `380 → 372`, que aparentemente desmente o "só sobe". Corrigido
  e **explicado**: aquele commit corrigiu a **medição** (ponta HEAD → merge-base), não a porta. O
  passivo não encolheu; o instrumento parou de mentir para mais. Omitir a queda seria o defeito que o
  próprio nó denuncia.
- **Um dos "dois defeitos reais" já está no ar.** `onion-wizard/SKILL.md:50` cita
  `.claude/commands/meta/adopt.md`, que **não existe** na porta publicada. E o que o esconde é o lint
  vendorizado dela, de 2026-07-19, que sai `Total: 0` — **zero violações de qualquer severidade**,
  porque a guarda que pegaria isto nasceu depois. **A porta está verde por ter guarda velha, não por
  estar limpa.** Isso muda a decisão: a opção *(B) congelar com data* não evita o defeito, apenas o
  mantém invisível — e precisa vir acompanhada de uma decisão sobre o lint congelado.
- **Os tempos estavam 30–45% acima** porque medi com a bancada rodando em paralelo e não disse isso.
  Agora são faixas, com a condição declarada.

## O que ele atacou e NÃO derrubou

- **620 arquivos** — reproduzido 3×.
- **8 HARD → 4 depois do regenerador** — reproduzido exato (as *identidades* é que estavam erradas).
- **268 caminhos = 126 + 132 + 10** — os quatro números batem.
- **`onion-core` 0/0 e o pin correto** — `gh api` confirma `acb7dda4`, e o `.onion-version` publicado
  traz `9f625086d80f`, idêntico ao `members.yaml`.
- **"parada desde 2026-07-19"** — o pin `514dda85833a` é daquela data.
- **Teto do `fios-abertos` não foi furado** — 20 nós, `kg-backlog-check.sh` limpo.
- **`plane: DEV` na question NÃO é fuga da REGRA 49.** Convenção do corpus: `question` é **DEV 198 ×
  PROD 62**, e as três questions do `fios-abertos` são DEV, uma delas com `impact: 4` — precedente
  exato no grafo-irmão.

## A lição

Duas passadas adversariais no mesmo dia, uma sobre código e outra sobre números, e **as duas
reprovaram**. A de números foi a mais desconfortável: o código eu escrevi com cuidado e errei na
superfície; os números eu **colhi executando** e mesmo assim errei — porque colhi sobre um caminho
que falhava em silêncio, medi sob carga sem declarar, e classifiquei severidade no olho.

> **Executar não basta: é preciso saber o que se está executando.** Uma medição feita sobre um
> caminho fail-open é tão falsa quanto uma estimativa, com o agravante de parecer evidência.
