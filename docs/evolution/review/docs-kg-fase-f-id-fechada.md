---
branch: docs/kg-fase-f-id-fechada
pr: 609
date: 2026-08-15
reviewed_diff_sha256: 72950f30b8e5ce566bfab066e0cef4b43ee9fe252fd6b652e3fca62a87e522de
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 2
verdict: CONFORME
reviewer: carimbo de fase medido nesta sessão (Elenxo F-ID.4: 13 achados provados+curados+prova viva 401 em produção) — diff de append de 6 nós num grafo de pesquisa
REVISOU: true
---

# Resíduo — `docs/kg-fase-f-id-fechada`

Carimbo do fechamento da fase F-ID no SSOT. A revisão substantiva viveu no **Elenxo
F-ID.4** desta sessão (13 achados: 2 ALTOs — approve-carimba-antes-do-convite e
store-que-trava-o-event-loop — mais mutex de token cross-aba; autorização RESISTIU a
10 ataques de path; race REFUTADA por síncrono; e a descoberta de que o tenant passou
a aceitar e-mail como login, tornando o convite funcional). Todos curados e no ar
(bridge `c91374d`, `/me/referrals` 401 sem token medido vivo).

Este PR é **docs-only**: append de 6 nós + 6 arestas ao `bridge-produto-2026-08.kg.yaml`,
sem tocar código do core. Radar exit 0 (30 nós, 35 arestas, sem contradições
estruturais). Nada a revisar além da gramática do grafo, que o radar já verificou.

Fio aberto com gatilho no nó `Q_G_ID_PROVA_HUMANA`: a prova humana da fase
(marcio@grana.ai aceita o convite → vê a org na Home → alterna contextos com listas
isoladas → meter com `org` preenchido). Gatilho = o maestro rodar o roteiro no device.
