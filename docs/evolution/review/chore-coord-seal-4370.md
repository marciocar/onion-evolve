---
branch: chore/coord-seal-4370
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: 731d37a931ea43c23c3527ee3f552be66a1976ecde09b03f9397d174b56b7d09
reviewed_code_sha256: ec0420d7aca24b71bc442b43ea9e3d5f074cbfaca1671bf62edae8f4e37bc012
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 25
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, conferindo cada afirmação dos nós contra gh pr view, git worktree list, o registry-pins --seal e o radar; sem subagentes
nota: ""
---

# Passada adversarial: `chore/coord-seal-4370`

## O que muda

- `members.yaml`: o 2º selo da rodada da 4.37.0. `ops/registry-pins.sh --seal --only <id>` carimba
  onion-curation, onion-kg-ssot, sge e brain-granaai de 95365699a0e3 para 5b27d09c088f, lido do remoto.
- Grafo de coordenação: fecham com carimbo `Q_COORD_UPDATE_4_ADOTANTES_4370` (os 4 merges e o selo),
  `Q_COORD_MAESTRO_CARTOES_2_3_4_IDA_E_VOLTA` (PR 1422) e `Q_COORD_WORKTREES_TRAVADAS_SESSAO_BD`
  (nenhuma worktree da sessão bd). Entram 18 pendências com dono e o nó de evidência do 2º censo
  cruzado; o que já tinha nó no grafo do Company Brain ou no sinais-de-campo entra por `external_edges`.
  Saem os 21 nós que já estavam `done` desde 2026-10-27, para caber no teto de 40 (34 depois).

## Achados

1. **Real, corrigido.** A evidência dizia 22 nós colhidos; a lista tem 21. O número no texto foi
   corrigido para o da lista.
2. **Real, corrigido.** A evidência dizia 19 pendências novas; são 18 nós `question`. Corrigido.
3. **Real, corrigido.** Os 18 nós novos nasceram sem `verified_at`, e os que se apoiam em relato das
   sessões sem `evidence_class: testimony`: o radar acusou STALE-MISSING e TESTIMONY-UNMARKED. Entraram
   os dois campos, e o radar ficou sem aviso nos nós novos.

## Conferido sem achado

- Os quatro PRs da rodada e o 1422 e o 1424 conferidos por `gh pr view` (MERGED); o pin 5b27d09c088f
  é o merge do 1424.
- As 3 worktrees travadas são da sessão atual do core (mesmo pid); nenhuma da sessão onion-evolve-bd.
- Nenhum nó novo duplica nó existente: conferido por grep nos grafos do core (Q_MA_FREE_ORG_READ_ENFORCED,
  Q_MA_CLASSIFICATION, Q_MA_WIKI_BRIDGE e a aresta Q_MA_CROSS_REPO → Q_MA_WRITE_SURFACE já existiam).
- O npm da 4.37.0 e o tsv do kg-trace não ganharam nó, pela correção do kg-ssot.
- Nenhum nome comercial de cliente nem conteúdo de repo privado além do autorizado (REGRA 36 (Superfície
  VENDORIZADA sem nome comercial de cliente)); nenhum caminho de máquina (REGRA 99).
- Radar `--integrity --schema` rc 0, contrato conforme, backlog-check 34/40.

## Mutantes

Nenhum: a mudança é dado de grafo e registro, sem código.

## Limites declarados

- Os relatos das sessões peer entram como testemunho, não re-medidos aqui.
- O hub-operacoes-enterprise segue divergente no registro (8278fee79d1c contra 58f162825541): não é
  desta rodada.
