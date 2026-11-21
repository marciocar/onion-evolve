---
branch: chore/vendor-kg-ssot-4.56.0
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: 6c55de88733dbbdd389351c93a0ac9ac8f00bc251eba48bac164f7cb1e381708
reviewed_code_sha256: 557feb510e8131a9a8f7d4f11eb8af43f4baa4e8814df6b9109d07f6744c3fcc
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 107107
duration_min: 4
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: true
reviewer: "agente separado, com contexto novo e sem a conclusão do autor, sobre a árvore da branch (origin/main b16cdc61e): clone novo da tag, sha256 dos 1006 arquivos contra o carimbo, gh attestation verify do manifesto da release, recálculo da identidade do contrato, ops/kg-gate-ci.sh, grep de x_processing_purpose e leitura das ferramentas que mudaram"
nota: "Adoção de vendor (v4.55.0 → v4.56.0, commit 24d6f1e5 do espelho público, 1006 arquivos; 36 mudam e 43 entram). Fora do vendor muda só a base do gate: a identidade nova do contrato e 5 registros de grafo sem dívida. Contrato v4.26, só SHOULD. Nenhuma regressão aceita."
---

# Passada adversarial: `chore/vendor-kg-ssot-4.56.0`

## O que muda

`vendor/kg-ssot` v4.55.0 → v4.56.0 (tag `kg-ssot-v4.56.0`, commit `24d6f1e5b56f` no espelho público), por
`kg_vendor.py update --tag`, com a conferência da atestação herdada do carimbo. O carimbo passa de 963 para 1006
arquivos: 36 mudam e 43 entram (os casos de conformidade de `spec/conformance/fixtures/latest/form/purpose/`).

O que a versão traz, lido no CHANGELOG do vendor novo:

- contrato v4.26, só SHOULD: o perfil `x_processing_purpose` (a finalidade do tratamento, só no `meta`, como lista
  de ponteiros para um vocabulário com versão fixada), julgado só pela forma;
- o schema SHOULD muda, então o gate avisa `· identity` e passa, e o `--update` grava a identidade nova;
- `kg_migrate.py format --to json`: o grafo passa de `.kg.yaml` para `.kg.json`, e quem o cita acompanha;
- correção de links relativos que a cópia vendorizada não resolvia.

Em `tools/` mudam 4 arquivos: `kg_migrate.py` (o subcomando `format`), `test_kg_migrate.py`, `kg_validate.py`
(`CONTRACT_VERSION` 4.26 e duas dicas do perfil novo) e `runners/ajv/kg.mjs` (só comentário). `kg_gate.py` e
`kg_vendor.py` não mudam.

## A identidade do contrato

`bash ops/kg-gate-ci.sh --update` grava em `.kg-ssot/gate/contract.json` o `contract_sha256` novo
(`b78a2b21…` → `302df7e7…`) e o `kit` (`4.55.0` → `4.56.0`). O revisor recalculou o sha256 dos schemas MUST e SHOULD
como o `kg_gate.py` faz e chegou ao mesmo valor. Nenhum registro de grafo que já existia mudou. Entram 5 registros de
grafos que chegaram à main depois da subida 4.55 (`guard-one-touch-approval-2026-11`, `radar-E3-2026-11-18-r25`,
`radar-E3-2026-11-20-r26`, `radar-E3-2026-11-21-r27`, `taco-2026-11`), todos com `must: []` e `should: {}`.

## Regressões aceitas

Nenhuma. Nenhum grafo do core (fora de `vendor/`) tem a chave `x_processing_purpose`, então o perfil novo não alcança
o corpus e a catraca não acusou piora. O `--accept-regression` não foi usado.

## Achados

Nenhum. Medido na mesma árvore:

| Conferência | Antes (4.55.0) | Depois (4.56.0) |
|---|---|---|
| `kg_vendor.py check` | rc 0, 963 arquivos | rc 0, 1006 arquivos |
| `ops/kg-gate-ci.sh` | rc 0 | rc 0, mesma saída mais o aviso de identidade |
| `ops/kg-gate-ci.sh --update` | — | rc 0; 271 grafos, 269 passam no MUST, 2 na dívida herdada |
| `ops/kg-gate-ci.sh` depois do `--update` | — | rc 0, sem o aviso de identidade |
| `kg-contract-check.sh` em 274 grafos | 269 conformes, 5 reprovam (dívida herdada) | saída idêntica byte a byte |
| atestação (`gh attestation verify`, identidade exata do `release.yml` da tag) | — | rc 0 |
| sha256 dos 1006 arquivos contra um clone novo da tag | — | 0 diferenças |
| `lint-artifacts.sh` | — | rc 0, 0 HARD, 26 SOFT (nenhum do diff) |

O "antes" do check do contrato rodou com o vendor 4.55.0 extraído do `HEAD` (`git archive`) e apontado por
`KG_SSOT_TOOLS`.

## Mutantes

Não se aplica: a mudança é a troca dos bytes do vendor pelos da tag, conferidos contra o carimbo e a atestação, e a
regravação da base pelo próprio gate. Não há guarda nem código do core novo para mutar.

## Os nós de coordenação do SAC-448 e do SAC-449

Não há nó desses cards nos grafos do core: os dois moram no grafo do produto, no repositório do kg-ssot
(`docs/onion/graph/kg-ssot-product.kg.yaml`), e a sessão dona já os carimbou. Conferido por `peer-ref-check.sh
onion-kg-ssot` (rc 0, origin/main do par em `f3756eea`): `C_KG_JSON_CORPUS_MIGRATION_GAP_1119` está `superseded` por
`C_KG_JSON_MIGRATION_SHIPPED_1121`, e o commit `59c457ca` (PR #479, o corte da 4.56.0) é ancestral da main dele.
`C_CI_MINUTES_CUT_1118` segue `open` lá, com a medida parcial do PR #478; a medida final é da sessão do kg-ssot.
Este PR não escreve no grafo de outro repo.

## Limites declarados

- `reviewed_diff_sha256` fica `pendente` até o `pr-finalize`, que é quem carimba.
- A bancada completa é do CI; aqui rodaram o gate, o check do contrato e o lint de artefatos.
- `kg_migrate.py format` e o perfil novo não foram exercidos no corpus do core.
- O servidor `kg-mcp` em produção não foi reiniciado nem medido aqui.
