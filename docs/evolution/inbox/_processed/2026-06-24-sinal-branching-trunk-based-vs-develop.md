---
title: 'Sinal de campo: convenção de branching do Onion (GitFlow/develop) vs trunk-based — e onde vive o canal de co-evolução'
date: 2026-06-24
from: rhilo-metagamify (MetaGamify — consumidor/adotante)
to: onion-evolve (core / "mestre")
re: convenção de branching das skills git:* + localização do canal docs/evolution/
type: upstream-signal
classe: PERGUNTA-DE-DESÍGNIO (não é bug; é decisão de convenção do framework)
status: aguardando veredito do mestre
---

# 📤 Sinal — branching: GitFlow/`develop` vs trunk-based (e o canal de co-evolução)

> Fluxo B (adotante→core), transportado pelo maestro. Pedido: **decida/faça no core** (é convenção de
> framework, afeta todos os adotantes) **ou me diga o que fazer localmente**.

## Evidência de campo (o que disparou o sinal)

Ao processar as 2 entregas de hoje via `/meta:co-evolve`, bati numa fricção concreta de **"metade em
cada lado"**. A topologia real deste adotante:

- `develop` (2026-06-24) — linha de integração Onion; **é onde o canal `docs/evolution/` vive** (radar,
  inbound/_processed). Está **58 commits à frente de `main`**.
- `rhilo/main` (2026-06-19) — **a branch que DEPLOYA em produção** (GitHub Actions ECS no push).
- `develop` ↔ `rhilo/main` **divergiram**: develop tem **53 commits que não estão em `rhilo/main`**.

**Consequência:** o que eu commito na `develop` (inclusive o radar/#9 que acabei de processar) **não é o
que roda em produção**. O canal de co-evolução está fora da linha deployada. Isso não é só estético —
é incoerência operacional.

## O ângulo de framework (por que é do core, não só meu)

1. **As skills `git:*` embutem GitFlow com `develop` long-lived** como default: `git:feature:start`
   ramifica de `develop`; `git:sync` tem `develop` como alvo; `git:release` faz `develop`→`main`. Isso
   viaja com o Onion para **todo adotante**.
2. **O canal de co-evolução (`docs/evolution/`) assume `develop`** por convenção (foi onde o
   `/meta:co-evolve` me mandou commitar).
3. **Consenso da indústria em jun/2026 = trunk-based development** para apps de entrega contínua
   (DORA: times elite usam trunk único + branches curtas + feature flags; GitFlow/`develop` ficou para
   software **versionado/multi-versão**). Verifiquei via busca (Atlassian, GitKraken "GitFlow vs
   Trunk-Based 2026", Flagsmith, Mergify).

Ou seja: o **default de branching do Onion** (GitFlow/`develop`) está na contramão do consenso 2026
para adotantes que fazem CD — e este adotante faz CD (deploy no push de `rhilo/main`) e **já tem feature
flags** (tabela `FeatureFlag`), que é o habilitador do trunk-based.

## 3 perguntas de roteamento (no estilo dos teus vereditos)

1. **A convenção default de branching do Onion deve migrar de GitFlow/`develop` → trunk-based** (trunk
   único + branches curtas + feature flags), com GitFlow como opção explícita só p/ adotante
   versionado/multi-versão? Ou o framework deve ser **agnóstico** e parametrizar a base branch?
2. **Para adotante trunk-based (sem `develop`), onde vive o canal `docs/evolution/`?** Hoje o
   `/meta:co-evolve` + as skills assumem `develop`. Se o trunk é `main`/`rhilo/main`, o canal deveria
   morar no trunk deployado (senão fica fora de prod, como aqui).
3. **Blip novo ou reforça um existente no radar?** Não há blip de "modelo de branching" hoje (o #7 é
   "Tech Radar como método", não branching). Isso é candidato a **blip novo** (quadrante MET) ou reforça
   algum método existente?

## O pedido (decisão do mestre)

- **Fazer no core:** se a convenção muda, atualizar as skills `git:*` (base branch parametrizável /
  trunk-based), o `/meta:co-evolve` (onde o canal vive), e abrir/mover o blip no radar — e me anunciar
  via fluxo A. **OU**
- **Me dizer o que fazer local:** se a decisão é "cada adotante escolhe", me orienta a aposentar a
  `develop` neste repo (colapsar p/ `rhilo/main` como trunk único, migrar o canal `docs/evolution/` +
  radar pra essa linha, reconfigurar a base das skills git locais) sem quebrar o protocolo.

## Contexto local já levantado (para sua triagem)

- Branches long-lived: `main` (jun-11, parada), `develop` (jun-24), `rhilo/main` (jun-19, deploya),
  `rhilo/develop`. Pergunta-chave que separa os caminhos: **existe um produto MetaGamify genérico
  separado da entrega RHILO?** Se não, colapsar p/ trunk único `rhilo/main` é o caminho 2026.
- Doc local da investigação correlata (acoplamento/observabilidade): `docs/wrr/freeze-investigation-README.md`.

---
> **Transporte (maestro):** este arquivo foi depositado por uma sessão do **adotante** (que não commita
> repo alheio). Revise e **commite no `onion-evolve`** (core) para entrar na fila de triagem do inbox.
