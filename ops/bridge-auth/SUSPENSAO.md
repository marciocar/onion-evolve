# Suspensão de acesso ao bridge (perda/roubo de device) — procedimento

> Mitigação (3) do flip PKCE, escrita em 2026-09-01 (etapa 2 da ordem). Antes disto o
> procedimento não existia em lugar nenhum (medido no censo r2).

1. **Suspender o usuário no Logto** (revoga sessões e refresh tokens na hora) — Admin console
   (loopback :3012 via túnel ssh) → Users → <user> → Suspend. Por API (mesmo auth M2M do
   provision): `PATCH /api/users/<id>/is-suspended {"isSuspended": true}`.
   (Sem flag no provision de propósito: suspensão é ato raro e humano — não se automatiza
   revogação de acesso num script idempotente que roda por rotina.)
2. **Confirmar**: o próximo uso de refresh token do device perdido falha (rotação ativa:
   token de acesso morre em ≤1h; refresh rotacionado morre no 1º replay).
3. **Reativar** quando o device for recuperado/trocado: Unsuspend + novo login.

Notas: accessTokenTtl segue 3600s por decisão selada (UX; ver D_TTL_UX_TRADEOFF no grafo M2).
A rotação de refresh (rotateRefreshToken) é a compensação: vazamento tem janela de UM uso.
