---
branch: docs/librechat-rc1-upgrade
pr: 640
date: 2026-08-20
reviewed_diff_sha256: fd94ebbd1b63bab21b10406ec71e29f6a830ab04a5d4ed388dc96983cba05914
findings_total: 4
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 15
verdict: CONFORME-CORRECAO-DA-CORRECAO-COMO-ARESTA
reviewer: passada adversarial manual (3 ataques re-medindo o vivo pós-upgrade); sem subagentes
REVISOU: true
---

# Resíduo — `docs/librechat-rc1-upgrade`

**Origem:** carta branca do maestro para o salto v0.8.8-rc1 — e o salto refutou a minha própria
correção anterior.

## Achado 1 — a hipótese "liga-sozinho-no-upgrade" era FALSA (REAL, curado como aresta)

O nó de ontem previa: fiação pronta + v0.8.8 = sync ligando sozinho. O upgrade REAL mediu: nem
no rc1 existe caller de boot; o único gatilho é request-scoped (GET /skills) e ele RECUSA
config==server por construção (`getRequestSkillSyncConfig` retorna undefined no isSame — lido
no dist da imagem). O desenho pós-ClickHouse é gestão via Admin Panel. A correção da correção
virou label do nó — o grafo carrega a genealogia do erro.

## Achado 2 — upgrade.sh quebrava rodando como marcio (REAL, curado no mecanismo)

`backup.sh` chamava `docker` cru → permission denied fora do cron-root. Curado com o padrão
`_dk` da casa (tenta direto, cai p/ sudo -n) — o mesmo script agora serve root E usuário.

## Os 3 ataques (re-medidos no momento do resíduo)

- **(a) o stack pós-salto está são?** 6/6 containers up (5 healthy + admin running).
- **(b) o painel está SÓ no loopback?** `docker port` → `127.0.0.1:3027` únicamente.
- **(c) o GET /skills de fato não disparou sync?** statuses = 0 — o claim do código confirmado
  por comportamento, não só por leitura.

## Ressalva declarada

RC em superfície de auth foi decisão EXPLÍCITA do maestro (carta branca), com atenuantes: pin de
tag, 1 usuário, backup pre-upgrade feito, rollback ensaiável (re-pin + restore). O passo final
do skillSync é UI do painel (túnel ssh) — fora do alcance desta sessão por desenho (superfície
admin = humano).
