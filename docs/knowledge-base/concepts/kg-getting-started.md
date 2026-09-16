# KG SDAAL — do zero ao seu primeiro `.kg.yaml` (rampa para dev/adotante)

> **O que este doc é.** A **rampa prática** para o método Knowledge Graph SDAAL: você sai daqui com um
> `.kg.yaml` rodando o radar. A doutrina densa (por que grafo, camadas, teoria) vive em
> [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md); o comando que orquestra é
> `/meta:kg`; o padrão-pai é
> [SDAAL](specification-driven-ai-abstraction-layer.md). Aqui é o **fazer**.

## 1. Quando usar (e quando NÃO)

Use um `.kg.yaml` quando a tarefa for **investigação, auditoria, verify multi-round ou design** — a classe
onde verdades se confrontam e se corrigem ao longo do tempo. A regra do core é **investigação NASCE no
grafo**, não em prosa (o gate REGRA 43 cobra isso) — porque a prosa esconde as contradições e as
auto-correções, o grafo as torna explícitas e o radar as encontra.

**NÃO** use para um fato único ou uma nota linear (isso é uma migalha de diário ou um KB). O grafo ganha
valor quando há **≥2 verdades que se relacionam** (uma sustenta, refuta ou supera a outra).

## 2. Anatomia — 3 blocos

```yaml
meta:
  id: minha-investigacao-2026-07     # slug único
  schema_version: "1"                # a versão da gramática (o radar valida)
  layer: audit                       # audit (epistêmica) | domain (SSOT durável)
  baseline: 2026-07-24               # data de referência para o frescor

nodes:                               # as "verdades" tipadas e ponderadas
  - id: C_ALGO                       # id em MAIÚSCULA por convenção
    node_type: claim                 # o TIPO (campo é node_type, NUNCA type)
    plane: DEV                       # DEV (código/branch lido) | PROD (artefato vivo)
    status: open                     # open | confirmed | refuted | superseded | done
    impact: 4                        # 1–5 (quanto importa)
    confidence: 0.7                  # 0–1 (quão certo)
    label: "o que esta verdade afirma, em uma linha"
    trace: "caminho/arquivo.ts:42"   # a migalha: file:line | commit | task | env

edges:                               # como as verdades se relacionam
  - from: E_PROVA
    to: C_ALGO
    edge_type: REFUTES               # ver a lista abaixo
```

**Tipos de nó** (camada `audit`): `entity` · `claim` · `decision` · `question` · `evidence` · `artifact`.
**Tipos de aresta** (camada `audit`): `SUPPORTS` · `REFUTES` · `SUPERSEDES` · `CAUSES` · `DEPENDS_ON` ·
`TRACES_TO`.
**Peso do nó** = `impact × confidence × status` — é o que faz o nó importante **emergir sozinho** no radar
(você não diz o que é central; o grafo diz).

> **A killer feature — `plane`.** `DEV` é o que você concluiu **lendo o código** (branch de trabalho); `PROD`
> é o **artefato vivo** (commit deployado + flags + env + dados). Separá-los deixa o radar pegar a conclusão
> que veio do código mas os dados vivos refutam — o `declarado≠verificado` no eixo do ambiente.

## 3. Seu primeiro grafo (exemplo trabalhado — este passa no radar)

Uma investigação minúscula: *"o retry de pagamento é idempotente?"* — o código diz sim, a produção refuta.

```yaml
meta:
  id: exemplo-retry-idempotente
  schema_version: "1"
  layer: audit
  baseline: 2026-07-24
nodes:
  - id: Q_IDEMPOTENTE
    node_type: question
    plane: DEV
    status: done
    impact: 5
    confidence: 1.0
    label: "o retry de pagamento e idempotente sob falha de rede?"
  - id: C_CODE_SAYS_YES
    node_type: claim
    plane: DEV
    status: refuted
    impact: 4
    confidence: 0.6
    label: "lendo PaymentService.ts: ha uma idempotency-key no header, logo o retry e seguro"
    trace: "src/payment/PaymentService.ts:88"
  - id: E_PROD_DOUBLE_CHARGE
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 5
    confidence: 0.95
    label: "logs de producao: 3 cobrancas duplicadas em 24h — a key expira antes do retry do gateway"
    trace: "env:prod/grafana/payment-dupes-2026-07"
  - id: D_TTL_FIX
    node_type: decision
    plane: DEV
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "estender o TTL da idempotency-key para > janela de retry do gateway"
    trace: "PR-1234"
edges:
  - from: C_CODE_SAYS_YES
    to: Q_IDEMPOTENTE
    edge_type: SUPPORTS
  - from: E_PROD_DOUBLE_CHARGE
    to: C_CODE_SAYS_YES
    edge_type: REFUTES
  - from: D_TTL_FIX
    to: E_PROD_DOUBLE_CHARGE
    edge_type: CAUSES
```

Repare: a auto-correção **não apagou** `C_CODE_SAYS_YES` — ela virou `status: refuted` + uma aresta
`REFUTES` explícita da evidência de PROD. **Append-mostly**: a história se reconcilia, não se apaga.

## 4. Rodar o radar (o instrumento de trabalho, não o lint do fim)

```bash
bash .claude/validation/kg-radar.sh docs/onion/graph/exemplo-retry-idempotente.kg.yaml
```

Sem flag, roda tudo. O que ler no veredito:

| Seção | O que diz |
|-------|-----------|
| **RADAR — atenção** | os nós por `peso × centralidade` — o que **precisa de olho** emerge no topo |
| **RECONCILIAÇÃO** | as arestas `REFUTES`/`SUPERSEDES` — as auto-correções que o grafo registra |
| **INTEGRIDADE** | contradições estruturais, ciclos, órfãos (`--integrity`) |
| **FRESCOR** | nós `plane: PROD` sem `verified_at` ou pré-baseline — "re-verifique contra o vivo" (`--freshness`) |
| **PROVENIÊNCIA** | decisões ancoradas em origem (`--provenance`) |
| **SCHEMA** | a gramática bate com o radar (`--schema`) — reprova na divergência |

Flags úteis: `--reconcile` (só a escada de refutações), `--triples` (emite o grafo em triplas),
`--radar` (só o ranking de atenção).

## 5. Duas leis que separam o grafo bom do ruído

1. **Ancore tudo.** Todo nó material carrega `trace:` — file:line, commit, task, env. Nó sem âncora é o
   mesmo que pin declarado sem verificar: **não entra**.
2. **Reconcilie, não delete.** Quando uma verdade cai, marque `status: refuted|superseded` e adicione a
   aresta — o `kg-radar --reconcile` reconstrói a escada. Deletar apaga a lição.

## 6. Onde os grafos vivem

- Investigação/auditoria do repo → `docs/onion/graph/*.kg.yaml` (ou `docs/<seu-escopo>/graph/`).
- O radar é **soberano por instância** — cada adotante roda o seu; o grafo cru nunca precisa sair do repo.
- Um `.md` de síntese pode carimbar `kg: <caminho>` no frontmatter para declarar "esta investigação nasceu
  no grafo" (o marcador da REGRA 43).

## 🔗 Aprofundamento
- Doutrina completa (por que grafo, camada domain, SSOT-as-runtime): [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md)
- O comando orquestrador: `/meta:kg`
- O padrão-pai: [SDAAL](specification-driven-ai-abstraction-layer.md)
- O motor: `.claude/validation/kg-radar.sh` (cabeçalho-doutrina auto-explicativo)
