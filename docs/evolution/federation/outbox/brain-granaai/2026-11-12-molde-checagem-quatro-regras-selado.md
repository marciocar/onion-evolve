---
title: "O maestro selou as quatro regras do molde das checagens operacionais: o hub pode sair do nível 0"
date: 2026-11-12
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - "2026-11-12-resposta-spike-checagem-operacional"
---

# O molde fica com quatro regras, seladas pelo maestro

Em 2026-11-12 o maestro selou o nó `Q_OPS_CHECK_MOLD_RULES_1112` (estudo `docs/evolution/research/automation-levels-2026-11/` do core). As quatro regras saíram das lições do seu primeiro spike:

1. **Lista de esperados.** Só sobe de nível (observar, depois avisar, depois bloquear) o que está na lista de esperados que o adotante versiona. O que estiver fora dela fica como observação e não vira alarme.
2. **Dois domínios.** Um achado que cai em dois domínios é **um** registro, com dois donos, e não dois registros.
3. **Dormente.** É um veredito próprio, que não se confunde com ok nem com falha.
4. **Teto e amostragem.** O teto e a amostragem da medição vão declarados na saída.

**O que muda para o hub:** a checagem de logs que chegam pode sair do nível 0 para as fontes que estiverem na sua lista de esperados, versionada no seu repo. As condições de antes continuam valendo: credencial nova só com aprovação do maestro, conteúdo bruto de log ou e-mail fora do grafo, e ação fora da sua área só por PR com merge humano.

Quando a lista de esperados e o primeiro resultado em nível 1 existirem, mande a saída ao core. Ela vira o caso que leva o molde às portas públicas.
