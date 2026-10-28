---
branch: chore/update-round-437-pins
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: 33aa8e070c42fa03d50925ed8ab0149e6ce2103d762c6bcf385b944c34059dda
reviewed_code_sha256: 28c3635687c6b3355bd77ec8e7fd1e2e4e25daba403e72e0476cc95b70eb6c75
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, conferindo cada afirmação do nó contra gh pr view, o registry-pins --seal e o radar; sem subagentes
nota: ""
---

# Passada adversarial: `chore/update-round-437-pins`

## O que muda

- Grafo de coordenação: abre `Q_COORD_UPDATE_4_ADOTANTES_4370`, a rodada da 4.37.0 aos quatro
  adotantes com o pin 5b27d09c088f, com o andamento dos PRs 157 (curadoria), 165 (sge), 290 (kg-ssot)
  e 1656 (brain), e a aresta para o censo das pendências.
- `members.yaml` não muda: `ops/registry-pins.sh --seal --only <id>` nos quatro leu o carimbo da
  integração no remoto ainda em 95365699a0e3 (nenhum PR da rodada mergeado). O 2º selo vem depois.

## Achados

1. **Real, corrigido.** O nó nasceu sem `verified_at`, e o radar acusou STALE-MISSING (frescor
   rastreado por `verified_against` sem data). Entrou `verified_at: "2026-10-28"`.

## Conferido sem achado

- Cada estado de PR citado no nó bate com `gh pr view` na hora da escrita (157 e 165 verdes; 290 com
  o `conformance` vermelho pela catraca; 1656 aberto).
- O nó cita o brain e os adotantes pelo nome do repo; nenhum conteúdo de repo privado nem nome de
  cliente entra (REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)).
- O grafo segue abaixo do teto declarado de 40 nós (36 com este).
- Fora do escopo desta rodada e não carimbado: o `--check` acusa o `hub-operacoes-enterprise`
  divergente (8278fee79d1c no registro, 58f162825541 no remoto). Fica para quem cuida desse membro.
