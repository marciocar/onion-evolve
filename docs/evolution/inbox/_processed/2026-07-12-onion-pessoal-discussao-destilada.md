---
title: 'Sinal destilado — a discussão Onion pessoal (5 passadas) produziu candidatos-a-doutrina gerais'
date: 2026-07-12
from: discuss/onion-pessoal-marcio (fonte de discussão isolada)
to: onion-evolve (sala de design)
re: docs/discussions/onion-pessoal-marcio/README.md · PR #343
type: discussion-distillation
status: candidatos (triagem gated — nada promovido)
---

# Sinal upstream — o que a discussão Onion pessoal revelou de reutilizável

> **Destilado, não bruto.** A discussão em si (um Company Brain N=1 para o Marcio) é **isolada e
> intra-órbita** — prova o **método**, não o **mercado** — e permanece em `docs/discussions/onion-pessoal-marcio/`.
> Este sinal extrai só o que é **geral** (candidato a virar doutrina do core), com ponteiros. **Nada aqui é
> decisão:** a triagem/aceite é de uma sessão gated do core (validação adversarial = insumo, não ordem).

## Contexto

5 passadas (P1–P5) fecharam as 4 perguntas do SEED + a fronteira aberta. Método idêntico em toda passada:
**pesquisa orquestrada citada → derivação `fonte≠derivação` → proto executável (`.kg.yaml` que passa no
`kg-radar`)**. ~200 fontes; cada síntese passou por verificação adversarial (que derrubou citações fabricadas).
Índice: [`docs/discussions/onion-pessoal-marcio/README.md`](../../../discussions/onion-pessoal-marcio/README.md).

## Candidatos-a-doutrina (o que pode transferir para o core)

1. **A lente Aristóteles+Hegel como primitivo de análise.**
   - **Aristóteles (a régua):** *tratar igual o que é igual, diferente o que é diferente* → em toda decisão de
     transferência/analogia, declarar **IGUAL→transferir / DIFERENTE→desenhar fresco**, com evidência. Evita
     falsa analogia (forçar) e falsa distinção (reinventar). Generaliza "adota, não impõe" e qualquer pergunta
     "X transfere para Y?".
   - **Hegel (o motor):** a *Aufhebung* (nega+conserva+eleva) **já é** a regra append-mostly do KG SDAAL
     (refutado permanece, superado-preservando). Nomear a correspondência dá vocabulário ao que o radar já faz.
   - **Candidato:** KB de conceito ou nota em [`onion-relation-vocabulary`](../../../knowledge-base/concepts/onion-relation-vocabulary.md) / método de análise.

2. **"Self-red-team = dogfood aplicado à saída."**
   - Rodar o **próprio motor do artefato como atacante** contra o que ele vai emitir, **antes** de emitir; se
     deduz o que deveria ficar oculto, não emite. É a doutrina de dogfood (rodar o artefato de verdade,
     tratar veredito como hipótese) virada **gate de pré-emissão**.
   - **Candidato:** nota em [`onion-dogfooding-doctrine`](../../../knowledge-base/concepts/onion-dogfooding-doctrine.md).

3. **"Convergência interna × externa" como sinal de validação.**
   - 3× (P3/P4/P5) a doutrina que o Onion já tem bateu, **sem se conhecer**, com o consenso externo de 2026
     (local-first + destilado; fail-safe; "errar para não-vazar"). Quando a doutrina interna e a arte externa
     convergem independentemente, é evidência forte de que a doutrina está certa — um teste barato a nomear.
   - **Candidato:** nota metodológica (onde a pesquisa de mercado valida o core).

4. **O workflow de discussão isolada, validado end-to-end.**
   - "research → derivation (`fonte≠derivação`) → executable proto (`kg-radar`)" rodou 5×, com o proto se
     auto-provando (nó mais central = a tese-núcleo). Complementa o [`discussion-worktrees-pattern`](../../../knowledge-base/concepts/discussion-worktrees-pattern.md)
     existente com o **método interno** de cada passada.
   - **Candidato:** estender a KB de discussion-worktrees com o playbook das passadas.

## Gaps REAIS do core que o exercício expôs (não N=1-específicos)

- **Adoção de domínio NÃO-software:** `/meta:adopt` e `docs/applying/` só adotam **repos de código**. O
  Onion pessoal exigiria adotar um repo que hospeda um **KG de vida** — não há caminho. Candidato a ADR/escopo
  de comando futuro (gated).
- **Verifiable Credentials como destilado verificável:** a federação troca "destilado, nunca o bruto" — VC
  (SD-JWT/BBS, W3C 2025) é o mecanismo maduro de **provar um fato sem entregar a fonte**. Peça candidata para
  o `exposes:`/co-evolução (P3/P4).
- **Inferência sobre KG lido pelo próprio LLM não tem defesa publicada** (P5): relevante para qualquer
  instância que rode um modelo sobre dado sensível — o freio é **negativo** (fronteira de acesso + não-emissão),
  não cifra. Candidato a nota de threat-model.

## O que NÃO fazer com este sinal

- **Não** promover o conteúdo N=1 ao core (é isolado por contrato).
- **Não** tratar nada como decidido — são candidatos; o aceite exige uma sessão de triagem com evidência.
- Lembrar o **caveat intra-órbita**: a discussão prova o método, não a demanda de mercado.

---

## Triagem do core (2026-07-12)

- **Status:** processado. O candidato principal foi **promovido sob convite**; o restante **segurado
  deliberadamente** pelo core (não é rejeição — é sequenciamento).
- **Roteamento:**
  - **Lente Aristóteles (régua+motor) → PROMOVIDA.** Virou a KB `transfer-heuristic-aristotle` (mesclada em
    `main`) e foi **fiada no `/meta:adopt`** (decisão reuse-vs-fresh), com o carimbo *"earned by use, draw from
    pessoal-marcio"* — usando esta discussão como **fonte + prova viva** (a régua pegando a própria falsa
    distinção da estrela). Commits `0dcacbb` / `e0b2d6a` / `68c2e1f`; overlay `constellation.kg.yaml` registra
    como **acordo + enriquecimento**, não contradição. Boletim downstream de retorno arquivado em
    `inbound/_processed/2026-07-12-boletim-core.md`.
  - **Restante → SEGURADO / `assess`** (self-red-team = dogfood-na-saída · workflow de discussão · Aufhebung =
    append-mostly · gaps G1 domínio-não-software / G2 Verifiable Credentials / G3 inferência-sem-defesa). Decisão
    do core: **segurar a promoção até o sensor (`behavior-mapping`) e o loop (`interface`, já promovido #344)
    firmarem a base.** Alinha com a recomendação de triagem original (`assess`, nada bloqueante).
- **Caveat mantido:** intra-órbita — a discussão N=1 prova o método, não o mercado; segue isolada.
