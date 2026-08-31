---
title: "arandek — mensagem pronta: fallbacks de senha no compose (complemento do achado de 08)"
date: 2026-08-31
status: REDIGIDO-PRONTO-PARA-ENVIO
kg: docs/onion/graph/identidade-onion-vps-2026-08.kg.yaml
---

# ⚠️ PRONTO PARA ENVIO — o envio é ato do maestro

> Para publicar no canal da federação (servido no próximo pull deles):
> `git mv docs/analysis/arandek-compose-fallbacks-message-2026-08.md docs/evolution/federation/outbox/arandek/2026-08-31-compose-fallbacks.md`
> — ou enviar por qualquer outro canal que o maestro preferir.

## Mensagem (pronta para colar)

Oi! Na varredura de segurança da federação, o `docker-compose.yml` do repo apareceu com **3
fallbacks literais de senha** — `${POSTGRES_PASSWORD:-arandek_dev}` (linhas 43 e 318) e
`${LOGTO_DB_PASSWORD:-logto}` (linha 45). Sem `.env`, o serviço sobe com senha conhecida — em
qualquer ambiente, incluindo a produção na AWS (security group não cobre isso). A cura é 1
caractere por linha: trocar `:-valor` por `:?defina no .env` — o `up` falha alto em vez de subir
aberto. As portas estão OK (nenhuma sem prefixo de bind). Se quiser, mando o patch de 3 linhas.

## Patch (anexo)

```diff
-      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-arandek_dev}
+      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?defina no .env}
-      LOGTO_DB_PASSWORD: ${LOGTO_DB_PASSWORD:-logto}
+      LOGTO_DB_PASSWORD: ${LOGTO_DB_PASSWORD:?defina no .env}
-      - DATABASE_URL=postgresql://${POSTGRES_USER:-arandek}:${POSTGRES_PASSWORD:-arandek_dev}@postgres:5432/...
+      - DATABASE_URL=postgresql://${POSTGRES_USER:-arandek}:${POSTGRES_PASSWORD:?defina no .env}@postgres:5432/...
```

## Contexto interno (não vai na mensagem)

- Medido 2026-08-31 no clone local: **zero porta sem bind** (essa metade já está limpa); os 3
  fallbacks são o resto vivo do achado de 08 (`arandek-repo-exposure-2026-08.md`, que segue
  REDIGIDO-NÃO-ENVIADO — este pacote é o subconjunto acionável e não-sensível dele).
- Produção deles = AWS, outra conta (contexto do maestro 2026-08-31): SG cobre porta, não cobre
  fallback de senha.
