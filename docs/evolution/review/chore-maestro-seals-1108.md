---
branch: chore/maestro-seals-1108
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: e31021c2f275d69e49aada294827b1087a5c3c80e50a59308c3b72d667e79ced
reviewed_code_sha256: ee3fc51622a8a22e833d42d7cb5fe84305846d5f7608c0605382b5a7707d8df1
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff, sem subagente (o brief proíbe criar agentes); gates mecânicos kg-radar e kg-contract-check, grep no dist
nota: "tokens e duração não medidos (0). Selo do checkpoint, grafo novo de 9 nós e troca de rótulo em snapshot estático; sem código."
---

# Passada adversarial: `chore/maestro-seals-1108`

## O que muda

- `docs/onion/graph/comms-stable-2026-11.kg.yaml`: checkpoint selado pelo `kg-drive-project.sh --seal`, com radar e
  contrato em rc 0.
- `docs/onion/graph/maestro-decisions-1108.kg.yaml`: grafo novo, com 2 evidências e os 7 selos da rodada. Foi grafo
  próprio porque `curation-seals-2026-11` declara teto de 8 nós e escopo só de peças da curadoria.
- `site/public/federacao/`: o id `metagamify` vira o rótulo «adotante hub (gamificação)», no mesmo molde do PR #1543.

## Achados

1. INCOMPLETO (corrigido antes do commit): trocar só `metagamify` deixaria `MetaGamify` no campo `name` e a
   especialização `metagamification`, que carrega o radical do nome. A busca no dist usa `-i` e o radical `metagami`.
2. REGRESSÃO EVITADA (corrigido antes do commit): o console mostra sempre os eventos cujo `alvo` começa com
   `adotante`. Um id `adotante-hub` faria o filtro por membro mostrar esses 25 eventos em qualquer filtro. O id ficou
   `hub-gamificacao`; o JSON do console foi relido e as 25 entradas casam.
3. LABEL ALÉM DA RESPOSTA (corrigido antes do commit): dois labels diziam mais do que o maestro escolheu («passam a
   inglês», «antes de qualquer aplicação»). Foram reduzidos ao que a opção diz.

## O que fica de fora, por decisão

- `site/src/pages/historia/index.astro` ainda cita o nome em 5 pontos e aparece no dist. A decisão selada é sobre
  `/federacao/`, então a página de história não entra aqui e vai como pendência no relatório.
- O deploy do site é do maestro.
- A pergunta e a opção no grafo guardam o id verbatim: selo é testemunho da pergunta feita.
