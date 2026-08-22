---
title: "Lógica de domínio — Sistema Onion (core)"
date: 2026-08-13
---

# Lógica de domínio do Sistema Onion (core)

> **Escopo do refresh 2026-08-13** — re-verificada contra `docs/onion/inventory.md` a contagem de
> arquivos dos três contextos de domínio. **Não** re-verifiquei o restante do documento; carimbo
> nomeia o que foi medido.


> **Escopo desta camada.** O "domínio" do Onion não é entidades de negócio de um app (não há
> `User`/`Order`/`Invoice`) — o Onion **é** o framework template em `.claude/` (ver
> `/home/marcio/onion-evolve/CLAUDE.md:9-16`). O domínio, portanto, é: (1) as **abstrações SDAAL**
> que o framework provê a projetos-alvo (task-manager, forge, KG); (2) o **Knowledge Graph SDAAL**
> como modelo de conhecimento; (3) a **co-evolução/federação** entre repos que adotam o Onion; (4)
> os **workflows faseados** que orquestram trabalho humano+IA. Seções do template genérico que
> pressupõem uma API HTTP de produto (`api-specification.md`) **não se aplicam** aqui — este é um
> framework de comandos/agentes Claude Code, não um serviço com endpoints REST próprios (os únicos
> "endpoints" reais são o webhook `a2a-live` do `onion-bridge`, tratado à parte, fora do escopo deste
> arquivo).

---

## 1. SDAAL — o padrão de abstração que rege todo o domínio

**SDAAL** = *Specification-Driven AI Abstraction Layer*. É o meta-padrão do qual **toda** abstração
externa do Onion deriva; a Task Manager Abstraction é a **referência canônica**
(`docs/meta-specs/integrations.md:27`).

### 1.1 Estrutura obrigatória de um adapter SDAAL

Todo domínio de integração externa (task manager, forge, e qualquer futuro domínio) replica a mesma
forma (`docs/meta-specs/integrations.md:66-75`):

```
.claude/utils/<dominio>/
├── factory.md           # Lê env var, valida obrigatórias, instancia o adapter certo
├── interface.md         # Contrato comum (operações independentes de provider)
├── types.md             # Tipos/DTOs compartilhados
├── detector.md          # Detecção automática (opcional)
└── adapters/
    └── <provider>.md    # Um arquivo por provider suportado
```

Instâncias reais hoje no core (`.claude/utils/`, listado via `Bash: ls .claude/utils`):
`task-manager/`, `forge/`, `federation-transport/`, `trust/`, `co-evolution/`, `adopt/`, `scope/`,
`de-identification/`, `design-source/`, `design-sink/`, `guardrails/`, `marketplace/`, `vertical/`,
`wizard/`.

### 1.2 Regra de transporte: API-first, MCP opcional (Task Manager)

`TASK_MANAGER_TRANSPORT` default `api`; `mcp` é opt-in e só ativa se o provider tiver servidor MCP —
caso contrário cai para API (`docs/meta-specs/integrations.md:44`, `CLAUDE.md` §Task Manager). A spec
(`ITaskManager`, `.claude/utils/task-manager/interface.md`) define **o quê**; o adapter define **o
como**. **Nunca** se chama o MCP/SDK de um provider direto de comando/agente — sempre via
`taskManager.*` (`CLAUDE.md:36`).

`ITaskManager` (`.claude/utils/task-manager/interface.md:1-60`) expõe: `provider` (readonly),
`isConfigured` (readonly), CRUD de task (`createTask`/`getTask`/`updateTask`/`deleteTask`).

### 1.3 Regra de transporte divergente: CLI-first (Forge)

**Divergência intencional e documentada**: o Forge Abstraction usa `cli` (`gh`/`glab`) como
transporte **default**, não `api` — porque a CLI oficial já embute auth/paginação/rate-limit
(`docs/meta-specs/integrations.md:34-37`; `CLAUDE.md` §Forge). `FORGE_TRANSPORT` default `cli`, `api`
é o fallback REST.

### 1.4 Edge case de domínio: fronteira local-vs-remoto do IForge

`IForge` cobre **exclusivamente** operações no host remoto — PR, comentário de review, status de
CI/checks, Release, leitura de branch protection. Git local (branch/checkout/merge/rebase/tag/**push**)
**nunca** passa pelo adapter — é `git` direto orientado pelo motor GitFlow
(`.claude/utils/forge/interface.md:9-22`). Regra explícita: `git push` funciona via SSH/HTTPS sem
token de forge — só PR/review/CI/Release exigem a API do host, então manter `push` fora do `IForge`
evita re-abstrair o que o git já abstrai (`.claude/utils/forge/interface.md:24`).

### 1.5 Fallback gracioso — regra de domínio comum a todo adapter

Se variáveis obrigatórias do provider ativo estiverem ausentes/inválidas: (1) avisar o usuário em
pt-BR nomeando a variável faltante; (2) sugerir `/meta:setup-integration`; (3) **nunca inventar**
valores nem assumir outro provider (`CLAUDE.md` §Fallback gracioso, ambas seções Task Manager e
Forge).

---

## 2. Knowledge Graph SDAAL — o modelo de conhecimento do domínio

Fonte: `docs/knowledge-base/concepts/knowledge-graph-sdaal.md`. Status no arquivo: **CANDIDATA**,
recebida via co-evolução de um adotante, gate `/meta:kg` **cumprido em 2026-07-04**
(`knowledge-graph-sdaal.md:1-13`).

### 2.1 Duas camadas de grafo (`layer:`)

| `layer` | Semântica | `node_type` | `edge_type` |
|---|---|---|---|
| `audit` (default, retrocompatível) | epistêmica — o que a investigação **acredita** | `entity`·`claim`·`decision`·`question`·`evidence`·`artifact` | `SUPPORTS`·`REFUTES`·`SUPERSEDES`·`CAUSES`·`DEPENDS_ON`·`TRACES_TO` |
| `domain` | SSOT durável — o que o sistema **é** | `entity`·`state`·`event`·`rule`·`invariant`·`policy` | `HAS_STATE`·`TRANSITIONS` (atributo `on:` = evento gatilho)·`EMITS`·`CONSTRAINS`·`READS`·`WRITES` |

(`docs/knowledge-base/concepts/knowledge-graph-sdaal.md:72-83`)

Outros campos estruturais: `plane` (`DEV` código/branch/commit vs `PROD` artefato vivo — deploy +
config + dados); peso do nó = `impact` (1–5) × `confidence` (0–1) × `status`
(`open|confirmed|refuted|superseded|done`); aresta unificada de rastro `TRACES_TO` →
`{file:line | task | commit | env | reason | snapshot}` (`knowledge-graph-sdaal.md:84-87`).

**Regra de domínio (append-mostly)**: o grafo nunca apaga histórico — auto-correções viram arestas
`REFUTES` explícitas; a história se **reconcilia**, não se apaga (mesmo parentesco do protocolo de
re-teste do diário — `superseded: true`, nunca deletar) (`knowledge-graph-sdaal.md:88-90`).

### 2.2 Convenção normativa de idioma nos nós

`id` em **inglês** (identificador/código), `label` em **pt-BR** (prosa lida por humano) — segue
`language-standards`/`code-standards`. Regra nascida de um custo real de campo: quando `id` derivou
para português, `atom-map.md` e o `.kg.yaml` correspondente nomearam o mesmo átomo com `id`s
diferentes (`E_REPLY` vs `E_RESPOSTA`), quebrando o contrato entre os dois artefatos
(`knowledge-graph-sdaal.md:92-99`).

### 2.3 Footguns de autoria (edge cases documentados de corrupção silenciosa)

1. **`on:` vira booleano YAML 1.1.** A chave `on:` de `TRANSITIONS ... on: EVENTO` é lida como `true`
   por parsers YAML 1.1 — gatilhos de transição somem sem erro visível. Mitigação: sempre citar entre
   aspas (`on: "EVENTO"`) (`knowledge-graph-sdaal.md:113-117`).
2. **Colisão de keyword-substring no radar — CORRIGIDA em 2026-07-19.** `kg-radar.sh` é awk puro
   (determinístico, sem LLM); até 07-19 capturava campos por substring de linha e um campo livre
   (`label:`/`trace:`/`reason:`) contendo `plane:`/`status:` sobrescrevia o campo real. Fix: casamento
   por **posição de campo** (`^[[:space:]]*<campo>:`). Continua footgun **inerente** a qualquer porta
   line-based noutro runtime (`knowledge-graph-sdaal.md:118-125`).
3. **Trailing commas em flow-maps** quebram o parse silenciosamente (`knowledge-graph-sdaal.md:126-127`).
4. **Frescor**: um nó `plane: PROD` é uma foto — sem `verified_at:` ele envelhece e "mente" como SSOT
   confiável; hoje é guarda do radar (`verified_at:` + gate STALE, `schema_version:` + gate de drift)
   (`knowledge-graph-sdaal.md:129-131`).

### 2.4 Doutrina — git merge não reconcilia verdades

Regra de domínio central: conflito **epistêmico** entre linhagens (o que cada uma acredita ser
verdade) se resolve na **camada de conhecimento** (KG SDAAL — claims por `plane`, arestas
`REFUTES`/`SUPERSEDES`, radar) e **só então** na camada de código (PR dirigido pelo veredito). `git
merge` reconcilia texto, não verdades (`knowledge-graph-sdaal.md:31-33`).

### 2.5 Integridade estrutural ≠ rastreabilidade

Um `.kg.yaml` pode selar 100% verde na integridade (0 ciclos, 0 órfãos, evidence 100%) e ainda ter
`TRACES_TO` órfão (0/N — nenhuma `decision` ligada aos nós que justifica). "O grafo é consistente" ≠
"o grafo é auditável" (`knowledge-graph-sdaal.md:43-48`). Regra de arquitetura de validação: um
validador local **delega** ao `kg-radar.sh` soberano em vez de reimplementar a gramática — um parser
duplicado em gramática divergente é a superfície onde o falso-verde volta
(`knowledge-graph-sdaal.md:50-53`).

---

## 3. Co-evolução e federação — o domínio multi-repo

Fonte: `docs/knowledge-base/concepts/onion-federation-and-adoption.md` (guia-síntese que cita as
fontes canônicas: `multi-repo-federation.md`, `federation-usage-modes.md`).

### 3.1 Dois sistemas distintos, não um

| | Co-evolução / Adoção | Federação formal por contrato |
|---|---|---|
| Estado | ativo, em uso real — 8 ADOTANTES hoje (de 12 membros; `kind: adopter`, régua D8) | construído, não graduado — 0 contratos |
| Unidade | um **membro** (repo inteiro) | um **contrato** (integração específica entre 2 repos) |
| Mecanismo | `/meta:adopt`, `members.yaml`, canais `inbox/`/`inbound/`, doc-bridge (`co-*`) | `contracts/<id>.md` em ledger git, `CHANGELOG.md` como inbox |

(`onion-federation-and-adoption.md:33-42`)

### 3.2 Regra de tiers (RFC-0003) e quem pode falar com quem

| Tier | Papel | Parent |
|---|---|---|
| T0 — source | o core, autoridade emissora, lê tudo por papel | nenhum |
| T1 — hub | adotou o core, pode ter sub-adotados | source |
| T2 — consumer | adotou um hub, hub é o único ponto de contato upstream | um hub T1 |
| T3 — standalone | adotou o core direto, sem sub-adotados | source |

(`onion-federation-and-adoption.md:76-83`)

Regras de canal derivadas dos 4 adapters de trust (`.claude/utils/trust/adapters/*.md`,
`onion-federation-and-adoption.md:88-93`): T2 **bloqueado** para o core — tudo passa pelo hub; T3s são
**isolados entre si**, nem sabem da existência uns dos outros; `private` é **imutável** — nem o core
lê `private` de outro membro em nenhuma circunstância.

### 3.3 Invariante I3 — um escritor por repo (entrega-sem-commit)

Regra dura, citada em `CLAUDE.md` e reforçada em toda a doutrina de doc-bridge: **o core nunca commita
no repo alheio** (nem vice-versa). Os carteiros-locais `co-deliver.sh`/`co-relay.sh` escrevem o
anúncio como **UNTRACKED** no `inbound/`/`inbox/` do outro repo — nunca fazem `git commit` lá; o
commit e o processamento (`git mv` para `_processed/`) é sempre da sessão **dona** daquele repo
(`.claude/utils/co-evolution/co-deliver.sh:11-22`; citação formal em
`onion-federation-and-adoption.md:258`). Untracked persiste entre checkouts de branch, então a entrega
é branch-agnóstica.

Edge case de robustez: `co-deliver.sh` valida que o `member-id` alvo tem `role: hub` ou
`role: standalone` — `role: consumer` (T2) fica **fora** do carteiro-local core→direto, por design
(via-hub apenas) (`.claude/utils/co-evolution/co-deliver.sh:16-19`). Uso inválido / member inexistente
/ role errada / outbox ou alvo ausente → `exit 2` (erro de uso, mensagem em pt-BR); arquivo já presente
no destino → no-op idempotente, `exit 0` (`.claude/utils/co-evolution/co-deliver.sh:26-29`).

### 3.4 Never-clobber — o mecanismo de `/meta:adopt`

Contrato de segurança antes de qualquer fase de adoção (`onion-federation-and-adoption.md:190-197`):

1. **Dry-run primeiro** — todo diff é mostrado antes de qualquer escrita.
2. **Branch dedicada** (`onion/adopt`) — nunca a branch default sem consentimento.
3. **Never-clobber implementado**: extrai para tmp → `diff` contra o alvo → só aplica após revisão.
   Mecanismo de `--update`: **vendor-branch 3-way merge** (`onion/vendor` ramificada, nunca órfã) —
   customização local do alvo vira **conflito git real**, não é sobrescrita em silêncio. Verificado em
   campo: 392 arquivos, 7/7 asserts, desde 2026-07-09.
4. **Idempotente** — re-adotar/atualizar aplica o delta, nunca duplica.

Edge case documentado: `CLAUDE.md` do alvo, se já existir, nunca é sobrescrito — o scaffold escreve em
`CLAUDE.onion.md` em vez disso (`onion-federation-and-adoption.md:210`, Fase 3).

### 3.5 O que nunca é vendorizado a um adotante

Regra de fronteira do manifesto de cópia (`onion-federation-and-adoption.md:284-289`):
`docs/{business,technical,compliance}-context/` (governança do próprio alvo),
`docs/evolution/` (canais são infraestrutura local — copiá-los clobaria inbox/inbound em uso),
`.env`/`.env.example` (never-clobber por-arquivo), e qualquer coisa em
`docs/{analysis,materials,applying}` da fonte.

### 3.6 Três eixos ortogonais de adoção

- **Eixo A — cenário do alvo**: `greenfield` (scaffold direto) | `legacy` (engenharia reversa
  obrigatória, instala em worktree, nunca sobrescreve `CLAUDE.md`) | `regulated` (legacy + compliance
  populado) (`onion-federation-and-adoption.md:216-221`).
- **Eixo B — forma de adoção**: `full` (vendoriza, membro durável) | `docs-only` (só doutrina/docs) |
  `in-place` (efêmero, **fora da federação por construção** — não instala, não carimba, não entra em
  `members.yaml`) (`onion-federation-and-adoption.md:223-227`).

### 3.7 Catraca de verificação — baseline que só encolhe

Dois gates HARD com doutrina de catraca (`onion-federation-and-adoption.md:233-239`): **REGRA 29**
(`kg-provenance-coverage.sh`) — documento novo em `docs/analysis/` ou `docs/evolution/research/` sem
citação em nenhum `.kg.yaml` falha; **REGRA 42** (`doctrine-freshness.sh`) — TTL de 90 dias em
afirmações world-facing sem `verified_at`.

---

## 4. Workflows faseados — a máquina de estado de sessão

Fonte: `CLAUDE.md` (Identidade canônica) + `.claude/commands/engineer/plan.md:24-37` +
`.claude/sessions/`.

### 4.1 Regra de domínio: workflows são invariantes do framework

`product/collect→feature` (descoberta a backlog) e `engineer/plan→pr-update` (planejamento a entrega)
são **invariantes do framework** — decisão explícita de **não** consolidá-los em um único fluxo
(`CLAUDE.md:9-16`, decisão 2026-05-18).

### 4.2 Contrato de fase — vocabulário de estado obrigatório

Todo `plan.md` divide implementação em **fases**, cada uma um chunk auto-contido de 100-300 linhas
(ler a fase N não exige as anteriores em contexto), dimensionada para ~2h de trabalho humano
(`.claude/commands/engineer/plan.md:24-26`).

**Tokens ASCII de estado** (máquina lê, emoji é só decoração para humano):
`[DONE]` / `[ACTIVE]` / `[TODO]` no header de cada fase/tarefa
(`.claude/commands/engineer/plan.md:28`).

**Invariante de máquina de estado**: exatamente **uma** fase `[ACTIVE]` por vez, e ela deve ser igual
a `STATE.md.NEXT.phase` — `STATE.md.NEXT` é o ponteiro **autoritativo** de resume; os badges de fase
são detalhe humano subordinado (`.claude/commands/engineer/plan.md:28,37`). Estado inicial: um plano
recém-criado nasce com Fase 1 `[ACTIVE]` e as demais `[TODO]`.

**Transição de fase**: ao concluir, marcar `[DONE]`, promover a próxima a `[ACTIVE]`, atualizar
`STATE.md.NEXT` (`.claude/commands/engineer/plan.md:37`, remete a `worklog-protocol.md` §6-7).

### 4.3 Sessões como estado persistente

Sessões vivem em `.claude/sessions/<feature>/` (`CLAUDE.md:118`) — evidência real no repo:
`.claude/sessions/adopt-arandek/STATE.md` (sessão ativa) e `.claude/sessions/archived/` (sessões
fechadas, ex.: `2026-07-09_adopt-vendor-branch-merge`, `2026-07-19_onion-guardrails`). O propósito
declarado do vocabulário de fase é justamente permitir **retomar o trabalho** caso a sessão seja
interrompida (`.claude/commands/engineer/plan.md:24`).

---

## 5. Números-âncora (SSOT — nunca hardcode; sempre `docs/onion/inventory.md`)

Lido de `docs/onion/inventory.md:11-14` (gerado por `.claude/validation/inventory.sh`, validado no
CI): 103 comandos invocáveis (10 categorias + root), 51 agentes (9 categorias), 11 skills, 90
Knowledge Bases. Contextos de domínio no próprio framework (template, ainda não populados):
`business-context/` 13 arquivos, `technical-context/` 6, `compliance-context/` 0 (medido 2026-08-13 contra `docs/onion/inventory.md` — o preenchimento greenfield que este arquivo anunciava já avançou; derive de lá, não copie)
(`docs/onion/inventory.md:58-61`) — **este arquivo que você está lendo é parte do preenchimento
inicial de `technical-context/`, greenfield**, conforme o pedido que originou esta geração.

---

## Fora de escopo — seções do template genérico não aplicáveis

- **`api-specification.md`**: o core não expõe uma API HTTP de produto. O único endpoint real é
  `/.well-known/agent-card.json` do `onion-bridge` (canal `a2a-live`, RFC-0004 F2.2) — infraestrutura
  de federação, não domínio de negócio do template; não modelado aqui.
- **Entidades de negócio tradicionais** (`User`/`Order`/etc.): não existem — o "domínio" é o próprio
  framework (comandos, agentes, sessões, membros da federação), coberto nas seções acima.

## Referências

- `docs/meta-specs/integrations.md` — meta-spec L0 de padrões de integração (SDAAL)
- `docs/knowledge-base/concepts/knowledge-graph-sdaal.md` — KG SDAAL completo
- `docs/knowledge-base/concepts/onion-federation-and-adoption.md` — guia-síntese de federação/adoção
- `docs/knowledge-base/concepts/multi-repo-federation.md` — federação formal por contrato
- `docs/knowledge-base/concepts/federation-usage-modes.md` — matriz canônica de 5 eixos
- `.claude/utils/task-manager/interface.md`, `.claude/utils/forge/interface.md` — contratos SDAAL
- `.claude/commands/engineer/plan.md` — contrato de fase/sessão
- `docs/onion/inventory.md` — SSOT numérica
