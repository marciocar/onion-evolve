---
title: 'RFC-0003 — Identidade federada e inteligência coletiva entre instâncias Onion'
status: draft
canonical-in: onion-evolve (core) — fonte da série de RFCs de co-evolução
drafted-in: onion-evolve (core, 2026-07-01)
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

### 2.2 Classificação de dados

| Nível | Visível para | Exemplos |
|---|---|---|
| `private` | Só a instância | Debugging interno, rascunhos, dados sensíveis de negócio |
| `protected` | Instância + core (T0) | Adaptações, erros com contexto de negócio, personality.md PROTECTED |
| `peer` | Instância + peers em `trust.diary_readable_by` | Learnings entre T1s autorizados |
| `downstream` | Instância + seus filhos (T2) | Docs que central publica para seus adotados |
| `public` | Qualquer instância federada | Inovações gerais, KBs de boas práticas |
| `collective` | Elegível para síntese co-autorada pelo core | Candidatos à KB coletiva |

### 2.3 Diário — formato breadcrumb-first

O diário é um sistema de breadcrumbs para o Transformer. A distinção crítica (formalizada em
`breadcrumb-patterns.md`): **acomodação** (modelo infere o provável) vs. **absorção** (modelo lê
sinal explícito e o segue). O diário força absorção.

**Canal de maior absorção documentado: Frontmatter YAML** — chega proeminente no contexto,
antes de qualquer prosa. O formato do diário usa frontmatter como canal primário.

**Diretório:** `.claude/diary/` por instância (versionado — é autobiografia, não ephemeral)
**Arquivo:** `<AAAA-MM-DD>-<slug>.md`
**Índice:** `.claude/diary/index.md` — gerado por `diary-index.sh`, ~1KB, Tier-0 pointer (kebab-case por code-standards)

```yaml
---
date: 2026-07-01
instance: onion-evolve
type: learning             # learning | decision | error | innovation | observation
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
| **F2** | `/meta:personality-sync` + `personality.md` do core + members.yaml estendido | Dogfood + personality legível |
| **F3** | Trust SDAAL + extensão co-relay `--to peer` | Primeiro relay peer real bem-sucedido |
| **F4** | `/meta:synthesize-collective` + `docs/knowledge-base/collective/` | 3+ instâncias com diários maduros (90+ dias) |
| **F5** | `/meta:market-scan` + `docs/knowledge-base/market-intelligence/` | Diário maduro + demanda real |

---

## 5. Em aberto

- Formato exato da projeção A2A Agent Card — a spec A2A está em upgrade; validar antes de F2
- Trigger para síntese coletiva: periódico (cron) ou on-demand (`/meta:synthesize-collective`)
- ~~Formato de log de tentativas de relay bloqueadas~~ **Resolvido (2026-07-01):** `docs/evolution/trust-log.md` — tabela markdown append-only (Timestamp/FROM/TO/ACTION/STATUS/Razão), gerada por `log_attempt()` em `trust-topology-check.sh`
- Como T2 (consumer-de-hub) solicita adoção inicial sem acesso direto ao core
