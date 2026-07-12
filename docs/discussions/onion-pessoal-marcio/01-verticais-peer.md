---
title: "P1 — As verticais peer de uma pessoa (Onion pessoal)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/onion-pessoal-marcio
lente: "Aristóteles (a régua) + Hegel (o motor)"
ancora_pesquisa: research/SYNTHESIS.md
---

# 🧵 P1 — As verticais peer de uma pessoa

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Este documento é **derivação** (camada 2): consome a pesquisa ([research/SYNTHESIS.md](research/SYNTHESIS.md),
> ~65 fontes verificadas adversarialmente) e o proto ([proto/](proto/)), **cita e nunca reescreve** a teoria.

A pergunta de partida do SEED era *"quais são as verticais peer de uma pessoa? (carreira/saúde/aprendizado/relações?)"*.
A pesquisa mostrou que a pergunta, do jeito que estava, **estava mal-posta** — e a resposta certa é mais interessante
que uma lista.

---

## A régua e o motor

Duas âncoras clássicas regem tudo (detalhe em [proto/theories/hegel-dialectics.md](proto/theories/hegel-dialectics.md) e na §7 da síntese):

- **Aristóteles — a régua** (*Ética a Nicômaco* V): *tratar igual o que é igual, diferente o que é diferente*.
  É o critério de transferência. Barra os dois erros gêmeos: **falsa analogia** (forçar a pessoa a caber no molde
  da organização) e **falsa distinção** (reinventar o que já transfere).
- **Hegel — o motor** (*Aufhebung*: negar+conservar+elevar): a contradição **gera** desenvolvimento, não é defeito.
  Explica *por que* verticais que se contradizem são generativas. Importa-se o **operador**, **recusa-se o telos**
  (o Espírito Absoluto, o fim garantido) — "dialético-no-passo, darwiniano-na-trajetória".

---

## 1. Verticais se **derivam**, não se postulam

Carreira/saúde/aprendizado/relações era um **chute** — razoável, mas chute. Assim como negócio/técnica/compliance
foram *descobertas* como as verdades peer irredutíveis de uma organização de software, as verticais de uma pessoa
têm que sair de **modelos acadêmicos validados do humano inteiro**, sob a disciplina **`fonte≠derivação`**
([concept do core](../../knowledge-base/concepts/source-vs-derivation.md); litmus: "se a fonte mudar, edito em quantos
lugares? → **um**"). Por isso o proto separa fisicamente [`proto/theories/`](proto/theories/) (a teoria fiel, zero
Onion) de [`proto/applications/`](proto/applications/) (a nossa derivação, que cita).

O material das verticais **transfere** dos modelos — mas com um filtro: os que passam a régua são os **cross-culturais
deliberadamente não-WEIRD** (WHOQOL, 15 culturas; capacidades de Nussbaum), não os construtos de bem-estar anglófonos
(PERMA ≈ Ryff medem largamente a mesma coisa; a crítica WEIRD diz que qualquer taxonomia "default" carrega pesos
ocidentais). Ver [proto/theories/whole-person-models.md](proto/theories/whole-person-models.md).

---

## 2. O teste de peer — agora com dente operacional

Uma vertical é **peer** sse:

1. **irredutível** — não se reduz a outra sem perda;
2. **pode contradizer** as outras — é a contradição que gera o trabalho de reconciliação (Hegel);
3. **não-subordinável** — subordiná-la a outra perde informação.

A pesquisa deu a esse teste um **dente operacional** e uma **fundação honesta**:

- **Dente (diagnóstico):** o colapso psicométrico do modelo de Ryff (4 dos 6 fatores viram **1** em survey grande —
  Springer & Hauser, 2006) vira um teste: **dois candidatos a vertical com correlação r>0,7 são o mesmo eixo**, não
  dois peers. É o "funde ou mantém" mensurável.
- **Fundação (honesta):** a irredutibilidade **não se sustenta na psicometria** — a psicometria mede covariância e,
  quando os fatores correlacionam, conclui "mesmo construto"; ela **nunca testa a pré-condição peer**. Quem sustenta
  a irredutibilidade+incomensurabilidade é a **filosofia**: as 10 capacidades de Nussbaum + o pluralismo de valores
  de Berlin (bens plurais, incomensuráveis, com "perda trágica"). **Consequência que carregamos com honestidade:** a
  verticalidade-peer é **filosoficamente fundamentada, psicometricamente não-testada**.

---

## 3. A descoberta estrutural: vertical × eixo transversal × decomposição ortogonal

Aqui a P1 muda de forma. Nem tudo que parece "uma vertical" é uma vertical. A pesquisa separou **três coisas
diferentes** que o instinto funde — e tratá-las igual seria falsa analogia:

| Estrutura | O que é | Exemplos | Papel |
|---|---|---|---|
| **Vertical de conteúdo** | um domínio de vida irredutível | Relações, Trabalho, Sentido, Saúde | o **quê** — os peers em tensão |
| **Eixo transversal** | atravessa e re-pondera todas as verticais | autonomia/competência/relação (SDT); cultura/valores | o **como/quanto** — não é aba |
| **Decomposição ortogonal** | aplica-se *dentro* de cada vertical | competência (C/H/A: cada domínio tem seu Conhecimento·Habilidade·Atitude) | a **anatomia** de cada peer |

Três vereditos concretos que caíram da pesquisa:

- **Competência (CHA/skills) é decomposição ortogonal, não vertical** — a própria WHO/UNICEF decompõe saúde, relações,
  finanças em Conhecimento·Atitude·Habilidade; competência é *skill × contexto*. Ver
  [proto/theories/competency-cha.md](proto/theories/competency-cha.md).
- **Cultura/geografia/crenças é eixo de ponderação, não vertical** — o peso preditivo de cada domínio *muda com a
  cultura* (Oishi et al., 1999). Exceção parcial: religião/espiritualidade tem **dupla natureza** (vertical para quem
  a vive como tal, lente para quem a usa como interpretação). Ver [proto/theories/culture-as-axis.md](proto/theories/culture-as-axis.md).
- **Autonomia é eixo, não vertical** — SDT a trata como necessidade *content-free* que se experimenta *dentro* de
  qualquer domínio. Listá-la como aba (Ryff, Wheel of Life) é **erro de categoria**.

> A resposta à P1, então, não é "a lista de N verticais". É uma **arquitetura**:
> **verticais de conteúdo (por domínio) × C/H/A (ortogonal, dentro de cada uma) × cultura/valores (ponderação transversal)**.

---

## 4. O modelo candidato (PLAUSÍVEL / open — não cravado)

Derivado da convergência acadêmica, marcado **PLAUSÍVEL** — o modelo vive, executável, em
[proto/applications/vertical-model-pessoal.md](proto/applications/vertical-model-pessoal.md) e como grafo de domínio em
[proto/marcio.kg.yaml](proto/marcio.kg.yaml).

**Núcleo convergente (reaparece em quase todo modelo — conf alta):**

- **Relações/vínculo** — SDT-relacionamento, PERMA-R, Ryff, WHOQOL-social, Nussbaum-afiliação
- **Trabalho/realização** — PERMA A+E, Locke & Latham, skills-graph
- **Sentido/propósito** — PERMA-M, Ryff-propósito, Nussbaum-razão-prática, ikigai
- **Saúde/vitalidade** — WHOQOL-físico, Nussbaum vida/saúde-corporal

**Questões abertas (deixadas abertas de propósito):**

1. **Recursos/finanças é vertical peer?** Só WHOQOL/Nussbaum a isolam; some dos modelos de bem-estar. Provável *sim*
   por irredutibilidade, mas sub-teorizada. **Aberto.**
2. **Espiritualidade é vertical, eixo, ou dupla-natureza?** Recomendação: **domínio opcional de dupla natureza**. **Aberto.**
3. **Vitalidade = 1 ou 2?** Saúde física vs energia psicológica podem ser uma ou duas — o teste r>0,7 decide. **Aberto.**
4. **Autonomia = vertical ou eixo?** Tendencialmente resolvido: **eixo**. (mas é o erro de categoria mais comum)
5. **Competência = vertical ou decomposição?** Resolvido: **decomposição ortogonal**.

---

## 5. O diferenciador não é a lista — é a reconciliação

Todo second-brain tem "áreas da vida". O que torna isto **Onion** (o combo que a pesquisa achou **desocupado para
N=1** — §9 da síntese) é a **reconciliação determinística com reconciliador explícito**, não a captura nem a lista.
E ela tem base sólida:

- **Motor DEV↔PROD = intenção × comportamento.** A lacuna intenção-ação é robusta (r≈.53) e — o achado operacional —
  **assimétrica**: os "inclined abstainers" (quem pretende e **não** faz) são ~7× o caso oposto (Sheeran & Webb, 2016).
  Isso é *literalmente* a célula **intenção-alta × comportamento-ausente** — o schema do confronto DEV (declarado) ×
  PROD (vivido). Uma `decision` só vira `done` verificada em PROD. Ver [proto/theories/behavior-intention-action.md](proto/theories/behavior-intention-action.md).
- **O operador é hegeliano.** Quando dois domínios colidem, a reconciliação certa **não apaga um lado** (o "nada"
  abstrato) nem faz média morna — **nega+conserva+eleva**, deixando rastro determinado do conflito. Isto **já é** a
  regra *append-mostly* do KG SDAAL (claim refutado permanece, superado-preservando). Aufhebung dogfoodada.
- **O discriminador que ninguém tem.** A tensão **Priest × Brandom** — contradição-que-eleva (dialetheia produtiva,
  ex.: "valorizo autonomia" × "valorizo pertencimento", tensão viva legítima) vs incompatibilidade-material-que-resolve
  (ex.: "reunião às 14h" × "às 16h", bug a corrigir) — é o **discriminador contradição-motor vs contradição-bug** que
  o motor precisa e que a literatura **não** entrega. Território a desenhar.

> Isto é **sinalizado** aqui, não desenvolvido — a P1 é sobre as verticais. O motor de reconciliação é a **P2**
> (metas × ações), e o **sensor** que alimenta o comportamento vivo é a discussão irmã `discuss/behavior-mapping-kg`.

---

## 6. Transformer + Onion — por que o KG, e não só o chat

O ganho de tratar a pessoa como person-KG (e não deixar tudo na cabeça do modelo) é **grounding ≠ guidance**: o KG
**aterra** o raciocínio do transformer sobre "você" em estrutura verificável e reconciliada, em vez de deixá-lo
**alucinar** sobre a pessoa. A pesquisa confirmou que RAG/GraphRAG puro **alucina em raciocínio temporal implícito** —
o que *legitima* a camada determinística (arestas tipadas + radar) **acima** da recuperação. O transformer gera; o
grafo e o gate decidem o que é verdade reconciliada.

---

## 7. Dogfood Extreme × caveat intra-órbita — o que isto prova, e o que não prova

Marcio é o 1º membro federado e o dogfood natural. **Onion Dogfood Extreme:** seus negócios são reais e
independentes — não foram criados para provar o Onion; resistem à doutrina. Essa independência **eleva a qualidade**
do dogfood (a doutrina tem que sobreviver a domínios que não foram feitos pra ela). Mas é preciso separar dois eixos,
com a dureza que a própria síntese impôs (§11):

- **O que PROVA:** é a 1ª prova viva **recursiva do NS1** (conhecimento reconciliável vivo, multi-vertical, sobre um
  sujeito real). Legítimo e valioso.
- **O que NÃO prova:** `Q_COLD_ADOPTER` — pull de mercado **fora** da órbita. Marcio *é* o centro da órbita; N=1-do-criador
  é validação intra-órbita **no limite**. Prova o **método**, não o **mercado**. O gap desocupado é **hipótese fundada,
  não fato verificado**.

Fingir que N=1-do-criador resolve o Q_COLD_ADOPTER seria **falsa distinção às avessas** — e auto-engano. A honestidade
aqui é o que mantém o dogfood *extreme* em vez de *cosmético*.

---

## Sub-perguntas abertas (o que a P1 deixa para as próximas passadas)

- **P2** — o que reconcilia: metas × ações (motor DEV↔PROD), decisões passado × presente (SUPERSEDES). O discriminador
  Priest×Brandom vira desenho.
- **P3** — fronteira com o core: o Onion pessoal é instância adotante na federação, ou algo à parte (privado)?
- **P4** — privacidade/soberania: classificação **por vertical** (saúde/relações >> carreira), `de-identification`
  `none` fail-safe, `exposes:`. O precedente `granaai` (regulated, trust zerado) já existe.
- Dentro da P1, ainda: Recursos peer? Espiritualidade dupla-natureza? Vitalidade 1 ou 2?

## Como inspecionar o proto (dogfood do próprio argumento)

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/marcio.kg.yaml
```

Esperado: **INTEGRIDADE exit 0**; **RECONCILIAÇÃO** mostra a aresta `REFUTES` (o declarado×vivido de saúde, superado-não-deletado);
**RADAR-DE-DOMÍNIO** aponta lacunas — o que é *esperado e desejável* num esqueleto-hipótese (vira a agenda da P2).
