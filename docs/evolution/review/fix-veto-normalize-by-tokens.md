---
reviewed_diff_sha256: e30e55ab66df411b6c21c223b353ece33f069e9b9179df2a41edc43b1ef61549
findings_total: 37
findings_real: 33
tokens: 401388
duration_min: 73
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Três passadas do Elenxo (opus, worktree isolada, mandato de achar falso positivo e escape), as três
  REPROVADAS e curadas no mesmo laço. tokens/duration somam a 2ª (188.804 tok, 28 min) e a 3ª
  (212.584 tok, 45 min); o custo da 1ª não foi atribuído com certeza e fica FORA da soma, declarado.
  Das contagens: 1ª passada 15 achados, 2ª 11, 3ª 11. Os 4 não-reais são as "falhas" que se provaram
  passes corretos (push.default=upstream sem upstream, gh repo sync sem repo, e dois mutantes
  declarados redundantes que eram a única defesa — estes viraram caso de bancada e contam como reais).
---

# Resíduo — `fix/veto-normalize-by-tokens`

Cura de classe dos dois vetos PreToolUse (`pretooluse-merge-gate.sh`, `pretooluse-protect-main.sh`)
e da lib partilhada, forjada por `/meta:forge-guard`. Grafo:
`docs/evolution/research/guard-vetos-por-tokens-2026-10/vetos-por-tokens-2026-10.kg.yaml`.

## As três passadas e o que cada uma derrubou

| passada | achado central | nó |
|---|---|---|
| 1ª | escapes NOVOS de vocabulário que a reescrita abriu (`#` no meio da palavra, worktree tida como outro repo, `time -p`, `$X` sem word-splitting) + escapes antigos reais + FPs | `E_ELENXO_REPROVOU_A_1A_REESCRITA` |
| 2ª | o diretório errado: a lib julgava pela raiz, não pelo `cwd` do JSON; isenção pelo `origin` do diretório; pflag colado; heredoc lido por shell; refspec vindo de config; caso de 140 KB da bancada VAZIO | `E_ELENXO_2A_PASSADA_O_DIRETORIO_ERRADO` |
| 3ª | a isenção era a falha aberta: isentava por ausência de prova (URL posicional do gh, remoto com `/`, caminho local, `cd` não seguido, `insteadOf`) | `E_ELENXO_3A_PASSADA_A_ISENCAO_E_A_FALHA_ABERTA` |

Na triagem da 3ª passada, a sessão ainda achou e curou três defeitos: comentário na linha do heredoc
tido como shell, `owner/repo#N` e `gh pr checkout <URL nossa> && gh pr merge`. E uma cura minha foi
desfeita no mesmo laço: isentar slug estrangeiro a partir do NOSSO diretório abriria escape por alias
de repo renomeado.

## Os `confirmed` dos grafos tocados

- `vetos-por-tokens-2026-10`: todos os nós `confirmed` foram re-medidos nesta rodada. A 1ª redação de
  `C_TETO_MUTANTES_QUE_AS_CAMADAS_ESCONDEM` afirmava redundância falsa e foi corrigida no próprio nó,
  com a evidência; `C_TETO_FRONTEIRA_DO_QUE_O_HOOK_VE` foi reescrito com o que fechou e o que fica.
  `D_TOKENIZADOR_SHLEX_COM_RECUSA` (done) carrega as medições finais.
- `radar-E3-2026-10-05-r7`: só `Q_CURAR_OS_VETOS_DE_MERGE_E_PUSH` → done, com `verified_at`.

## Medição final

Bancada 186/186; 74/75 mutantes mordem; 22.662 comandos reais reexecutados (0 FP novo, 4 antigos
curados, 31 artefatos de estado); gate completo do pre-commit verde em `d3783143`.

## Depois da revisão: só a bancada mudou

Dois commits pós-resíduo, ambos na PREPARAÇÃO da família `pretooluse_veto`, nenhum em hook ou lib: o
git do runner do CI recusa remoto com `/` no nome (`git remote add up/x`), e esse `remote add` sob
`set -e` abortava o worker 1 antes da soma (exit 128). A preparação agora tolera a falha, e o caso do
remoto com barra roda onde o git aceita a forma e PULA com motivo onde a recusa. O hash acima cobre
esses commits e a regeneração das duas projeções da bancada (inventário e painel), que só mudam contagem.
