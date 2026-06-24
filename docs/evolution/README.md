# 🔄 Co-evolução Onion — modelo operacional (canônico)

> **Autoridade:** este diretório é a **fonte canônica** do protocolo de co-evolução entre o **Onion core**
> (`onion-evolve`) e os **projetos que o adotam** (derivados, ex. `rhilo-metagamify`). Projetos
> **referenciam/respondem**; não redefinem. Mantido pela sala de design do core.

## O problema

O Onion (framework) evolui; **muitos projetos** o adotam. Sem método, duas dores aparecem:

1. **Instâncias de IA colidem** — duas sessões mexendo no mesmo repo geram trabalho duplicado e pontes meio-construídas.
2. **O sinal do campo não volta** — bugs e pedidos dos projetos não chegam ao framework de forma rastreável.

## Princípios (estado da arte 2026)

- **Orquestração, não autonomia:** o humano (você) é o **maestro**; agentes rodam async, cada um no seu escopo. O risco que se controla é **ler+interpretar+executar** automático sem gate — **não** "agentes se falarem". **Transportar** e **notificar** mensagens podem ser automáticos (determinísticos); **executar** o que chega é gate humano. A2A é ortogonal. Por isso o **A2A-runtime cross-repo fica `hold`** (auto-execução distribuída + atomicidade multi-repo inexistente), não por proibir conversa. Eixo completo: [`../analysis/onion-adr-comms-transport-vs-execution-2026-06.md`](../analysis/onion-adr-comms-transport-vs-execution-2026-06.md).
- **Coordenação = git-async:** mensagens são **markdown commitado** (padrão *drop-box* / GitHub Squad). "Async dentro do repo escala melhor que tempo-real."
- **Um escritor por repo:** cada repo tem uma sessão dona; **git worktrees** para paralelismo no mesmo repo.
- **Eficiência > cerimônia:** o mínimo que destrava; maquinaria formal só quando se paga.

## Linguagem ubíqua

> Um termo, um significado — compartilhado entre o maestro e **todas** as sessões (DDD). **Onde o mercado
> já tem o termo, usamos o do mercado** (menos esforço cognitivo p/ quem adota o Onion); só cunhamos nome
> próprio onde não existe. Aprofundamento do mapeamento contra a indústria: [`../analysis/onion-vision-concept-map-2026-06.md`](../analysis/onion-vision-concept-map-2026-06.md) §1.

| Termo (nosso) | Significado | Equivalente de mercado |
|---|---|---|
| **Core** | a fonte/fábrica do framework (este repo, `onion-evolve`) | `role: source` · **upstream** · **producer** |
| **Instância adotada** (adotante) | repo que vendorizou o Onion (ex. metagamify, Arandek) | `role: adopted` · **downstream** · **consumer** |
| **Onion de \<repo\>** | a cópia do framework dentro de um repo | **vendoring** (dependência copiada pra dentro) |
| **Sessão do \<repo\>** | um CLI Claude Code ancorado em **1** repo | — (ver *um escritor por repo*) |
| **Maestro** | o humano que orquestra e roteia | **human-in-the-loop (HITL)** / orquestrador |
| **doc-bridge** | canal de markdown commitado entre instâncias | coordenação **async git-backed** (*drop-box* / GitHub Squad) |
| **inbox/** · **inbound/** | os dois canais do doc-bridge no consumidor: `inbox/` = **upstream** (sinal consumidor→core) · `inbound/` = **downstream** (relatório de update/anúncio core→consumidor). Ambos versionados, com `_processed/` p/ lido/não-lido | *outbox* · *inbox* |
| **O que o Onion é** | (p/ explicar a terceiros) | **agent harness** (técnico) · **agentic SDLC framework** (funcional) · specs = **Spec-Driven Development (SDD)** |

**Eixo de papel — mesmo conceito, 3 nomes conforme o contexto** (não são coisas diferentes):
`source = upstream = producer` → **Core** · `adopted = downstream = consumer` → **instância adotada**.
(O stamp `.onion-version` diz `source/adopted`; o `federation/members.yaml` diz `producer/consumer`; a
distribuição fala `upstream/downstream`. **Um eixo só.**)

**⚠️ "control plane":** o nosso (futuro) governa a **evolução do framework** entre repos (≈ *schema/package
registry com governança*) — **não** é o "agent control plane" de **runtime** do mercado (OpenHands, Galileo…).
Sempre qualificar para não colidir.

**Regra anti-ambiguidade:** nunca dizer **"o Onion" / "a sessão" / "a instância"** cru — **sempre qualificar
com o repo** ("o Onion do Arandek", "a sessão do metagamify").

**Convenção do assistente:** em toda ação de **escrita**, o assistente prefixa o repo-alvo —
`[Core]`, `[Arandek]`, `[metagamify]` — para o maestro nunca confundir qual ponta está sendo tocada.

## Os 3 fluxos

### Downstream — Core → projetos (distribuição)
*Quando o framework muda, os projetos descobrem e adotam com segurança.*
- **Registro:** [`federation/members.yaml`](federation/members.yaml) — quem adota o Onion e em que versão.
- **Pin de versão:** cada projeto carrega `.claude/.onion-version` (commit de origem).
- **Anúncio:** o core registra mudanças relevantes em [`federation/CHANGELOG.md`](federation/CHANGELOG.md).
- **Atualização no projeto:** `/meta:adopt --update` (deliberado, nunca link vivo).
- **Canal + notificação no consumidor:** a adoção/update **auto-emite o relatório** no `inbound/` do alvo
  (git-visível) e o hook "you have mail" o sinaliza — o maestro não precisa repassá-lo à mão. `inbound/` é o
  **próprio** canal de downstream (≠ `inbox/`, que é o outbox de upstream). Lido/não-lido via `git mv` p/ `inbound/_processed/`.
- **Carteiro (transporte automático)** 🟠 *a-desenhar:* hoje o **relay entre repos é manual** (o maestro
  cruza as pontas). O carteiro automatiza só **transporte + notificação** (atos 1-2), nunca a execução
  (ato 3): **pull pelo destino** (respeita "um escritor por repo"), reusando ledger git + scripts
  determinísticos. Design no [ADR do eixo](../analysis/onion-adr-comms-transport-vs-execution-2026-06.md); liga no gatilho de graduação.

### Upstream — Projetos → core (sinal + pedido de ajuda) ← o loop de co-evolução
*Um projeto reporta bug, dá feedback, **pede ajuda/feature**, manda status.*
- **Canal:** [`inbox/`](inbox/) aqui no core. O projeto deposita um markdown datado (`AAAA-MM-DD-<assunto>.md`).
- **Exemplo real:** o bug do `.env.example` (dogfooding no metagamify) virou o fix `#89`. O 1º veredito do metagamify está em [`inbox/`](inbox/).

### Handoff — Dentro de um repo (sessões paralelas)
*Duas sessões no mesmo repo não colidem.*
- **git worktrees** (isolamento) + **um escritor por escopo** + **handoff commitado** (cada sessão registra o que fez antes de sair).

## Notificação & gerenciamento do inbox ("you have mail")

Você não precisa lembrar de checar — o **SessionStart hook** avisa no boot:

- **Hook** (`.claude/hooks/co-evolution-inbox-check.sh`, registrado em `.claude/settings.json`): no início
  da sessão conta as mensagens não-processadas e injeta o aviso. **Bidirecional** — cobre os dois canais,
  cada um com sua label: `📬 … inbox (upstream: sinal/feedback)` + `📥 … inbound/ (downstream: relatório de
  update/anúncio)`. **Silencioso quando 0** em ambos (disciplina de *motd*). É o primitivo "you have mail on
  login" — o único que dispara sozinho (memória e `/warm-up` não). _(O nome do arquivo mantém `inbox-check`
  por estabilidade do registro nos consumidores já adotados; o comportamento cobre os dois canais.)_
- **Comando [`/meta:co-evolve`](../../.claude/commands/meta/co-evolve.md)**: lê e gerencia — detecta o papel
  do repo (`.onion-version`), resume as mensagens, orienta conforme core/consumidor.
- **Lido/não-lido (git-visível, sem state file):** ao tratar uma mensagem, `git mv` dela para
  `_processed/` do canal (`inbox/_processed/` ou `inbound/_processed/`). O hook só conta o 1º nível de cada
  canal, então processadas somem do aviso.

Esse trio (hook + comando + `_processed/`) vive em `.claude/`/`docs/evolution/` → **core e todo projeto
herdam** o mesmo "you have mail".

## Seu ritual (maestro)

1. **Início de sessão:** `git fetch` + ler o `inbox/` do repo (e, se for sessão de projeto, o `inbound/` p/ relatórios do core + o `inbox/` do core).
2. **Projeto precisa de algo do core** → deposita mensagem no `inbox/` do core (upstream).
3. **Core mudou algo que afeta projetos** → registra no `CHANGELOG.md` (downstream); projetos puxam via `/meta:adopt --update`.
4. **Você roteia** entre os repos e decide a ordem de merge. **Uma sessão por repo**; se uma sessão cobrir outro repo (a ponta estava adormecida), **logue quem fez** no handoff e commit isolado.

## Ownership — de quem é a RFC?

- O **core (`onion-evolve`) é dono** do protocolo e da **série de RFCs** de co-evolução ([`rfc/`](rfc/)).
- Projetos **referenciam/respondem** — não mantêm série própria.
- A `rfc-0001` foi rascunhada no `metagamify` e **promovida aqui como canônica**; a cópia de lá vira referência.

## Fundamentação 2026 (por que assim)

| Decisão | Base (estado da arte) |
|---|---|
| Coordenação por arquivo commitado no repo | *drop-box* do GitHub Squad — async no repo escala melhor que tempo-real |
| Humano maestro, agentes async por escopo | "Coerência por orquestração, não autonomia" (consenso 2026) |
| A2A-runtime cross-repo = `hold` | risco = auto-execução distribuída (ato 3 sem gate) + atomicidade multi-repo inexistente; A2A v1.2 (LF) é peso cross-org enterprise. Não é "proibir conversa" — ver [ADR do eixo](../analysis/onion-adr-comms-transport-vs-execution-2026-06.md) |
| Registro + pin de versão | manifest-pinning (textbook); multi-repo custa 15–30% em coordenação |

Fontes: [GitHub Squad](https://github.blog/ai-and-ml/github-copilot/how-squad-runs-coordinated-ai-agents-inside-your-repository/) · [Orchestration not autonomy](https://mikemason.ca/writing/ai-coding-agents-jan-2026/) · [LF Agent2Agent](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents) · [Multi-repo coordination tax](https://medium.com/@kantmusk/the-20-coordination-tax-every-multi-repo-javascript-team-pays-in-2026-f58d1a6b85d3)

## Gatilho de graduação (quando ligar a Federação formal)

Hoje a coordenação é **leve**: registro + inbox + changelog. **Ligar contratos versionados + tests/fixtures + ciclo `publish/check`** (comandos `/meta:federation-*`, **já implementados**) quando:

- surgir um **contrato que pode quebrar** consumidores (ex.: mudança *breaking* no `/meta:adopt --update`); **ou**
- o nº de projetos tornar o roteamento manual custoso (a 15–30% de "coordination tax" começa a doer).

Até lá, o humano roteia e o doc-bridge basta.
