---
name: catch-up
description: |
  Briefing de retomada — reconstrói "onde paramos" de sinais duráveis
  (git recente, sessão ACTIVE, memória, inbox) após queda/saída de sessão.
model: sonnet
allowed-tools: Read Grep Glob Bash(git *) Bash(ls *) Bash(find .claude/sessions*) Bash(find docs/evolution*)
category: general
tags: [resume, briefing, session, recovery, cold-resume]
version: "1.0.0"
updated: "2026-06-21"
---

# 🔁 Catch-up — Briefing de Retomada

Reconstrói **onde você parou** quando uma sessão cai, é resumida (`/compact`) ou
você volta depois de um tempo. É o **irmão do `/warm-up`**: warm-up carrega o
contexto *do projeto*; catch-up reconstrói *a sua última atividade*.

## 🎯 Objetivo

Produzir um **briefing curto e acionável** de retomada a partir de **sinais
duráveis** — sem depender do transcript da conversa anterior. É o **resume frio**
(worklog-protocol §2) generalizado para trabalho **ad-hoc** que nunca virou um
worklog formal: a sequência de commits soltos, a análise em andamento, o ajuste
que ficou pela metade.

> **Fronteira vs `/engineer:work`:** se há um worklog formal ACTIVE
> (`.claude/sessions/<slug>/STATE.md`), aquele é o ponteiro **autoritativo** de
> retomada — o catch-up o **detecta e aponta**, não o substitui. O catch-up
> brilha quando **não** existe worklog.

## 📋 Protocolo de Reconstrução (barato → caro)

Leia na ordem; pare cedo se já tiver o suficiente para o briefing. **Nunca**
faça `cat` de pastas inteiras (anti-pattern Context Dump).

### 1. Git — a espinha dorsal ("o que eu estava fazendo")
- `git status -sb` → branch atual + estado da árvore (limpo? N alterações?)
- `git log --oneline -15` → o **fio** de trabalho recente (tema inferível dos commits)
- `git diff --stat` e `git diff --cached --stat` → trabalho **não-commitado** (o que ficou pela metade é o sinal mais forte de "onde parei")
- Se a branch for `feature/*`, `hotfix/*` ou `release/*` → há provável worklog formal (passo 2)

### 2. Sessão formal ACTIVE (se houver)
- `find .claude/sessions -maxdepth 2 -name STATE.md -not -path '*/archived/*'` → worklogs vivos
- Para o mais recente (`mtime`), leia **só o `STATE.md`** (Tier 0, ~300 tokens): o bloco `## NEXT` é o próximo passo autoritativo
- Se existir → no briefing, **aponte** `/engineer:work <slug>` como retomada canônica

### 3. Memória recente
- Leia `MEMORY.md` (índice) e os arquivos de memória **mais recentes** (`mtime`) em `~/.claude/projects/<repo>/memory/` — capturam decisões/`project`/`feedback` em curso que o git não mostra
- Recall já é automático; aqui é só **destacar** o que é relevante à última atividade

### 4. Co-evolução / pendências externas
- Contar não-processados em `docs/evolution/inbox/` (📬) e `docs/evolution/inbound/` (📥), se existirem → pendências que esperam ação
- O hook SessionStart já avisa a contagem; aqui apenas **integramos** ao briefing

### 5. Arquivos tocados recentemente (último recurso)
- Só se 1–4 não bastarem: `git log --name-only -5` ou arquivos do working tree com `mtime` recente → reconstrói o foco de arquivo

## 🧾 Formato do Briefing

Sintetize em **um bloco curto** (não despeje os comandos crus):

```
🔁 Catch-up — <repo> @ <branch>

📍 Última atividade: <tema inferido dos commits/diff>
🌳 Árvore: <limpa | N arquivos alterados, M não-commitados>
🗂️  Sessão formal ACTIVE: <slug + próximo passo do STATE.md | nenhuma>
🧠 Memória relevante: <1–2 pontos em curso, se houver>
📬 Pendências: <inbox/inbound, PRs abertos, diff não-commitado>

▶️  Próximo passo provável: <inferência acionável>
```

Termine oferecendo a retomada: se há worklog → `/engineer:work <slug>`; se há diff
não-commitado → revisar/concluir; se há inbox → `/meta:co-evolve`. **Não execute**
nada automaticamente — o briefing orienta, o maestro decide.

## 💡 Quando Usar

- ✅ Sessão caiu / foi resumida (`/compact`) e você perdeu o fio
- ✅ Voltou depois de horas/dias e não lembra onde parou
- ✅ Trabalho **ad-hoc** (análises, ajustes soltos) sem worklog formal
- ✅ Máquina nova / transcript perdido (resume frio puro)

## ⚠️ Notas

- **Read-only / orientação**: reconstrói e propõe; não muta estado nem executa workflows
- Para contexto **do projeto** (não "onde parei"), use `/warm-up`
- Para retomar um worklog formal específico, `/engineer:work <slug>` é o caminho direto
- Mecânica de resume frio vs quente: `docs/knowledge-base/concepts/worklog-protocol.md §2`
