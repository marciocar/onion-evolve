---
date: 2026-11-10
instance: onion-evolve
type: innovation
classification: public
tags: [baton, load, lease, orchestration]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Comparar a fila de passo pesado de uma semana antes e depois das N vagas"
review_after: 2027-02-08
conflict_class: dynamic
significance: "A espera por carga deixou de ser regra reescrita à mão por cada agente e virou uma porta de admissão com N vagas derivadas da carga."
kg: "docs/evolution/research/forge-baton-2026-11/forge-baton-2026-11.kg.yaml"
---

## Signal
Passo pesado (bancada, mutantes, fechamento de PR) passa por uma porta de admissão com N vagas, e N se deriva da
carga a cada tentativa. A vaga única serializava demais; espera escrita à mão por agente divergia.

## Evidence
- PR #1577: a batuta rege a carga, o parado e a dona da pergunta; N = piso((12 − load) / 2), entre 1 e 4.
- Medido em 2026-11-10: 4 agentes na fila de uma vaga com a máquina folgada.
- PRs #1499 e #1503: a regra de carga virou lease (reserva com prazo, pega e devolvida por cada passo pesado), com a pressão de CPU como segundo sinal.

## Next crumb
A trava é de eficiência, não de correção: se algum dia ela guardar correção, precisa de fencing token.
