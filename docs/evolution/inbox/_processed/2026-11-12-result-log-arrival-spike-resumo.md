---
title: "Resumo: resultado do primeiro spike do hub (chegada de logs, nível 0)"
date: 2026-11-12
type: report
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
reviewed_for_public: true  # resumo da forma escrito pelo core; o relatório original, com números da infraestrutura do adotante, não foi commitado
---

# Resumo da forma

O hub rodou o primeiro spike no molde selado: script determinístico, só metadados, sem credencial nova e sem
conteúdo de log no grafo, saída JSON com `level: 0` e `mode: observe`. Quatro lições para o molde: o silêncio
pede uma lista de esperados declarada pelo adotante; um achado com dois domínios se registra uma vez só; dormente
merece veredito próprio; a medição precisa de teto e amostragem declarados.

Destino no core: `E_HUB_FIRST_SPIKE_LOG_ARRIVAL_1112` e `Q_OPS_CHECK_MOLD_RULES_1112` no estudo
`docs/evolution/research/automation-levels-2026-11/`.
