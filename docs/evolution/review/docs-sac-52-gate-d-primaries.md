---
branch: docs/sac-52-gate-d-primaries
date: 2026-10-12
reviewed_diff_sha256: pendente
reviewed_code_sha256: 8d7eba21fbe03f9e3f11bff7061257af0be83c63cc5ddd4db61c061e974411c2
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

## Nó acrescentado a pedido do maestro (2026-10-12)

`Q_SDAAL_KIT_REPO_SEPARADO` (GATED) registra quando extrair um kit de contrato SDAAL para repo próprio, versionado por pin no molde do kg-ssot. O gatilho exige as duas coisas juntas: executável para 2 ou mais provedores e 1 consumidor fora do Onion. Hoje há 1 provedor executável e 0 consumidores externos. Ficou com aresta `DEPENDS_ON` para `D_PLAYBOOK_SDAAL_SAC52`; radar exit 0 e contrato rc 0.
