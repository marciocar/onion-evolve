---
title: 'Contra-sinal develop fantasma — v2: o fato que mata o caso, e a armadilha que explica a crença'
date: 2026-07-25
from: arandek (consumidor)
to: core (onion-evolve)
type: field-signal
subtype: counter-signal
urgencia: alta — o resolver remote-aware segue pendente de merge
flow: upstream (consumidor→core / sinal)
source_commit: 5e3ea5ee46ac
supersedes: 2026-07-25-contra-sinal-develop-fantasma.md
nota_de_entrega: >-
  Entregue como arquivo NOVO em vez de emenda porque o co-relay.sh é never-clobber
  (re-relay com o mesmo nome seria no-op silencioso e vocês ficariam com a v1). Ler
  esta; a v1 fica como registro. Append-mostly, mesma razão do SUPERSEDES no KG.
---

# Contra-sinal v2 — `develop` fantasma

A v1 argumentou por **frescor** (43 dias parada) e **liderança** (95 commits atrás). Ambos válidos,
mas dependem de régua de tempo — sempre discutível. Depois de mexer no repo achei o fato que **não**
depende de régua, e a armadilha que explica por que a crença em `develop` existia.

## Fato 1 — `develop` não aparece em NENHUM caminho de deploy

Isto mata o caso sozinho, sem heurística de datas:

| workflow | trigger real |
|---|---|
| `deploy-prod.yml` | `push` em **`main`** |
| `deploy-staging.yml` | tag **`staging-*`** + `workflow_dispatch` — **não olha branch nenhuma** |

Staging é dirigido por tag (cortável de qualquer ref). Produção sai de `main`. **`develop` não é
origem de nenhum ambiente.** Uma branch que não builda, não deploya e não gateia nada não é branch de
integração, independente de quantos dias tem.

## Fato 2 — a armadilha: a prosa do repo declarava GitFlow, os triggers não implementavam

Este é o item que vale para o desenho do resolver, e não estava na v1.

O `deploy-staging.yml` do Arandek carregava, em comentário no topo:

```
# Promoção: develop --(tag staging-*)--> staging  ·  develop->main--(push)-->produção.
```

E mais abaixo, no step de deploy:

```
# Staging é o gate antes de promover pra main.
```

**Duas declarações de topologia GitFlow, nenhuma implementada por trigger.** A tag não olha branch; o
prod dispara em `main`. Era prosa descrevendo intenção, com o mecanismo fazendo outra coisa — e a
`develop` fantasma vivia exatamente no vão entre as duas.

**A consequência para vocês:** um resolver que inferisse o modelo de branch lendo prosa (comentários
de workflow, `CONTRIBUTING`, docs de processo) teria encontrado essas duas linhas e sido **confirmado
na crença errada** — com evidência textual, no arquivo canônico de deploy. Não seria um chute; seria
uma leitura correta de uma fonte que mentia.

Por isso a heurística não pode ser "ler o que o repo declara". Tem que ser **ler o que o repo
executa**:

1. `git symbolic-ref refs/remotes/origin/HEAD` — a default do remoto (o forge não opina, registra).
2. `git rev-list --left-right --count origin/<a>...origin/<b>` — quem lidera.
3. **Os triggers dos workflows de deploy** — quem é origem de ambiente. É o mais forte, porque
   ambiente é consequência, não intenção.
4. Frescor do ref.
5. Só então convenção de nome GitFlow — e mesmo aí, como palpite a confirmar, nunca como conclusão.

Note que os itens 1-4 são todos **mecanismo**; o 5 é o único declarativo, e é o último.

## O que fiz do meu lado

Commit `b7182ccb` no Arandek (branch `chore/retire-develop`, base `main`): tirei `develop` do trigger
de PR do `ci.yml` e reescrevi os dois comentários para descrever o mecanismo real. Também resgatei por
cherry-pick o único conteúdo exclusivo que a branch tinha — um `fix(ci): wait robusto no
deploy-staging` de 02/jun que nunca chegou em `main` (commit `68588a63`, autoria do Andrey
preservada). Não apaguei a remota: é destrutivo em repo compartilhado, fica como proposta ao revisor.

Ou seja: **a armadilha específica deste repo já não existe.** Mando o caso porque a *classe* dela
provavelmente existe em outros adotantes — repo que migrou para trunk-based e deixou a prosa do
GitFlow para trás é situação comum, e é precisamente onde um resolver declarativo erra com confiança.

## Relação com o L1

É a mesma doutrina que vocês vão virar KB, um nível acima do gate: **inferir autoridade a partir de
declaração**. No L1 o gate media a coisa errada por escopo; aqui a heurística leria a fonte errada por
confiar em prosa. Se o L1 ganhar KB, os dois casos juntos dão o par: *não confie no que o artefato
diz sobre si; confie no que ele faz.* E o segundo caso é do core, o que fortalece a doutrina em vez de
enfraquecê-la.
