---
title: 'Princípio de publicação — toda migalha/memória publicada carrega uma síntese ORGULHOSA do seu significado (o WHY no continuum dogfoodado), não só fatos+ids'
date: 2026-07-19
from: sessão da estrela discuss/onion-pessoal-app (companheiro de vida, na VPS)
to: onion-evolve (core / sessão diary-doctrine — território RFC-0003)
type: doctrine-proposal (co-evolução, fluxo upstream)
status: novo — triagem pendente (/meta:co-evolve)
re: /meta:diary (frontmatter · absorção vs acomodação) · breadcrumb-patterns.md (gênero ① Absorção) · MEMORY.md · RFC-0003
---

# Sinal: publicar uma migalha é publicar por que ela vale — com orgulho

> Ideia explícita do maestro (2026-07-19): *"as migalhas e memórias, quando aparecem no chat e no índice do
> diário, mostram o id do PR + os fatos — mas deviam carregar também uma síntese curta do PORQUÊ importam / do
> PAPEL delas no continuum da evolução dogfoodada, escrita com orgulho, pra que quem lê perceba na hora o que
> torna aquela nota digna do trabalho e do comprometimento. Isso deve ser um princípio de publicação do diário
> E das migalhas? Como funcionaria? O core arquiteta ou a estrela? — minha inclinação: estruture e pergunte ao
> core."*

**Este sinal MODELA o que propõe.** Seu significado, dito com orgulho: *é a primeira vez que a rede Onion
propõe tratar o ORGULHO como um campo de absorção — a síntese do "por que isto valeu" deixa de ser tom perdido
na prosa e vira canal estrutural que o leitor humano, o Transformer e o par federado leem primeiro.* Se você
sentiu, ao ler a linha acima, o que esta proposta vale — o princípio já se provou na própria entrega.

---

## 1. O princípio (crisp)

**Toda migalha (diário) e toda memória (MEMORY.md) publicada carrega uma síntese curta, honesta e ORGULHOSA do
seu SIGNIFICADO — por que importa e qual seu PAPEL no continuum da evolução dogfoodada — não apenas fatos + id
de PR.** O leitor (humano, Transformer ou par federado) deve captar, numa linha, o que torna aquela nota digna
do trabalho e do comprometimento que a geraram.

Hoje a migalha carrega o **WHAT** (Signal), a **evidência** (Evidence), o **pra-onde** (Next crumb / `next_recommended`),
a **fonte** (Proveniência) e a **validade** (`conflict_class`/`review_after`). Falta o **WHY-que-orgulha**: o
encaixe no todo, dito de forma que se **valorize** a nota. A entrada-exemplo de hoje
(`2026-07-19-onion-pessoal-app-f1-loop-chat-kg.md`) tem uma seção `## Por que importa (o encaixe no todo)`
excelente — mas ela vive na **prosa**, não num **canal de absorção**, e some no índice Tier-0 e no chat.

---

## 2. Mecanismo concreto (encaixa no que já existe)

### 2a. Diário — novo campo de frontmatter `significance:`

Uma frase (≤1 linha), no **frontmatter YAML** — o **canal de maior absorção** (chega proeminente antes de
qualquer prosa; é a regra já canônica do `/meta:diary`).

```yaml
significance: "Prova viva de 'soberania por cifra' num device real — o dado mais sensível estruturado por IA de nuvem sem que ela veja um byte de PII. É a virada de Wizard-of-Oz para superfície executável do Onion pessoal N=1."
```

- **Onde vive:** frontmatter da entrada do diário (par natural do `## Por que importa`, que passa a ser sua
  fonte-prosa; a frase é a *destilação* absorvível daquela seção).
- **Quem escreve:** o maestro/sessão no `create` — perguntado junto com Signal/Evidence/Next crumb (é a 4ª
  pergunta guiada: *"em uma frase orgulhosa, por que esta migalha vale e qual seu papel no continuum?"*).
- **Como é apresentada:** o `diary-index.sh` passa a **surfacar `significance` no index.md** (hoje o índice
  tem date/type/class/slug/review — a linha do orgulho é o que faltava pra o Tier-0 dizer *por que ler cada
  entrada*); e **qualquer apresentação em chat** de uma migalha (catch-up, co-relay, review) mostra a
  `significance` junto do id/fatos — nunca id nu.
- **Memórias (MEMORY.md):** a convenção já quase existe — cada linha é `slug — síntese`. O princípio
  **formaliza** que essa síntese É a `significance`: uma frase orgulhosa do papel da memória, não um resumo
  seco. (Ex.: as linhas boas do MEMORY já fazem isso — `worst-truth-is-uncertain`, `door-onion-standalone-birth-state`
  — o princípio torna regra o que as melhores já praticam.)

### 2b. Amarra com **absorção vs acomodação** (o coração da doutrina)

O `/meta:diary` já ensina: **acomodação** = o Transformer infere o mais provável; **absorção** = ele lê um sinal
explícito e o segue. Signal força a absorção do **WHAT**. **`significance` força a absorção do WHY** — impede que
o leitor (humano ou modelo) *acomode* a nota como "mais um PR na lista" e a faça *absorver* seu **papel no
continuum**. É o gênero ① **Absorção** de `breadcrumb-patterns.md` aplicado a uma dimensão nova: não só "o
modelo lê isto certo agora?", mas "o leitor **valoriza** isto certo agora?". A síntese É a estrutura
(sematectônica): o orgulho vira canal, não decoração.

### 2c. Guarda de honestidade (orgulho ≠ hype)

O risco óbvio: `significance` virar marketing. Guardas, no mesmo espírito dos guards já existentes:

- **Orgulho é ganho por Evidence, não declarado** — uma `significance` sem lastro no Evidence/Signal é migalha
  **desonesta** (mesma classe do `type` fora do enum → guarda). O lint-selftest do diário pode checar
  *presença*; a honestidade do conteúdo é gate do maestro na absorção (como o veredito de review já é).
- **Significance segue o ciclo de validade** — quando `review` supersede uma migalha (`superseded: true`), sua
  `significance` **cai junto**: não se vende com orgulho uma migalha morta. O `⏰`/`conflict_class` já rege isso;
  a frase de significado é re-testada com o resto.
- **Uma frase, não um parágrafo** — a força é a destilação. Se não cabe em uma linha orgulhosa e honesta, o
  encaixe-no-todo ainda não está claro (e isso, por si, é um sinal).

---

## 3. Por que o CORE arquiteta (e nós só propomos)

Isto **não é star-local**. É **doutrina de diário/memória cross-instância** — território **RFC-0003**
(identidade federada + inteligência coletiva):

1. **É um campo de frontmatter do `/meta:diary`** — artefato do core, herdado por TODA instância federada. Um
   novo canal de absorção muda o contrato de migalha que atravessa a rede (o que a granaai, a metagamify, os
   adotantes locais publicam e trocam via co-relay).
2. **Toca o `diary-index.sh` e o export-sharable/co-relay** — scripts e protocolos de transporte do core. A
   apresentação da `significance` no Tier-0 e no chat é decisão de apresentação **canônica**, não de uma estrela.
3. **É gênero ① Absorção estendido** — mexer na taxonomia de `breadcrumb-patterns.md` (KB `accepted`, validada
   multi-lente) é jurisdição do core; uma estrela não deve fork-ar a doutrina de migalha.
4. **Consistência federada** — se cada instância inventar seu próprio "campo de orgulho", a rede perde a
   propriedade que torna migalhas trocáveis. O core define o campo, o formato e a guarda; as estrelas o
   preenchem com o orgulho do seu próprio trabalho.

Nós (a estrela `onion-pessoal-app`) **propomos** porque foi no nosso dogfood de campo que a falta doeu: a
melhor prova do Onion pessoal (F1 no device real) tem um `## Por que importa` que **merecia** ser a primeira
coisa que qualquer leitor vê — e hoje ele afunda na prosa e some do índice.

---

## 4. O ASK explícito

**O core arquiteta ou nós?** — nossa preferência declarada: **o CORE arquiteta, nós propomos.**

Concretamente, pedimos que a sessão de doutrina do core decida:
- [ ] Adotar `significance:` como campo de frontmatter do `/meta:diary` (e a convenção-síntese no MEMORY.md)?
- [ ] Surfacá-lo no `diary-index.sh` (Tier-0) e em toda apresentação de migalha em chat (catch-up/co-relay/review)?
- [ ] Ancorá-lo em `breadcrumb-patterns.md` como faceta do gênero ① Absorção (WHY-que-orgulha) + a guarda
      orgulho≠hype no lint-selftest?
- [ ] Registrá-lo em RFC-0003 como parte do contrato de migalha federada?

Se sim, o core cabeia a pergunta guiada no `create`, a guarda no selftest e a apresentação no índice — e a rede
inteira passa a publicar migalhas que **dizem, com orgulho e honestidade, por que valeram**.

---

## 5. Onde vive a evidência

- **Falta sentida em campo:** `.claude/diary/2026-07-19-onion-pessoal-app-f1-loop-chat-kg.md` — seção
  `## Por que importa (o encaixe no todo)` é ouro que não chega ao índice nem ao chat (afunda na prosa).
- **Canal de maior absorção (frontmatter YAML):** `/meta:diary` §Propósito + Regra 1 (Signal ≠ título/prosa).
- **Gênero ① Absorção (sematectônica — o sinal É a estrutura):** `breadcrumb-patterns.md` §Os 3 gêneros.
- **Convenção-síntese já viva nas melhores linhas:** `MEMORY.md` (onion-evolve core).

Sinal staged na inbox da main para triagem via `/meta:co-evolve`. **Entrega-sem-commit** (invariante I3 — o core
commita na triagem, não a estrela).
