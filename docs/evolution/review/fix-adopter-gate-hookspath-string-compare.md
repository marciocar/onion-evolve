---
title: 'Resíduo — o verificador que provava comportamento decidia por string'
date: 2026-09-15
branch: fix/adopter-gate-hookspath-string-compare
reviewed_diff_sha256: PENDENTE
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Sem passada adversarial de subagente, e a razão é que o REFUTADOR FOI O DOGFOOD: o defeito apareceu
  abortando uma adoção real no meio da entrega, não numa leitura de código. O que um refutador
  acrescentaria — "prove que a cura não virou fail-open" — virou o caso (c) da bancada, escrito antes
  deste resíduo.
---

# O verificador que existe para provar comportamento decidia por declaração de path

## Como apareceu

Não por leitura: **abortando uma adoção real**. O `/meta:adopt --update` do jogo-da-vida parou no passo
bloqueante do gate com `rc=1`, e a saída do verificador **se contradizia**:

```
✗ há hook do Onion em .githooks/ que o git IGNORA (hooksPath aponta para '/home/marcio/jogo-da-vida/.githooks')
✓ o hook EXECUTOU no commit (assinatura observada)
✓ o commit foi BARRADO pelo gate do Onion com o lint reprovando — bloqueio provado
```

O `hooksPath` apontava **exatamente para onde o hook estava**. `ops/verify-adopter-gate.sh:65` comparava
por **string** (`[ "${DIR}" != ".githooks" ]`) e o alvo tinha o caminho na forma **absoluta** — que o
git aceita e resolve para o mesmo diretório.

O gate do jogo-da-vida **sempre esteve vivo**. Quem mentia era o verificador.

## Os dois achados

**1. A comparação.** O `ABS` resolvido já era calculado **15 linhas acima**, exatamente para isto; só
esta checagem não o usava. Curado com `-ef` (identidade de diretório) — o mesmo idioma que a família
`capability` já exercita noutra guarda.

**2. A causa de fundo, que é maior:** `ops/verify-adopter-gate.sh` tinha **ZERO cobertura de bancada**.
É ele que a adoção consulta para decidir se **entregou o produto** — e o modo-de-falha dele só
apareceria no repo de um cliente. Guarda sem bancada é guarda cujo defeito é descoberto pelo adotante.

## Por que isto dói mais que um `!=` errado

A doutrina desta casa é `behavior-over-declaration`: confie no que o artefato **faz**, não no que
declara. Este script existe para **aplicar** essa doutrina num alvo — e estava decidindo por
**declaração de path**, com a prova comportamental impressa duas linhas abaixo, contradizendo-o.

## Bancada

Família `adopter_gate`, **4 casos**, e o desenho deles importa:

```
(a)      hooksPath RELATIVO não acusa — controle (se ele cair, (b) não prova nada)
(b)      hooksPath ABSOLUTO no MESMO diretório NÃO é acusado de ignorado
(b-MUT)  devolvendo a comparação para STRING, (b) REPROVA — (b) mede o -ef
(c)      gate SOMBREADO de verdade (hooksPath → .husky) AINDA acusa — a cura não virou fail-open
(d)      gate que EXECUTA mas não BARRA não é declarado VIVO — o veredito distingue
(e)      e por isso o grep do adopt.md não casa: o KG do alvo nasce 'open', não 'confirmed'
```

A fixture teve de ser refeita para os casos (d)/(e): a primeira não emitia a assinatura que o
verificador procura no stdout do commit, nem trazia um `lint-artifacts.sh` — sem os dois, o ramo que
avalia BLOQUEIO nunca é alcançado, e o caso mediria outra coisa achando que media o veredito.

O caso `(c)` é o que impede a cura preguiçosa: "nunca acusar" passaria em (a) e (b) e abriria a guarda
para o caso real que ela nasceu para pegar (o husky ocupando o `core.hooksPath`).

## O terceiro achado, e ele veio de um SINAL DE CAMPO no mesmo dia

Um adotante escreveu ao core (`inbox/2026-09-15-adocao-sem-registro-e-gate-nao-provado.md`) apontando
que o relatório de adoção afirmava *"gate provado vivo"* contra um nó `DETERMINISTIC_GATE` ainda
`open`. Medindo, o defeito **não era do relatório** — era do verificador, e é a mesma classe dos
outros dois:

```
·  lint limpo agora: o BLOQUEIO não foi exercido (só a execução) — declarado, não aprovado
                        ↓ três linhas depois ↓
✓  GATE VIVO — provado por execução
```

O script **sabia** a distinção e o veredito a **apagava**. E o estrago não parava no texto: o
`adopt.md` faz `grep 'GATE VIVO'` na saída para carimbar `--gate-proven` na semente do KG do adotante
— então o **grafo do cliente afirmava prova que ninguém fez**, que é literalmente o defeito que aquele
passo declara existir para não repetir (*"só afirma prova quem VÊ a prova"*).

Curado mantendo a string `GATE VIVO` **exclusiva do caso provado**: o consumidor fica correto por
construção, não por disciplina. O caso não-provado ganhou veredito próprio, que manda o grafo do alvo
registrar `open`.

> Um gate que roda e sempre passa é indistinguível de um gate quebrado até o dia em que precisa barrar.

## Curado ao escrever a própria bancada

As capturas `out="$(bash "${v}" ...)"` mataram a suíte sob `set -e` — o verificador **sai ≠0 ao
reprovar** e a atribuição propaga. É a classe que o próprio harness avisa em `bancada-espelha-o-runner`,
e ela me pegou na primeira execução.

## O quarto: a limpeza que dependia de eu lembrar

Três vezes neste dia o gate reprovou por **fixtures órfãs** que a bancada deixou na árvore viva — uma
delas com **271 HARD**, todas fixtures, nenhuma do código. As três vezes a cura foi eu lembrar de
limpar. `fix-must-become-mechanism`: virou `sweep-orphan-fixtures.sh`, chamado pelo pre-commit
**antes** do lint.

Duas medições fixaram o desenho, e as duas derrubaram a versão anterior:

- **`--porcelain` sozinho não enxergava a pior fixture.** `plugins/__*__/` **já estava no
  `.gitignore`** — alguém antecipou o lixo sem antecipar a limpeza. Sem `--ignored`, a varredura era
  cega justamente para a que produziu as 271 HARD.
- **Olhar ignorados traz o `node_modules` junto.** `site/node_modules/css-what/src/__fixtures__` casa
  o padrão e é **dependência de terceiro** — a primeira versão a apagaria e quebraria o site.

E um terceiro, mais sutil: o regex de derivação era `__[a-z0-9]+__`, que **não casa
`__selftest-deeplink__`**. Derivação estreita demais é guarda que parece funcionar — limpa o que
lembra e deixa o resto.

A família `sweep_fixtures` prova as **recusas**, não os acertos: rastreado intacto, `node_modules`
recusado, `__fixtures__` fora do alcance (é convenção de Vitest de projeto real), `--dry-run` não
remove. Ferramenta que apaga tem de provar o que **não** apaga.

**Core-only por ora, declarado:** o helper viaja, o passo no hook não — mesmo tratamento da guarda
anti-commit-na-default-branch, e pela mesma razão (apagar untracked no repo de outro é aposta maior).
Gatilho para promover: um adotante reportar fixture órfã reprovando o lint dele.

## Gate

```
famílias novas      : adopter_gate 6/6 · sweep_fixtures 5/5
radar / integrity    : exit 0 (34 nós)
realign              : ALINHADO
commit               : SEM --no-verify
```
