---
branch: fix/merge-verified-foreign-rebase
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: c96854af2ba72d81f6cf001df97cd8501431e0c52483c6324ade7be9f3a83aba
reviewed_code_sha256: 47b10c2f1586902c1f93efa9ca121564e6f3bd94d8b9f33543ea429baf1085aa
findings_total: 11
findings_real: 10
tokens: 141498
duration_min: 6
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose, mandato REFUTAR, mais a passada do autor
nota: "tokens e duração são do subagente revisor. Um achado ficou declarado e não curado: o _warn_serialize faz até 50 'gh pr view' em série e corta em --limit 50 sem avisar"
---

# Passada adversarial: `fix/merge-verified-foreign-rebase`

## O que muda

Adotantes sem `ops/` (onion-kg-ssot, onion-curation) mergeiam pelo `ops/pr-merge-verified.sh` do core com
`--repo`. Em 2026-10-25 o defeito foi medido quatro vezes (#225, #227, #229 e #230 do kg-ssot): o auto-rebase
rodava `bash ops/pr-finalize.sh --rebase --push` na worktree da branch, e esse motor não existe no adotante
(rc 127). Sem worktree, a mensagem mandava rodar o mesmo motor ausente.

Pela decisão do maestro, entram as opções (a) e (c). A (b), `merge=ours`, foi recusada.
- **(a) Rebase próprio quando a worktree da branch não tem `ops/pr-finalize.sh`.** Só se resolvem sozinhas
  `docs/backlog.md` (pelo `kg-backlog-project.sh --markdown`) e `docs/onion/kg-read-index.tsv` (pelo
  `kg-trace.sh . --emit-index`), sempre pelo gerador do próprio alvo. Os dois viajam ao adotante, conferido
  no kg-ssot e no curation. Qualquer outro conflito, ou gerador ausente ou falho, aborta e deixa a branch no
  head de antes, com rc≠0 nomeando o arquivo. Depois do rebase, as projeções são regeneradas na árvore
  combinada (com commit próprio se mudaram) e o lint do alvo tem de dar 0 HARD. Só então vem o push
  `--force-with-lease`, amarrado ao head do PR. Com `--merge-commit`, recusa. Não usa o caminho rápido do CI:
  o head novo espera o CI dele. Sem worktree, a mensagem passa a dar o comando que o adotante tem.
- **(c) Aviso de serialização.** Avisa, sem bloquear, quando outro PR aberto toca a mesma projeção.

## Achados

1. **MÉDIA, curado.** Sem trap de sinal, um SIGTERM no lint ou no gerador deixava a worktree reescrita ou em
   rebase; o revisor mediu os dois casos. Agora há trap em EXIT, TERM, INT e HUP que desfaz tudo, salvo o
   push que já chegou ao remoto. Caso (fx-viii).
2. **MÉDIA, curado.** Uma branch com commit de merge era linearizada, e o conteúdo que mora só no merge sumia
   do head enviado, com rc 0. O revisor mediu um `src/evil.sh` que sumiu. Agora a branch é recusada antes do
   rebase. Caso (fx-vii).
3. **MÉDIA/BAIXA, curado.** O rc 3 do `kg-trace` era aceito sem conferir o estado, e grafo ilegível também
   devolve rc 3: o índice povoado virava vazio. Agora o rc 3 só vale se a base também tem o índice vazio ou
   não o tem, e se o stderr não diz "ilegível". Caso (fx-vi).
4. **BAIXA, curado.** O texto do rastro de recusa narrava sucesso ("o lint julgou, o push foi…"). Agora ele é
   neutro, e o texto de sucesso sai do que a função disse que fez.
5. **BAIXA, curado.** Era o rc do push que decidia "nada enviado". Agora, com rc≠0, quem decide é o ref
   remoto (`_fr_pushed`), como no SAC-85. Não foi medido: não houve como forçar localmente um push que chega
   e sai com rc≠0.
6. **BAIXA, curado.** O caminho absoluto da worktree ia para o comentário do PR, num repo que pode ser
   público. Agora vai só o nome da worktree.
7. **BAIXA, curado.** A causa do rastro repetia arquivos quando havia vários commits. Agora passa por `sort -u`.
8. **BAIXA, curado.** O comando sugerido sem worktree (`kg-trace … > docs/onion/kg-read-index.tsv`) truncava o
   índice vivo se o gerador falhasse. Agora sugere arquivo temporário e `mv`.
9. **BAIXA, curado (passada do autor).** Fora de qualquer repo, com `_top` vazio, o script caía na mensagem do
   core. Agora isso conta como repo alheio.
10. **BAIXA, declarado e não curado.** O `_warn_serialize` faz até 50 `gh pr view` em série e corta em
    `--limit 50` sem avisar. O custo é aceitável nos adotantes de hoje, que têm poucos PRs abertos.
11. **Não procede.** Funções e variáveis que vazam (`_undo`, `_FR_*`, `_top`): conferido por grep, não há
    colisão.

A bancada também pegou um defeito meu durante a cura: `_fr_ret 1` saía só da função auxiliar, não do
`_foreign_rebase`. Os casos (fx-ii), (fx-iii) e (fx-v) reprovaram, e a cura virou `_fr_off; return 1`.

## Suspeitas descartadas

- **`reset --hard` perde commit.** Só roda antes do push, com a worktree já provada limpa e no head do PR.
- **Force-push por cima de push alheio.** O lease amarrado ao head do PR recusa; o revisor mediu.
- **PR de fork.** O ref não existe no `origin`, então o lease falha e o caminho fecha seguro.
- **`pipefail` com fechador precoce.** Os `grep -q` leem here-string, não pipe.
- **Regressão no caminho do core.** Só muda o texto do rastro, que virou variável com o mesmo default. O caso
  (y) ganhou o motor na raiz do r2, como o checkout do core tem.
- **Commit que fica vazio depois da regeneração.** Vai por `--skip`; sondado à parte, e o head termina na
  base.

## Mutantes

Cada caso novo roda contra o SUT e contra um mutante, e o mutante tem de reprovar:

| Caso | Mutante | Ordem |
|---|---|---|
| (fx-i) | `if [ ! -f "${_wt}/ops/pr-finalize.sh" ]` → `if false` (o código antigo, rc 127) | mutante antes do real |
| (fx-ii) | a guarda de projeção → `true` | mutante antes do real |
| (fx-iii) | o `say` do aviso → `:` | mutante antes do real |
| (fx-iv) | a mensagem do adotante → `if false` | mutante antes do real |
| (fx-v) | o julgamento do lint → `if false` | real antes do mutante |
| (fx-vi) | a conferência da base no rc 3 → `elif false` | real antes do mutante |
| (fx-vii) | a recusa de commit de merge → `true` | real antes do mutante |
| (fx-viii) | `_fr_on_death` → `:` | real antes do mutante |

Os casos (fx-v) a (fx-viii) rodam o real antes porque ali o mutante empurra e muda a fixture.

Também rodei os casos com o `ops/pr-merge-verified.sh` da `origin/main` no lugar do SUT: (fx-i) a (fx-iv)
reprovam todos, com rc 1 e a chamada ao `pr-finalize` ausente.

Placar da bancada: `--families pr_merge_verified,merge_serial,merge_skip_ci,merge_dispensa` dá 102 passaram
e 0 falharam.

## Limites declarados

- Os geradores da bancada são stubs determinísticos do alvo; o `kg-trace` e o `kg-backlog-project` reais não
  rodam aqui.
- O rc 3 aceito, com a base vazia, não tem caso próprio. Só a recusa (fx-vi) está coberta.
- O caminho "atrás sem conflito" no repo alheio não tem caso próprio. Ele usa o mesmo `_foreign_rebase`,
  pelo ramo em que o rebase sai limpo.
- O lint do alvo pode ser lento ou ter HARD pré-existente. Nesse caso o auto-rebase recusa nomeando o
  problema, por desenho.
