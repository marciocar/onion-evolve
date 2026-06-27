---
status: snapshot
type: evolution-backlog
date: 2026-06-27
topic: "Harness + Ledger (camada de comunicação) nos 3 modos: solo · equipe · federação"
method: discovery (fan-out-and-synthesize, 4 lentes, frota onion-fleet/Workflow run wf_e3aa9343-950)
scope: read-only research — propõe, não muta (exceto este relatório)
related: onion-research-how-we-work-2026-06.md, onion-distribution-instance-model (memória)
---

# Pesquisa de evolução — Tópico 2: "Harness + Ledger nos 3 modos"

> **Discovery, não execução.** Investiga como o **harness** (sessões persistentes, subagentes, a
> ferramenta Workflow) e a **camada de comunicação** (hoje o Ledger da Federação) se adaptam e se
> **generalizam** aos três modos de operação: solo · equipe · federação. Parte do esclarecimento do
> maestro: *"o Ledger não deixa de ser camada de comunicação"*. Pedido de 2026-06-25. Frota de 4 lentes
> (read-only); síntese com filtro crítico (anti-inchaço: dogfood antes de produto).

## Sumário executivo (veredito)

**Existe um modelo unificado implícito, e o achado é nítido: solo e federação estão maduros; EQUIPE é o
gap.** As 4 lentes convergiram para a mesma formulação:

```
harness + camada-de-comunicação = modelo de coordenação = função(escala-da-unidade)

escala-da-unidade:
  SOLO       = eu-comigo-mesmo-no-tempo   → memória + sessões            [✅ maduro]
  EQUIPE     = devs-no-mesmo-repo         → worktrees + handoff           [🔴 gap crítico]
  FEDERAÇÃO  = repos-separados            → Ledger git + doc-bridge       [✅ em produção]
```

O **Ledger é a camada de comunicação**, e seu núcleo é **isomórfico** entre os modos:
`{registry (quem/versões) · changelog (o-que-mudou-porquê) · contracts (o-que-quebra)}`. O que muda é a
**escala da unidade que se comunica** — de "eu no tempo" a "repos no espaço".

## O isomorfismo do Ledger por modo

| Componente do Ledger | SOLO | EQUIPE | FEDERAÇÃO |
|----------------------|------|--------|-----------|
| **Registry** (quem/versões) | sessions INDEX (qual worklog ACTIVE) | — (informal: git log + notes) | `members.yaml` (pin .onion-version) |
| **Changelog** (o-que-mudou-porquê) | memória (`MEMORY.md` + `memory/*.md`) | — (handoff em `notes.md`, papel) | `CHANGELOG.md` append-only |
| **Contracts** (o-que-quebra) | — (n/a) | — | `contracts/` spec-as-code |
| **Transporte** | n/a (consigo mesmo) | `git mv` entre worktrees (informal) | `/meta:co-relay`/`co-deliver` (entrega-sem-commit) |
| **Notificação** | recall automático (prompt-cache) | — (ler `notes.md` à mão) | hook "you have mail" (📬/📥) |

A coluna **EQUIPE está quase toda vazia** — é o diagnóstico central.

## Estado por modo (destilado das 4 lentes)

### ✅ SOLO — maduro
Harness completo: sessões `.claude/sessions/<slug>/` (STATE.md Tier-0, worklog-protocol, retomada fria sem
transcript), Workflow/frota (fan-out determinístico, 0 tokens de coordenação). A "comunicação" colapsa em
**handoff consigo mesmo no tempo**: memória (recall automático) + STATE.md (sessão N→N+1). O doc-bridge
(inbox/inbound) existe como scaffolding provisionado pelo `/meta:adopt`, mas **sem tráfego** (silencioso).
Nada essencial falta.

### 🔴 EQUIPE — gap crítico (design incompleto)
O **harness existe** (worktrees isolam, "um escritor por escopo" previne colisão, RFC-0001 §C). Mas a
**camada de comunicação é informal**: o handoff entre devs é "papel" (`evolution/README.md` §Handoff, ~3
linhas) — sem SSOT versionada, sem notificação automática, sem auditoria append-only, sem detecção de
"quem-fez-o-quê". Quando um 2º dev entra 3 dias depois, ele descobre o estado lendo `notes.md` + `git log`
à mão. **Não há `role detection` intra-repo** (quem é o maestro? quem cobre qual escopo?).

### ✅ FEDERAÇÃO — em produção
Modelo peer com maestro humano, git-async, pull-based (RFC-0001 + Federation v2). Ledger completo
(`members.yaml` + `CHANGELOG` + `contracts/`), doc-bridge (`/meta:co-*`, inbox/inbound, entrega-sem-commit,
invariante I3 "um escritor por repo"), 3 fluxos. Dogfoodado com o `rhilo-metagamify`. Pendente só o que já
está gated (carteiro automático, no gatilho de graduação).

## Recomendação (com filtro anti-inchaço)

### ✅ RECOMENDADO agora: documentar o modelo unificado como conhecimento

O **achado teórico** (harness + comms = f(escala); isomorfismo do Ledger) responde diretamente ao pedido
do maestro e é valioso por si. Cabe como **seção/KB** — idealmente a Camada 2 da KB integrada do Tópico 1
(`onion-working-method.md`) ou uma KB irmã `onion-coordination-model.md`. **Conhecimento, não nova infra.**
Conecta com [[onion-distribution-instance-model]]: o modo EQUIPE é a **graduação intermediária** entre solo
(1-escritor trivial) e federação (1-escritor/repo) — o mesmo invariante "um escritor por escopo" em escalas
diferentes.

### 🔴→🟡 GATED: o modo EQUIPE é o próximo eixo de evolução — mas só com dogfood

O gap EQUIPE é **real e o mais valioso** dos três (solo e federação já entregam). MAS **não há hoje nenhum
caso de equipe operando** (N devs / 1 repo). Implementar a camada de comunicação de equipe agora seria
**produto sem dogfood** — exatamente o que a doutrina proíbe. Quando o gatilho surgir (1º projeto com N devs
usando Onion no mesmo repo — candidato: `rhilo-app`), o design já está esboçado:

- **Formalizar o handoff-C de papel para versionado:** `HANDOFF.md` append-only por sessão (registry +
  changelog + bloqueadores + proof), espelhando a estrutura do inbox da federação.
- **Hook bidirecional:** estender "you have mail" para "você tem handoff não-revisado / bloqueador esperando".
- **`role detection` intra-repo** como primitiva (coordinator-inrepo vs developer-inrepo).

**Gatilho:** 1º caso real de N-devs/1-repo. **ADR a sair quando graduar.**

### ❌ REJEITADOS (over-engineering / contra o modelo)

- **Migrar a memória pessoal (`~/.claude/.../memory/*.md`) para `docs/evolution/memory/` git-commitada
  (lente ledger-as-comms):** a memória solo vive em `~/.claude/` **por design** — é do *dev*, não do *repo*
  ("eu comigo mesmo", privada). Commitá-la no repo a **expõe e mistura** com o canal de co-evolução, violando
  a separação proposital memória-pessoal vs ledger-de-repo. A memória **já é** o ledger-consigo; não precisa
  virar artefato de repo.
- **Gate de detecção automática de colisão entre worktrees:** o `git merge` já resolve; um gate Onion seria
  redundante e geraria atrito — mesma lógica anti-guarda-hard do Tópico 1 (recall > bloqueio heurístico).

## Síntese dos dois tópicos

O Tópico 1 (método) e o Tópico 2 (coordenação) **se encaixam**: o método tem 3 camadas (Seleção · Execução ·
Validação) + Disciplina; a **Execução** roda sobre o harness, e a **coordenação** (este tópico) é como o
harness + comunicação escalam por modo. Recomendação combinada: **uma KB integrada do método** (Tópico 1)
que inclua o **modelo de coordenação por modo** (Tópico 2) como a seção de Execução-em-escala. O gap EQUIPE
fica como o **maior eixo de evolução futura**, gated por dogfood. Nenhuma infra nova agora — síntese de
conhecimento + um item gated bem-nomeado.

## Próximo passo (decisão do maestro)

Discovery dos dois tópicos entregue. **P0 acionável (se aprovado):** escrever a KB integrada
`onion-working-method.md` consolidando os dois (síntese, 1 PR, cita as fontes). **Gated:** modo EQUIPE
(handoff versionado + role detection), no gatilho de 1º caso real de N-devs/1-repo. **Rejeitados** registrados
para não reaparecer.
