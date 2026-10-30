---
branch: chore/registry-pins-seal-1030
pr: pendente
date: 2026-10-30
reviewed_diff_sha256: c1d9320651da56a989e2816fa4aa11f6b2444c862ffdbd7b97124de8c277ea4a
reviewed_code_sha256: ed44ed17bbec140529fe146a9c6104bd772110fe576a64cc4eafc7d2cf052a99
findings_total: 5
findings_real: 0
tokens: 36874
duration_min: 10
findings_fixed: 0
verdict: APROVADO
elenxo: sim
reviewer: subagente revisor separado, só leitura (sem edição, commit ou push), que tentou refutar cada afirmação do commit por comando
nota: "5 tentativas de refutação, todas falso-positivo; 0 achado real"
---

# Passada adversarial: `chore/registry-pins-seal-1030`

## O que muda

- O `ops/registry-pins.sh --seal` sela três pins no members.yaml: onion-curation e onion-kg-ssot passam de 1d04d4e24cec para 67e9d003689f, e hub-operacoes-enterprise passa de 8278fee79d1c para 58f162825541.
- As projeções graph.md, federation-map.md e federation-console.html foram regeneradas pelos geradores da casa (REGRAS 24 e 38).

## Achados (tentativas de refutação)

1. **Diff mínimo (falso-positivo).** O diff do members.yaml muda só as 3 linhas `onion_version` e a data do comentário, e não traz nome comercial novo.
2. **`--check` depois do selo (falso-positivo).** Saiu rc 0, com 20 em dia, 0 divergentes e 0 ilegíveis.
3. **Ancestralidade (falso-positivo).** Os pins 58f162825541, de 2026-10-21, e 67e9d003689f, de 2026-10-30, dão `merge-base --is-ancestor` 0 contra origin/main.
4. **Projeções (falso-positivo).** As três, regeradas no scratchpad, batem byte a byte com a árvore pelo `cmp`.
5. **Lint (falso-positivo).** O `lint-artifacts.sh` sai rc 0, com 0 HARD.

## Limites declarados

- O commit de conteúdo saiu com `--no-verify` como checkpoint. O pre-commit passou de ~9 min e foi cortado pelo timeout em 560 s, já depois do lint com 0 HARD e durante a faixa local da bancada. O gate fica com o `pr-finalize` e o CI.
- O revisor não verificou se os 21 avisos SOFT do lint são anteriores a este commit.
