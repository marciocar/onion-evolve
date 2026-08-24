---
title: "Revisao — materializacao do bug do --update (self-review)"
date: 2026-08-24
branch: docs/materialize-update-removido-bug
reviewer: "self-review (autor) — 4 nos de grafo materializando um achado dogfood verificado por comportamento"
reviewed_diff_sha256: 
findings_total: 3
findings_real: 0
verdict: APROVADO
tokens: 1400
duration_min: 3
---

# Residuo de revisao — REGRA 56 (self-review, grafo-primeiro)

Materializa no catraca-regra49 o bug que a granaai (adotante regulado) achou no /meta:adopt --update.

- **Achado verificado por comportamento?** SIM — o fork mediu ao vivo (merge traz baseline nao-filtrado;
  REMOVIDO le HEAD×working; 47 HARD; 0 arquivo vazado; granaai rolou de volta limpa). Nao e suposicao.
- **Ancoragem correta?** SIM — E_UPDATE_FILTER_REMOVIDO_COLLISION SUPPORTS C_GUARDA_QUE_PUNE_CONFORMIDADE
  (o bug e instancia fresca dessa tese: a guarda pune o ato CORRETO de filtrar divida estrangeira).
  4 nos, 4 arestas, nenhum orfao; radar --integrity --schema exit 0.
- **Nada fabricado / nome comercial?** granaai = id publico (ok); onion-pessoal-marcio = path interno
  do core (nao comercial); numeros (47, pins) medidos pelo fork. Lint 0 HARD.

**Veredito: APROVADO** — grafo-primeiro cumprido: o bug nasce no grafo (com a cura D_CURE e o bloqueio
Q_GRANAAI como nos ABERTOS rastreaveis) ANTES de qualquer edicao de codigo. A cura e o proximo passo.
