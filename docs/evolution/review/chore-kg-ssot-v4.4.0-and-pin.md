---
branch: chore/kg-ssot-v4.4.0-and-pin
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: APROVADO
reviewer: passada própria (sem subagente) — gate mecânico: kg_vendor check, kg_gate do CI, lint
---

# O core adota a kg-ssot-v4.4.0 e carimba o pin do onion-kg-ssot

## O que muda

- **Vendor**: de `kg-ssot-v4.3.5` para `kg-ssot-v4.4.0` (e70eac26b2c3, 310 arquivos). A minor traz
  o `tools/kg_prov_export.py`, que exporta a provenance de cada nó como PROV-O em JSON-LD. Contrato, gate e
  validador são byte a byte os mesmos da 4.3.5.
- **Registro**: o pin do onion-kg-ssot sobe para `dcdacf9ba196` (`registry-pins.sh --seal --only`, lido do
  remoto main, PR #85 de lá). O papel continua `standalone` no registro e `adopted` no carimbo. O par é
  compatível pela REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela), e o maestro decidiu
  mantê-lo depois de saber que não havia divergência.

## Conferido

- `kg_vendor check` saiu íntegro. O `kg_gate` com os `--exclude` do CI deu rc 0. O sha256 dos schemas, do
  `kg_gate.py` e do `kg_validate.py` não mudou.
- **Dogfood do exportador**: rodei-o sobre `forge-decide-2026-10.kg.yaml` e saiu rc 0, com um JSON-LD de
  `prov:Entity` por nó.

## Achado (não curado aqui)

1. **19 fontes do corpus juntam duas URLs num só `source`** ("https://a + https://b"), segundo a medição
   do dono do kit. O exportador as trata como nó em branco, não como IRI. É dívida de dado do corpus: fica
   para uma leva própria.
