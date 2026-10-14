---
title: 'Resíduo — cache do pin das portas em 668cac66a12b e mensagem própria para head sem check-run no caminho rápido do merge'
date: 2026-10-14
branch: chore/tail-door-cache-fastpath-msg
reviewed_diff_sha256: a3c514725c99eed7f3ff7b929d4577e3511d44cd338ead6d2ce480c136976c20
reviewed_code_sha256: 2e2de201d0dfa187aca5e0ff25f5845953d7fcfb8afd8e62bf06598297a343c9
findings_total: 4
findings_real: 2
findings_fixed: 1
tokens: 0
duration_min: 40
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Dois itens. (1) O cache onion_version das quatro portas no members.yaml sai de 9b5c89318dfc para
  668cac66a12b (onion-v1.1.0), o pin que o publish-door.sh --status lê do REMOTO. (2) A condição 4 de
  _skip_ci_decide em ops/pr-merge-verified.sh ganha mensagem própria para o head anterior com zero
  check-runs (o #1092 de 2026-10-13); o comportamento não muda, continua esperando. Caso (d3) na
  família merge_skip_ci, dois mutantes, os dois reprovados. Nó de evidência no grafo do merge.
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Item 1: cache do pin das portas

- **Antes:** `bash ops/publish-door.sh --status` mostrava as quatro portas `em dia · cache do registro
  difere`, com pin publicado `668cac66a12b` e pin de registro `9b5c89318dfc`.
- **Caminho:** o `ops/registry-pins.sh` deixa `kind: door` de fora e manda para o `ops/door-seal-pin.sh`.
  Este recusou nas quatro portas (`--dry-run`): onion-mini com árvore suja, onion-standalone e onion-core
  com o clone local atrás do remoto, onion-plugins sem carimbo no clone. A causa é a F3: o motor publica
  de um clone descartável e não atualiza os clones locais (publish-doctrine §6), e o door-seal-pin.sh é
  anterior a isso e lê o clone. Não mexi nos clones (I3; repo de outro escritor). Segui o precedente de
  2026-10-11 no próprio registro: o cache recebe o pin que o `--status` leu do remoto, e o comentário diz
  essa fonte (antes dois deles diziam "carimbado por ops/door-seal-pin.sh", o que deixou de ser verdade).
- **Depois:** `--status --members <árvore>` dá `em dia` nas quatro, sem "cache difere".
  `ops/registry-pins.sh --check`: 20 em dia, 0 divergentes, 0 ilegíveis, 8 fora do escopo.
  `members-validate.sh`: válido, 28 membros.

## Item 2: mensagem do caminho rápido

- **Medido:** o head `1cddfb80` do #1092 tem `total_count: 0` de check-runs. O comentário de auto-rebase
  dizia "o check exigido 'selftest-gate' não está verde". Desde o merge do #1081 (o caminho rápido), 11
  PRs mergearam e só um passou por auto-rebase, o #1092. Logo não houve oportunidade ao vivo do pulo.
- **Cura:** antes do laço dos exigidos, `_runs` sem nenhuma linha devolve
  `espera: o head anterior <sha> não tem check-run nenhum — o caso típico é o PR aberto/empurrado já em
  conflito (...) nunca houve verde para ler; espera o CI do head novo`. Retorno 1, como antes.
- **Caso (d3):** `MSC_OLD_RUNS='\n'` (stub sem linha nenhuma, porque o vazio cairia no default GREEN). O
  caso exige rc 4, nenhum merge, a mensagem nova no comentário e a ausência de "não está verde". O caso
  (d) ganhou a negação simétrica, a ausência de "não tem check-run nenhum".

### Mutantes (ops/mutate-and-restore.sh)

| # | Mutante | Reprova |
|---|---|---|
| M1 | a guarda de zero runs vira `{ : ONION_MUTANTE; true; } \|\| …` (zero cai na mensagem do vermelho) | (d3) |
| M2 | a mensagem do vermelho vira a de zero runs (fusão na outra direção) | (d) |

Bancada: `LC_ALL=C bash .claude/validation/lint-selftest.sh --families merge_skip_ci,pr_merge_verified`:
60 passaram, 0 falharam, 0 pulados. Os dois mutantes deram 14/15 com o caso esperado em ✗, e o SUT foi
restaurado (zero `ONION_MUTANTE`).

## Passada adversarial

1. **REAL, CORRIGIDO.** A mensagem sugerida afirmava a CAUSA ("o PR foi aberto/empurrado já em
   conflito"). Zero check-runs é o sinal, e outros motivos dão o mesmo zero: workflow filtrado por path, CI
   ainda não criado, commit com skip. É a classe da regra ajustada a um caso que afirma causa falsa. A
   mensagem agora diz "o caso típico é…".
2. **REAL, DECLARADO, fora do escopo.** Um head com check-runs, mas SEM o check exigido (por exemplo, só
   `onion-review-verdict`), ainda cai em "não está verde", quando o certo seria "ausente". Pedi só o caso
   do zero total. A decisão continua certa: espera.
3. **Não é defeito.** Se o `gh api` falhar, o caminho continua sendo "não li os check-runs", antes da guarda
   nova. Um vazio por falha de leitura não chega à mensagem de zero.
4. **Não é defeito.** O cache do registro não decide nada: a REGRA 85 (Porta pública espelha o core, com
   catraca) só informa, e o `--status` lê o remoto. Errar aqui só mudaria a exibição.

## Limitações

- A contagem de oportunidades ao vivo usa o índice de busca do forge (`gh search prs "Auto-rebase de"`),
  não uma leitura PR a PR.
- "Nasceu em conflito" no #1092 é inferência: zero check-runs no head de abertura, e o auto-rebase só roda
  em PR CONFLICTING. Não li o `mergeable` do momento da abertura.
- O bypass `--admin` no forge segue NÃO MEDIDO AO VIVO.
- O `door-seal-pin.sh` continua lendo o clone local, e por isso não serve para portas publicadas pela F3.
  Não o mudei: é código vizinho do motor, que está em edição noutra branch.
