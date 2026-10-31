---
branch: fix/core-small-defects-1031
pr: pendente
date: 2026-10-31
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 3
tokens: 77476
duration_min: 10
findings_fixed: 1
verdict: APROVADO
elenxo: nao
reviewer: "@branch-code-reviewer, agente separado e só leitura, mandato refutar (2ª instância: a 1ª travou ao tentar escrever arquivo e não entregou veredito)"
nota: "tokens e duração do revisor medidos pelo harness (77476 tokens, 578 s, com ~7 min perdidos no timeout da família kg_backlog). Dos 3 achados reais, 1 curado (d3) e 2 cosméticos declarados abaixo, sem cura."
---

# Passada adversarial: `fix/core-small-defects-1031`

Empilhado sobre o #1446 (`chore/coord-graph-harvest-1031`). A colheita é daquele PR e aparece aqui pelo diff contra
a `main`. Os ids colhidos são `Q_COORD_UPDATE_4_ADOTANTES_4370`, `Q_COORD_UPDATE_4_ADOTANTES_4380`,
`Q_COORD_WORKTREES_TRAVADAS_SESSAO_BD`, `Q_COORD_MAESTRO_CARTOES_2_3_4_IDA_E_VOLTA`,
`Q_COORD_CORE_RESIDUO_ADOTANTE_ELENXO_SEM_TIL`, `Q_COORD_CORE_CC_UPDATE_2_1_312`, `Q_COORD_CORE_DPAREN_END_KG_READ_LEG`,
`Q_COORD_CORE_SELFTEST_9_CASOS_NO_ADOTADO`, `Q_COORD_KGSSOT_WITH_NO_REVISIT_E_DECISION`,
`Q_COORD_KGSSOT_HASH_CANONICO_SCHEME_KG_NODE` e `Q_COORD_MAESTRO_SELAR_PRODUTO_KGSSOT`. O resíduo próprio da colheita é
`chore-coord-graph-harvest-1031.md`.

## O que muda

- `lint-selftest.sh`: o `rm` do `_FIXTURE_NODE` entra no `_bench_on_exit`. Caso (a2) do `kg_backlog`, comportamental,
  com mutante embutido.
- `kg-corpus-grep.sh`: `--query` vazio ou só espaços sai rc 0 com «sem pergunta» e não varre o corpus; sem argumento e
  `--query` sem valor seguem rc 2. Casos (d), (d2) e (d3) de `corpus_grep`.
- `claude-code-specialist.md`: o exemplo de settings recomenda `claude-opus-5-5` (allowlist `session_models`).
- Grafo de coordenação: os três nós curados vão a `done` com carimbo medido.

## Achados

1. O (a2) prova o handler real, também em faixas (`--child` arma o trap e cria o seu `mktemp`): falso-positivo.
   Reproduzido inline: forma nova apaga, forma antiga deixa o arquivo.
2. **REAL, baixo.** `--query` sem valor no fim da linha saía rc 0. **Curado:** rc 2 com mensagem de uso, caso (d3).
3. `--phrase ""` segue rc 2: falso-positivo, a skill só usa `--query`.
4. **REAL, cosmético.** Com a pergunta vazia, o `onion-research.js` registraria a linha «sem pergunta» como formato
   não canônico. Não quebra nada, e o SKILL.md manda perguntar ao maestro antes. Sem cura.
5. **REAL, detalhe.** O exemplo recomenda o 2º degrau da escada (`claude-opus-5-5`), não o primário
   (`claude-fable-5-1`). Vale para a REGRA 3 (Campo model: restrito à allowlist sonnet|opus|haiku|fable) e para o nó;
   mantido porque é o Opus default da plataforma. Sem cura.
6. Integridade dos nós: falso-positivo; radar rc 0, carimbos reproduzidos.
7. Vazamento: falso-positivo.

## Veredito

APROVADO. Depois da cura do (2): `corpus_grep` 9/9, radar `--integrity --schema` rc 0, `ops/kg-gate-ci.sh` rc 0.
A família `kg_backlog` inteira passa de 590 s na VPS (o caso (e) roda o lint duas vezes): localmente rodou até o (d),
com o (a2) verde e o mutante vermelho; a família completa é do CI.
