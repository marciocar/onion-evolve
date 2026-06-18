---
title: 'Design: "you have mail" no boot via SessionStart hook + /meta:co-evolve + retrofit de adotantes'
date: 2026-06-18
from: sessão-core (maestro perguntou o padrão de notificação de mensagens no início)
to: onion-evolve (core)
type: design-note / framework-gap
flow: A (downstream — distribuição/notificação)
relates: 2026-06-18-co-evolution-not-distributed-by-adopt.md (PR #91, mergeado)
status: aberto (design pronto; ação = sessão-core futura)
---

# "You have mail" no início de sessão — padrão e retrofit

## Problema
Ao começar a trabalhar, o maestro precisa saber **se há mensagens no seu inbox** (em qualquer lado —
core ou produto) **sem ter de lembrar de checar**. O `/warm-up` não resolve (só roda se invocado);
memória não viaja entre repos.

## Padrão escolhido (proven, nativo — não invenção)
**SessionStart hook** = o clássico "you have mail on login" (`motd`/`mail` do Unix). É o **único primitivo
que dispara sozinho** no início (o harness roda hooks automaticamente). **O framework já usa um**
(`.claude/settings.json`: detecta `TASK_MANAGER_PROVIDER` + `worklog-capture-session.sh`) → basta
**estender**, não criar infra.

**Trio coeso:**
1. **Hook** (SessionStart, 3º comando): escaneia `docs/evolution/inbox/` (não-processadas) + entradas
   novas do `CHANGELOG`; injeta `📬 Onion: N mensagem(ns) — rode /meta:co-evolve`. **Silencioso se zero**
   (disciplina de motd). Rápido (~5s), determinístico, sem LLM.
2. **Comando `/meta:co-evolve`** (role-aware via `.claude/.onion-version`: `source`=core · `adopted`=consumidor):
   lê/gerencia as mensagens, mostra a posição nos 3 fluxos, como sinalizar o core, regra um-escritor-por-repo.
3. **Convenção de inbox:** processadas movem p/ `inbox/_processed/` (read/unread = git-visível, sem state file).

Vive em `.claude/` → **core e todo projeto herdam** o mesmo "you have mail".

## Gaps de distribuição (pré-requisitos pra chegar aos projetos)
O `/meta:adopt` hoje vendoriza `.claude/{agents,commands,skills,utils,validation}` + `docs/{meta-specs,
knowledge-base,sdaal}`. **NÃO** vendoriza:
1. **`.claude/settings.json`** (registro do hook) — e **não pode ser cópia cega** (clobba settings do
   projeto: hooks/permissions próprios) → exige **MERGE never-clobber** (adicionar a entrada Onion sem
   apagar as do projeto).
2. **`.claude/hooks/`** (scripts do hook).
3. **`docs/evolution/`** (inbox + protocolo) — o gap do #91.

## Retrofit de adotantes EXISTENTES (ex.: rhilo-metagamify)
Projetos já adotados (com `.claude/` antigo) **não recebem automático**. Caminho:
- **`/meta:adopt --update`** → traz `/meta:co-evolve` (está em `.claude/commands/`, é vendorizado).
- **Manual one-time (até o adopt evoluir):** adicionar a entrada do hook no `settings.json` do projeto
  (merge), copiar o script p/ `.claude/hooks/`, criar `docs/evolution/inbox/`.
- **Fix durável:** estender `/meta:adopt --update` p/ fazer isso com segurança (merge de `settings.json`
  + manifesto cobrindo `hooks/` + starter de `docs/evolution/`). Aí futuros updates retrofitam sozinhos.

## Próximo passo (sessão-core)
1. Construir o trio: hook (3º comando no SessionStart) + `/meta:co-evolve` + convenção `_processed/`.
2. Evoluir o `/meta:adopt`: manifesto + **merge never-clobber de `settings.json`** + starter de `docs/evolution/`.
3. Backfill dos adotantes atuais (hoje só rhilo-metagamify) — manual one-time ou via adopt evoluído.

Sem urgência: workaround atual = o maestro briefa a sessão do produto manualmente (copy-paste).
