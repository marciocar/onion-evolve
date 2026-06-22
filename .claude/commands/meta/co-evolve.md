---
name: co-evolve
description: Orienta a sessão na co-evolução Onion core↔derivados — detecta o papel do repo (core/consumidor via .claude/.onion-version), lê o inbox de mensagens pendentes, mostra a posição nos 3 fluxos e como sinalizar/gerenciar. Use no início de sessão ou quando o hook avisar 📬.
model: haiku
category: meta
tags: [co-evolution, inbox, bridge, federation, onboarding, sdaal]
version: "1.1.0"
updated: "2026-06-20"
allowed-tools: Read Grep Glob Bash(ls docs/evolution/*) Bash(git mv docs/evolution/*) Bash(bash .claude/validation/onion-version.sh)
argument-hint: "(sem argumentos — lê o estado de co-evolução deste repo)"
---

# 🔄 /meta:co-evolve — Orientação de co-evolução (core ↔ derivados)

Mostra a posição **deste repo** no modelo de co-evolução do Onion, lê o `inbox` e orienta o que fazer.
**Read-only por padrão** — só move mensagens para `_processed/` quando você confirmar.

> Modelo (resumo autossuficiente — o protocolo canônico completo vive em `onion-evolve/docs/evolution/`):
> 3 fluxos — **A** core→projetos (releases/anúncios) · **B** projetos→core (sinal/bug/pedido-de-ajuda
> via `inbox/`) · **C** dentro do repo (worktrees + um escritor por escopo + handoff). O humano é o **maestro**;
> coordenação é **git-async** (sem IA-fala-IA).

## Passo 1 — Detectar o papel deste repo

O `role` pode vir de dois lugares (o core **não** tem `.onion-version` estático — ele o computa):
1. Se **`.claude/.onion-version`** existe → ler o campo `role:` (consumidor adotado: `role: adopted`).
2. Senão, se **`.claude/validation/onion-version.sh`** existe → rodar `bash .claude/validation/onion-version.sh`
   e ler `role:` (a fonte/core retorna `role: source`).
3. Se nenhum dos dois → repo ainda não é Onion (ou pré-adoção) — avisar e parar.

Mapear: **`role: source` → CORE** (`onion-evolve`, dono do framework + protocolo) ·
**`role: adopted` → CONSUMIDOR** (projeto que adotou o Onion, ex. vendorizado/standalone).

## Passo 2 — Ler os canais (mensagens pendentes)

Listar de 1º nível (excluir `_processed/` e `README.md`) **os dois canais** do doc-bridge:
- **`docs/evolution/inbox/*.md`** — fluxo B (sinal/feedback). No core: chegando dos projetos; no consumidor: a relayar ao core.
- **`docs/evolution/inbound/*.md`** — fluxo A (core→consumidor): relatório de adoção/update + anúncios. **Só existe no consumidor.**

Para cada, resumir `title`/`date`/`type` do frontmatter. Canal vazio/ausente → "sem pendências".
(É o que o hook SessionStart conta para emitir o 📬 inbox / 📥 inbound.)

## Passo 3 — Orientar conforme o papel

**Se CONSUMIDOR (projeto):**
- **Pedir ajuda / reportar bug / dar feedback ao core (fluxo B):** depositar um markdown datado
  (`AAAA-MM-DD-<assunto>.md`) no `inbox/` do **core** (`onion-evolve/docs/evolution/inbox/`, se montado;
  senão entregar ao maestro copiar). Sem comunicação viva — é assíncrono via git.
- **Receber releases do framework (fluxo A):** ler o `inbound/` (relatório de update auto-emitido pelo core,
  com arquivos aplicados + novidades + próximos passos) e o `CHANGELOG` do core; atualizar com `/meta:adopt --update`.
- O protocolo é **canônico no core** — este repo **referencia**, não redefine.

**Se CORE (`onion-evolve`):**
- **Ler o inbox** = sinal de campo dos projetos; triar (vira fix/feature/backlog).
- **Anunciar** mudança relevante aos projetos no `docs/evolution/federation/CHANGELOG.md` (fluxo A) e
  **gerar o anúncio pronto-para-transportar** com [`/meta:co-announce`](co-announce.md) (produtor do
  doc-bridge: escreve na staging `federation/outbox/<id>/`; o maestro transporta ao `inbound/` do adotante).
- **Registro** de quem adota: `docs/evolution/federation/members.yaml`.

## Passo 4 — Regras invariantes (sempre, qualquer papel)

- **Um escritor por repo.** Esta sessão escreve só neste repo; nunca pusha em repo alheio (cobertura de
  ponta adormecida = commit isolado no repo coberto + log de quem fez).
- **`git fetch` antes de evoluir** (outra instância pode ter mexido — ver lição stale-branch).
- **Você (humano) é o maestro** que roteia mensagens entre repos e decide ordem de merge.

## Passo 5 — Gerenciar (opcional, sob confirmação)

Ao **tratar** uma mensagem, mover para o `_processed/` **do canal** dela
(`git mv docs/evolution/<inbox|inbound>/<arquivo> docs/evolution/<inbox|inbound>/_processed/`). Assim o
"lido/não-lido" fica **git-visível** (sem state file) e o hook deixa de contá-la. **Só mover após o maestro
confirmar** que a mensagem foi de fato endereçada.

## Referência canônica

`onion-evolve/docs/evolution/README.md` (modelo dos 3 fluxos + ritual) e `rfc/rfc-0001-co-evolution-comms.md`.
