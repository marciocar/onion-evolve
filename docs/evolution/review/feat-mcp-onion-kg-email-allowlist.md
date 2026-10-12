---
branch: feat/mcp-onion-kg-email-allowlist
date: 2026-10-12
reviewed_diff_sha256: f529dd7e531c8453c8c35146323c4d6c32b725f239ff04d31a4553ba22cbe583
reviewed_code_sha256: 1e7abf9748607df9bd9cf2a6b030ccb28f09062e086fd3836982e8f64b340c38
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 30
verdict: REPROVADO_E_CURADO
reviewer: passada própria + medição do deploy ao vivo + 2 mutantes (sem subagente) — gate mecânico: mcp_onion_kg
---

# O runbook mandava "restringir por papel", e o papel não protegia nada

## Achados (medidos no deploy do degrau 1, em 2026-10-12)

1. **Todo servidor do `librechat.yaml` fica disponível para todo usuário do LibreChat.** Na mesma
   instância roda o MCP de um cliente sob NDA, e o Logto tem cadastro aberto. Se o Brain fosse
   registrado como o runbook descrevia, qualquer usuário logado o enxergaria. A cura segue o precedente
   medido nesta mesma stack (o servidor do SGE): o LibreChat manda `X-User-Email:
   {{LIBRECHAT_USER_EMAIL}}` e o **servidor** confere esse e-mail numa lista. Agora, com
   `ONION_KG_ALLOWED_EMAILS` definida, todo `tools/call` exige o header e que o e-mail esteja na
   lista. Lista vazia nega todos. `initialize` e `tools/list` passam, porque não trazem dado do repo.
2. **O passo 6 do runbook foi reescrito** com o bloco real do `librechat.yaml`:
   - `allowedDomains`, porque a guarda anti-SSRF do LibreChat exige o destino declarado;
   - os headers `X-Api-Key` e `X-User-Email`, com o token passado por env e nunca escrito no yaml.

## Prova

- O harness `ops/mcp-onion-kg/selftest.py` passou de 29 para **34/34**. Os casos novos cobrem:
  e-mail da lista passa (normalizado), e-mail de fora é recusado, falta do header é recusada,
  `tools/list` passa e a lista vazia nega todos.
- Dois mutantes novos na família `mcp_onion_kg`, ambos reprovam:
  - o gate desligado;
  - a lista vazia tratada como ausente.

  Com eles a família fica 23/23.

## O que NÃO cobre

- O header pode ser forjado por quem tiver o token. O token prova que quem chama é o LibreChat, e só
  ele alcança a porta, porque o firewall restringe à sub-rede da bridge.
