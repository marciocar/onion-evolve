---
branch: chore/kgssot-4440
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 0
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `chore/kgssot-4440`

## O que muda

- `vendor/kg-ssot` 4.43.0 → 4.44.0 pela tag `kg-ssot-v4.44.0` (`87cd7840ed0f`), da fonte pública. Segundo o dono, entram o `kg_refs.py` (`cited-by REPO:ID`, com rc 3 para varredura parcial, e `pins`), o `kg_trace check --strict-sources` e a saída `kg-ssot.trace/2`, que só aparece quando a forma `repo#ID@commit` ocorre em `provenance.source`. O contrato não muda (segue o v4.18).
- `.kg-ssot/gate/` renovado por `bash ops/kg-gate-ci.sh --update`: o kit vai para 4.44.0, 8 grafos sem registro ganham o seu, e `vetos-por-tokens-2026-10` trava o ganho de um `form.range.node.label` (12 → 11).
- `Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA` (grafo de coordenação) ganha a re-medida na 4.44.0 e segue aberto.
- O anúncio `outbox/brain-granaai/2026-11-05-resposta-persona-de-servico.md`, já entregue ao hub pelo co-deliver, passa a ser versionado.

## Achados

1. Hipótese: um leitor do core quebrar com `kg-ssot.trace/2`. `git grep` por `source:` na forma `repo#ID@commit` nos `.kg.yaml` fora do vendor dá zero, então o core segue recebendo `trace/1`. Os pontos que citam `trace/1` são comentários (`kg-trace.sh`, `lint-artifacts.sh`) e fixtures da família `kg_trace_resolve`, que passou. Não confirmada.
2. Hipótese: o core importar nomes privados do `kg_diff.py`, que a 4.44.0 renomeou (`_decode` → `decode` e outros). A 4.44.0 mantém os nomes antigos como apelidos, e `git grep` não acha import de `kg_diff`, `kg_query` ou `kg_trace` fora do vendor. Não confirmada.
3. Hipótese: um grafo do core piorar no contrato. `kg-contract-check.sh` nos 736 `.kg.yaml` rastreados deu saída idêntica com o vendor de `origin/main` (4.43.0) e com o novo: os 214 reprovados são fixtures de propósito más e a dívida herdada, os mesmos nas duas. `ops/kg-gate-ci.sh` deu rc 0 com 0 códigos novos. Não confirmada.
4. Hipótese: o buraco 1 da aresta entre repos ter sido curado sem o nó saber. Um grafo de teste com a ponta `from` por URL reprova na 4.44.0 com `form.pattern.edge.from` e `integrity.dangling-from`, igual à 4.43.0. O nó segue aberto. Não confirmada.

## Mutantes

Não se aplica: atualização de vendor, sem guarda nova. O `kg_vendor.py check` dá o vendor intacto.

## Medido

- Bancada, só as famílias ligadas ao vendor: `kg_trace_resolve`, `kg_trace_root_file`, `kg_vocab_ci`, `kg_gate_ci`, `kg_contract_check`, `kg_criterion_ci`, `kg_ssot_require_hashes`, `currency_census`, `kg_radar_contract`, `kg_radar_integrity`, `kg_read_leg` e `kg_read_index_empty`. 225 passaram, 0 pularam, 0 falharam.
- `kg-radar.sh --radar --integrity` nos 224 grafos fora do vendor e das fixtures: rc 0 em todos.

## Limites declarados

O grep acha só chamada literal: nome montado em variável passaria. O buraco 2 (grafo de submodule) não foi re-medido. O `kg_refs.py` novo não foi exercido contra os clones dos adotantes. A bancada completa é do CI.
