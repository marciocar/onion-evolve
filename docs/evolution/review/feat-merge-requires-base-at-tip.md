---
title: 'Resíduo — strict local no caminho verificado: a base do PR na ponta do main (FASE 0)'
date: 2026-10-14
branch: feat/merge-requires-base-at-tip
reviewed_diff_sha256: 2d5a63c07062613d75800810010169ab6900b163806838e2c1175438aac242da
reviewed_code_sha256: 08a66ea897aa54d3a1422d6f389c2d556eeda33f62a40429a9b61d0c87660627
findings_total: 12
findings_real: 5
findings_fixed: 4
tokens: 0
duration_min: 120
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Decisão do maestro de 2026-10-14 («Fase 0 já + ler primárias antes do B1») sobre
  D_POSTMERGE_PROJECTION_WRITER_2026_10, nó de um grafo de pesquisa ainda não rastreado (citado pelo
  nome). A cura é a opção contrarian C_OPCAO_C_CONTRARIAN_STRICT_LOCAL. O ops/pr-merge-verified.sh passa
  a exigir a base do PR na ponta do main, lida no forge. PR atrás sem conflito vai pelo mesmo auto-rebase
  do CONFLICTING, e o merge sem o CI do head novo fica condicionado às projeções regeneradas na árvore
  combinada serem byte-idênticas às do head anterior. Bancada de 4 famílias com 93 casos verdes; 6 mutantes
  executados, 6 reprovados.
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que mudou

`ops/pr-merge-verified.sh`:

1. **Leitura da distância até a ponta.** Usa o compare do forge, `gh api repos/<slug>/compare/<base>...<head>`
   com `--jq .behind_by`. Ele conta os commits que a base tem e o head não, ou seja, diz se
   `merge-base(head, base)` é diferente da ponta da base. Escolhi o forge em vez do `git merge-base origin/main`
   local porque a base que importa é a que o forge vai usar no merge, e a cópia local pode estar atrasada.
   Se a leitura for ilegível, o script não mergeia.
2. **O gatilho do auto-rebase** passa a ser `CONFLICTING` **ou** `behind_by > 0`. O teto
   (`ONION_MERGE_REBASE_MAX`, 2 na série inteira) é o mesmo. O rastro no PR diz qual dos dois motivos
   disparou o rebase.
3. **A regeneração na árvore combinada.** Conferido no `ops/pr-finalize.sh`: com `--rebase`, o passo 1
   (`_regen`, `_restamp`, `_commit`) roda **sempre** depois do rebase, haja conflito ou não. A projeção
   regenerada vira commit no head que é empurrado. O caso novo, PR atrás sem conflito, passa pelo mesmo
   caminho, e não precisei mudar o pr-finalize.
4. **Condição (8) do caminho rápido.** As projeções da lista única (`onion-regen-lib.sh`: `ONION_GENERATED`
   e `ONION_GENERATED_DIRS`) têm de ser iguais byte a byte entre o head anterior e o novo, pelo
   `git diff --name-only <velho> <novo> -- <lista>`. Se alguma mudou, o script espera o CI. Se a comparação
   falhar, também espera.
5. **Condição (9)**, achado desta passada: o head novo ainda tem de estar na ponta no momento da decisão.
6. **Última leitura antes do merge**, outro achado desta passada. Ela acontece antes de qualquer registro
   no PR. Direto, o script para; na série, sai com rc 4.
7. **`--merge-commit` com PR atrás:** o script recusa e diz o caminho (mergear a base na branch). O
   rebase linearizaria o merge, que nesse modo é o próprio conteúdo do PR.

## Casos da bancada (família `merge_skip_ci`, mais stubs ajustados em `pr_merge_verified`, `merge_dispensa` e `merge_serial`)

| caso | o que prova |
|---|---|
| (s1) | PR atrás do main, sem conflito, com projeção mudada pela combinação: rebase para a ponta, regenera, espera o CI (rc 4) e nomeia `docs/backlog.md` |
| (s2) | PR na ponta: sem rebase, sem rastro, merge pelos gates de sempre (sem `--admin`) |
| (s3) | a regeneração muda a projeção do PR: não há caminho rápido, mesmo com as outras 7 condições valendo |
| (s4) | PR atrás, sem conflito, regeneração idêntica: rebase e caminho rápido (`--admin --match-head-commit` no head novo) |
| (s5) | **478/479 reproduzido.** O `git merge-tree` da combinação é LIMPO e sai velho: 4 itens com `count: 3`. Sem CI do head novo, nada é mergeado. Com o CI do head novo verde, entra o head regenerado (`count: 4`) |
| (s6) | o main que não para de andar: para em 2 rebases, sem merge |
| (s7) | o main anda logo depois do rebase: a condição (9) manda esperar, e o rastro não anuncia merge sem CI |
| (s7b) | o main anda durante os gates: a última leitura recusa (direto rc 1, série rc 4) |
| (s8) | compare ilegível: não mergeia; `--merge-commit` com PR atrás: recusa sem rebasear |

Os 14 casos antigos da família continuam verdes. Para isso o stub do compare mede `rev-list --count` no
remoto bare, que é o que o compare do GitHub mede.

`LC_ALL=C bash .claude/validation/lint-selftest.sh --families merge_skip_ci,pr_merge_verified,merge_dispensa,merge_serial`
→ **93 passaram, 0 falharam**.

**Re-revisão depois do rebase** (2026-10-14): o main trouxe o commit `d87449b7`. Ele separa, na condição 4 de
`_skip_ci_decide`, o caso de zero check-runs no head anterior, com o caso (d3), e acrescentou um nó ao mesmo
grafo. O conflito ficou só no grafo (o teto e os nós) e na projeção `testing-inventory.md`. Resolvi
mantendo os dois nós, com o teto 77 → 78 declarado. A condição 4 dele vem antes das minhas (8) e (9), e as
duas não se cruzam. Na árvore combinada: **94 passaram, 0 falharam** (os 93 mais o (d3)).

## Mutantes (`ops/mutate-and-restore.sh`, cada um com o marcador; restauração conferida por sha256)

| mutante | o que tira | reprova |
|---|---|---|
| M1 | o gatilho de "atrás" no laço (`while [ "$_mg" = CONFLICTING ]`) | s1, s4, s5, s6, s7 |
| M2 | a condição (8), das projeções idênticas | s1, s3, s5 |
| M3 | a última leitura antes do merge (`if false`) | s7b |
| M4 | o teto, afrouxado para 4 só no caso "atrás" | s6 |
| M5 | compare ilegível vira `_behind=0` | s8 |
| M6 | a condição (9), do head na ponta na decisão | s7 |

## Passada adversarial

1. **Laço infinito de rebase com o main andando sem parar.** O teto é o mesmo do CONFLICTING e vale para a
   série inteira (`ONION_MERGE_REBASE_DONE`). O caso s6 faz o main andar depois de cada rebase: o script
   para em 2 rebases, nomeando o estado, sem merge. O M4 prova que o caso pega um teto afrouxado.
   **Declarado:** na série, o rc 4 da última leitura também conta como rodada de rebase (o `merge-serial`
   soma todo rc 4). Isso é conservador: a série chega ao teto mais cedo, nunca mais tarde. Fica também o
   teto de rodadas do `merge-serial` (`ONION_MERGE_SERIAL_ROUNDS`, 6).
2. **Interação com o alarme do main.** O caminho rápido já recusava com o alarme aberto, e isso não mudou.
   O que muda é que, com o main vermelho, um PR atrás agora é rebaseado **sobre o main quebrado**. O CI do
   head novo herda a quebra e reprova, então só entra quem conserta. Antes, o PR atrás entrava com o verde
   do head velho por cima do main quebrado. A regra ficou mais estrita e coerente com "com o alarme aberto,
   só o conserto entra". **Declarado:** o PR de revert do alarme nasce na ponta. Se outro merge entrar antes
   dele, ele é rebaseado, e um conflito de fonte no revert para no auto-rebase e tem de ser resolvido à mão,
   como qualquer conflito de fonte.
3. **PR que só toca projeção.** (a) Depois do rebase e da regeneração, o diff dele pode sumir: o rebase
   descarta o commit vazio, a branch vira a ponta do main e o PR fica sem commits. Pela leitura do código,
   o `gh pr merge` falharia e a prova pelo estado diria "não mergeou", sem sucesso falso. **NÃO MEDIDO**:
   não há caso de bancada para o forge recusando um PR vazio. (b) Se o main trouxe projeção, esse PR sempre
   espera o CI depois do rebase, porque a condição (8) compara exatamente a única coisa que ele muda.
   (c) A guarda que reprova PR que toca projeção é do B1, não desta fase.
4. **REAL, CORRIGIDO (pela bancada):** a 1ª forma lia a base dentro de `_behind_base`, que roda em `$(…)`.
   A atribuição morria no subshell, e a base saía vazia nas mensagens e na URL do compare. Os casos s1 e s6
   pegaram (`atrás de ''`). Agora a base é lida uma vez, fora da função.
5. **REAL, CORRIGIDO:** o `--match-head-commit` amarra o HEAD, não a BASE. Entre a 1ª leitura e o merge
   pode passar a espera inteira do CI, de 15 a 25 minutos, e o main anda nesse tempo. Sem a última leitura,
   o forge rebasearia no merge e reabriria exatamente o buraco que esta fase fecha. Caso s7b, mutante M3.
6. **REAL, CORRIGIDO:** quando o main anda logo depois do rebase, o rastro no PR anunciava "merge SEM
   esperar o CI" para um merge que a última leitura ia recusar. Criei a condição (9). Caso s7, mutante M6.
7. **REAL, CORRIGIDO:** com `--merge-commit` (o PR de update de adotante com `onion/vendor`), o auto-rebase
   de um PR atrás linearizaria o merge, e o update seguinte acusaria conflito espúrio. Agora o script
   recusa. Caso s8.
8. **REAL, NÃO CORRIGIDO (pré-existente, fora do escopo):** com `--merge-commit`, um PR **CONFLICTING**
   continua sendo auto-rebaseado como antes, com o mesmo risco de linearizar. Na prática, esse PR raramente
   tem worktree no core e morre antes no "sem worktree". Fica declarado.
9. **Equivalência compare × merge-base.** Não verifiquei ao vivo: assumi pela doc da API (`behind_by`) e
   pela bancada, que mede `rev-list --count` no remoto bare. Nenhuma chamada real ao compare foi feita.
   PR de fork não foi considerado, porque os PRs do core são do mesmo repo.
10. **Custo no ritmo** (medido; o detalhe está em `E_STRICT_LOCAL_EXECUTADO_2026_10_14`). Nos 50 últimos
    merges, 5 estavam atrás, o que dá 5 rebases a mais (10%). Em 3 desses 5 o main tinha trazido projeção,
    e o PR esperaria o CI do head novo. Como 43 de 50 PRs commitam projeção, o caminho rápido do #1081
    depois de um rebase fica raro. Nos rastros de auto-rebase de #1045 a #1099 (7 PRs), ele nunca foi
    registrado. Esse é o preço da cura, e o B1 (escritor único) é quem o devolve.
11. **Janela que sobra:** entre a última leitura e o `gh pr merge` há segundos, sem lock no forge. Duas
    séries do `merge-serial` não disputam essa janela, porque o lock envolve o verificado. Um merge **fora**
    do caminho verificado pode entrar nela, e o hook de merge o veta na sessão.
12. **Nenhum merge real** foi feito: remoto bare e `gh` falso.
