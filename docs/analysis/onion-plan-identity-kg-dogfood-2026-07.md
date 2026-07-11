---
title: "Plano — Dogfood KG SDAAL para (re)construir o conhecimento das verticais do Onion Evolve"
category: meta
tags: [kg-sdaal, dogfood, identidade, icp, north-star, verticais, spec-dogfood-code, bloom-revisado]
status: plano-aberto
date: 2026-07-11
autor: maestro (Marcio) + onion (síntese)
supersedes: none
feeds: [docs/business-context/, docs/technical-context/, docs/knowledge-base/meta/onion-framework-identity.md]
---

# Plano — Dogfood KG SDAAL para (re)construir o conhecimento das verticais

> **O momento.** Chegamos a um lugar onde poucos chegaram com IA generativa: uma federação viva
> (`members.yaml`, co-evolução em 3 fluxos), Spec-Dogfood-Code rodando, KG SDAAL soberano e dogfoodado
> em produção. Este documento não responde às perguntas abertas — **estabelece o método** para respondê-las
> sem entortar doutrina, na ordem que importa, no momento que importa. É o "primeiro plano" que dá início
> ao processo de reaprender **como o Onion constrói conhecimento**.

---

## 1. A tese central (o que estamos estabelecendo)

**Padrão novo (ABERTO, candidato):** o Onion passa a construir o conhecimento das suas verticais
(negócio, técnica, produto) **como um Knowledge Graph SDAAL vivo** — não como prosa em docs soltos.
Pesquisa densa entra como `claim`/`evidence`/`decision` tipados; contradição vira aresta `REFUTES`;
verdade que envelhece vira `SUPERSEDES`; o **radar determinístico** (`kg-radar.sh`) produz o veredito de
atenção/priorização. A prosa (KBs, business-context) é a **materialização** do que o grafo já reconciliou,
não o lugar onde a verdade é decidida.

**Por que agora é dogfood, não teoria:** o `/meta:kg` + `kg-radar.sh` já existem e já auditaram *verdade
de produção* (WRR/rhilo, `onion-evolution-2026-07.kg.yaml`). Apontá-los contra a **própria identidade e
estratégia do Onion** é o próximo dogfood natural — e o mais valioso, porque força o método a servir o caso
mais difícil (conhecimento de negócio, não só de código).

**Descoberta que fixa a ordem:** `docs/business-context/` e `docs/technical-context/` estão **vazios** (só
README). Não há SSOT de negócio a proteger — há SSOT a **nascer**. Logo: primeiro o **método + o grafo**,
depois o preenchimento das verticais a partir do que o grafo reconciliou. Não se preenche uma vertical com
prosa antes de a verdade estar reconciliada no grafo.

---

## 2. Princípios-guarda (as barreiras que impedem o boil-the-ocean)

### 2.1 Não entortar doutrina para caber na tese
"Lane de framework/conhecimento" **e** integração GitFlow **coexistem** — servem a coisas diferentes
(conhecimento vs versão/entrega). RFC-0005 já crava: **versão × escopo são eixos separados**. Aplicamos a
força do que já existe (GitFlow, worktrees, KG, SDAAL) a cada caso pelo que ele é — não forçamos um eixo a
explicar o outro. As perguntas de branch (main-produto × rhilo/main × develop) entram como **claims a
reconciliar no grafo**, não como tese a defender.

### 2.2 Bloom revisado como medidor de esforço (a barreira de profundidade)
Fonte: taxonomia revisada de Anderson & Krathwohl (paper SciELO fornecido pelo maestro). Cada pergunta de
pesquisa é etiquetada com o **nível mais alto que ela realmente exige** — e gastamos esforço só até lá:

| Nível | Verbo | Uso no KG | Custo/barreira |
|---|---|---|---|
| **Lembrar** | recuperar | já está no grafo/KB → citar, não repesquisar | ~0 (evidência existente) |
| **Entender** | explicar | resumir/mapear o que já sabemos | baixo |
| **Aplicar** | usar | rodar o radar, aplicar convenção existente | baixo |
| **Analisar** | relacionar | confrontar verdade×verdade (arestas) | médio — é aqui que o KG brilha |
| **Avaliar** | julgar | veredito de priorização (radar + maestro) | médio-alto (gate humano) |
| **Criar** | desenhar | north-star, padrão novo, spec | alto — só com base analisada |

**Regra anti-desperdício:** uma "super-pesquisa" nível *Criar* sobre algo que o grafo responde no nível
*Lembrar* é retrabalho. Pesquisa que **não retroalimenta o KG** (não vira claim/evidence) é revista antes
de rodar. Conhecimento é conhecimento; a inferência é a **ponte** — e ela é escassa, então se usa onde
falta conhecimento, não onde já se tem.

### 2.3 Breadcrumbs tipados a favor do fluxo do transformer
Cada tipo de rastro serve um momento diferente do transformer (prefixo estável cacheável vs cauda volátil;
aresta tipada vs prosa). Não misturar:

| Breadcrumb | Papel | Quando |
|---|---|---|
| **Diário / migalha** | narrativa datada, compartilhável, "o momento aconteceu" | ao vivo, append-only |
| **Sinal inbox/inbound** | pergunta/veredito entre instâncias da federação | cross-instância |
| **KG `claim/evidence/decision`** | verdade tipada, confrontável pelo radar | conhecimento reconciliável |
| **`STATE.md` / `notes.md`** | estado retomável de trabalho (Tier-0) | execução faseada |
| **Analysis (este doc)** | plano/diagnóstico que alimenta verticais | decisão de rumo |

### 2.4 SSOT protegido, mas não cego
O SSOT (specs L0, `members.yaml`, KBs canônicas) é protegido — mas só **promove** para ele o que o grafo
marcou `confirmed` e o que maturou por uso (gated-until-trigger, a doutrina que fez o `/meta:kg` nascer
*depois* do dogfood, não antes). Verdade não-confirmada mora no grafo (candidata), não no SSOT.

### 2.5 Realismo — não dá para fazer tudo de uma vez
O plano é faseado e retomável. Fases baratas primeiro (método + seed do que já sabemos), a cara (pesquisa
densa orquestrada) **gated** por opt-in explícito. Cada fase deixa valor mesmo se pararmos ali.

### 2.6 Critério do limite (Hegel) — quando `.kg.yaml` vs. outras técnicas
Fonte validada: Hegel, *Ciência da Lógica* — distinção **Grenze** (limite: a determinação *positiva*, o
que uma técnica **é** boa em fazer) × **Schranke** (barreira: o limite posto como negativo a ultrapassar).
Núcleo (citado): *"a inquietude do algo em seu limite… a contradição que impele o algo para além de si
mesmo."* No limite, a coisa **é e não-é** ao mesmo tempo — por isso é difícil dizer quando X vira Y. A
fronteira não é uma linha fixa; é a **sede da inquietude**.

**Refinamento decisivo (quase-refutação da leitura ingênua):** NEM todo rastro está destinado a virar
grafo. A passagem só ocorre quando a **Schranke** aparece — quando há **contradição real**. Sem
contradição, cada técnica repousa no seu Grenze e basta. Pré-transformar tudo em `.kg.yaml` seria a
"super-pesquisa que não alimenta o KG" (§2.2). Deixamos cada técnica no seu limite positivo até ela
*provar* que chegou na barreira.

**Critério operacional** (cai limpo de Hegel + da doutrina de campo *"git merge não reconcilia verdades"*):

> **`.kg.yaml` é a técnica certa exatamente quando o conhecimento deixa de ser monotônico** — quando o
> novo não *soma* ao velho mas o **contradiz, refuta ou supera** (`REFUTES`/`SUPERSEDES`), ou quando duas
> linhagens acreditam em verdades rivais. Abaixo de "Analisar" (Bloom §2.2), não há KG.

| Técnica | Seu *Grenze* (repouso) | Sua *Schranke* (falha → passa ao KG) |
|---|---|---|
| Diário/migalha | cronologia: "o que aconteceu, quando" | não confronta verdade×verdade |
| Prosa (KB, analysis) | síntese **já reconciliada** | não segura contradição sem **apagar** (editar reescreve a história) |
| Task manager | o que **fazer** | não guarda o que é **verdade** |
| GitFlow/branch | reconciliar **código no tempo** (eixo versão) | não reconcilia **verdades** (epistêmico) |
| `.kg.yaml` | contradição viva: `REFUTES`/`SUPERSEDES` + radar | — (é a técnica *de* inquietude) |

**Evolução separada do KG (Aufhebung):** KG e prosa não são a mesma coisa em maturidades diferentes — são
dois momentos da dialética. O **KG é a inquietude sendo trabalhada** (sustenta a contradição até o radar
reconciliar); a **prosa/SSOT é a superação** que *nega + preserva + eleva* (a aresta `REFUTES` **permanece**
no grafo — "história reconcilia, não apaga"). Por isso o KG evolui num eixo próprio: a inquietude é
perpétua; a prosa é sempre o instantâneo do último repouso. Corolário: `business-context/` vazio não é
dívida — a vertical **repousa** quando o grafo tiver inquietação suficiente reconciliada, não antes.

> 🧵 **Fio a puxar (lente hegeliana ampla):** o limite é só uma das estratégias de Hegel úteis aqui. A
> *Ciência da Lógica* inteira (ser→essência→conceito), o **Espírito Absoluto** (auto-conhecimento que
> retorna a si enriquecido — espelho do loop dogfood→KG→SSOT→dogfood) e a dialética senhor-escravo (quem
> produz conhece) são candidatos a lentes de método. Registrado no diário
> [`2026-07-11-hegel-limit-kg-boundary`](../../.claude/diary/2026-07-11-hegel-limit-kg-boundary.md) para
> retomar o fio. **Não** aprofundar agora — é fio de F4/estudo, não de execução.

---

## 3. O que já sabemos (seed do grafo — trabalho de hoje, nível *Lembrar/Analisar*)

Antes de pesquisar o novo, o grafo ingere o que a exploração de 10-11/07 já produziu (evita repesquisar):

- **Identidade canônica** (`onion-framework-identity.md`, `CLAUDE.md`): framework template em `.claude/`,
  3 dimensões peer (produto/engenharia/compliance), plataforma única Claude Code, não-npm/não-CLI.
- **Branch-methodology (diagnóstico neutro de hoje):**
  - RFC-0004 = federação inter-instâncias (não trata do trio de branches interno).
  - RFC-0005 = herança de escopo; **rejeita branch-como-escopo**; branch fica no eixo versão.
  - Parecer de 03/07 = modelo de 2 linhagens (`framework`/develop × `production`/rhilo/main), 3 Movimentos
    (Mov.1 pendente); a `main`-produto **não** está no mapa.
  - **Correção factual (git):** a premissa "3 branches disjuntas desde 15/06" é falsa — `develop` e
    `rhilo/main` compartilham base em `05f96a05` (01/07); `main` **tem** framework (239 arq `.claude/`),
    não está vazia; está apenas parada (26/06). → Estes viram claims com `REFUTES` ao framing original.
- **Verticais de contexto:** `business-context/` e `technical-context/` vazios (greenfield).

---

## 4. Plano faseado

### F0 — Método & moldura  ·  *agora, barato*  ·  nível Entender/Aplicar
- [x] Este documento (o método + as barreiras + a ordem).
- [ ] Decidir slug e local do grafo: `docs/onion/graph/onion-identity-<slug>.kg.yaml` (camada `domain`
      para a vertical de negócio; `audit` para reconciliar as branches).
- [ ] Etiquetar cada pergunta da F2 com seu nível Bloom-teto (§6) — o gate de esforço.

### F1 — Seed do grafo com o que já sabemos  ·  *barato*  ·  nível Analisar
- [ ] `/meta:kg novo onion-identity-2026-07` → ingerir os claims do §3 (identidade + branch-diagnosis +
      correções factuais como `REFUTES`).
- [ ] Rodar `kg-radar.sh` → primeira leitura de atenção/lacunas. Já produz valor: mostra **o que falta
      saber** antes de gastar pesquisa cara.

### F2 — Pesquisa densa "o que somos de verdade"  ·  *cara, GATED por opt-in*  ·  nível Analisar/Avaliar
Orquestrada (multi-agente) — **só dispara com seu "vai"** (custo real de fan-out). Dimensões (§6), cada
uma retornando `claims`+`evidence` estruturados, verificados adversarialmente, convergidos no grafo.

### F3 — Radar → veredito → priorização  ·  nível Avaliar (gate humano)
- [ ] `kg-radar.sh` sobre o grafo cheio → atenção, reconciliações, integridade.
- [ ] Veredito de priorização: **priorizar / fechar / segundo-plano / estudar / formalizar / documentar /
      reorganizar** — cada item ancorado num nó do grafo (rastreável), não em impressão.
- [ ] Derivar a **north-star** (nível Criar) só a partir do que foi analisado.

### F4 — Realimentar as verticais + promover o padrão  ·  gated-until-trigger
- [ ] O que o grafo marcou `confirmed` materializa em `business-context/` (ICP, dor, posicionamento),
      `technical-context/` (fluxo, verdades de arquitetura), e atualiza `onion-framework-identity.md`.
- [ ] O **método** vira KB/padrão candidato ("como o Onion constrói conhecimento das verticais via KG
      SDAAL") — o padrão novo que este plano inaugura. Promove só após 2º dogfood (a própria doutrina).

---

## 5. Limites e gates explícitos (o que NÃO fazer agora)
- **Não** responder às perguntas de branch ainda — elas são insumo do grafo (F1), veredito na F3.
- **Não** disparar a pesquisa densa (F2) sem opt-in — é a fase cara; plano primeiro.
- **Não** preencher `business-context/` com prosa antes de F3 — vertical se preenche do grafo reconciliado.
- **Não** promover nada ao SSOT sem `confirmed` + maturação por uso.

---

## 6. Perguntas de pesquisa (F2) mapeadas por profundidade Bloom
| # | Dimensão | Pergunta-núcleo | Bloom-teto |
|---|---|---|---|
| Q1 | Identidade | O que o Onion **é de verdade** hoje (vs o pitch)? Qual o fluxo real? | Analisar |
| Q2 | Dor / ICP | Qual **dor** atendemos e **para quem** (ICP concreto, não genérico)? | Analisar |
| Q3 | Mercado | Concorrentes/padrões de mercado (jul/2026) — onde somos únicos vs commodity? **Lente Hagel (edge/core):** onde está nossa *edge* (baixo investimento, alto potencial) que pode virar o novo core? | Avaliar |
| Q4 | Valor | O que **gera valor de verdade** no que fazemos? Quais **quick-wins reais**? | Avaliar |
| Q5 | Futuro | O que **desejamos ser** × o que **podemos ser** (north-star + adjacências)? **Lente Hagel:** escalar a edge (federação/rhilo puxando o core) driblando o "sistema imunológico" do core em vez de transformar tudo de uma vez. | Criar |
| Q6 | Método | Como a herança/polimorfismo (RFC-0004/0005) se aplica à construção de conhecimento? | Analisar |

> **Nota sobre as duas fronteiras (não confundir):** *Hegel* = fronteira **lógica** (*quando* uma coisa
> vira outra) → governa "KG vs outras técnicas" (§2.6). *John Hagel* (edge/core, *Scaling Edges*) =
> fronteira **organizacional/estratégica** (*onde* a transformação nasce) → insumo de Q3/Q5. A federação
> é uma história edge-Hagel: o rhilo (edge) dogfoodou o KG e está puxando o core. Eixos diferentes,
> ambos "de fronteira" — por isso a confusão fácil; por isso valem separados.

---

## 7. Próximo passo concreto
Rodar **F1** (seed do grafo + primeiro radar) — barato, e já revela as lacunas que devem (ou não)
justificar a pesquisa densa da F2. F2 só dispara com o "vai" do maestro.
