---
title: 'Sinal: a rule research-lens faz TODO adotante greenfield nascer com 1 HARD'
date: 2026-09-02
from: sacola-de-ideias (consumidor)
to: core (onion-evolve)
type: field-signal
source_commit: 8e2517724c0a
flow: upstream (consumidor→core)
---

# A rule `research-lens.md` faz o adotante greenfield nascer com 1 HARD

## O que foi medido

Adoção greenfield deste repo no pin `8e2517724c0a` (main do core, 2026-09-02). Depois do commit
durável, com tudo rastreado, o lint vendorizado devolve:

```
VIOLATION: .claude/rules/research-lens.md: nenhum glob de 'paths:' casa arquivo rastreado
(docs/evolution/research/**) — a regra existe no disco e NUNCA carrega
  Violações HARD : 1
```

É a **única** HARD do repo. Todo o resto (7) é SOFT.

## Causa

`.claude/rules/research-lens.md` declara `paths: ["docs/evolution/research/**"]`. Esse diretório só
existe no core: um adotante recém-nascido não tem pesquisa nenhuma, logo nenhum arquivo rastreado
casa o glob, e a REGRA que exige "rule tem que carregar em algum path real" reprova.

A rule irmã `kg-grammar.md` **não** sofre disso porque usa `**/*.kg.yaml` — glob que a semente de
adoção já satisfaz.

## Por que importa

É exatamente o modo-de-falha que a própria doutrina de adoção nomeia no passo (6b) e no passo (9)
do procedimento pós-cópia: **dia 1 vermelho é o que faz apagarem o arquivo**. O adotante não fez
nada errado, e a violação cobra dele um diretório do core.

## Direções possíveis (decisão é do core, não deste repo)

1. A guarda ignorar rules vendorizadas cujo glob descreve uma convenção ainda não exercitada no alvo
   (o análogo do que o `regen-baselines.sh` já faz com chave estrangeira).
2. A rule aceitar também um glob genérico que a semente de adoção satisfaça.
3. A adoção semear `docs/evolution/research/` como semeia `inbox/` e `inbound/`.

Nada foi alterado aqui: a superfície vendorizada ficou intacta de propósito, para o core corrigir na
origem em vez de cada adotante remendar a própria cópia.

---

# Achado 2: a semente do KG nasce sem o pin, e o pin nunca é preenchido

Medido na mesma adoção, com dois defeitos independentes que se somam.

## 2a — a chave que o semeador procura não é a que o carimbo escreve

`seed-adoption-graph.sh` lê o pin assim (linha 67):

```bash
PIN="$(_f commit)"   # _f faz: awk '$1=="commit:"{print $2}' .claude/.onion-version
```

Mas `write-stamp.sh` escreve o campo como **`source_commit:`**, nunca `commit:`. Verificado no
stamp real deste repo:

```
$ awk '$1=="commit:"{print $2}' .claude/.onion-version      # → vazio
$ grep commit .claude/.onion-version
source_commit: 8e2517724c0a
source_commit_date: 2026-09-02
```

Consequência: **todo** grafo-semente de adoção nasce dizendo pin `(não carimbado)`, mesmo quando o
carimbo está correto e presente. `mode:` e `role:` funcionam porque esses nomes batem.

## 2b — a ordem documentada semeia antes de carimbar

O «Procedimento de Configuração pós-cópia» roda na **Fase 3** e traz o passo (8c) que semeia o grafo.
O passo (4) do mesmo procedimento diz apenas "re-stamp — ver **Fase 5**". Como a Fase 5 vem depois da
Fase 3, quem executa o procedimento ao pé da letra semeia o grafo **antes** de o `.onion-version`
existir — e aí `mode` e `role` também saem `(não carimbado)`, além do pin.

Neste repo os quatro campos foram corrigidos à mão depois do carimbo, e o radar fecha `exit 0` com
pin `8e2517724c0a`, modo `greenfield`, papel `adopted`. Mas a correção foi manual: o mecanismo
continua produzindo semente cega.

## Por que importa

O passo (8c) existe justamente porque a adoção "entregava todos os RECURSOS e ZERO ESTADO". Uma
semente que não sabe de que pin nasceu entrega estado **falso**, que é pior: o primeiro nó do grafo
do adotante afirma não saber uma coisa que o repo sabe e tem carimbada ao lado.

## Direção

Trocar a chave lida para `source_commit` (com fallback para `commit`, que é o nome que o
`onion-version.sh` usa ao vivo no core), e mover a semeadura para depois do carimbo — ou fazer o
passo (4) carimbar de fato, em vez de apontar para uma fase posterior.

---

# Achado 3: o `lint-selftest.sh` vendorizado NÃO PODE passar num repo adotado

## O que foi medido

Rodado no repo adotado, com tudo commitado: `SELFTEST_RC=1`, **19 casos ✗** (18 em
`r16-count-drift`, 1 em `r22-evolution-links`), e — o que mais importa — a bancada **abortou antes
da própria soma**, imprimindo ela mesma o aviso:

```
✗✗ BANCADA ABORTOU ANTES DA SOMA (exit 1) — o último ✓ acima NÃO é o fim da suíte.
```

## Causa (não é acaso: é o desenho do lint)

O predicado `inventory_scope_excluded()` do `lint-artifacts.sh` exclui da REGRA 16 tanto
`*/validation/fixtures/*` quanto — num repo derivado (`IS_DERIVED=1`, que é o caso de qualquer
`role: adopted`) — **tudo** que não seja `docs/onion/*` ou `CLAUDE.onion.md`. Essa exclusão foi
adicionada de propósito, e o comentário no código explica por quê: sem ela "todo adotante com
artefato próprio nasce vermelho".

Só que a bancada afirma o contrário: para cada fixture `bad-*` ela **espera** a violação aparecer.
Num adotante a violação nunca aparece — por desenho — e cada asserção vira ✗. Ou seja, a cura de
2026-08-06 para a REGRA 16 no adotante tornou a bancada da REGRA 16 insatisfazível no adotante, e
ninguém mediu isso porque a bancada só era rodada no core.

## Por que importa

1. A bancada viaja no manifesto (`.claude/validation/`), então **todo** adotante a recebe.
2. Ela sai `exit 1` e aborta sob `set -e` — quem a rodar e ler o final vê ✓ nas últimas linhas.
   O próprio script avisa que isso não é verde, mas o aviso depende de alguém ler com atenção.
3. É a mesma classe do achado 1: capacidade vendorizada que só funciona na casa de origem.

## Direção

Ou a bancada declara os casos **core-only** e os pula quando o stamp diz `role: adopted`
(fica honesta: "não se aplica aqui" ≠ "falhou"), ou ela não viaja no manifesto de adoção.
A primeira parece melhor: o adotante continua podendo exercitar as guardas que valem para ele.
