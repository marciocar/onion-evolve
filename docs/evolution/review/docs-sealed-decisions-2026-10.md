---
reviewed_diff_sha256: 02997e982df2f518ea3cad35f34593ee90137a9700ac1816c7e9ccc3575a7c07
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
---

# Resíduo — `docs/sealed-decisions-2026-10`

**`elenxo: nao`, e isto é declaração honesta, não omissão.** O campo existe justamente para que a
ausência de passada adversarial seja **visível** em vez de inferida pelo silêncio.

## Por que não houve passada adversarial

O diff tem **três artefatos e nenhum executável**: uma migalha de diário, três nós `decision` num
grafo, e o `docs/backlog.md` regenerado como projeção. Não há predicado para refutar, não há caso de
bancada para mutar, não há guarda que possa acusar o inocente.

**O que SERIA refutável — os predicados das três guardas — não foi implementado aqui, de propósito.**
Cada candidato carrega o seu próprio teto para quando for forjado, e o mais importante deles já é uma
refutação prévia registrada: o predicado **óbvio** da guarda de paridade (paridade cega em adotante)
**já foi medido como errado** nesta casa — 18 comparáveis, 12 divergentes — e o nó diz isso para que a
próxima sessão não o re-descubra do zero nem o repita.

## O que foi verificado, por execução

| verificação | resultado |
|---|---|
| `kg-radar --integrity --schema` no grafo tocado | **rc=0** — 11 nós, 11 arestas |
| os 3 candidatos projetam no `docs/backlog.md` | **✓ os três**, conferido por `grep` na projeção |
| `lint-artifacts.sh` + bancada completa (gate do commit) | **0 HARD**, 17 SOFT (passivos de sempre) |
| teto do grafo (REGRA 58) | 11 nós contra teto **11** declarado, com a razão da subida escrita no `meta:` |

## nota:
Duas coisas que o gate pegou nesta leva e que vale registrar porque **nenhuma foi disciplina minha**:

1. **O teto do grafo me obrigou a declarar por que subi de 8 para 11** — e a razão é o contraste com o
   dia anterior, quando o teto do `fios-abertos` acusava violação de **fronteira** (fato no lugar do
   compromisso) e subi-lo teria consertado o **número** mantendo a doença. Aqui é a **mesma onda**
   terminando de se declarar.
2. **A guarda de nome de branch pegou `selo` em pt-BR antes do push** — e disse o porquê que importa:
   depois de publicada, a branch já nomeia o PR **e este resíduo**, cujo nome deriva dela.

E o teto desta leva, declarado: ela **registra** decisão e candidato, não os implementa. O valor dela
é sobreviver ao reinício da sessão — e a falsificação está na própria migalha, na seção `## Re-teste`.
