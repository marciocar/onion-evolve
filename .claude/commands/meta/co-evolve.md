---
name: co-evolve
description: Orienta a sessão na co-evolução Onion core↔derivados — detecta o papel do repo (core/consumidor via .claude/.onion-version), lê o inbox de mensagens pendentes, mostra a posição nos 3 fluxos e como sinalizar/gerenciar. Use no início de sessão ou quando o hook avisar 📬.
model: haiku
category: meta
tags: [co-evolution, inbox, bridge, federation, onboarding, sdaal]
version: "1.4.0"
updated: "2026-07-16"
allowed-tools: Read Grep Glob Bash(ls docs/evolution/*) Bash(git mv docs/evolution/*) Bash(git fetch origin*) Bash(git pull --ff-only*) Bash(git merge --ff-only origin/main*) Bash(bash .claude/validation/onion-version.sh)
argument-hint: "(sem argumentos — lê o estado de co-evolução deste repo)"
---

# 🔄 /meta:co-evolve — Orientação de co-evolução (core ↔ derivados)

Mostra a posição **deste repo** no modelo de co-evolução do Onion, lê o `inbox` e orienta o que fazer.
**Read-only por padrão** — só move mensagens para `_processed/` quando você confirmar.

> Modelo (resumo autossuficiente — o protocolo canônico completo vive em `onion-evolve/docs/evolution/`):
> 3 fluxos — **downstream** core→projetos (releases/anúncios) · **upstream** projetos→core (sinal/bug/pedido-de-ajuda
> via `inbox/`) · **handoff** dentro do repo (worktrees + um escritor por escopo). O humano é o **maestro**;
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

> **Passo 2.0 — sincronizar ANTES de ler (obrigatório).** Um sinal do **mesmo repo** (entregue via PR
> mergeado em `origin/main`, não via doc-bridge) só "chega" ao inbox quando o **checkout de `main`
> sincroniza** — worktrees compartilham o `.git` mas têm working trees separados; um merge no forge **não**
> atualiza um checkout que não deu `pull`. Rode **`git fetch origin && git pull --ff-only`** (ou `git merge --ff-only origin/main`) antes de listar o inbox. Lição de campo 2026-07-16: o sinal
> `método pessoal-usando-dogfood-kg-sdaal` "não chegou" na 1ª leitura por checkout 3 commits atrás. Isto
> **complementa** o invariante "git fetch antes de evoluir" (Passo 4) — aqui é antes de **ler**, não só de escrever.

Listar de 1º nível (excluir `_processed/` e `README.md`) **os dois canais** do doc-bridge:
- **`docs/evolution/inbox/*.md`** — upstream (sinal/feedback). No core: chegando dos projetos; no consumidor: a relayar ao core.
- **`docs/evolution/inbound/*.md`** — downstream (core→consumidor): relatório de adoção/update + anúncios. **Só existe no consumidor.**

Para cada, resumir `title`/`date`/`type` do frontmatter. Canal vazio/ausente → "sem pendências".
(É o que o hook SessionStart conta para emitir o 📬 inbox / 📥 inbound.)

## Passo 3 — Orientar conforme o papel

**Se CONSUMIDOR (projeto):**
- **Pedir ajuda / reportar bug / dar feedback ao core (upstream):** escrever um markdown datado
  (`AAAA-MM-DD-<assunto>.md`) no **próprio** `inbox/` (`docs/evolution/inbox/` — é o que "a relayar ao core")
  e **transportar com [`/meta:co-relay`](co-relay.md)** (`/meta:co-relay <sinal> --target <path-do-core>`):
  Ato-1 determinístico, **entrega-sem-commit** (untracked no `inbox/` do core; a sessão do core commita +
  tria). Se o core **não** vive na mesma máquina → entregar ao maestro transportar. Sem comunicação viva —
  assíncrono via git.
- **Receber releases do framework (downstream):** ler o `inbound/` (relatório de update auto-emitido pelo core,
  com arquivos aplicados + novidades + próximos passos) e o `CHANGELOG` do core; atualizar com `/meta:adopt --update`.
- O protocolo é **canônico no core** — este repo **referencia**, não redefine.

**Se CORE (`onion-evolve`):**
- **Ler o inbox** = sinal de campo dos projetos; triar (vira fix/feature/backlog).
- **Anunciar** mudança relevante aos projetos no `docs/evolution/federation/CHANGELOG.md` (downstream) e
  **gerar o anúncio pronto-para-transportar** com [`/meta:co-announce`](co-announce.md) (produtor do
  doc-bridge: escreve na staging `federation/outbox/<id>/`; o maestro transporta ao `inbound/` do adotante).
- **Registro** de quem adota: `docs/evolution/federation/members.yaml`.

## Passo 3.5 — Propor rascunho (responder-gated, topologia W6)

Havendo mensagem pendente (📬/📥) ou migalha vencida (⏰), **proponha — nunca execute**
([ADR work-models](../../../docs/analysis/onion-adr-work-models-session-topologies-2026-07.md) §2:
atos 1-2 automáticos; o ato 3 vira *propor→confirmar*):

- **CORE com 📬:** redigir o **rascunho de triagem** (veredito: fix/feature/backlog/informativo + resposta
  sugerida) e, se couber anúncio, o **esboço de entrada de CHANGELOG** — apresentar e **parar**. Só após o
  maestro confirmar: registrar/anunciar (`/meta:co-announce`) e mover a mensagem (Passo 5).
- **CONSUMIDOR com 📥:** redigir o **rascunho de processamento** (o que o anúncio pede, o que muda aqui,
  ação proposta) e, se gerar sinal de volta, o **esboço de mensagem upstream** no próprio `inbox/` —
  apresentar e **parar**. Só após confirmação: commitar/relayar (`/meta:co-relay`) e mover.
- **⏰ (qualquer papel):** propor a sessão de **re-teste** das migalhas vencidas via `/meta:diary review`
  (nunca re-carimbar sem re-testar — risco de reflexão falsa persistida).

O rascunho nasce **no repo desta sessão** (ou como entrega-sem-commit) — I3 intacto.

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

**Caso residual — duplicata untracked (entrega de carteiro pós-triagem):** se uma mensagem de 1º nível é
**untracked** (entrega-sem-commit do co-relay/co-deliver) e **byte-idêntica** a uma cópia já em
`_processed/` (verificar com `diff`/`cmp`, nunca só pelo nome), é re-entrega da corrida do assíncono —
propor **remover** o original untracked (o conteúdo já está preservado tracked). Conteúdo **diferente**
com mesmo nome = sinal ATUALIZADO → triagem nova, não remoção. (O co-relay v≥ incidente 2026-07-03
deduplica por conteúdo na entrega; esta linha cobre entregas de carteiros antigos.)

## Referência canônica

`onion-evolve/docs/evolution/README.md` (modelo dos 3 fluxos + ritual) e `rfc/rfc-0001-co-evolution-comms.md`.
