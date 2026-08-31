---
title: "Onion atualizado (pin 219e9a5f) + ajuste de segurança no compose — 2 branches prontas"
date: 2026-08-31
from: onion-core
---

# 📥 Onion core → granaai — atualização + segurança do compose

Oi! Duas entregas prontas no repo de vocês (branches já pushed — **nada foi mergeado**, a
decisão é de vocês):

## 1. `chore/onion-update-158f47c7` — atualização do framework Onion

- Novo pin do core: `219e9a5f365b` (traz `.claude/rules/`, a nova REGRA 64 de exposição de
  compose com catraca de legado, e correções do vendor).
- Dogfood rodado no clone: HARD caiu de **56 → 6** — os 6 restantes são locais de vocês
  (1 link `nuclea` + 5 traces de technical-context), nomeados em
  `docs/evolution/inbound/2026-08-31-onion-update-158f47c7.md` dentro da branch.
- Também corrige o `.gitignore` que estava engolindo `.claude/` inteiro.

**Ação:** revisar e mergear a branch; depois resolver os 6 HARD locais no ritmo de vocês.

## 2. `fix/compose-bind-and-secret-fallback` — segurança (recomendo priorizar)

No `docker-compose.yml` rastreado, as portas `5435:5432` (Postgres) e `6379:6379` (Redis)
estão sem prefixo de bind — o Docker publica em todas as interfaces e **ignora o firewall do
host** (na AWS o security group cobre essa metade, mas em dev local/outros hosts o risco vale
integral). E o fallback `${DB_PASSWORD:-postgres123}` sobe com senha conhecida em **qualquer**
ambiente onde o `.env` falte — essa metade o security group não cobre.

A branch aplica: `127.0.0.1:` nos dois binds + `${DB_PASSWORD:?defina no .env}` (falha alto em
vez de subir aberto). Se Postgres/Redis precisarem ser alcançados de fora, o caminho é
túnel/SSH, não bind público.

**Ação:** revisar e mergear (3 linhas); conferir que o `.env` de cada ambiente define
`DB_PASSWORD`; 1 min no console AWS confirmando a SG fechada nas portas 5435/6379.
