---
date: 2026-09-04
instance: onion-evolve
type: decision
classification: public
tags: [plugins, marketplace, consolidacao, granularidade, research-first]
affects: [meta, engineering, product]
breadcrumb_for: []
share_with: []
next_recommended: "REGRA 77 (contrato de dependência entre plugins: requires plugin:onion + seção Requer); depois F3 (idioma) quando o maestro selar R2"
review_after: 2026-12-03
conflict_class: static
---

# Oito plugins viram cinco — o canal premia bundle vertical, e work-tools era saco de ferramentas

**Decisão do maestro (2026-09-04):** consolidar. **Embasamento (R1, `plugin-directory-landscape-2026-09`):** o sinal primário do diretório favorece o plugin vertical coeso (skills + commands + agentes por função de trabalho) e os dois mais instalados (>1M cada) são bundles verticais; `onion-work-tools` era o candidato a reprovar no critério — e duplicava skill, motor e KB do núcleo.

**Fusões:** `onion` ← `onion-work-tools` (some a duplicação de `onion-orchestration`, `kg-radar.sh`, `knowledge-graph-sdaal.md`) · `onion-engineering` ← `onion-testing` (validate/test são o ciclo de engenharia; fecha o README que prometia comandos não entregues) · `onion-product` ← `onion-docs` (descoberta → backlog → docs de contexto é um ciclo só). `onion-compliance` e `onion-design` seguem verticais gold com audiência própria.

**Janela:** antes da submissão — nomes são imutáveis no diretório, não no nosso marketplace. O README do marketplace ganha a nota de migração (`uninstall` do antigo, `install` do novo). `roles.yaml`, a REGRA 37 (Mapa role→bundle consistente com os verticais) e a bancada apontam `work_tools` para o `onion`.

**O que a consolidação expôs:** a catraca da REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca) era por conjunto de chaves `<rel>|<ref>` — um rename de plugin reescreve todas as chaves sem mudar o passivo e acusaria "cresceu" com zero refs novas. A catraca passou a ser por CONTAGEM: o que só encolhe é o número (125 → 119, medido).
