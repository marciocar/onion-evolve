---
name: co-relay
description: 'Carteiro-LOCAL do doc-bridge (UPSTREAM) — espelho do /meta:co-deliver. Relaya um sinal do adotante (docs/evolution/inbox/) direto no inbox/ do CORE que vive na MESMA máquina, para o hook "you have mail" sinalizar 📬 sem o maestro copiar à mão. ENTREGA-SEM-COMMIT (o adotante nunca commita no repo alheio — invariante I3); o commit + triagem é da sessão do core. Dissolve o incidente "commit cross-repo na branch errada" (sinal S2): sem commit, não há pergunta de branch/push. Roda só no ADOTANTE.'
model: sonnet
category: meta
tags: [co-evolution, upstream, transport, carteiro, inbox, relay, bridge]
version: "1.1.0"
updated: "2026-06-28"
allowed-tools: Read Bash(bash .claude/utils/co-evolution/co-relay.sh*) Bash(ls docs/evolution/*) Bash(cat .claude/.onion-version)
argument-hint: "[<signal-file>] --target <path-local-do-core> [--from <dir>] [--dry-run]"
---

# 📨 /meta:co-relay — Carteiro-local (upstream, relay de sinal ao core)

Transporta um **sinal** que o adotante escreveu (`docs/evolution/inbox/`) para o `inbox/` do **core na mesma
máquina** — automatizando o `cp` que o maestro fazia à mão. É o **espelho UPSTREAM** do [`/meta:co-deliver`]
(co-deliver.md) (que é downstream, core→adotante). Materializa o sub-protocolo do regime manual fixado no
[ADR de relay manual](../../../docs/analysis/onion-adr-manual-relay-subprotocol-2026-06.md).

> **O que este comando NÃO é.** Não escreve o sinal — isso é a sessão do adotante (autor). Este é o
> **carteiro**: pega o sinal pronto no inbox/ e o **relaya** ao core. E não é o transporte distribuído
> (CI/repo-neutro) — esse é **gated** pela Federação plena; o Carteiro-local resolve o caso 1-máquina.

## Invariante (por que relaya SEM commit)

A sessão do adotante **nunca** commita/pusha no repo alheio (**I3 — um escritor por repo**). O carteiro
escreve o sinal como **untracked** no `inbox/` do core. Funciona porque o hook `co-evolution-inbox-check.sh`
**conta arquivos do diretório** (não exige commit) — então o 📬 dispara na próxima sessão do core. O
**commit + triagem** (ler, virar fix/feature/backlog, `git mv` para `inbox/_processed/`) é da **sessão do
core**, com o contexto de lá. Como **não commita**, a entrega é **branch-agnóstica** → o incidente do sinal
S2 ("commit cross-repo na branch errada") é **estruturalmente impossível**.

## Passo 1 — Guarda de papel (só ADOTANTE)

**Ler o STAMP `.claude/.onion-version` (campo `role:`) — NÃO rode `onion-version.sh`** (aquele hardcoda
`role: source` por ser a identidade da FONTE; cópia byte-idêntica no adotante mentiria 'source').
- `role: adopted` → **ADOTANTE** → segue.
- `role: source` / stamp ausente → **CORE/pré-adoção** → **parar**: o core não relaya upstream; ele anuncia
  downstream via [`/meta:co-announce`](co-announce.md). (O helper aplica a mesma guarda e sai com exit 2.)

## Passo 2 — Resolver alvo (o core) e sinal(is)

`$ARGUMENTS` = `[<signal-file>] --target <path-do-core> [--from <dir>] [--dry-run]`.
- `--target <path>` é o **path local do repo core** — **obrigatório** (o adotante não tem `members.yaml`
  para resolver o alvo; o stamp traz `adopted_from` = remote, não path local).
- `<signal-file>` opcional: basename ou path de UM sinal. Omitido = **todos** os `.md` de 1º nível de
  `docs/evolution/inbox/` (cuidado: pode re-relayar sinais antigos não-arquivados).
- `--from <dir>` opcional: fonte alternativa (default = o `inbox/` do adotante).

**Sempre rode com `--dry-run` primeiro** para conferir alvo + lista de arquivos antes de escrever.

## Passo 3 — Relayar

```bash
bash .claude/utils/co-evolution/co-relay.sh [<signal-file>] --target <path-do-core> [--from <dir>] [--dry-run]
```

O helper: aplica a guarda de papel (stamp), valida o alvo (git + avisa se não tem `docs/evolution/` na
árvore atual), e copia never-clobber (sinal já presente no `inbox/` = no-op idempotente).

## Passo 4 — Marcar relayado no PRÓPRIO repo (ato determinístico) + checkpoint do maestro

Após o relay, **mova o sinal local para `inbox/_processed/` e commite esse registro NO PRÓPRIO repo do
adotante**. É o estado git-visível "já enviado ao core" (sem state file). Isto é **ato determinístico — NÃO
uma escolha a devolver ao maestro**: untracked some num `git clean -fd`, então o registro **precisa ser
commitado para durar**. Commite **junto da linha Onion/co-evolução, separado de outras frentes** em curso
(ex.: não misturar com trabalho de produto na mesma branch). **Não pergunte "commito ou deixo solto?"** —
oriente e execute; commitar é o caminho correto.

> **Não confundir com I3.** Commitar o `_processed/` é no **próprio** repo do adotante (permitido — ele é o
> escritor dele). O I3 proíbe commitar no repo **alheio** (o core) — e isso o carteiro já respeita
> (entrega-sem-commit). O lado do core (commit + triagem do **sinal recebido**) é da **sessão do core**; não o assuma.

Saída sugerida (ORIENTE o próximo passo — não pergunte se deve commitar):

```
📨 Carteiro-local upstream — relayado ao core (<N> arquivo(s)) em <core>/docs/evolution/inbox/
   ◆ entrega-sem-commit (I3 respeitado) — a sessão do core commita + tria o sinal
   ▶ aqui (adotante): git mv inbox/<sinal> inbox/_processed/ + commit (junto da linha Onion, separado de outras frentes)
   ▶ no core: abrir sessão → 📬 you-have-mail → /meta:co-evolve (triar)
```

## ⚠️ Notas

- **Human-in-the-loop preservado:** relay + notificação são automáticos (atos 1-2); commit/triagem no repo
  do core = **gate humano** (a sessão do core). "branch?/push?" no contexto do *transporte* são Ato-1
  (determinístico) — **não escalar** (é untracked/branch-agnóstico). Só a execução no core é Ato-3.
- **Untracked é entrega, não durabilidade.** Um `git clean -fd` no core apagaria o sinal **antes** de
  processado — por isso a sessão do core deve ler/triar logo (mover p/ `_processed/` torna durável lá).
- **Distribuição:** este comando só existe no adotante após `/meta:adopt --update` (vendorização do delta).
- **Verbo solto em `meta/`**; não funde nem dispara workflows faseados.

## 🔗 Referências

- Espelho downstream: [`/meta:co-deliver`](co-deliver.md)
- Orientação/gestão: [`/meta:co-evolve`](co-evolve.md) · Protocolo: [docs/evolution/README.md](../../../docs/evolution/README.md)
- Sub-protocolo (decisão): [ADR de relay manual](../../../docs/analysis/onion-adr-manual-relay-subprotocol-2026-06.md) · Eixo dos 3 atos: [ADR transporte vs execução](../../../docs/analysis/onion-adr-comms-transport-vs-execution-2026-06.md)
- Hook: `.claude/hooks/co-evolution-inbox-check.sh` · Registro: [members.yaml](../../../docs/evolution/federation/members.yaml)
