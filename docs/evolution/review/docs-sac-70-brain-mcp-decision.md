---
branch: docs/sac-70-brain-mcp-decision
date: 2026-10-11
reviewed_diff_sha256: pendente
reviewed_code_sha256: a5f7a381f2b018565c0f87d074d1315e19c22aa261f12e84366a12c12cbe80b2
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 7998840
duration_min: 19
verdict: REPROVADO_E_CURADO
reviewer: Elenxo do run wf_19d83833-a3e (refutador opus/high, 45 objeções) + passada própria sobre o grafo escrito
---

# O grafo dizia que a recomendação chegou truncada, e ela estava inteira no retorno

## Achados

1. **Recomendação marcada como truncada.** O agente de escrita recebeu o texto cortado e completou o
   degrau 2 "de forma conservadora a partir da opção B". O retorno do run trazia o texto inteiro.
   Reescrevi o degrau 2 do `D_ONION_BRAIN_MCP_REMOTO` com a redação integral, incluindo o que o
   remendo tinha perdido: a rejeição de D, SSE e stdio, e o custo recorrente da churn da spec que
   pede comparar a opção C antes do degrau 2.
2. **O grafo nasceu na worktree errada.** O workflow escreveu na worktree do #1032, porque o `cwd`
   da sessão estava lá. Ele ficou untracked e fora do push daquele PR (conferido com
   `git log origin/main..HEAD --name-only`). Movi o grafo para a branch própria.
3. **A SYNTHESIS não teria leitor.** Todos os 52 nós já tinham `trace:`. O de lacunas apontava para o
   próprio grafo, e troquei o valor para a `SYNTHESIS.md`, sem duplicar a chave.

## O que esta passada NÃO verificou

- As 39 claims cortadas por orçamento.
- A divergência entre a síntese e o Elenxo sobre onde mora o código, que fica para o maestro selar.

## Passada do selo (2026-10-12)

O maestro selou o nó de decisão na opção recomendada, por pergunta com opções. Diff revisado: só o bloco do `D_` mudou (`status: confirmed`, `verified_at`, `verified_against` com a opção selada, `provenance` de testemunho), radar exit 0 e contrato rc 0. Nenhum outro nó foi tocado.
