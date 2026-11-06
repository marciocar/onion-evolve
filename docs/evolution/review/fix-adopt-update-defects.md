---
branch: fix/adopt-update-defects
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: e4a95f1b0c853cd8966ebed8db192866ace8768f0ffbf8610a9a92a21bd8601d
reviewed_code_sha256: 0e6c8325e4262eb9cfdf08ec21caa88b624e6bc06f50516b8809b1fdc9049d6f
findings_total: 7
findings_real: 7
tokens: 0
duration_min: 0
findings_fixed: 7
verdict: CORRIGIDO
elenxo: sim
reviewer: autor (leitura adversarial do próprio diferencial) + sessão principal (team-lead), NÃO independentes
nota: >-
  Duas leituras do diferencial do 963fd9002, declaradas como não independentes: a minha, durante a forja,
  achou 7 defeitos reais, todos curados antes do commit; a da sessão principal achou 0 e conferiu que o
  contrato do helper preserva os adotantes sem husky (rc 0 com hooksPath ausente ou absoluto, rc 4 não para
  quem chama, rc 3 só no caso medido). tokens e duration_min = 0: não medidos (a passada foi inline, sem
  subagente). Nenhum refutador independente leu o diff.
---

# Passada adversarial: `fix/adopt-update-defects`

## O que muda

Três defeitos do `/meta:adopt --update` achados no update de um adotante (monorepo com husky v9) em 2026-11-05:

1. `ops/verify-adopter-gate.sh` decidia pelo texto do pre-commit resolvido e reprovava um gate encadeado pelo
   husky que a sonda viu executar e barrar. Agora a sonda decide.
2. `.claude/utils/adopt/applied-delta.sh` media pela ref LOCAL da integração (atrasada) e contava produto como
   aplicado. Agora usa o merge-base mais novo entre o nome, o upstream e `origin/<nome>`.
3. A worktree irmã do `--update` nascia sem o `.husky/_` gerado e o gate ficava inerte. O helper novo
   `worktree-hooks-ready.sh` detecta, gera sem rede ou declara o passo; o `dedicated-branch.sh` para com rc 3.

## Achados

| # | achado | quem | destino |
|---|---|---|---|
| 1 | `printf` do aviso de cadeia com quebra de linha LITERAL no formato (o `\n` virou newline no script) | autor | curado |
| 2 | `WT_HELPER` resolvido depois do `cd "$REPO"`: com `BASH_SOURCE` relativo, `cd: ops/..: No such file` e o caminho do helper saía errado | autor | curado: resolvido antes do `cd` |
| 3 | 1ª forma do conserto do defeito 3 como passo no `adopt.md` estourava a REGRA 5 (Limites de linhas) (811 > 800) e era passo que se pula | autor | curado: a conferência foi para o `dedicated-branch.sh`, onde a worktree nasce; o `adopt.md` voltou a 800 |
| 4 | o helper dava rc 3 também quando o diretório falta no checkout principal, e o `dedicated-branch.sh` pararia adotantes cujo hook falta de verdade (o próprio `--update` o reinstala adiante) | autor | curado: rc 4 distinto, que não para quem chama |
| 5 | 1ª heurística de atribuição do bloqueio na cadeia (exigir "Commit bloqueado" na saída) não separava nada: `bash .githooks/pre-commit \|\| true` imprime a recusa e engole o rc | autor | removida; vira limite declarado (abaixo) |
| 6 | o mutante (e-MUT) do `applied_delta` rodava depois do (e3), que avança o `main` local, e não mordia por causa do estado da fixture | autor | curado: o mutante roda antes do (e3) |
| 7 | o mutante (w-MUT) era copiado para `.claude/utils/adopt/` da árvore viva (fixture stageável) | autor | curado: mora em `mktemp -d`, com o helper ao lado |

## Mutantes

Todos mordem (bancada `adopter_gate,applied_delta,worktree_hooks_ready,adopt_robust,githook`: 58 passaram, 0 pularam, 0 falharam):

- `adopter-gate (g-MUT)`: a busca textual volta a reprovar sozinha (`FOREIGN_HOOK=1; FAILED=1`) e o (g) reprova.
- `applied-delta (e-MUT)`: só o nome dado como candidata e o produto da remota volta ao delta no (e2).
- `worktree-hooks-ready (m)`: resolver o caminho no checkout PRINCIPAL faz a worktree sem `.husky/_` passar como pronta.
- `worktree-hooks-ready (w-MUT)`: sem a chamada `_wt_ready` na criação, o `dedicated-branch.sh` sai rc 0 numa worktree inerte.
- Os que já existiam seguem mordendo: `adopter-gate (b-MUT)`, `(f-MUT)`, `applied-delta (m)`.

Os casos novos (g), (h), (e), (e2) e a família `worktree_hooks_ready` REPROVAM contra o SUT de `origin/main`
(medido com a bancada nova numa worktree destacada de `origin/main`) e passam aqui. O (e3) passa nos dois: é controle.

## Limites declarados

- **Cadeia que engole o rc do Onion.** Encadeado, o rc do commit é o da cadeia. Um `.husky/pre-commit` com
  `bash .githooks/pre-commit || true` e outro passo que barre depois daria "bloqueio provado" ao Onion: a sonda
  não separa os dois sem mexer no alvo. Não medido em adotante nenhum (a cadeia medida é `sh -e`, que para no
  1º rc≠0). Está escrito no código; a guarda nasce se aparecer recorrência.
- **rc 3 no `promote-hub.sh`.** O `promote-hub.sh` também abre a branch dedicada pelo `dedicated-branch.sh` (`|| exit 1`).
  Com farol vivo num hub com husky e sem `node_modules` na worktree irmã, o `--promote-hub` agora PARA com o
  passo impresso, em vez de seguir com o gate inerte. É o mesmo comportamento desejado do `--update`, mas é
  efeito colateral que não foi exercitado por um caso de bancada próprio do `promote-hub`.
- O `--install` só gera sem rede (husky já em `node_modules/.bin`). Instalar dependências usa rede e roda
  scripts do adotante: fica declarado como passo do operador, nunca feito pelo helper.
- Nada foi exercitado no repo real do adotante: só fixtures descartáveis. O repo do adotante foi só LIDO, para
  copiar a forma da cadeia do husky v9.
