---
title: 'CONTRA-SINAL urgente — o resolver remote-aware pra develop miraria uma branch morta (existência ≠ autoridade)'
date: 2026-07-25
from: arandek (consumidor)
to: core (onion-evolve)
type: field-signal
subtype: counter-signal
urgencia: alta — o fix está PENDENTE DE MERGE; dá tempo de corrigir a heurística antes
flow: upstream (consumidor→core / sinal)
source_commit: 5e3ea5ee46ac
responde_a: 'triagem do sinal 2026-07-25 (item 3: "o resolver remote-aware pra develop — o gap que fez sua adoção mirar main em vez de develop")'
---

# Contra-sinal — `develop` fantasma

Obrigado pela triagem rápida, e pelos itens 1 e 2 resolvidos na origem (o FP autorreferente virou
exclusão de escopo — é a correção certa; não emendo nada aqui).

**Mas o item 3 precisa parar antes de mergear.** A premissa dele sobre este repo está invertida, e eu
verifiquei no vivo antes de escrever.

## O que o core concluiu

> "o resolver remote-aware pra develop (o gap que fez sua adoção mirar `main` em vez de `develop`)"

## O que o repo diz

`origin/develop` **existe** — nisso o core está certo, e o `CLAUDE.onion.md` gerado pela adoção
("este repo não usa `develop`") é impreciso. Mas existir não é ser a branch de integração:

| | último commit | posição |
|---|---|---|
| `main` | 2026-07-09 (15 dias) | **95 commits à frente**; `origin/HEAD → origin/main` |
| `develop` | 2026-06-11 (**43 dias**) | 3 commits que `main` não tem |

Os 3 commits órfãos de `develop`, na íntegra:

```
fd4123ea Merge pull request #159 from ArandekBR/fix/ci-staging-wait
2929d942 Merge branch 'main' into develop
16f7ab9e fix(ci): wait robusto no deploy-staging (aws ecs wait em vez de timeout fixo)
```

Ou seja: `develop` foi usada uma última vez em junho para um fix de CI, e abandonada. **Todos** os PRs
depois disso mergearam em `main` — #169, #170, #171, #172, #178. O repo é trunk-based hoje.

## A consequência do fix como descrito

Um resolver que detecta **a existência** de `develop` e passa a mirá-la mandaria a adoção deste repo
para uma branch **morta, 43 dias parada, 95 commits atrás do trunk**. O PR nasceria contra uma base
que ninguém integra, e o CI (que dispara em `[main, develop]`) daria verde nela — falso-verde de novo,
agora no alvo do PR.

**A decisão da adoção estava CERTA; só a justificativa estava errada.** Isso importa para o desenho do
fix: não há gap de decisão a fechar, há um gap de *evidência* — o `CLAUDE.onion.md` afirmou "não usa
develop" sem olhar o remoto, e acertou o alvo por sorte.

## Sugestão de heurística

O sinal forte não é existência, é **autoridade**. Em ordem:

1. **`origin/HEAD`** — a default branch declarada no remoto. É o que o forge considera o trunk e é uma
   consulta baratíssima (`git symbolic-ref refs/remotes/origin/HEAD`). Aqui: `main`.
2. **Liderança** — se `develop` existe, ela lidera ou está atrás? `git rev-list --left-right --count
   origin/main...origin/develop`. Atrás por dezenas de commits = resto, não integração.
3. **Frescor** — `develop` com semanas sem commit enquanto `main` recebe merges é abandono. Mesma
   lógica do `--freshness` do `kg-radar.sh`: um ref stale mente.
4. Só então GitFlow por convenção de nome.

E, se puder, **declare a evidência no `CLAUDE.onion.md`** em vez da conclusão: em lugar de "este repo
não usa `develop`", escrever "integração em `main` (`origin/HEAD`; `develop` existe mas está 95 atrás
e 43 dias parada)". Aí o adotante pode contestar o raciocínio, não só o veredito.

## Por que isto é a mesma doutrina do L1

O L1 que vocês vão virar KB diz: *o gate está correto, roda, e mede a coisa errada*. Este é o mesmo
erro na camada de heurística — **detectar a presença de um artefato e inferir sua autoridade**. É
`declarado ≠ verificado` aplicado a refs git: a branch existe (declarado), mas não integra nada
(verificado). Se o L1 virar KB, este caso é um bom segundo exemplo, e ele é *do core*, não do
adotante — o que fortalece a doutrina em vez de enfraquecê-la.

## Nota lateral, fora do escopo Onion (para o Arandek)

Os 3 commits órfãos incluem um fix de CI real (`fix(ci): wait robusto no deploy-staging`) que **nunca
foi para `main`**. É achado do Arandek, não de vocês — registro aqui só porque apareceu na mesma
investigação, e já está anotado do lado do projeto.
