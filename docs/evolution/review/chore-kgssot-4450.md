---
branch: chore/kgssot-4450
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: 7963364708edef306b9fd867c2e07f6aa39d68680ad800b5c6bd11ba37cc8a38
reviewed_code_sha256: b527f9a75b2536f28f5d3d286124a3a2acfd78f56957f2c00b0d0a986381bdd7
findings_total: 6
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "agente de execução da sessão do core (passada inline)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `chore/kgssot-4450`

## O que muda

- `vendor/kg-ssot` 4.44.0 → 4.45.0 pela tag `kg-ssot-v4.45.0` (`86945e2de459`), da fonte pública. Segundo o CHANGELOG do dono, nenhuma mudança de contrato (segue o v4.18) e nenhum veredito muda. Entram o SBOM CycloneDX por artefato da release (`packaging/sbom/sbom.py`), o `SECURITY.md`, as formas recomendadas e não normativas do `x_event` e do `x_change` (manual, capítulo 3), a seção "Dado pessoal, LGPD e GDPR" no ADOPTING, e o `fast-uri` 3.1.9 no lockfile do leitor JavaScript.
- `.kg-ssot/gate/` renovado por `bash ops/kg-gate-ci.sh --update`: o kit vai para 4.45.0 (o `contract_sha256` não muda), e 7 grafos que ainda não tinham registro ganham o seu.
- No grafo de coordenação: `Q_COORD_MAESTRO_PVR_KGSSOT_1106` fecha (done, pelo relato do kg-ssot, conferido por `gh api .../private-vulnerability-reporting` → `{"enabled":true}`); o label de `Q_COORD_MAESTRO_UPDATE_CONSULTORIA_1106` passa a "o atual é 4.45.0"; `Q_COORD_KGSSOT_FORMA_X_CHANGE_1111` ganha a medida da 1ª metade entregue e segue aberto.

## Achados

1. Hipótese: um grafo do core piorar no contrato. `kg-contract-check.sh` nos 743 `.kg.yaml` rastreados deu saída byte a byte idêntica com o vendor 4.44.0 (`KG_CONTRACT_VENDOR` apontando para ele) e com o 4.45.0: os 214 reprovados são fixtures de propósito más e a dívida herdada, os mesmos nas duas. `ops/kg-gate-ci.sh` deu rc 0 com 0 códigos novos, antes e depois do `--update`. Não confirmada.
2. Hipótese: uma ferramenta do vendor que o core chama ter mudado de comportamento. O diff em `vendor/kg-ssot/tools/` é só o `package-lock.json` do runner ajv (o `fast-uri`), e nenhum arquivo do core fora do vendor cita `runners/ajv`. Não confirmada.
3. Hipótese: o arquivo novo trazer caminho de máquina ou endereço real para a superfície que viaja aos adotantes e às portas. Os endereços do diff são todos `@example.com`, do exemplo do `x_change`; `SECURITY.md` e `sbom.py` não têm `/home/`, `/Users/` nem e-mail. Não confirmada.
4. Hipótese: a porta ou o `/meta:adopt` filtrar o vendor por lista de arquivos e perder `SECURITY.md` ou `packaging/sbom/`. O `durable-commit.sh` leva `vendor/kg-ssot` inteiro, e o `kg_vendor.py check` confere os 719 arquivos pela `release.json` da própria tag, que já lista os dois. Não confirmada.
5. Hipótese: o buraco 1 da aresta entre repos (`Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA`) ter sido curado. O `contract_sha256` da base é o mesmo da 4.44.0, então o MUST que reprova a ponta por URL é o mesmo. O nó segue aberto e não foi editado aqui. Não confirmada.

6. Hipótese: esta release entregar outro `Q_COORD_KGSSOT_*` aberto que devesse fechar. `Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA`: contrato igual, o buraco 1 segue. `Q_COORD_KGSSOT_GATILHOS_DE_CAMPO_DO_PRODUTO`: a release traz a forma do `x_event`, mas o gatilho do perfil B pede 2 adotantes ou 50 nós, e nenhum disparou. `Q_COORD_KGSSOT_FORMA_X_CHANGE_1111`: o "pronto quando" tem duas metades; a forma está no manual (capítulo 3), mas nenhum `.kg.yaml` do hub em origin/main tem `x_change` (`git grep`, rc 1). Nenhum fecha; o terceiro ganha a medida. Não confirmada.

## Mutantes

Não se aplica: atualização de vendor, sem guarda nova. O `kg_vendor.py check` dá o vendor intacto.

## Medido

- Bancada, só as famílias ligadas ao vendor: `kg_trace_resolve`, `kg_trace_root_file`, `kg_vocab_ci`, `kg_gate_ci`, `kg_contract_check`, `kg_criterion_ci`, `kg_ssot_require_hashes`, `currency_census`, `kg_radar_contract`, `kg_radar_integrity`, `kg_read_leg`, `kg_read_index_empty` e `kgssot_tools`. 260 passaram, 0 pularam, 0 falharam.
- `currency-census.sh`: `kg-ssot 4.45.0 4.45.0 em-dia`.
- No grafo de coordenação editado: `kg-contract-check.sh` rc 0, `kg-radar.sh --radar --integrity` rc 0, `ops/kg-vocab-ci.sh` rc 0 (0 códigos novos).

## Limites declarados

O grep acha só citação literal. As formas `x_event` e `x_change` não foram exercidas contra um grafo do core (nenhum as usa). O SBOM não foi gerado nem conferido aqui: é artefato da release do kg-ssot, não do core. A bancada completa é do CI.
