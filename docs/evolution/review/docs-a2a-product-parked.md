---
branch: docs/a2a-product-parked
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: bf0b613313c58f2cf89dcb509a3ca8534317f0e303de30b1640da531a17b3e2d
reviewed_code_sha256: 910c7aa2ebc8d6924c5d9bd21427a982774998e5f2a11e820e2186d91bc6a66f
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/a2a-product-parked`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: entram três nós e duas arestas.
  - `E_SINAL_A2A_PRODUTO_PROPRIO_1025` é a evidência do sinal da curadoria, com `trace:` para o sinal processado.
  - `D_A2A_PRODUTO_PARQUEADO_COM_GATILHO_1025` é o selo do maestro: «Parquear com gatilho».
  - `Q_CANAL_ENTRE_SESSOES_NEUTRO_DO_AGENTE_1025` é o estudo seguinte, aberto com a curadoria.
- `docs/evolution/inbox/_processed/2026-10-25-proposal-a2a-product.md` guarda o sinal, triado e lido inteiro.

## Achados

1. REAL, corrigido: o código `N2` na prosa saiu ambíguo no lint de nomes da kg-ssot (vocab.code-ambiguous: dissect,
   refutation-finding, selfconsistency-claim). Agora está escrito `dissect:N2`.
2. REAL, corrigido: o `provenance.method` da evidência não seguia o padrão `<método>: …` do contrato (SHOULD
   form.pattern). Agora começa por `medição:`.

## Mutantes

- Nenhum: a mudança é só de grafo. O radar `--integrity --schema` sai rc 0, o contrato rc 0 e o lint de nomes rc 0
  depois das curas. Antes delas, o contrato saía rc 1 e o lint de nomes reprovava, e as duas guardas morderam.

## Limites declarados

- O nó `D_A2A_PRODUCT_VERDICT` mora no grafo da curadoria. Quem o fecha é a sessão dela, apontando o selo deste
  repo.
