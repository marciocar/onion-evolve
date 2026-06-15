---
title: Avaliação — Agent Teams no Sistema Onion (junho/2026)
date: 2026-06-15
author: Sistema Onion (assistido por IA)
status: proposta
scope: framework-template-instalavel
decisao: opt-in-terceiro-modo-com-fallback-gracioso  # NÃO padrão obrigatório
relacionados:
  - onion-review-2026-05.md                                       # identidade canônica
  - ../knowledge-base/concepts/agent-fleet-orchestration.md        # doutrina de frota
  - ../knowledge-base/frameworks/agent-orchestration-landscape-2026.md
  - ../knowledge-base/concepts/onion-modernization-doctrine.md
ciclo-de-vida: efêmero  # sintetizar a conclusão na doutrina de frota e remover (ver analysis/README.md)
---

# Avaliação — Agent Teams no Sistema Onion (junho/2026)

## 1. Decisão (TL;DR)

**Agent Teams NÃO se torna padrão do framework em junho/2026, e NÃO exige revisar os padrões vigentes.**
É uma vantagem real para **uma forma específica de trabalho** que hoje o Onion não cobre bem
(negociação viva entre agentes peer). O lugar canônico dele é **terceiro modo de orquestração,
opt-in, atrás de detecção de capacidade com fallback gracioso** — o mesmo espírito SDAAL dos
adapters de forge e task-manager. Nunca um requisito duro.

| | Decisão |
|---|---|
| Vira padrão obrigatório do Onion agora? | **Não** |
| Exige rever os padrões existentes (sessões faseadas, Workflow/onion-fleet)? | **Não** |
| É vantagem real para algum shape de trabalho? | **Sim — nicho** (negociação viva peer-a-peer) |
| Postura recomendada | **Capacidade opt-in** + detecção + fallback gracioso |

---

## 2. Contexto

Em 2026-06-15 a flag experimental `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` foi ligada no
`~/.claude/settings.json` e **validada empiricamente** nesta sessão (ver §5). Isso destrava as
ferramentas nativas de Agent Teams: `TeamCreate`/`TeamDelete`, `SendMessage` (mailbox entre
sessões Claude Code), e uma **task list compartilhada** (`TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet`
com `owner`/`blockedBy`). A pergunta de framework: isso muda a identidade/padrões do Onion?

A **identidade canônica** ([onion-review-2026-05.md](onion-review-2026-05.md)) fixa: framework
**template em `.claude/`** instalável em qualquer projeto, **plataforma única Claude Code**, três
dimensões peer (produto/engenharia/compliance), **workflows faseados retomáveis**, e frota via
`onion-fleet`/`Workflow`.

---

## 3. As três primitivas de orquestração

Com Agent Teams, o Onion passa a ter **três** modelos de orquestração — complementares, não
concorrentes:

| Primitiva | Modelo | Controle | Estado | Bom para |
|-----------|--------|----------|--------|----------|
| **Sessões faseadas retomáveis** (`.claude/sessions/`) | 1 thread, humano no loop | Determinístico, durável em arquivo (worklog) | Persistente | `product/collect→feature`, `engineer/plan→pr-update` — o **backbone** |
| **Workflow / onion-fleet** | Fan-out de workers **stateless** | **Determinístico** (script: loop/cond/pipeline), retomável por journal | Efêmero | Auditoria, migração, review, pesquisa — **shape conhecido a priori** |
| **Agent Teams** (novo) | Peers **persistentes** + mailbox + task list compartilhada | **Emergente** (model-driven; agentes negociam) | Idle entre turnos; `owner`/`blockedBy` | Negociação viva entre sub-streams; hand-off dinâmico; humano redirecionando no meio |

A distinção que importa: **Workflow = orquestração que o orquestrador desenha** (a forma é
conhecida antes de começar). **Agent Teams = coordenação que emerge** (os agentes se acertam em
runtime).

---

## 4. Análise

### 4.1 Onde é vantagem genuína
- **Negociação viva entre agentes.** Ex.: feature full-stack onde front e back precisam acertar um
  contrato de API em tempo real. O fan-out stateless do Workflow não permite diálogo; o mailbox do
  Agent Teams sim.
- **Humano no loop redirecionando no meio do voo.** As mensagens dos teammates chegam ao lead como
  turnos; dá para reatribuir/corrigir sem reiniciar — um script Workflow roda até o fim.
- **Task list nativa com `owner`/`blockedBy`** é prima conceitual da **Task Manager Abstraction**
  do Onion. Há uma ponte futura (espelhar a lista local no provider ativo), mas é especulativa e
  acopla — fora de escopo desta decisão.

### 4.2 Bloqueadores para virar padrão (honestos)
1. **Experimental + gated + acoplado a versão.** Off por default, atrás de flag, exige versão
   específica do Claude Code. O Onion é um **template instalado em qualquer projeto**; tornar isso
   obrigatório quebraria a invariante de **portabilidade** ("instala em qualquer lugar"). Há
   regressões conhecidas (param `resume` da tool `Agent` removido ~v2.1.77; sem resumption de
   teammate in-process; sem split-panes no terminal integrado do VS Code).
2. **Não-determinismo × identidade de compliance.** O Onion cobre **governança como dimensão peer**.
   Coordenação emergente é mais difícil de **reproduzir, verificar e auditar** — atrito direto com a
   doutrina *fail-loud-and-resume* (afirmar "essa fase terminou?" fica mais difícil no modelo
   idle/mailbox).
3. **Risco de bloat.** Uma 3ª primitiva sem fronteira clara ("use X quando Y") incha a frota e gera
   paralisia de decisão — contra a doutrina de modernização (SSOT/inventário enxuto).

### 4.3 Por que NÃO força revisão dos padrões atuais
Agent Teams **não depreca** nem as sessões faseadas nem o Workflow. Preenche um shape que nenhum dos
dois cobre (negociação viva). Logo, é **adição opt-in**, não substituição.

---

## 5. Evidência empírica (esta sessão, 2026-06-15)

**Smoke-test de conectividade — PASS (6/6 etapas):**
`TeamCreate` → `Agent` spawn com `team_name`+`name` (background) → `SendMessage` lead→teammate
(`success:true`) → resposta teammate→lead **automática** (sem polling, como novos turnos) →
`shutdown_request` (approved) → `TeamDelete`. Comunicação bidirecional confirmada.

**Demo de task list compartilhada — PASS + output verificado contra a SSOT:**
Time `onion-teams-demo` com 3 tasks (2 independentes + 1 síntese `blockedBy [1,2]`), `owner`
atribuído a dois teammates (`counter-a`, `counter-b`). Cada um reivindicou sua task, executou Bash
real e reportou:

| Métrica | Reportado pelos teammates | Sonda determinística no loop principal | Inventário canônico (CLAUDE.md) | Bate? |
|---|---|---|---|---|
| Agentes em `.claude/agents` | 49 | 49 | 49 | ✅ |
| Comandos invocáveis em `.claude/commands` | 78 | 78 | 78 | ✅ |

Relevância para a §4.2(2): com a flag ligada, os agentes fizeram **tool calls reais** e reportaram
números **exatos** (cross-check triplo bateu). Isso refuta, **neste ambiente**, o modo de falha
histórico `tool_uses:0`/alucinação registrado na memória de IA. **Ressalva:** a confiabilidade do
*output* não elimina a §4.2(2) — o ponto da auditabilidade é sobre a *coordenação emergente*, não
sobre a aritmética de um worker isolado. A disciplina de cruzar veredito de agente com sonda própria
no loop principal **permanece** obrigatória em apostas altas.

**Addressabilidade humana confirmada (corrobora §4.1):** durante a demo o usuário enviou uma
mensagem **diretamente** ao teammate `counter-a`. O agente reconheceu que o pedido estava fora do
escopo da sua task (#1, contagem) e, corretamente, permaneceu idle e pediu direção em vez de agir
por conta própria. Isso demonstra dois pontos a favor: (a) o humano consegue endereçar um teammate
individual pelo mailbox — exatamente a capacidade de "humano no loop redirecionando no meio do voo"
(§4.1); e (b) o agente fez *scoping* correto, não extrapolou. (Não é evidência de não-determinismo
— a §4.2(2) se sustenta por mérito próprio, independente deste episódio.)

---

## 6. Postura recomendada

1. **Manter os padrões atuais intactos.** Nenhuma mudança em sessões faseadas ou Workflow/onion-fleet.
2. **Adotar Agent Teams como capacidade opt-in:** `onion-fleet` **detecta** a flag e **prefere**
   Agent Teams **apenas** para o shape "negociação viva entre peers"; **degrada graciosamente** para
   Workflow/serial quando a flag está off — idêntico ao padrão dos adapters forge/task-manager
   (avisar em pt-BR, nunca assumir).
3. **Fronteira na doutrina.** Adicionar à KB
   [`agent-fleet-orchestration`](../knowledge-base/concepts/agent-fleet-orchestration.md) uma seção
   "Workflow vs Agent Teams: quando usar qual" + nota de capacidade opt-in. Atualizar a
   [`agent-orchestration-landscape-2026`](../knowledge-base/frameworks/agent-orchestration-landscape-2026.md)
   se descrever o cenário.
4. **Não** criar comando/skill dedicado a Agent Teams antes da fronteira de doutrina existir (evita
   bloat sem boundary).

---

## 7. Próximos passos (não executados aqui)

- [x] Sintetizar a fronteira "Workflow vs Agent Teams" na KB `agent-fleet-orchestration` (a conclusão
      duradoura desta análise vive lá). — **feito 2026-06-15** (seção "🔀 Dois Substratos de Orquestração", KB v1.2.0).
- [ ] Implementar detecção de capacidade + fallback gracioso em `onion-fleet` (espelhar o padrão
      SDAAL dos adapters).
- [ ] Reavaliar quando a feature sair de experimental (remover a ressalva de portabilidade da §4.2).
- [ ] **Ao concluir os itens acima:** condensar este doc na doutrina e **remover** o artefato
      (`git rm`), conforme [analysis/README.md](README.md) — análises são efêmeras.

---

## 8. Conclusão

Vantagem real **sim**, mas para um nicho. Padrão do Onion em junho/2026 **não** — e não exige rever os
padrões vigentes. Exige **adicionar** um modo opt-in com fronteira clara e degradação graciosa,
preservando a portabilidade e a auditabilidade que definem a identidade do framework.
