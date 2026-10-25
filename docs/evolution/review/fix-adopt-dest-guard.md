---
branch: fix/adopt-dest-guard
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
tokens: 0
duration_min: 40
findings_fixed: 6
verdict: CORRIGIDO
elenxo: sim
reviewer: "passada própria do autor, por sondas executadas (11 casos de borda do guarda num sandbox, bancada --affected-range) e não por leitura; um achado vem da bancada, não do olho"
nota: "tokens não medido (0): a passada correu na mesma sessão da implementação, sem contador separado"
---

# Passada adversarial: `fix/adopt-dest-guard`

## O que muda

Incidente medido em 2026-10-25: um agente rodou o bloco "Procedimento de Configuração pós-cópia" do
`/meta:adopt --update` com o placeholder `DEST="<INSTALL_DIR (Fase 3) | WORK (--update)>"` sem preencher.
Um helper criou um diretório-lixo com esse nome literal na raiz do core, e os
`git -C "$DEST" config gitflow.branch.*` gravaram no `.git/config` do core, que era o repo que continha o
diretório. O `core.hooksPath` só escapou porque já estava setado.

- `.claude/utils/adopt/assert-dest.sh` (novo): recusa com rc=2, dizendo o motivo, quando o DEST está vazio,
  tem `<`/`>`, não existe, não é diretório, não está numa árvore de trabalho git, não é a raiz do repo (o
  toplevel físico difere do DEST) ou quando o `GIT_DIR`/`GIT_WORK_TREE` do ambiente aponta outro repo.
  Só lê.
- `adopt.md`: o guarda é a 1ª chamada do bloco pós-cópia (`|| exit 1`), e também vem antes do `cp -R` da
  cópia segura e do `mkdir -p` do relatório downstream.
- Helpers protegidos, escolhidos pela medida
  `grep -n 'mkdir\|git -C' .claude/utils/adopt/*.sh` cruzada com o que o bloco chama:
  `install-onion-githook.sh` (cria `.githooks` e seta `core.hooksPath`), `starter-coevolution.sh`,
  `starter-kg-inbox.sh` e `starter-research-seed.sh` (o `mkdir -p "$DEST/…"` deles cria o próprio DEST:
  é a origem do diretório-lixo), `regen-ssot-projections.sh` (`mkdir -p "$DEST/docs/onion"`) e
  `durable-commit.sh` (faria checkout e commit no repo pai; um DEST que não é repo segue "pulado", como já era).
  O `offer-onion-ci.sh` já tinha a mesma checagem de raiz inline e ficou como estava.
  Ficaram de fora os helpers que só escrevem arquivo dentro de um DEST que já existe e não fazem `mkdir`
  nem `git config` (`scope-claude-gitignore`, `ensure-secret-gitignore`, `emit-licenses`,
  `merge-prettierignore`, `emit-eol-gitattributes`, `migrate-seed-graph`, `regen-baselines`). O guarda do
  topo do bloco cobre todos eles.

## Achados

1. **REAL, curado: o `GIT_DIR` do ambiente desviava o repo.** Git hook exporta `GIT_DIR`. Com ele
   apontando outro repo, `git -C DEST rev-parse --show-toplevel` devolve o próprio DEST (o cwd do `-C`),
   a checagem de raiz passava e o `git -C DEST config` caía no repo do `GIT_DIR`. Medido pela sonda 1.
   Cura: passo (7) do guarda, que compara o git-dir com o ambiente ao git-dir medido sem ele. As sondas 2,
   3 e 8 (hook legítimo, `GIT_DIR=.git` relativo, hook de worktree) seguem passando. Caso (f) da bancada.
2. **REAL, curado: fixtures que passariam a medir a recusa em vez do comportamento.**
   `ssot_projections` (a/b/c/c0/e) e `upstream_portal_fixes` (d, d2) rodavam os helpers num diretório
   solto. Com o guarda, o (d) reprovou (medido), e o (d2) ficaria vacuoso: o rc≠0 viria da recusa e não do
   DEST somente-leitura. Cura: cada fixture virou raiz de repo (`git init`).
3. **REAL, curado (achado da bancada): `adopt_robust` (a1, a2, b1) reprovou.** O guarda estava antes do
   passo (a) da cópia segura, e o caso extrai esse trecho sem `DEST`. Cura: o guarda foi para a linha do
   `cp -R` de (d), que é a escrita que ele protege. O (a) só lê.
4. **REAL, curado: a REGRA 5 (Limites de linhas) reprovou o adopt.md (809 > 800).** Cura: o guarda foi
   para a mesma linha do `cp`/`mkdir` que protege, o comentário do bloco pós-cópia ficou numa linha, e o
   bloco do commit durável não repete o guarda que o `durable-commit.sh` já faz. O arquivo fica com 800
   linhas, **no limite**. A próxima linha nele tem de vir junto de uma extração.
5. **REAL, curado (no harness): o mutante (f-MUT) sobrevivia por causa da fixture.** O mutante de (e) já
   tinha gravado `main` no core da fixture, e regravar o mesmo valor deixava o config byte-idêntico. Cura:
   (f) grava `f-probe`. Depois disso o `_prove_mutation` aprovou.
6. **REAL, NÃO curado (declarado): o `dedicated-branch.sh` resolve o toplevel.** No `--update`,
   `WORK="$(dedicated-branch.sh "$TARGET" …)"` devolve a raiz do repo que contém o `TARGET`. Se o `TARGET`
   for um subdiretório do core, o `WORK` vira o core, que É uma raiz, e o guarda aprova. O incidente foi o
   DEST e não o TARGET. Mudar isso muda o contrato do `dedicated-branch.sh`, que hoje aceita qualquer
   caminho dentro do alvo, e fica para um PR próprio.
7. **Cosmético, curado:** a mensagem para repo bare e para DEST dentro de `.git` dizia "não está num
   repositório git". Agora diz "árvore de trabalho … (fora de repo, repo bare ou dentro de .git)".

## Mutantes

- **(e-MUT)**: sem a comparação de toplevel (`[ "${_top_p}" = "${_dest_p}" ]` → `true`), o bloco real
  do adopt.md (as linhas do guarda e do `git -C "$DEST" config gitflow.branch.develop`, extraídas do
  documento) roda num DEST subdiretório e o `.git/config` do repo pai muda. O intacto o deixa
  byte-idêntico. Aprovado pelo `_prove_mutation`, que confere também que a mutação foi aplicada e que a
  fixture está viva.
- **(f-MUT)**: sem a comparação de git-dir (passo 7), com `GIT_DIR` desviado, o config do outro repo muda.
  Aprovado.

## Limites declarados

- O achado 6 segue aberto.
- `ops/materialize-adopter.sh` grava `git -C "${DEST}" config gitflow.branch.develop main` inline, sem o
  guarda. Lá o DEST é `git init` do próprio script, então é raiz por construção. Não foi tocado.
- O guarda confere o DEST e não o `SOURCE_ROOT`. Um `SOURCE_ROOT` com placeholder faz o `bash` do guarda
  falhar com rc=127, e o `|| exit 1` para o bloco do mesmo jeito, só que com uma mensagem pior.
- O adopt.md está em 800 linhas, no teto da REGRA 5.
