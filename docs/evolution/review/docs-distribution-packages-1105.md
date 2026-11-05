---
title: 'Resíduo — pesquisa de distribuição do Onion e selo do maestro'
date: 2026-11-05
branch: docs/distribution-packages-1105
pr: pendente
reviewed_diff_sha256: 3d67245eae690ca9d244e726870a17398542066f5105bd588882845a71d0dddf
reviewed_code_sha256: 3acf82dcccd4a3c8590a96982f2212dd8ea30edb57ad42e7d964c13c88ae3095
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
reviewer: "fase Elenxo do workflow onion-research (wf_615a4f2b-024), agente separado; a sessão do core só releu"
elenxo: sim
nota: "tokens e duração 0 = não medido, porque o run atravessou a queda de uma sessão. A passada adversarial é a do workflow; esta leva só acrescenta o selo, a medida de tráfego e a projeção. Depois da passada, entrou o baseline de caminhos com 3 linhas, relidas pela sessão do core: citações do caminho genérico de configuração."
---

# O que esta leva faz

Versiona o grafo da pesquisa, o selo "Diretório e parque" e a primeira medida de tráfego das portas.

## Limites

A candidatura ao diretório oficial não foi feita nem levantada. A origem dos clones das portas não foi verificada.
