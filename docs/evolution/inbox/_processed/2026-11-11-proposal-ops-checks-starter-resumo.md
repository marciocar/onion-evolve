---
title: "Resumo: o hub propõe checagens operacionais simples já no formato do padrão"
date: 2026-11-11
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
reviewed_for_public: true  # resumo da forma escrito pelo core; o sinal original, com detalhe do adotante, não foi commitado
---

# Resumo da forma

O hub propôs começar por checagens operacionais de nível 0 (chegada de logs, alarmes agrupados com dono,
checkpoints com evidência, revisão de custo de nuvem), cada uma como script determinístico só leitura com saída
JSON e veredito, evidência como nó `evidence` e card quando falha. Pediu ao core o molde comum, a ordem e o
encaixe com a vertical de compliance.

Destino no core: estudo `docs/evolution/research/automation-levels-2026-11/` (selos de 2026-11-11 sobre a
divisão em três domínios, os níveis 0 a 2 e o script do adotante).
