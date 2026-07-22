---
title: 'ADR — Blog/publicação do Onion: fonte-no-repo, gerador determinístico, voz autoral gated, plataforma SSG-git'
date: 2026-07-22
type: adr
status: aceito (plataforma + arquitetura do gerador); gated (contêiner de ensaios até o 1º ensaio real; costura SDAAL até o 2º destino)
decision-scope: meta / publicação / fonte≠derivação / dobradinha-de-vozes
supersedes: none
deciders: maestro + sweep orquestrado de plataforma (verificado na web, jul/2026) + design orquestrado (arquitetura + voz)
context_freshness: 2026-07-22
related:
  - docs/knowledge-base/concepts/source-vs-derivation.md (fonte≠derivação — "uma só fonte"; o litmus deste ADR)
  - docs/knowledge-base/concepts/knowledge-graph-sdaal.md ("relatório é PROJEÇÃO do grafo, nunca fonte paralela")
  - docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md (o molde SDAAL da costura gated)
  - docs/knowledge-base/concepts/onion-dogfooding-doctrine.md (gate de uso; "cerimônia à frente da substância = erro v4.0")
  - docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md (identity/ EMERGENTE — o eixo que NÃO se funde com ensaios)
  - .claude/commands/meta/diary.md (a máquina de frontmatter que o gênero-ensaio generaliza)
  - site/README.md (site/ = fonte, /var/www = derivado — a instância física de fonte≠derivação)
---

# ADR — Blog/publicação do Onion

## Contexto

O maestro quer publicar, em onionevolve.com, uma **dobradinha**: a sua voz (visão, metodologia — "inteligência
é saber usar de formas diferentes aquilo que já se sabe") ao lado da autobiografia do framework (o diário, já
projetado nas migalhas), com convidados no futuro (Claude, Claude Code). A tese é que a publicação deve
**encarnar** o SDAAL/KG-SSOT, não só falar dele — viral pela concepção, não pelo midiatismo.

Três problemas concretos motivam a decisão:

1. **O site atual JÁ viola fonte≠derivação — e a dor está provada.** `historia/migalhas/index.html` +
   `feed.xml` + `provas/index.html` são editados **em paralelo, à mão** (fonte paralela). Evidência de campo:
   o bloco `pc-prs` está ausente nos cards ≥ 2026-07-19, e há **5 commits de correção de link-404** de
   repo-privado que vazaram para o público (c6102d8…). O litmus de `source-vs-derivation.md` ("se a fonte
   muda, edito em quantos lugares? → um") está quebrado: hoje são três.
2. **Não há plataforma decidida** — headless-CMS vs SSG-git era pergunta em aberto.
3. **A voz do maestro não tem home** — e o único candidato próximo, `.claude/identity/` (RFC-0003), é para
   personalidade **emergente** (derivação one-way, gated), o *oposto* de visão **declarada autoral** (fonte).

## Decisão

### D1 — Plataforma: SSG-git (Astro), repo como SSOT `[aceito]`

Sweep orquestrado, **verificado na web (jul/2026)** com fontes, contra 7 critérios. O corte que decidiu não
foi "qual blog é melhor", mas **onde mora o dado canônico**:

- **Modelo A (headless-CMS: Ghost/WordPress/Hashnode)** — o dado vive num banco; a UI sempre convida a editar
  lá; KG-SSOT-first vira convenção imposta de fora, com imposto de export/sync.
- **Modelo B (SSG-git: Astro)** — o markdown no repo **é** o input nativo do motor; nada nasce só na
  plataforma, **por construção, não por convenção.**

Vence o **Modelo B / Astro**. A "fraqueza" (sem Admin HTTP API) é a propriedade *certa*: o build é só mais um
projetor derivado do grafo. Refinamento da metáfora WAHA do maestro: **WAHA é sobre infra própria e
descartável, não sobre HTTP** — e o SSG-git é *ainda mais WAHA* que o Ghost (sem servidor de app). `Forem/dev.to`
fica como **canal de sindicância descartável** (`canonical_url` → a fonte real). **Ghost fica gated** — só se
newsletter/membership/paywall virar requisito duro (aí paga-se o export/sync e a conversão lossy p/ Lexical,
conscientemente).

### D2 — Arquitetura: gerador determinístico agora, costura SDAAL declarada-não-implementada `[aceito / gated]`

Constrói-se **agora** o **gerador determinístico** que lê a fonte-no-repo e emite as superfícies estáticas —
`read(fonte)→verify(vivo)→act→write`, colapsando o drift ao litmus "edito em um". Justificado **sozinho** pelo
drift já provado (D-contexto-1), independente dos ensaios.

**Refinamento load-bearing (determinístico ≠ editorial):** o gerador **não** traduz diário-cru→prosa-leiga —
isso é curadoria editorial (LLM, 1× por post), não determinística. O pipeline separa os dois:

```
diário cru (voz framework, jargão)
   │  [curadoria editorial — LLM, 1× por post, "nunca dump verbatim"]
   ▼
post CURADO (FONTE estruturada: title, descobri, prova, levou, type, date, review, kg_refs)
   │  [GERADOR determinístico — sem LLM]
   ▼
migalhas/index.html  +  feed.xml  +  provas/index.html   (3 projeções, 1 fonte)
```

O gerador é determinístico para a **estrutura** (o que elimina o drift); a curadoria produz a **fonte curada**
(o que respeita "nunca dump verbatim"). Guardado como as demais SSOT geradas (drift-check no lint, à la
`inventory.sh`/`kg-view.sh`), aplicando a curadoria público-segura (repo privado → só metadado objetivo, zero
link de PR) e a REGRA 29 (todo claim projetado cita nó rastreável — `kg_refs:`).

A **costura SDAAL `blog-provider`** (`.claude/utils/blog/`) é **declarada** (`interface.md` + `none.md` =
`NoBlogAdapter` = o rsync-para-webroot de hoje) e **não implementada** até um 2º destino provar — espelhando o
forge com gitlab/bitbucket. Com SSG-git vencedor, a costura nasce **dormente** (git push é portátil → fica
fora da abstração, pela própria regra de fronteira do forge). O output do gerador é modelado como `PostOutput`
normalizado **desde já**, para graduação limpa sem refactor de shape.

### D3 — Voz do maestro: gênero-irmão do diário, nascimento gated `[gated]`

A voz do maestro nasce **reusando a máquina do diário** (frontmatter-YAML-first, índice gerado, enum-como-guarda,
`significance`, review-TTL) — *não* uma topologia nova. Eixo de autoria: **`author: marcio`** (nunca
`instance:` — o maestro não é instância trocável da federação), `genre: essay|vision|method`, **`lens: true`**
(a trava de honestidade: um ensaio JAMAIS se passa por prova), `kg_refs:` (proveniência), atribuição de voz por
bloco (`> voice: marcio` / `> voice: onion`) para a dobradinha renderizar vozes creditadas.

**Camadas da fonte (o que casa com KG-SSOT-first):** os *claims* falsificáveis nascem no `.kg.yaml` (SSOT,
sob a catraca da REGRA 29); a *prosa/postura* nasce no arquivo de ensaio (fonte autoral legítima — é *stance*,
não *finding*), desde que seus claims tracem para o grafo. O site `/ensaios/` é **derivado** — irmão da tríade
migalhas, nunca autorado no webroot.

**GATED (dogfood-honesto, não pré-cozinhar o contêiner):** o maestro escreve o **1º ensaio primeiro**, num
espaço mínimo existente; o contêiner formal (`journal/essays/`, o schema de gênero, o ramo do gerador) é
promovido **quando o uso provar a falta** — precedente do `type: reflection`, que entrou no enum *depois* de o
campo já o escrever. Não se desenha o contêiner antes do 1º ensaio real mostrar o que ele precisa.

## Alternativas rejeitadas

- **SDAAL pleno já** (5 docs + factory + detector para 1 destino self-hosted): **cerimônia à frente da
  substância — o erro do plano v4.0.** Rejeitado (`onion-dogfooding-doctrine.md`).
- **Estender o site à mão, puro** (só um lint de paridade): trata o *sintoma* (drift) sem eliminar a *fonte
  paralela*. O gerador é superior — paridade vira **estrutural** (uma fonte → N projeções), não policiada
  depois.
- **Ensaios em `docs/essays/` com KG próprio por ensaio** (Modelo 2 do design): mais spec-as-code, menos reuso
  do motor. Em aberto como seam, não escolhido — o reuso da máquina do diário é mais dogfood-puro no eixo que
  o maestro elegeu.
- **Ghost/WordPress como fonte**: o dado canônico migraria para um banco; KG-SSOT-first viraria convenção
  imposta. Ghost fica gated como *pouso*, nunca como fonte.

## Consequências

- **KG-SSOT-first ENFORÇADO, não só respeitado:** o litmus "edito em um" vira verdadeiro por construção; a
  REGRA 29 aplica-se mecanicamente sobre claims projetados.
- **Sobrevive a ambos os cenários de plataforma:** SSG-git → costura dorme; se um dia Ghost, → costura nasce
  com 1 adapter, **fonte e gerador intocados** (por isso `PostOutput` normalizado desde já).
- **Reversível:** deletar o gerador → cai no hand-authoring atual (nada se perde).
- **Custo front-loaded e honesto:** o gerador precisa respeitar curadoria público-segura + proveniência
  estrutural — o custo que *entrega valor*, pago em qualquer arquitetura.
- **Fronteira que este ADR crava (hazard do RFC-0003):** `.claude/identity/` = personalidade **emergente**
  (derivação, projeção one-way, `/meta:personality-sync`, gated) — **NÃO se funde** com a voz autoral do
  maestro (`ensaios/` = visão **declarada**, fonte). Eixos distintos; qualquer trabalho de identidade que
  toque os dois trata-os separados.

## Seams abertos (decisão futura do maestro)

1. Home física dos ensaios: `.claude/journal/essays/` (máximo reuso do motor) vs `docs/essays/` (spec-as-code).
   Recomendação: família `.claude/`. Decidir quando o 1º ensaio nascer.
2. Shape do KG-do-método: mesmo `.kg.yaml` do audit (`layer:` discrimina) vs KG por ensaio.
3. `revisit_after` dos ensaios (cutucão soft) vs o `review_after` obrigatório da migalha — a guarda ramifica
   por `genre`.
4. Vozes convidadas (Claude, Claude Code) como identidades em `members.yaml` — dogfood-gated: só quando o 1º
   ensaio real com aquela voz aterrissar.

## Status

**Aceito** para D1 (plataforma SSG-git/Astro) e D2 (gerador determinístico + costura declarada-dormente) —
execução começa agora, sobre as migalhas/provas existentes. **Gated** para D3 (contêiner de ensaios, até o 1º
ensaio real) e para a implementação da costura SDAAL (até o 2º destino de publicação).
