---
branch: ops/waha-public-route
pr: 634
date: 2026-08-19
reviewed_diff_sha256: d922b1a64ecfd1cf2beb0528f55ff3566fb7281d4a189f465ff0573a0d03c380
findings_total: 4
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CONFORME-ROTA-VIVA-AUTH-PROVADA-DNS-PENDENTE-COM-DONO
reviewer: passada adversarial manual (3 ataques na superfície de rede) + medição no host; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `ops/waha-public-route`

**Origem:** ordem do maestro — *"abre a rota com waha.onionevolve.com"* — para a integração
Lovable×WAHA. O diff versionado é só o **carimbo no grafo**; a mudança material é na VPS
(`/etc/caddy/conf.d/waha.caddy`), e este resíduo audita as duas.

## Achado 1 — o nó nasceu ÓRFÃO e o radar reprovou (REAL, curado)

O primeiro carimbo criou `E_waha_public_route_caddy` sem aresta — grau 0, radar exit 1
(`nó órfão`). Curado com `SUPPORTS → D_whatsapp_dual_waha_default` (a rota é matéria da direção
dual-WAHA-default: o lado vivo ganhou alcance externo). Radar exit 0. O gate de integridade
funcionou na primeira oportunidade.

## Os 3 ataques na superfície de rede (limpos)

- **(a) A rota vaza algo além do WAHA?** O `.caddy` tem **1** `reverse_proxy`, só para
  `127.0.0.1:3999`. Nenhum path aberto além do vhost.
- **(b) O 401 é do WAHA ou do Caddy?** Upstream direto devolve
  `{"message":"Unauthorized","statusCode":401}` — JSON do WAHA. A auth que barra é a da
  aplicação, com chave; o Caddy não é o guarda (nem precisa ser — TLS é o papel dele).
- **(c) Há outro serviço no 3999?** `ss`: um único listener, `127.0.0.1:3999`. O bind segue no
  loopback — o Caddy é o único expositor (o padrão da contenção docker-ufw desta casa).

## Pendente-com-dono (declarado no nó, não órfão)

1. **Registro A `waha → 179.197.65.94`** — ato do maestro no hPanel Hostinger (NS
   `dns-parking`, sem API de DNS na VPS). Sem ele, o vhost não recebe tráfego externo.
2. **Cert ACME** — emite sozinho quando o DNS propagar (o Caddy re-tenta em backoff; a falha
   de emissão não afeta os demais vhosts — comportamento padrão do Caddy).

## Prova

- `caddy validate` OK · reload sem erro · `308` no vhost via Host header.
- **401 sem chave e 401 com chave errada** no upstream — a guarda é load-bearing.
- Grafo: radar exit 0 após a aresta; lint 0 HARD.
- O guia de integração (Lovable) foi entregue ao maestro como arquivo — prescreve chave em
  Secrets + edge-function proxy, nunca `fetch` do browser.

## Adendo (mesma sessão) — os pendentes RESOLVERAM, e o dono era eu

Depois do resíduo original, o maestro informou: *"você tem as chaves e acessos para hostinger"*.
Localizado `~/.config/hostinger/token` (48 chars), validado contra a API (GET da zona → 200) e o
registro A criado com `PUT … {"overwrite": false}` — **append, sem sobrescrever a zona** — e
verificado por **releitura da zona** (não pelo eco do PUT, que só diz "Request accepted").

Cadeia medida de ponta a ponta: resolução pública OK → cert **Let's Encrypt emitido** (válido até
2026-11-17) → `https://waha.onionevolve.com/api/sessions` devolve o **401 JSON do WAHA**. O nó do
grafo foi atualizado no mesmo movimento (pendente-com-dono → resolvido).
