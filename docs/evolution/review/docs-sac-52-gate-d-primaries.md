---
branch: docs/sac-52-gate-d-primaries
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 643690
duration_min: 7
verdict: REPROVADO_E_CURADO
reviewer: Ancoragem (verificador separado por fonte, reabre o documento) + Elenxo do run wf_5ceb8e1b-6d6 + passada própria
---

# O gate D confirmou a opção selada, e o grafo nasceu na worktree errada

## Achados

1. **O grafo foi escrito na worktree do #1042, porque era o `cwd` da sessão.** O escritor semeou a partir do grafo de `main`, de modo que o conteúdo é a versão de main mais um apêndice. Copiei o arquivo para esta branch, nascida de `main`, e conferi o diff: só apêndice e três flips. Removi a cópia não rastreada da outra worktree.
2. **Três flips de status em nós já selados no `main`.** As objeções do tipo "primária citada, não lida" de 2026-10-11 viram `superseded`, com `SUPERSEDES` vindo das evidências ancoradas que leram aquelas primárias. Pela tabela de selagem, flip de nó selado é do maestro: estão nomeados no corpo do PR, e o merge é o selo.

## O que NÃO cobre

- Estado e aprovação no Runme, e a semântica de passo humano no CACAO. As 3 claims sobre esses pontos foram rejeitadas como EXAGERADAS, e as lacunas seguem abertas em `E_LACUNAS_PLAYBOOK_SDAAL_1012`.
