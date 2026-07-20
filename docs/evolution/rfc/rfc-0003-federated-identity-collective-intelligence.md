---
title: 'RFC-0003 — Identidade federada e inteligência coletiva entre instâncias Onion'
status: accepted
canonical-in: onion-evolve (core) — fonte da série de RFCs de co-evolução
drafted-in: onion-evolve (core, 2026-07-01)
accepted-in: 2026-07-02 (revisão Lote B da auditoria de federação 2026-07-01 — 5 pendências arbitradas)
extends: RFC-0001 (modelo dos 3 fluxos), RFC-0002 (doutrina catálogo-first)
review_after: 2026-10-01
---

# RFC-0003 — Identidade federada e inteligência coletiva

## 1. Contexto e escopo

RFC-0001 estabeleceu o protocolo de co-evolução core ↔ derivados (3 fluxos: downstream, upstream,
handoff). O modelo funciona para propagação de updates e sinalização de bugs. O que falta:

1. **Identidade além do stamp** — `.onion-version` diz *de onde viemos*; não diz *quem nos tornamos*
2. **Aprendizado acumulado** — erros, decisões e inovações não têm registro estruturado por instância
3. **Comunicação peer-to-peer** — hoje toda troca passa pelo core; peers legítimos não têm canal direto
4. **Síntese coletiva** — learnings de múltiplas instâncias não se consolidam em conhecimento compartilhado
5. **Hierarquia de tiers** — `producer`/`consumer` binário não captura hub vs. standalone vs. consumer-de-hub

**Escopo desta RFC:**
- Definir formato de diário por instância (breadcrumb-first, para absorção pelo Transformer)
- Definir hierarquia de tiers de acesso (T0 core → T1 hub → T2 consumer → T3 standalone)
- Definir modelo de classificação de dados (private → protected → peer → downstream → public → collective)
- Definir topologia de confiança (quem pode relay, aconselhar, corrigir quem)
- Definir arquitetura Trust SDAAL (espelho do task-manager)
- Definir comandos: `/meta:diary`, `/meta:personality-sync`, extensão de `/meta:co-relay`

**Não-objetivos:**
- Runtime A2A (proibido — RFC-0001, invariante permanente)
- Auto-execução cross-repo (invariante I3 — um escritor por repo)
- Síntese coletiva automática (Fase 4 — gated, pós-90 dias de dogfood)
- Market scan automatizado (Fase 5 — gated)

---

## 2. Decisões

### 2.1 Hierarquia de tiers (substitui producer/consumer binário)

```
TIER 0 — CORE (role: source)
  onion-evolve; autoridade emissora; lê tudo; escreve só em si; sem parent

TIER 1 — CENTRAL/HUB (role: hub)
  Adotante que tem seus próprios adotados; parent = core
  Lê: public do core + public/peer de T1 autorizados no bloco `trust:` do members.yaml

TIER 2 — CONSUMER-DE-HUB (role: consumer, parent: <hub-id>)
  Adota um hub, não o core diretamente
  Lê: o que seu parent T1 marca como downstream; não acessa core diretamente

TIER 3 — STANDALONE (role: standalone)
  Adota o core diretamente, sem ser hub; sem sub-adotados
  Lê: public do core apenas; não vê outros T3 nem T1/T2
```

**Campo `role` em `members.yaml`:** substitui `producer` → `source`; `consumer` → `hub|standalone|consumer`.

> **Fora de escopo — namespace de contrato (nota da revisão 2026-07-02, audit #13):** os campos
> `producer:`/`consumers:` do formato de **CONTRATO** da Federação formal (`contracts/<id>.md` — KB
> [multi-repo-federation](../../knowledge-base/concepts/multi-repo-federation.md)) são um eixo **ortogonal**
> (papel *por contrato*) e permanecem **inalterados** por esta RFC. Só o `role:` de **membro** migra para
> tiers. Os 3 namespaces de "role" (contrato / membro / stamp) estão reconciliados na KB
> [federation-usage-modes §1.1](../../knowledge-base/concepts/federation-usage-modes.md).

**Adoção de T2 (decisão da revisão 2026-07-02, audit #11):** T2 onboarda **via core** (source-driven) —
o maestro roda `/meta:adopt` do core e registra `parent: <hub-id>` no `members.yaml`; o hub **não** roda
adopt. *Hub-driven adoption* fica como **gatilho futuro** (1º T2 real + dor de roteamento via core); até
lá, a relação hub→T2 é só de leitura (`exposes_downstream`).

### 2.2 Classificação de dados

| Nível | Visível para | Exemplos |
|---|---|---|
| `private` | Só a instância | Debugging interno, rascunhos, dados sensíveis de negócio |
| `protected` | Instância + core (T0) | Adaptações, erros com contexto de negócio, personality.md PROTECTED |
| `peer` | Instância + peers em `trust.diary_readable_by` | Learnings entre T1s autorizados |
| `downstream` | Instância + seus filhos (T2) | Docs que central publica para seus adotados |
| `public` | Qualquer instância federada | Inovações gerais, KBs de boas práticas |
| `collective` | Elegível para síntese co-autorada pelo core | Candidatos à KB coletiva |

> **Membros `mode: regulated` (decisão da revisão 2026-07-02, audit #18):** o default de `classification`
> é **`protected`** (não `public`). Promover uma entrada a `public`/`collective` exige **revisão humana
> explícita** do maestro da instância, e o `/meta:diary export-sharable` pede confirmação extra nesses
> membros. Racional: num membro regulado (ISO/SOC2/PMBOK), o custo de um vazamento por descuido supera o
> atrito da revisão por entrada.

### 2.3 Diário — formato breadcrumb-first

O diário é um sistema de breadcrumbs para o Transformer. A distinção crítica (formalizada em
`breadcrumb-patterns.md`): **acomodação** (modelo infere o provável) vs. **absorção** (modelo lê
sinal explícito e o segue). O diário força absorção.

**Canal de maior absorção documentado: Frontmatter YAML** — chega proeminente no contexto,
antes de qualquer prosa. O formato do diário usa frontmatter como canal primário.

**Diretório:** `.claude/diary/` por instância (versionado — é autobiografia, não ephemeral)
**Arquivo:** `<AAAA-MM-DD>-<slug>.md`
**Índice:** `.claude/diary/index.md` — gerado por `diary-index.sh`, ~1KB, Tier-0 pointer (kebab-case por code-standards)

> **Emenda (2026-07-17) — o schema evoluiu; a SSOT viva é o comando.** O bloco abaixo registra o schema
> **como aceito em 2026-07-02** (não se reescreve RFC aceita). Desde então ele ganhou, via dogfood:
> **(a)** `conflict_class` (`dynamic|static|conditional`) + `valid_when` — a *estrutura de invalidação* que
> dirige o re-teste (`/meta:diary` v1.2.0, vocabulário MemConflict); **(b)** o tipo **`reflection`**
> (2026-07-17) — síntese retrospectiva sobre o método, que o campo já escrevia antes de existir no
> vocabulário. **SSOT viva do schema: [`/meta:diary`](../../../.claude/commands/meta/diary.md)**, com guarda
> determinística em `diary-index.sh` (tipo ou classe fora do enum = migalha desonesta → exit 1). Se este
> bloco divergir do comando, **o comando vence**.

> **Emenda (2026-07-19) — `significance:` entra no CONTRATO de migalha federada.** Campo **opcional**
> (retrocompatível) no frontmatter: **uma frase orgulhosa e honesta** dizendo por que a migalha vale e
> qual seu **papel no continuum dogfoodado**. Se `Signal` força a absorção do **WHAT**, `significance`
> força a do **WHY-que-orgulha** — tirando o encaixe-no-todo da prosa (onde afunda) e pondo-o no canal de
> maior absorção. Ancorado em [`breadcrumb-patterns.md`](../../knowledge-base/agentic-patterns/ai-strategies/breadcrumb-patterns.md)
> §Faceta de ① como **absorção AVALIATIVA** (o leitor lê certo e ainda assim acomoda como "mais um PR").
>
> **Por que é contrato desta RFC, e não escolha de instância:** migalha é **trocável** entre instâncias
> (`/meta:co-relay`, `export-sharable`, `diary_readable_by`). Se cada instância inventar seu próprio
> "campo de orgulho", a rede perde exatamente a propriedade que torna migalhas intercambiáveis. **O core
> define campo, formato e guarda; cada estrela o preenche com o orgulho do próprio trabalho.**
>
> **Herda a classificação (§2.2) — não é canal de vazamento.** A `significance` viaja **dentro** da
> migalha e está sujeita ao mesmo gate: migalha `private`/`protected` não exporta sua `significance`. Ela
> **não** cria superfície de disclosure nova — escrever nela algo que a `classification` não permitiria no
> corpo é violação da mesma regra, não exceção a ela.
>
> **Guarda orgulho ≠ hype:** precisa de **lastro** em Signal/Evidence (sem lastro = migalha desonesta) e
> **morre junto** — quando o `review` supersede a migalha, a `significance` cai com ela. Mecanização
> honesta: `diary-index.sh` valida **forma/presença** e surfaça no índice Tier-0 (selftest cobre o caminho
> não-vazio); **o lastro do orgulho não é mecanizável** — fica no gate humano da absorção, como o veredito
> de review. Origem: proposta de campo da estrela `onion-pessoal-app` (sinal upstream 2026-07-19), triada
> via `/meta:co-evolve`. **SSOT viva segue sendo [`/meta:diary`](../../../.claude/commands/meta/diary.md).**

```yaml
---
date: 2026-07-01
instance: onion-evolve
type: learning             # learning | decision | error | innovation | observation  (+ reflection — emenda 2026-07-17)
classification: public     # private | protected | peer | downstream | public | collective
tags: []
affects: []                # engineering | product | compliance | design | meta
breadcrumb_for: []         # quais fluxos/workflows esta migalha orienta
share_with: []             # [] = respeita classification; ou [core] [peer-id] [collective]
next_recommended: ""       # próxima migalha sugerida ao Transformer que absorver esta
review_after: ""           # AAAA-MM-DD — quando reavaliar se este learning ainda é válido
---

## Signal
[≤3 linhas — o que o Transformer DEVE absorver]

## Evidence
[bullets — o que aconteceu de concreto, não prosa]
-

## Next crumb
[o que quem receber isto deve fazer a seguir]
```

**Regra de periodicidade:** todo entry tem `review_after` (default: 90 dias após `date`).
O hook `co-evolution-inbox-check.sh` será estendido para sinalizar entries vencidos: `⏰ diary`.

### 2.4 Personalidade emergente

**Arquivo:** `.claude/identity/personality.md` por instância
**Gerado por:** `/meta:personality-sync` a partir de:
- Diário (entradas acumuladas — innovations, decisions, learnings)
- `.onion-version` (origem, adoção, modo)
- Git log dos primeiros 30 commits (o que o projeto fez primeiro)

A personalidade não é declarada — **emerge do uso**. Cada sync regenera.

**Formato compatible com A2A Agent Card (projeção one-way, não fonte de verdade):**
```markdown
---
instance: <id>
tier: hub | standalone | source
generated: <AAAA-MM-DD>
review_after: <AAAA-MM-DD (+30 dias)>
a2a_card_projection: true   # sinaliza que este arquivo é projeção, não fonte
---
# Personalidade — <instância>
## Domínio e contexto
## Especialidades desenvolvidas
## Adaptações do core
## Padrões de erro superados
## O que ofereço à rede
```

**Campo `personality_summary`** em `members.yaml` — 1 linha, auto-gerado pelo sync.

### 2.5 Trust SDAAL — arquitetura (espelho do task-manager)

Nova instância do padrão SDAAL, idêntica em estrutura:

```
.claude/utils/trust/
├── factory.md      # resolve TrustTier + localPath via members.yaml
├── interface.md    # ITrustManager: can_relay(), can_advise(), can_correct(),
│                   #   visible_classifications(), resolve_peer_path()
├── types.md        # TrustTier, ClassificationLevel, TrustPolicy, RelayResult
├── detector.md     # detect_tier(), resolve_peer_path(), validate_trust_policy()
└── adapters/
    ├── source.md   # T0: lê tudo, escreve só em si
    ├── hub.md      # T1: peers autorizados + expõe downstream
    ├── standalone.md  # T3: só public do core
    └── consumer.md    # T2: só o que parent T1 publica
```

**Script determinístico:** `.claude/validation/trust-topology-check.sh`
```bash
# Uso: trust-topology-check.sh --from <id> --to <id> --action relay|advise|correct
# exit 0 = autorizado; exit 1 = bloqueado (com mensagem explicativa)
# Lê members.yaml; nunca falha silenciosamente (sem || true)
```

### 2.6 Extensão do `/meta:co-relay` (Fase 3 — gated)

Parâmetro novo: `--to peer:<peer-id>` resolve via `detect_peer_path()` (campo `local_path` em
`members.yaml`). ANTES de qualquer cópia: `trust-topology-check.sh`. Se bloqueado: log + exit.
Se autorizado: cópia never-clobber no `inbox/` do peer (sem commit — I3 respeitado).

**Campo novo em `members.yaml`:** `local_path: "<path-absoluto>"` — obrigatório para relay peer.

---

## 3. Invariantes que PERMANECEM (não negociáveis)

- **Sem A2A runtime** — agentes não executam em repos alheios (RFC-0001)
- **I3: um escritor por repo** — relay = cópia sem commit no alheio
- **Maestro humano no gate** — relay transporta; execução é sempre ato 3 (humano)
- **Never-clobber** — relay nunca sobrescreve arquivo existente no destino
- **Sem || true** — scripts de trust nunca mascaram erros
- **Auditável** — toda tentativa de relay (autorizada ou bloqueada) é logada

---

## 4. Roadmap faseado

| Fase | O que | Gate para avançar |
|---|---|---|
| **Pré-F1** | Esta RFC + bloco `trust:` em `members.yaml` (nome real do campo implementado) | RFC aceita pelo maestro |
| **F1** | `/meta:diary` + `diary-index.sh` + 10 entradas reais no core | Dogfood 1 semana |
| **F2** | `/meta:personality-sync` + `personality.md` do core + members.yaml estendido | **Mecânico:** `personality.md` existe, gerado pelo sync (não manual), com as 5 seções do template preenchidas · **+ humano:** maestro confirma que o texto reflete a instância |
| **F3** | Trust SDAAL + extensão co-relay `--to peer` | Primeiro relay peer real bem-sucedido |
| **F4** | `/meta:synthesize-collective` + `docs/knowledge-base/collective/` | 3+ instâncias com diários maduros (90+ dias) |
| **F5** | `/meta:market-scan` + `docs/knowledge-base/market-intelligence/` | **Mecânico:** ≥1 entrada de diário com tag `market-signal` OU pedido registrado em `inbox/` · **+ humano:** maestro confirma a demanda |

> **Gates híbridos (revisão 2026-07-02, audit #15):** F2 e F5 têm **precondição mecânica**
> (script-checkável) **+ decisão final humana** — coerente com o invariante "maestro no ato 3". F1 e F4
> já eram contagens objetivas.
>
> **Nota de execução — antecipação de F3 (audit #9):** o commit `f07fe90` (2026-07-01) entregou a infra
> de F3 (Trust SDAAL + `trust-topology-check.sh`) junto com F1, **antes** do gate de F1 ser cruzado. A
> antecipação fica registrada: a infra **existe mas não conta como fase concluída** — o roadmap segue
> sequencial e o gate F1 (10 entradas + 1 semana; estado em 2026-07-02: 2/10) continua sendo o próximo
> marco. Risco aceito: adapters de trust não exercitados por relay real até F3 abrir — bitrot vigiado
> pelo modo `trust-topology` do lint-selftest (desde a auditoria 2026-07-01).
>
> **Estado F1 em 2026-07-03:** contagem **10/10 atingida** (todas reais — 4 nascidas de incidentes,
> 2 de pesquisas verificadas, 4 de decisões/aprendizados; estruturadas com `conflict_class` desde a
> v1.2.0 do `/meta:diary`). O 2º critério (**dogfood 1 semana**, início 2026-07-01) fecha em
> **2026-07-08** — F1 só gradua aí, e a graduação **habilita** F2 (precondição mecânica satisfeita),
> não a constrói: decisão de abrir F2 é do maestro (gated-until-trigger).

---

## 5. Em aberto

- Formato exato da projeção A2A Agent Card — a spec A2A está em upgrade; validar antes de F2
- Trigger para síntese coletiva: periódico (cron) ou on-demand (`/meta:synthesize-collective`)
- ~~Formato de log de tentativas de relay bloqueadas~~ **Resolvido (2026-07-01):** `docs/evolution/trust-log.md` — tabela markdown append-only (Timestamp/FROM/TO/ACTION/STATUS/Razão), gerada por `log_attempt()` em `trust-topology-check.sh`
- ~~Como T2 (consumer-de-hub) solicita adoção inicial sem acesso direto ao core~~ **Resolvido (2026-07-02,
  audit #11):** T2 onboarda **via core** (source-driven) com `parent: <hub-id>` registrado no members.yaml;
  hub-driven adoption é gatilho futuro (1º T2 real + dor de roteamento) — ver §2.1 e
  [adoption-lifecycle.md](../../applying/adoption-lifecycle.md)
