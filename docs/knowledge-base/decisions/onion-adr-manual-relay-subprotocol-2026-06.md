---
title: 'ADR — Sub-protocolo do transporte manual de co-evolução: relay upstream entrega-sem-commit (/meta:co-relay)'
date: 2026-06-27
type: adr
status: accepted
decision-scope: co-evolution / manual-transport
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - ../evolution/rfc/rfc-0001-co-evolution-comms.md (protocolo dos 3 fluxos — invariantes; I3 = um escritor por repo)
  - onion-adr-comms-transport-vs-execution-2026-06.md (eixo dos 3 atos: transportar/notificar auto, executar = gate)
  - onion-adr-ledger-format-location-2026-06.md (Carteiro-local liberado não-gated; Decisão 3 — corrigida aqui)
  - ../../.claude/commands/meta/co-deliver.md (espelho downstream — entrega-sem-commit)
  - ../../.claude/commands/meta/co-relay.md (mecanismo deste ADR)
  - ../evolution/inbox/2026-06-25-sinal-mecanica-transporte-regime-manual.md (sinal S2 — origem)
---

# ADR — Sub-protocolo do transporte manual de co-evolução (relay upstream)

> **Status: ACEITO** (2026-06-27). Responde ao sinal de campo **S2** (um adotante, 2026-06-25): o
> regime *manual* do doc-bridge não tinha sub-protocolo determinístico, e a IA improvisou — commitou
> cross-repo na branch errada e escalou ao humano decisões que o ADR 3-atos já classifica como Ato-1
> determinístico. Este ADR fixa o **como** do regime pré-carteiro-distribuído, reusando o padrão que o core
> já tinha (co-deliver, entrega-sem-commit) e estendendo-o à direção que faltava (upstream).

## Contexto / Origem (S2)

Numa sessão do **adotante**, ao transportar pela 1ª vez um sinal para o `inbox/` do **core** (operando o
doc-bridge de verdade), a IA:

1. Executou uma **escrita cross-repo a partir da sessão do adotante** (zona cinza frente ao invariante I3 —
   "a sessão nunca pusha/escreve em repo alheio; o maestro transporta").
2. **Commitou na branch errada** do core (uma feature branch em check-out), porque não havia guarda que
   forçasse o pouso no canal certo.
3. **Escalou ao humano** "em qual branch? push ou não?" — quando o **ADR 3-atos** já diz que **transporte é
   Ato-1 (determinístico)**. Erro de classificação: tratou mecânica de Ato-1 como juízo de Ato-3.

**Lacuna real:** o core já tinha o padrão certo para *downstream* — o `/meta:co-deliver`
+ `co-deliver.sh`, que **entrega-sem-commit** (escreve o arquivo **untracked** no canal do alvo; o hook conta
arquivos → notifica; o **commit é da sessão home do destino**). Faltava o **espelho upstream**
(adotante→core `inbox/`). co-deliver é core-only + downstream-only.

## Decisão 1 — Transporte upstream = entrega-sem-commit (branch-agnóstico)

O relay upstream **copia o sinal como untracked** no `inbox/` do core; **nunca commita nem pusha** em repo
alheio. A **sessão home do core** commita e tria (Ato-3, com contexto local). Mecanismo: **`/meta:co-relay`**
+ `.claude/utils/co-evolution/co-relay.sh` (espelho simétrico do co-deliver).

**Corolário (dissolve o incidente):** sem commit cross-repo → **não existe "branch errada"** (untracked
persiste entre checkouts, é branch-agnóstico) → **não existe pergunta de push** → **nada a escalar**. As
perguntas que a IA subiu ao humano em S2 *desaparecem por construção*.

## Decisão 2 — Rejeitar worktree+commit; corrigir o vocabulário "worktree" do ADR de ledger

O script worktree+commit que o sinal S2 propôs é uma **regressão**: re-introduz exatamente o commit
cross-repo que causou o incidente (tensiona I3 mesmo sem push — ver Decisão 7). **Rejeitado.**

A **Decisão 3 do [ADR de ledger](onion-adr-ledger-format-location-2026-06.md)** descreve o Carteiro-local
como "branch certa via **worktree**, entrega-sem-commit" — mas o `co-deliver.sh` real **abandonou o
worktree**: é `cp` branch-agnóstico (cabeçalho do script: *"untracked persiste entre checkouts → entrega
branch-agnóstica"*). Este ADR **registra a correção**: o mecanismo canônico é a **cópia untracked**, não o
worktree — para que uma instância futura não reintroduza worktree achando que o ledger-ADR o endossa.

## Decisão 3 — RACI do regime manual

| Ato | O quê | Quem | Gate |
|-----|-------|------|------|
| **1 — Transportar** | copiar o sinal untracked entre as caixas (relay/deliver) | **IA = Driver** (via script determinístico) | nenhum (Ato-1) |
| **2 — Notificar** | sinalizar 📬/📥 que chegou mensagem | hook SessionStart (`co-evolution-inbox-check.sh`) | automático |
| **3 — Ler + interpretar + commitar/branch/push** | versionar + triar + agir no destino | **humano = Approver**, na **sessão home** | **gate humano** |

**Regra de classificação (a que faltava):** "em qual branch? push?" **no contexto do transporte** são Ato-1
(determinístico, resolvido: untracked, branch-agnóstico, sem push) — **não escalar**. Só a **execução no
destino** (commit consciente, merge, push do que foi triado) é Ato-3.

## Decisão 4 — Vocabulário de papéis

- **maestro = humano** (autoridade final, Approver do Ato-3) — já é o uso dominante nos docs (README, RFC,
  ADRs). Mantido.
- **maestro principal / core** = `onion-evolve` (rege a evolução, ratifica o canon). Padroniza-se "core" ou
  "maestro principal"; **abandona-se "mestre"** (que aparecia solto e gerava a inversão semântica apontada
  em S2/P2).
- **sessão/repo home do destino** = quem commita o que foi entregue untracked.
- **Guarda canônica de papel = o STAMP `.claude/.onion-version` (campo `role:`)** — **nunca**
  `onion-version.sh` (hardcoda `role: source`; cópia byte-idêntica no adotante mentiria 'source' →
  falso-amigo). `co-evolve.md` já fazia certo; `co-deliver.md`/`co-announce.md` foram corrigidos.

## Decisão 5 — "Silêncio ≠ consentimento"

Formaliza-se a invariante: **a ausência de resposta do core não autoriza o adotante a agir sobre ele**. É
**distinto** do "silêncio = veto" do `federation-inbox-scan` (lá, falta de aprovação **bloqueia** um
contrato). Aqui: o adotante relaya (Ato-1) e **espera**; sem anúncio de volta no `inbound/` (fluxo A), o
adotante é cego ao core — por isso responder a um sinal exige **anúncio explícito** (silêncio do core =
invisível ao adotante). O notify upstream já funciona (hook conta `inbox/` → 📬 no core).

## Decisão 6 — Fora de escopo (Fase 2, só com uso real — disciplina Tech Radar)

Convenção de chave de artefato (`uuidv7`/`ulid`, P3); comando/skill/KB dedicados de "toolbox" de transporte
(P4); auto-notify bidirecional rico (P5-parte-2). Ligam quando o uso real provar valor (assess→trial).

## Decisão 7 — Coerência com invariantes (não contradiz)

- **ADR 3-atos:** Ato-1 "mover a mensagem entre as caixas... ✅ pode ser automático (carteiro)". O relay **é**
  o Ato-1. Endossa.
- **I3 (um escritor por repo, RFC-0001):** o escritor é **quem versiona (commita)**. A cópia untracked **não
  versiona** — quem commita continua sendo a sessão home do destino. Logo **"untracked-copy ≠ escrita
  versionada"** → I3 preservado. (O worktree+commit, ao contrário, versionaria no repo alheio → violaria I3:
  o incidente S2 é a materialização disso.)
- **Simetria com co-deliver:** a aceitação de "untracked é entrega, não durabilidade" já foi feita downstream
  (`co-deliver.md`); upstream herda a mesma postura.

## Consequências

- **Cria:** `/meta:co-relay` + `co-relay.sh` (espelho upstream) + selftest das guardas (`run_corelay_selftests`).
- **Edita:** `co-evolve.md` (wire o relay no ramo consumidor); `co-deliver.md`/`co-announce.md` (guarda de
  papel via stamp; fix do "mestre" solto).
- **Distribuição:** o relay só existe no adotante após `/meta:adopt --update`.
- **Não muda:** A2A-runtime cross-repo segue proibido; gate humano para irreversível; validação
  determinística-sem-LLM.

## Alternativas consideradas

- **A-estrito** (só o humano transporta, à mão): mantém o toil de Ato-1 no colo do maestro — a dor que
  originou S2. Rejeitado.
- **B-worktree+commit** (proposta do sinal): regressão (re-introduz o commit cross-repo). Rejeitado (Decisão 2).
- **Generalizar co-deliver p/ bidirecional role-aware:** fonte e guarda divergem demais (outbox+members.yaml
  vs inbox+stamp) → vira if-ladder por role e muda o contrato estável do co-deliver. Sibling `co-relay` é
  mais limpo (mesma lição de co-announce/co-deliver serem separados).

## Gatilho de revisão

Promover a Fase 2 (Decisão 6) quando o relay manual provar uso real repetido **ou** o nº de adotantes
elevar a "coordination tax". Até lá, co-deliver + co-relay + o maestro bastam.

## Conexão com o sinal S1 (toolbox)

Este ADR é o **1º caso concreto** do sinal S1 (padrão "toolbox"): o critério de classificação —
*procedimento recorrente → script determinístico (controle) + comando (juízo/quando) + ADR (doutrina) +
human-gate (irreversível)* — é o que S1 pede como meio de 1ª classe. Resolver S2 **destila** esse critério
sem construir o S1 inteiro.
