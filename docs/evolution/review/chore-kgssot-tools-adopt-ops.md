---
branch: chore/kgssot-tools-adopt-ops
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 9282e2fedff15949a5f2400181db9e711def509ed1ab36bd28c18cc75a8dba6c
reviewed_code_sha256: 8e6148e7dea37cf8f66fbaa02580ec3946849dc008b6748c66098691e935d970
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 50
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "o autor (passada própria, bancada e mutantes contra o código da main); NÃO independente"
nota: "tokens = 0 porque não foram medidos; duration_min é o relógio da tarefa, bancada inclusa. Sem refutador independente: o agente de execução não lança subagentes por regra da sessão. Os 3 achados vieram da passada do autor e foram curados no mesmo PR."
---

# Passada adversarial: `chore/kgssot-tools-adopt-ops`

## O que muda

Continuação do #1498 (resolver único `.claude/utils/kg/kgssot-tools.sh`). Os sítios executáveis que ainda fixavam
`vendor/kg-ssot/tools` em `.claude/utils/adopt/` e `ops/kg-*-ci.sh` passam pelo resolver, e a catraca da família
`kgssot_tools` (caso d) ganha os dois diretórios e a forma "só a pasta" (`TOOLS="${T}/vendor/kg-ssot/tools"`), que
a 1ª catraca não via.

Migrados: `ops/kg-vocab-ci.sh`, `ops/kg-criterion-ci.sh`, `ops/kg-gate-ci.sh` (o `kg_gate.py`),
`.claude/utils/adopt/remeasure-contract.sh`, `plan-contract-migration.sh`, `migrate-seed-graph.sh` e o template
`ci-workflow-onion.tpl` (o `pip install` do requirements no CI do adotante).

Deixados fixos, de propósito: o `kg_vendor.py check --dest vendor/kg-ssot` do `kg-gate-ci.sh` (confere o carimbo DO
vendor; agora só roda onde há vendor), o `kg-index-floor.sh` (lê o carimbo `.kg-ssot-version` do vendor e já
declara rc 4 para o produto), os caminhos de pasta inteira (`vendor/kg-ssot`, sem `/tools`) de
`durable-commit.sh`, `vendor-manifest.sh` e `prettierignore-onion.tpl` (são o que viaja e o que se rastreia, não
onde moram as ferramentas), os workflows do CI do core (o core sempre tem o vendor; o passo instala antes de
qualquer script) e a prosa dos comandos e das KBs.

## Achados (da passada do autor, curados aqui)

1. A catraca de origem só via `vendor/kg-ssot/tools/<arquivo>.(py|txt)`: o `TOOLS="${T}/vendor/kg-ssot/tools"`
   do `remeasure-contract.sh` passava por ela. Curado: o padrão aceita a pasta sozinha, e o stub `KGSSOT_TOOLS` de
   quando o lib falta (`kg-decide-seal.sh`) entra nos deliberados. Mutantes das três formas fixas acusados; o
   fallback ao lado do resolver e o `kg_vendor.py`, deixados passar.
2. Com `KG_SSOT_TOOLS` exportado na sessão do core, o `remeasure-contract.sh` mediria o corpus do ALVO com o
   contrato de outra pasta e o relatório diria "o vendor do alvo". Curado: a linha medida diz de onde veio
   (`o vendor do alvo`, `o próprio produto, tools/ do alvo`, ou `a pasta do KG_SSOT_TOOLS=…, NÃO a do alvo`).
3. No próprio produto a versão saía `?` (o carimbo `.kg-ssot-version` só existe no vendor). Curado: lê o
   `spec/release.json` quando não há carimbo.

## Comportamento novo, declarado

- `kg-gate-ci.sh` sem `vendor/kg-ssot` (produto, ou override) pula a integridade do vendor com uma linha, em vez de
  sair rc 2 antes de julgar. No core nada muda (o vendor existe).
- `remeasure-contract.sh` num alvo que É o produto mede (antes: rc 4 "não se aplica"); o `plan-contract-migration`
  acompanha, com as dicas de caminho relativas à pasta resolvida.
- O template de CI do adotante instala o requirements de `tools/` quando o projeto adotado é o produto kg-ssot
  (antes pulava o `pip` e o `kg-contract-check` saía rc 2 por PyYAML ausente).

## Prova

- `bash ops/kg-vocab-ci.sh` na branch: `✓ nomes: nenhum código novo sem termo na prosa dos grafos`, rc 0.
  `bash ops/kg-gate-ci.sh`: vendor íntegro (kg-ssot-v4.44.0), 225 grafos, rc 0.
- Numa cópia com `spec/` e `tools/` na raiz (a forma do repo do kg-ssot): `remeasure-contract.sh` rc 0 (main: rc 4),
  `kg-criterion-ci.sh` rc 0; sem nada, rc 2 como hoje; vazio com `KG_SSOT_TOOLS`, rc 0.
- `plan-contract-migration.sh` no core: as mesmas dicas de antes (caminhos do vendor), rc 2 "sem perfil".
- Bancada: `kgssot_tools`, `kg_ssot_require_hashes`, `remeasure_contract`, `plan_contract_migration`,
  `migrate_seed_graph`, `kg_vocab_ci`, `kg_gate_ci`, `kg_criterion_ci`, `remeasure_hard`, `secret_gitignore`,
  0 falhas. Mutante: com o `remeasure-contract.sh` e o `kg-criterion-ci.sh` da main, a família `kgssot_tools`
  reprova 5 casos (b2 no produto e no override, e a catraca).
