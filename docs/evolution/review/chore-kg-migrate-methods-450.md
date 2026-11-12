---
branch: chore/kg-migrate-methods-450
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: b923fa0396acd4bf728ec222b0b3c707e163434824178979d97767230db52157
reviewed_code_sha256: e5eaecfbeece623b681e443489ae32601f4d686ad3ac876848af97fe4d5888b0
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 60
findings_fixed: 1
verdict: APPROVED
elenxo: false
reviewer: agente de execução da sessão do core, por comando, sem revisor independente (o brief vedou lançar agentes)
nota: "tokens 0 = não medido. Migração mecânica dos apelidos em português do provenance.method pela classe inglesa, com o kg_migrate.py da kg-ssot 4.50.0. Passada do próprio autor; o refutador do preâmbulo fica para a sessão principal antes do PR."
---

# Passada: `chore/kg-migrate-methods-450`

## O que muda

- **Commit 1, deriva da base (separada da migração):** `bash ops/kg-gate-ci.sh --update` na `origin/main`
  `5274443d2` sem nenhuma troca grava os dois grafos que nasceram fora da base (`forge-baton-2026-11`,
  `subagent-background-wait-2026-11`, ambos sem dívida) e a baixa de `integrity.bare-decision` (671 → 0) em
  `pr-decision-history-2026-08`. Nenhum grafo muda nesse commit.
- **Commit 2, migração:** `kg_migrate.py methods apply --manifest-out` troca 5327 classes em 206 grafos
  (medição→measurement, leitura→reading, juízes→judges, derivado→derived, testemunho→testimony). Só a classe muda; o
  detalhe depois de `: ` fica byte a byte. 0 para o revisor, 0 na cauda. A base do gate trava o ganho
  (`form.deprecated.node.provenance.method` 5327 → 0, 206 registros). Recibo versionado em
  `docs/evolution/research/contrato-kg-absorcao-2026-10/data/methods-migration-450/methods-manifest.tsv`
  (grafo, id, antes, depois; 5327 linhas).

## Achados

1. **(real, curado) A base do gate estava atrasada em relação à `main`.** Dois grafos fora dela e uma dívida
   já paga não travada. Curado no commit 1, separado da migração para o diff da base de cada commit ter uma só causa.
2. **(real, não bloqueia) REGRA 121 (Grafo novo ou tocado não cita repositório não conferível por terceiro) acende
   em `session-orchestration-2026-11`.** O nó `Q_SO_PADROES_DE_MERCADO` cita um repo por hash; a citação é anterior,
   e a regra passa a enxergá-la porque a migração tocou o grafo (14 trocas nele). SOFT; a cura é reescrever a fonte do
   nó, o que é decisão de conteúdo e fica fora de uma migração mecânica.

## Medições

- `ops/kg-gate-ci.sh` depois do `--update`: rc 0; 258 grafos, 256 passam MUST, 2 na dívida herdada; `--touched`:
  nenhum nó tocado carrega dívida (206 grafos alterados); critério 14/0; nomes 0 novos.
- `kg-contract-check.sh` nos 817 `.kg.yaml` rastreados (vendor incluso): rc 1 antes e depois, 599 ✓; a parte que
  reprova (fixtures propositais e dívida herdada) é **idêntica byte a byte** antes e depois da migração.
- `kg-radar.sh --integrity --schema` nos 261 grafos fora de fixture e de vendor: 261 rc 0.
- Bancada (`LC_ALL=C`) `kg_contract_check, adopter_shape, kg_gate_ci, kgssot_tools, kg_migrate_v3`: 117/0/0.
- `lint-artifacts.sh`: rc 0, 0 HARD, 66 SOFT (65 do vendor 4.50.0 + a REGRA 121 do achado 2).

## Mutantes

Nenhum: a migração não traz guarda nem caso de bancada novos. O migrador já tem os dele na kg-ssot.

## Limites declarados

- Sobra em português só nos 9 fixtures de conformidade do próprio vendor (`vendor/kg-ssot/spec/conformance/fixtures/`,
  8 em `method-vocabulary` e 1 em `coherence`), que existem para provar o aviso e não são do core. Fixtures do core:
  zero.
- Sem refutador independente nem CI: ficam para a sessão principal.
