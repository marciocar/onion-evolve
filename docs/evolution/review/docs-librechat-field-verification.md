---
branch: docs/librechat-field-verification
pr: 637
date: 2026-08-20
reviewed_diff_sha256: f210d8c711241d1c3083c8a14bfc01ffd5a5cf55b0f1eebb5afdf8fac7317add
findings_total: 3
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME-COM-A-HONESTIDADE-DO-RAG-NO-NO
reviewer: passada adversarial manual (2 ataques re-medindo o vivo) + o próprio dogfood de campo do maestro; sem subagentes
REVISOU: true
---

# Resíduo — `docs/librechat-field-verification`

**Origem:** dogfood de campo do maestro no navegador fechou a checklist F4 — e o diff é o nó do
catálogo acompanhando (grafo-sempre-atualizado).

## Achado 1 — o "funcionou" do RAG era a via ERRADA (REAL, curado por declaração honesta)

O teste de documento respondeu certo na tela — e o pgvector tinha **0 embeddings**: a resposta
veio da via CONTEXTO (200k), não do RAG. Quase virou "RAG provado" no nó. Curado declarando a
via NÃO-exercitada com gatilho nomeado (1º agente com File Search = F6.2 Onion-KB). É a família
testar-no-caminho-errado-é-não-testar, pega antes de virar afirmação.

## Os 2 ataques (limpos, re-medidos no momento do resíduo)

- **(a) os claims do nó batem com o vivo?** pgvector = 0 embeddings ✅ · `login success` ≥2 no
  log ✅ — o nó afirma exatamente o medido, nem mais nem menos.
- **(b) o break-glass documentado acha a conta?** `countDocuments({email, provider:"openid"})`
  = 1 — o updateOne de reversão tem alvo real.

## Ressalva declarada

O ES384 "provado em uso real" é o **primeiro precedente Logto+LibreChat que conhecemos** (a
pesquisa não achou guia no mundo) — vale sinal de co-evolução/KB se o maestro quiser exportar
o precedente; decisão dele, não automática.
