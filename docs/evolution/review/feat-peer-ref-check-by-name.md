---
branch: feat/peer-ref-check-by-name
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 20
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `feat/peer-ref-check-by-name`

## O que muda

- `.claude/validation/peer-ref-check.sh`: o primeiro argumento aceita o NOME do par, resolvido nesta ordem:
  1. o `local_path` do membro no members.yaml;
  2. o diretório irmão, só se a URL da origin dele termina no nome.

  Se nada resolve, a saída é NÃO MEDIU. Caminho existente segue como antes.
- `.claude/validation/lint-selftest.sh`: o caso (i) cobre members.yaml, irmão certo, irmão com outra origin e nome
  desconhecido, mais o mutante (MUT-d) sem a prova da URL.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_GATILHO_DO_CANAL_NEUTRO_DISPAROU_E_O_CORE_REOLHOU_1025` e
  duas arestas.

## Suspeitas descartadas

1. O palpite do diretório irmão conferir o repo errado: descartada pelo caso (i). O irmão com outra origin dá NÃO
   MEDIU, e o mutante sem a prova da URL responde 0, que é exatamente o erro que a prova impede.

## Mutantes

- (MUT-d): sem a checagem da URL, o irmão errado sai rc 0. A família `peer_ref_check` passa 12 de 12.
- O script da `origin/main` reprova o caso (i): o nome não é diretório, e a saída é "o par não é repo git" (rc 2).
