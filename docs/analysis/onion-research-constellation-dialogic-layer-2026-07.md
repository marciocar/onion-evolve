---
title: "Pesquisa — A camada dialógica da Constelação (prévia + auto-regulação) e a epistemologia qualitativo→quantitativo"
date: 2026-07-12
type: research
status: proposto
decision-scope: meta / modelo operacional de orquestração do maestro (estende a Constelação de Estudos)
supersedes: none
deciders: maestro + sessão de evolução (julgamento conjunto — nada promovido)
context_freshness: 2026-07-12
related:
  - ../knowledge-base/concepts/constellation-of-studies.md (o modelo que esta pesquisa estende)
  - onion-adr-constellation-operating-model-2026-07.md (o ADR dos 3 serviços atuais)
  - ../knowledge-base/concepts/knowledge-graph-sdaal.md (o motor qualitativo→quantitativo)
  - ../knowledge-base/concepts/authorization-layers-intake-vs-execution.md (intake×execução, sob convite)
  - ../knowledge-base/concepts/worklog-protocol.md (## NEXT / blocked_by — o self-report durável)
  - onion-plan-identity-kg-dogfood-2026-07.md (§2.6 Hegel Grenze/Schranke · §2.2 Bloom revisado)
---

# Pesquisa — A camada dialógica da Constelação

> **Status: PROPOSTO — design-only, gated, guardado para o futuro.** Nada aqui é construído; nada é promovido a
> doutrina. O julgamento passa por **NÓS** (maestro + core). Este doc **estende** o ADR da
> [Constelação de Estudos](onion-adr-constellation-operating-model-2026-07.md) com um candidato a **4º serviço** e
> a epistemologia que já opera por baixo dele.

## 1. Contexto — o vão que os 3 serviços não fecham

A Constelação hoje tem três serviços do observatório (core): 🗺️ **mapa** (lê o Tier-0 dos SEEDs), 🔬 **radar**
(reconcilia grafos entre estrelas), 📬 **carteiro** (entrega uma estrela ao core). Os três são sobre
*artefatos/metadados* e quase **uni-direcionais**. Falta um eixo **bidirecional e dialógico** sobre o *estado de
pensamento* em si:

- o core não tem como **pedir uma prévia** do que uma estrela está aferindo/decidindo/duvidando, pra ajudar no
  encaminhamento;
- a estrela não tem como **relatar os próprios incômodos** e se **auto-regular** com uma gramática compartilhada.

O gap foi confirmado na exploração: existe self-report durável (worklog `## NEXT`/`blocked_by`, diário
`error`/`conflict_class`) e um caminho estrela→core (carteiro + W6), mas **nenhum mecanismo de a estrela emitir uma
prévia dos próprios incômodos, nem de o core pedir uma**.

## 2. A tese — o 4º serviço dialógico (📻 boletim)

Um serviço bidirecional com **duas metades que são o mesmo objeto visto de dois lados**:

| Metade | Direção | O que é | Camada de liberação |
|---|---|---|---|
| **Prévia** | core → estrela (sob convite) | boletim: *aferido · decidido · dúvidas · possíveis problemas · o pertinente* | **intake** (ler/pedir estado epistêmico) — seguro, sob convite |
| **Auto-regulação** | estrela (intra) | a estrela roda um auto-check e **grava seus incômodos como nós** | a estrela mantém o próprio grafo (self→self) |

**Por que são o mesmo objeto:** ambos operam sobre o **`.kg.yaml` da estrela** — `claims` = aferido, `decisions` =
decidido, `questions` = dúvidas, arestas `REFUTES`/nós `open` = incômodos/problemas. A prévia é uma *leitura* desse
grafo; a auto-regulação é a *manutenção* dele. O grafo é o meio onde core e estrela se encontram — e é dogfood puro.

## 3. A epistemologia — qualitativo→quantitativo (o coração)

Incômodos, dúvidas e vereditos são **ações não-determinísticas, qualitativas**. O
[KG SDAAL](../knowledge-base/concepts/knowledge-graph-sdaal.md) as cristaliza em dado **rastreável e contável**:
`confidence` (0–1), `impact` (1–5), `status`, e o radar computa `atenção = impact × confidence × centralidade`
(peso do nó × grau — [`kg-radar.sh`](../../.claude/validation/kg-radar.sh)). Como diz o veredito F3 do dogfood de
identidade: **"a atenção sai do motor, não da impressão"**
([plano §F3](onion-plan-identity-kg-dogfood-2026-07.md)).

**O recorte honesto (o que salva isto de virar auto-engano):** o número **não torna o julgamento objetivo** — ele
o torna **explícito, endereçável e componível** (dá pra ranquear, rastrear, refutar; o radar cobra). Há **dois
quantitativos** no grafo:

1. **`confidence` atribuída** — julgamento cristalizado; uma *alça* sobre a intuição.
2. **evidência medida** — o **dogfood** real (ex.: os tokens/`tool_decision`/reject-rate capturados na N05 da
   estrela interface).

> **O dogfood é o motor que move um nó da alça atribuída para o número medido.** É por isso que "dogfoodar é o
> melhor caminho, e por isso criamos o Dogfood KG SDAAL": **o grafo segura o julgamento; o dogfood ganha o número.**

Isto responde diretamente à intuição do maestro — "dados qualitativos viram quantitativos" — com a precisão de que
o *quantitativo atribuído* é uma promessa que **só o dogfood quita**.

## 4. A gramática compartilhada — Aristóteles + Hegel + Bloom (como alavanca, não filosofia)

As estrelas se auto-regulam com três réguas que o Onion já usa (duas com casa canônica, uma sem):

- **Aristóteles — a régua de transferência:** *igual → transfere / diferente → desenha*. Bloqueia os dois erros
  simétricos: **falsa analogia** (forçar o novo no molde do velho) e **falsa distinção** (reinventar o que já
  transfere). É como a estrela decide se um achado externo entra.
- **Hegel — o incômodo como alavanca (movimento, não filosofia):** o **incômodo** (*Schranke*, o limite sentido
  como contradição) é o **sinal** de que a estrela precisa se mover/aprofundar/reconciliar; a **síntese**
  (*Aufhebung*) é o ato de reconciliar — nega, preserva e eleva — e a aresta `REFUTES` **permanece como cicatriz**.
  Já canônico: [plano §2.6](onion-plan-identity-kg-dogfood-2026-07.md) (Grenze/Schranke; "o KG é a técnica certa
  quando o conhecimento deixa de ser monotônico") + o diário
  [`hegel-limit-kg-boundary`](../../.claude/diary/2026-07-11-hegel-limit-kg-boundary.md).
- **Bloom revisado — o teto de esforço:** cada dúvida é etiquetada com o nível mais alto que exige (Lembrar…Criar);
  gasta-se esforço só até lá. Já canônico: [plano §2.2](onion-plan-identity-kg-dogfood-2026-07.md).

**Achado da exploração (candidato gated):** Hegel e Bloom têm casa canônica no core; **a régua de Aristóteles só
existe nas worktrees** (mais articulada em `discuss/onion-pessoal-marcio`, aplicada nas notas da interface). Pra
virar gramática **compartilhada** pelas estrelas, Aristóteles precisa de um lar canônico no core — **candidato
gated, não promoção agora**.

## 5. Composição — cada peça ESTENDE uma existente (nunca reinventa)

| Metade nova | Estende | Como |
|---|---|---|
| **Prévia** (core pede boletim) | doc-bridge `co-deliver.sh` (I3 + **W6 propor→confirmar**) + [authorization-layers](../knowledge-base/concepts/authorization-layers-intake-vs-execution.md) | pedir/ler é **intake sob convite**; qualquer *ação* sobre a prévia é execução (gated) |
| **Auto-regulação** (estrela grava incômodos) | [worklog](../knowledge-base/concepts/worklog-protocol.md) `## NEXT`/`blocked_by` + diário re-teste (`migalha vencida → re-testar`) | o self-report durável já existe; falta ligá-lo ao `.kg.yaml` como incômodo endereçável |
| **Boletim** (o objeto) | SEED Tier-0 (`phase`/`next_action`) + o **`.kg.yaml` da estrela** | Tier-0 é o metadado público; o grafo é o estado epistêmico; o boletim é a projeção dos dois |
| **Agregação** (macro, se um dia) | `federation-status-scan.sh` (`--json` determinístico) | mesmo molde do mapa (Fase 1 da Constelação) |

## 6. A prova viva — isto já teve o 1º dogfood

Dois passos antes deste doc, ao revisar a estrela **interface-state-of-art**, um refutador adversarial produziu
três incômodos qualitativos (o invariante "formativo" se auto-contradiz com o loop NS1; "exibir degrada skip" tem
furo quando o display alimenta um gate; "reversível=soft" não herda "externo=irreversível"). Esses incômodos foram
**dobrados de volta** ao `interface-state-of-art.kg.yaml` como **nós com `confidence` própria + arestas `REFUTES`**
nos invariantes (que seguem `open`). Resultado: o `kg-radar` passou a **acender 3 contradições não-reconciliadas**
(exit 1 de propósito) — a dívida ficou barulhenta e endereçada a NÓS.

**Isso é exatamente a camada deste doc, em miniatura:** incômodo qualitativo → nó quantitativo → radar cobra o
julgamento compartilhado. A camada dialógica é a **generalização** desse gesto único num protocolo.

## 7. Rollout faseado gated (as "sessões necessárias")

| Fase | Entrega | Gatilho | Sessões necessárias |
|---|---|---|---|
| **F0 — agora** | este doc + o `.kg.yaml`-dogfood da própria pesquisa + a prova viva | cumprido (o gesto já aconteceu) | esta sessão de evolução |
| **F1 — schema do boletim** | os campos da prévia (aferido/decidido/dúvidas/incômodos) como **projeção** de `.kg.yaml` + SEED | o maestro querer padronizar a prévia | 1 research + maestro |
| **F2 — ritual de auto-regulação** | o auto-check Aristóteles+Hegel que a estrela roda pra atualizar o grafo | ≥2 estrelas mantendo `.kg.yaml` **vivo** | dogfood numa estrela |
| **F3 — prévia sob convite (tooling)** | core pede o boletim; **reusa o carteiro** (I3 + W6) | o maestro pedir prévia à mão ≥2× | 1 build + maestro (gated) |
| **Aristóteles → core** | dar casa canônica à régua de transferência | F1/F2 pedirem a gramática compartilhada | 1 doc (candidato gated) |

## 8. O que explicitamente NÃO fazer agora (guardas anti-v4.0)
- **NÃO** construir o boletim/prévia como script, nem o ritual de auto-regulação, nem tocar o carteiro
  (design-alvo, gated por gatilho real).
- **NÃO** transformar `confidence` **atribuída** em "medição" sem dogfood real (honrar os dois-quantitativos).
- **NÃO** promover Aristóteles/Hegel a doutrina compartilhada nesta fase (candidato gated).
- **NÃO** mesclar esta pesquisa — fica pra julgamento conjunto.

## 9. Fronteiras (o que a camada dialógica NÃO é)
- **Não é o radar.** Radar = confrontar premissas rivais **entre** estrelas. A camada dialógica = prévia +
  auto-regulação **de uma** estrela (por-estrela), embora ambas leiam o mesmo `.kg.yaml`.
- **Não é vigilância da sessão.** A auto-regulação é a estrela observando a si mesma pela própria gramática — não o
  core bisbilhotando (a prévia é **sob convite**, intake).
- **Não é medição automática.** O quantitativo atribuído é uma alça; só o dogfood o converte em medida.

## 10. Resolução — a dúvida "sobrepõe o radar?" (2026-07-12, síntese)

A dúvida `Q_DIALOGIC_VS_RADAR` foi trabalhada e **resolvida por síntese** (o incômodo virou alavanca; no grafo:
`C_DIALOGIC_DECOMPOSED SUPERSEDES C_DIALOGIC_SERVICE`). Veredito:

**Ortogonal ao radar-da-constelação, mas reusa o motor-base — sobreposição é *reuso*, não competição.** A palavra
"radar" esconde dois: o **motor-base `kg-radar.sh`** (per-graph, roda em qualquer grafo) e o
**radar-da-constelação** (`kg-constellation-radar.sh`, Fase 2, roda no overlay cross-study). Os eixos são
distintos: a camada dialógica é **por-estrela** (n=1, dentro de um grafo); o radar-da-constelação é
**entre-estrelas** (n≥2, cruzando grafos). Decompondo a camada:

| Peça | Relação com o radar | Novo? |
|---|---|---|
| **Auto-regulação** (mecanismo) | **roda o motor-base `kg-radar.sh` no próprio grafo** (foi o que a dobra da interface fez) | não — motor existente aplicado a si mesmo |
| **Prévia** (boletim) | **vista agrupada-por-papel**; a seção "dúvidas/o-que-fazer-agora" **contém** o radar-base per-graph (superset) | fina — é uma projeção |
| **Ritual Aristóteles+Hegel** (autoria) | **upstream do radar** — produz os nós, não os ranqueia | **sim — o único conteúdo genuinamente novo** |

**Consequência de design (encolhe o escopo, baixa o risco anti-v4.0):** a camada **não é um 4º serviço
monolítico** — é uma **disciplina de autoria** (o ritual) + uma **vista fina** (a prévia), ambas cavalgando o
motor de radar que já existe. Isso *fortalece* "cada peça estende uma existente" e reduz o que haveria a construir.

## 11. Resolução — o ritmo do auto-check (2026-07-12)

A dúvida `Q_AUTOREG_RHYTHM` foi trabalhada e **resolvida dissolvendo a premissa**: "ritmo" assume um relógio, e
relógio manufatura teatro (auto-check em cadência fixa checa quando nada mudou → rubber-stamping, o anti-padrão
que a estrela interface marcou: "fadiga de aprovação é falha de segurança", "formativo, não performático").

**Veredito: não há bom ritmo — o gatilho é o evento.** O auto-check é **event-triggered**, ancorado nos momentos
onde uma decisão de Aristóteles/Hegel já está sendo tomada:

| Gatilho | Dispara quando | Régua |
|---|---|---|
| **Aristóteles @ intake** | conhecimento externo entra (transferir um achado) | igual→transfere / diferente→desenha — na transferência, não no relógio |
| **Hegel/Schranke @ contradição** | o novo contradiz/refuta/supera o velho (não-monotônico, §2.6) | o **incômodo é o gatilho** — quando uma aresta `REFUTES`/`SUPERSEDES` quer existir |
| **Backstop @ recolher** | no handoff (atualizar Tier-0 antes de rotacionar) — já acontece | varredura TTL de baixa freq. p/ incômodos latentes |

**Travas anti-teatro** (da interface + do diário): (1) **batch por unidade lógica**, nunca por-edit; (2)
**dogfood-gated, não click-gated** — o backstop **re-testa, nunca re-carimba** (`/meta:diary review`); (3) a fadiga
é **mensurável** — `blocked_on_user` subindo sinaliza que virou teatro. **Consequência:** os três gatilhos já
acontecem → *piggyback* = zero cadência nova, nada a construir; estende `/meta:diary review` + o recolher do
worklog + o critério §2.6.

## 12. Resolução — o schema do boletim + a projeção sem expor o corpo (2026-07-12)

A dúvida `Q_PREVIA_SCHEMA` foi trabalhada e **resolvida** (com um resíduo gated, honesto, abaixo). O boletim é uma
**projeção por-papel** do `.kg.yaml` + SEED Tier-0:

| Seção do boletim | Vem de |
|---|---|
| **fase · próximo passo** | SEED Tier-0 (`phase` · `next_action`) |
| **aferido** | `claim`/`evidence` com `status: confirmed` (label + confidence) |
| **decidido / decidindo** | `decision` — `confirmed` / `open` |
| **dúvidas** | `question` `open`, ranqueadas por atenção = o "o que fazer agora" do RADAR |
| **incômodos / problemas** | RECONCILIAÇÃO (`REFUTES`/`SUPERSEDES`) + contradições não-reconciliadas |
| **saúde** | INTEGRIDADE (nº nós/arestas, pendências, exit) |

**A projeção sem quebrar o isolamento:** a fonte é **o `.kg.yaml` + o SEED Tier-0, nunca o corpo (`NOTE-*.md`)**.
Régua de Aristóteles: o `.kg.yaml` é *igual* a metadado (distilado estruturado, tipado, curado pelo autor, já
construído pra compartilhar — é o insumo do radar) → transfere "metadado é intake seguro"; é *diferente* do corpo
(prosa Tier-1→3) → privado, sob convite. Logo **o `.kg.yaml` é a face epistêmica pública da estrela** (como o SEED
é seu Tier-0 público). Três travas: (1) **só labels + scores**, nunca a prosa; (2) **determinístico** (molde
`federation-status-scan --json`) — o core formata o que o motor computa, não interpreta; (3) **read-only, sob
convite** (intake). **Consequência:** zero motor novo — o boletim é `kg-radar.sh` + SEED reformatado; a Fase 1 é um
formatador fino, gated.

**Resíduo gated (honesto):** isso **estende** a linha só-metadados (hoje "frontmatter + Tier-0") para incluir o
`.kg.yaml` como superfície pública. Essa extensão **precisa de ratificação** (candidato gated, não promoção) —
registrada no grafo como `D_ISOLATION_EXTENSION_GATED` (`open`). É a próxima decisão nossa, se a Fase 1 abrir.
