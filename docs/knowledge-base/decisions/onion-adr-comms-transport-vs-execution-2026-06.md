---
title: "ADR — Eixo de risco da comunicação: transporte (auto) vs execução (gate)"
date: 2026-06-20
type: adr
status: accepted
decision-scope: co-evolution
supersedes: none
related:
  - ../evolution/README.md
  - ../knowledge-base/concepts/multi-repo-federation.md
  - ../knowledge-base/concepts/agent-orchestration.md
  - onion-federation-adr-a2a-format-interop-2026-06 (core-only)
  - onion-federation-design-v2-2026-06 (core-only)
---

# ADR — Eixo de risco da comunicação: transporte (auto) vs execução (gate)

| Campo | Valor |
|-------|-------|
| **Decisão** | Reposicionar o eixo de risco da comunicação entre repos: o que se controla **não** é "A2A sim/não", e sim **três atos** — transportar e notificar (automatizáveis, determinísticos) vs **ler+interpretar+executar** (gate humano obrigatório). A2A é **ortogonal** ao risco. |
| **Escopo** | Co-evolução / federação multi-repo. Não toca produto/engenharia/compliance. |
| **Status** | ✅ **Aceito (doutrinário)** em 2026-06-20. Nenhum código muda agora; especifica o **carteiro** como design e fixa a postura sobre **Agent Teams** cross-repo. |
| **Origem** | Correção conceitual do maestro ao revisar a automação do relay (sessão 2026-06-20), sobre os sinais `inbox/_processed/2026-06-19-*`. |

---

## Status

✅ **Aceito (doutrinário)** — 2026-06-20. O **carteiro** (Decisão 2) é **design**, não implementação —
liga no gatilho de graduação da co-evolução. A linha vermelha do A2A-runtime cross-repo **permanece**;
muda apenas a **razão** registrada (e, com ela, o vocabulário da doutrina).

---

## Contexto

### Como o problema emergiu

A feature 1 (canal `inbound/` + "you have mail" bidirecional + relatório auto-emitido) fechou a
**entrega e a notificação** do downstream. Ao discutir o passo seguinte — **automatizar o relay** entre
repos —, o maestro corrigiu uma imprecisão da doutrina:

> O risco **não é** "A2A" (dois agentes se falarem). O risco é **leitura + execução automática** sem
> gate humano. O *meio* é que preocupa.

### A imprecisão na doutrina vigente

A doutrina rotula o eixo de risco como **"A2A-runtime = linha vermelha"** (`evolution/README.md:16`;
`multi-repo-federation.md §7`; RFC-0001). Mas, **na prática**, o Onion já age por outro eixo:

- **automação determinística é abraçada** — scripts em `.claude/validation/` (sem LLM) validam
  contratos, escaneiam inbox, detectam drift (`multi-repo-federation.md:117-125`);
- **gate humano é exigido para decisões** — "control before autonomy" (`agent-orchestration.md
  §7.5`), checkpoints de publish/rollback, "a orquestração propõe, o humano confirma".

Ou seja: o Onion **nunca** controlou "agentes se falarem". Ele controla **quem executa e com qual
gate**. Chamar isso de "A2A" confunde — e foi o que o ADR `a2a-format-interop` já começou a desfazer
(separando runtime-proibido de formato-permitido). Esta ADR conclui a correção.

---

## Decisão 1 — O eixo correto: três atos

A comunicação entre repos decompõe-se em **três atos** com fronteiras de automação distintas:

| Ato | Exemplo | Determinístico? | Automação |
|-----|---------|-----------------|-----------|
| 1. **Transportar** | mover a mensagem entre as caixas dos repos | sim (mover arquivo + git) | ✅ pode ser automático ("carteiro") |
| 2. **Notificar** | avisar que uma mensagem chegou | sim (contar arquivos) | ✅ já automático (hook "you have mail") |
| 3. **Ler + interpretar + executar** | aplicar um update, mudar código, responder | **não** (exige juízo) | 🔴 **gate humano obrigatório** |

**Corolários:**

- **A2A é ortogonal ao risco.** Dá para ter A2A sem auto-executar (seguro) e auto-execução sem
  nenhum A2A (perigoso). O eixo de risco é o **ato 3**, não a existência de troca de mensagens.
- **A linha vermelha do A2A-runtime cross-repo permanece** — mas pela razão certa: ela evita
  **auto-execução distribuída** (ato 3 sem gate, em escala multi-repo) somada à **atomicidade
  multi-repo inexistente** (merge atômico cross-repo não existe no git). Não é "porque agentes não
  podem se falar".
- **Reconciliação:** esta ADR não contradiz nada — ela **renomeia o eixo** que a doutrina já seguia.
  Determinístico-vs-LLM e "control before autonomy" são **instâncias** deste eixo.

---

## Decisão 2 — O carteiro (design, não implementação)

O gap real hoje **não** é o método (git-async é adequado), é a **fricção do transporte manual**: o
maestro copia mensagens de um repo para outro à mão (meta-aprendizado registrado em
`inbox/_processed/2026-06-19-mgfy-adocao-update-a0fdf35.md`). O **carteiro** automatiza os atos 1+2 —
**nunca** o ato 3.

**Princípios de design:**

1. **Pull pelo destino, nunca push no alheio.** A sessão do repo-destino *puxa* o que lhe é
   endereçado. Respeita a invariante **"um escritor por repo"** (`evolution/README.md`): cada repo
   escreve apenas em si mesmo. (É o mesmo padrão de `/meta:federation-check`, que lê e veta.)
2. **Só transporta e notifica.** Move/disponibiliza a mensagem e dispara o "you have mail". **Não**
   interpreta nem age sobre o conteúdo — isso é a sessão do destino + o maestro (ato 3).
3. **Gate leve, não copy-paste.** O agente **propõe** a entrega; o maestro **confirma** num gesto.
   Elimina o trabalho manual sem conceder auto-execução.
4. **Reusa o que já existe** — sem inventar substrato:
   - **ledger git como working dir** (spike Fase 0 validado, `git-ledger-as-working-dir.md`): o canal
     comum entre repos, montado como *additional working directory* nativo;
   - **scripts determinísticos** modelo `federation-inbox-scan.sh` (com fail-safe **"silêncio = veto"**);
   - o **doc-bridge** `inbox/`/`inbound/` (a feature 1).
5. **Não toca a camada git local.** O carteiro vive na camada de **co-evolução/federação**. As "git
   skills" (`/git/*`, `gitflow-patterns.md`) e o **forge** (PR/CI/Release) são o instrumento de
   escrita *dentro* de um repo — camadas distintas, sem acoplamento (ver [Como o git se encaixa](#como-o-git-se-encaixa)).

**Posição no backlog:** o carteiro é o **"doc-bridge pull"** — uma extensão leve do doc-bridge atual,
anterior (ou ponte) à Federação formal (Fase 2 `publish`/`check` do
`onion-federation-design-v2-2026-06.md`). Liga no **gatilho de graduação** (contrato breaking OU
nº de repos tornando o relay manual custoso).

---

## Decisão 3 — Agent Teams fora da co-evolução cross-repo

**Agent Teams** (feature oficial do Claude Code, experimental, atrás de
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) **não entra** na comunicação entre repos — por **dois
motivos independentes**:

1. **Doutrina:** seria justamente o **ato 3 vivo e distribuído** (peers que se auto-reclamam tarefas e
   agem). É o que a linha vermelha evita.
2. **Limitação técnica oficial:** Agent Teams coordena **dentro de uma sessão/worktree** — **não
   suporta multi-repo nativo**. O próprio caso da Anthropic (compilador C com Claudes paralelos) usou
   **git + file-lock**, não Agent Teams.

**Onde Agent Teams cabe:** **dentro de um repo**, como terceiro modo opt-in da orquestração, só quando a
coordenação precisa de *negociação viva* não pré-desenhável como grafo — com o default permanecendo
**Workflow** (determinístico, 0-token, auditável). Detalhe na KB `agent-orchestration.md`.

---

## Como o git se encaixa

A co-evolução é **git-async** (mensagens = markdown commitado). O carteiro **reusa git como
transporte**, via o **ledger montado como working dir** + scripts determinísticos, na camada de
federação. **Não** mexe em `/git/*` (git local: branch/merge/tag/push intra-repo, refatorados em
`1ca200c`) nem no **forge** (host remoto: PR/CI/Release, `0f21714`). Três camadas limpas:

| Camada | Domínio | Instrumento |
|--------|---------|-------------|
| Git local | dentro de 1 repo (branch/merge/tag/push) | `/git/*` + `gitflow-patterns.md` |
| Forge | host remoto (PR/CI/Release) | `.claude/utils/forge/` |
| **Co-evolução/federação** | transporte cross-repo | ledger git + scripts determinísticos + doc-bridge |

O carteiro é **orquestração da terceira camada** — as outras duas seguem intactas.

---

## Consequências

- **Doutrina:** `evolution/README.md` e `agent-orchestration.md` passam a falar do eixo dos três
  atos; o rótulo "A2A" deixa de carregar o peso do risco (que é o ato 3).
- **Implementação:** nada muda agora. O carteiro entra no backlog como design pronto.
- **O que NÃO muda:** A2A-runtime cross-repo segue proibido; "um escritor por repo", gate humano para
  irreversível, e validação determinística-sem-LLM seguem invariantes.

## Gatilho de implementação

Construir o carteiro quando o relay manual passar a doer (contrato breaking que precise propagar; ou
nº de repos adotantes elevando a "coordination tax"). Até lá, a feature 1 (entrega + notificação) +
o maestro bastam.

## Referências

- Eixo prévio (formato vs runtime): `onion-federation-adr-a2a-format-interop-2026-06.md` (core-only)
- Federação (fases, ledger): `onion-federation-design-v2-2026-06.md` (core-only)
- Doutrina dos 3 fluxos: `../evolution/README.md` (core-only)
- Determinístico-vs-LLM + fail-safe: [`../knowledge-base/concepts/multi-repo-federation.md`](../../knowledge-base/concepts/multi-repo-federation.md)
- Workflow vs Agent Teams + control-before-autonomy: [`../knowledge-base/concepts/agent-orchestration.md`](../../knowledge-base/concepts/agent-orchestration.md)
- Sinais de campo: `../evolution/inbox/_processed/2026-06-19-flow-a-report-and-bidirectional-mail.md` · `../evolution/inbox/_processed/2026-06-19-mgfy-adocao-update-a0fdf35.md`
