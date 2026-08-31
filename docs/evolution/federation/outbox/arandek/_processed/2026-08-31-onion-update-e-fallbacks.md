---
title: "Onion atualizado (pin 219e9a5f) + gate de pre-commit religado + fallbacks de senha"
date: 2026-08-31
from: onion-core
---

# 📥 Onion core → arandek — atualização + 2 avisos

## 1. `chore/onion-update-3ed62001` — atualização do framework Onion (branch pushed)

- Novo pin do core: `219e9a5f365b` (`.claude/rules/`, REGRA 64 de exposição de compose com
  catraca — os 38 casos legados de vocês entraram na baseline tolerada; a métrica é diminuir,
  linha nova reprova).
- Dogfood no clone: HARD caiu de **89 → 4** — os 4 restantes são locais (2 traces, 1 link de
  mail antigo, 1 transição one-time de ESCOPO), nomeados em
  `docs/evolution/inbound/2026-08-31-onion-update-3ed62001.md` dentro da branch.
- **O gate de pre-commit do Onion estava INERTE** no repo (o `core.hooksPath` aponta para
  `.husky/_`, e o hook do Onion nunca rodava). A branch acrescenta a chamada
  `bash .githooks/pre-commit` ao `.husky/pre-commit` — provado bloqueando artefato inválido
  em staged.

**Ação:** revisar e mergear a branch; depois os 4 HARD locais no ritmo de vocês.

## 2. Fallbacks literais de senha no compose (fix de 3 linhas — recomendo priorizar)

O `docker-compose.yml` tem 3 fallbacks: `${POSTGRES_PASSWORD:-arandek_dev}` (linhas 43 e 318)
e `${LOGTO_DB_PASSWORD:-logto}` (linha 45). Sem `.env`, o serviço sobe com senha conhecida —
em qualquer ambiente, incluindo a produção na AWS (security group não cobre isso). As portas
estão OK (nenhuma sem prefixo de bind).

Cura de 1 caractere por linha — trocar `:-valor` por `:?defina no .env`:

```diff
-      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-arandek_dev}
+      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?defina no .env}
-      LOGTO_DB_PASSWORD: ${LOGTO_DB_PASSWORD:-logto}
+      LOGTO_DB_PASSWORD: ${LOGTO_DB_PASSWORD:?defina no .env}
```

(e o mesmo na `DATABASE_URL` da linha 318). **Ação:** aplicar o patch + garantir
`POSTGRES_PASSWORD`/`LOGTO_DB_PASSWORD` no `.env` de cada ambiente antes do próximo `up`.
