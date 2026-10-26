---
branch: fix/cc-delta-census-worktree-relative
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: dc277afdc9e6501106d7b08f454ec4cbc62a34e1be3f49ff57c7ab01f2b14b7e
reviewed_code_sha256: 287300e4222da0420312ca1e23d5c037c3d2d7746a4fdfa6ab59f0ac608eba23
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: agente de execução (passada própria sobre o diff, com mutante)
nota: "tokens não medidos (0): passada no próprio contexto do agente de execução"
---

# Passada adversarial: `fix/cc-delta-census-worktree-relative`

## O que muda

O filtro de worktrees do `cc-delta-census.sh` passa a olhar o caminho relativo ao repo
(`'/' + os.path.relpath(f, repo)`), não o absoluto. A bancada ganha o caso (w) na família
`cc_delta_census`.

## Achados

1. **Real, curado:** pelo caminho absoluto, a rodada que roda numa worktree da sessão
   (sob `.claude/worktrees/`) descartava todo arquivo e a contagem de `scriptPath` zerava.
   Medido nesta própria worktree com `CC_DELTA_BASELINE=2.1.309` (para o inventário imprimir):
   **8** depois da cura (era 0 antes, segundo E_CENSO_ZERA_SCRIPTPATH_EM_WORKTREE_1022).
2. **Não real:** a mesma classe em outro filtro do core. Medido com
   `grep -rn "'/worktrees/'" .claude --include=*.sh --include=*.py`: só este ponto existe.
   Os outros globs do censo (`.claude/agents/**`, `.claude/rules/*`, `.claude/skills/*`) não
   descem em `.claude/worktrees/`.

## Mutantes

- Filtro de volta ao absoluto (`if '/worktrees/' in f`): o caso (w) reprova com
  `raiz=[2] worktree=[0] (esperado 2 e 2)`. Mutante morto. Restaurado: família 25/25 verde.

## Limites declarados

- O caso (w) prova a forma (worktree aninhada sob `.claude/worktrees/` do próprio repo do
  fixture). Worktree fora da árvore com outro segmento `worktrees` no caminho fica coberta pelo
  mesmo relpath, mas sem caso próprio.
- O censo só imprime o inventário quando há delta. Por isso a medição ao vivo usou o override de
  baseline, que o próprio censo declara como não-produção.
