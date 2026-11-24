---
branch: fix/deny-field-notes-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: 79e7146b8762c7ce5e42b725b999da023be7ec82473b732cedfdf61396f92f94
reviewed_code_sha256: c955e5467b113bcdc606953314a5a98c85ad81d8cb04d57eced643eb0eb68f99
findings_total: 4
findings_real: 4
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "Passada do próprio agente de execução, com medição no motor real do Claude Code 2.1.331 (ops/testing/permissions-deny-bench.py), no git real e no hook. A revisão isolada fica com a sessão principal."
nota: "tokens e duração não medidos (0): a passada é do condutor, misturada à construção. O achado 4 é limite declarado, não código."
---

# Passada adversarial: `fix/deny-field-notes-1124`

## O que muda

São as três notas de campo da sessão messaging (23/11) sobre o push forçado e o `git clean` destrutivo. Antes de
curar, cada uma foi medida no motor real (2.1.331, settings de `origin/main`):

- **Nota 1, reproduzida.** Com `&&` ou `;` puros, o motor julga cada subcomando, e o título com `+` passa. Com `$(…)`
  ou pipe, o motor julga o comando INTEIRO. Por isso `git push -u origin feat/x && gh pr create --title "a +b" --body
  "$(cat …)"` caía em `Bash(git push* +*)`. Esse é o formato comum de abrir PR.
- **Nota 2, reproduzida.** `git clean -fdx -n`, `-xn` e `-x --dry-run` caíam no deny, porque o `*` do fim de
  `git clean -fdx*` casa o `-n`.
- **Nota 3: o deny NÃO deixa escapar no 2.1.331.** `FOO=1 git push origin +feat/x`, `env FOO=1 git push -f`,
  `command git push origin +feat/x` e `FOO="$(…)" git push -f` caem no deny, inclusive em `bypassPermissions`. O
  falso negativo estava no hook: a lib já tirava o prefixo, mas o hook só vetava força na produção.

As curas:

- **deny.** Saem `git push* +*`, `git -* push +*` e `git -* push * +*`, e entram `git push origin +*` e
  `git -* push origin +*`, com o `+` colado no remoto e sem `*` antes dele. As 28 regras `git clean -<grupo>*` viram o
  grupo EXATO (`git clean -fdx`, sem nada depois). Também entram, exatas, as ordens que o `*` cobria e que agora
  ficariam de fora: `-xf`, `-xd`, `-xfd`, `-xdf`, `-fxd` e `-dxf`, com `x` e `X`, nua e com `git -*`. São 24 regras.
  As 31 regras retiradas estão em `deny-retired.tsv`: o `--update` as tira do adotante, e o `deny-monotonic.sh` nomeia
  a retirada sem reprovar.
- **Para onde foi a cobertura.** O `+` de refspec em qualquer outra posição (`push -u origin +x`, `push upstream +x`)
  passou ao hook `pretooluse-protect-main.sh`. O mesmo vale para o grupo do clean seguido de caminho ou de outra flag
  (`-fdx sub/`, `-fdxq`). O hook já julgava o clean por token e deixa passar o `-n`.
- **lib** (`invocation-lines.sh`). A linha canônica separa a força dura (`--force`, para `-f`, `--force`, `+ref` e
  `--mirror`) da lease (`--force-with-lease`).
- **hook.** A força dura cai em QUALQUER branch, como no deny. A lease cai só na produção, como antes. O `+` só conta
  quando abre um refspec do próprio push, porque a lib já o lia assim: título de PR, `-o "ci +skip"`, `tail -n +2` e
  `v1.0.0+build1` passam.

## Achados

1. **Bloqueante, curado.** A 1ª redação trocou o clean só pelos 14 grupos exatos. Na fase bypass da bancada do motor,
   o `git clean -xfd` (D10) RODOU e apagou o `.env` e o settings do fixture, porque o `*` de `-x*` cobria essa ordem.
   Cura: as 24 regras exatas das ordens de {f, d, x|X}, com os casos D10, E10-E13 e E40-E58.
2. **Bloqueante, curado.** Com a força dura vetada em qualquer branch, 6 casos antigos da família `pretooluse_veto`
   mediam a RESOLUÇÃO da produção com `-f` ou `+ref` (`master` não é produção quando origin/HEAD é main, gitflow
   etc.). Eles inverteriam, e os casos VETO perderiam o poder de discriminar. Cura: os casos "passa" passaram a usar
   `--force-with-lease`, que ainda separa produção de não-produção. Entraram as versões VETO com lease (pr-gfd-l,
   pr-feat-l, pr-oht-l, pr-gf-l) e o caso pr-ohn-hard.
3. **Menor, curado.** O D64 da bancada do motor (`git -C . push +feat/x`) não é push forçado. O git lê `+feat/x` como
   REPOSITÓRIO (medido: `fatal: '+feat/x' does not appear to be a git repository`, rc 128). Saiu da lista, e o hook
   ganhou o caso que passa. A forma sem `origin` passou a ser `git push upstream +feat/x` (L52).
4. **Limite.** `git -C . commit -m "push origin +main"` segue barrado por `git -* push origin +*` (C11): o `*` de `-*`
   casa tudo. O custo é menor que antes (o C12 e o C13 saíram) e fica declarado.

## Mutantes

- `lint-selftest.sh`, família `pretooluse_veto`:
  - **(dn1)** sem o bloco da força dura no hook, `FOO=1 git push origin +feat/x` passa: morre.
  - **(dn2)** com a lib tratando a lease como força dura, a lease de feature cai: morre.
- `lint-selftest.sh`, família `update_base_and_deny`:
  - **(fr1-MUT)** sem `git push origin +*`, o `+main` passa: morre.
  - **(fr1-MUT3)** com `git push* +*` de volta, o título do PR com `$(…)` cai: morre.
  - **(fr1-MUT4)** com `git clean -fdx*` de volta, o `-fdx -n` cai: morre.
  - **(fr2-MUT2)** sem a linha do `+` no `deny-retired.tsv`, a regra velha fica no adotante: morre.
- Motor real: a fase `--only mutants` tira uma regra por vez das 98 e exige que algum caso solte (nenhuma decorativa).

## Limites declarados

- A emulação do glob na família `update_base_and_deny` não tira o prefixo de ambiente. O que prova o env no deny é a
  bancada do motor (D67-D70).
- A bancada do motor mediu as fases default, bypass e mutants. As fases sandbox e flows não rodaram.
- `--force-with-lease` de branch de trabalho segue livre nas duas camadas (P01, e o caso da família `pretooluse_veto`).
  Não foi barrado aqui: o rebase e o fluxo de stack dependem dele, e ele não era barrado antes.
- `eval "git push -f …"` e `bash -c` seguem como antes: o deny não os vê (L06, L10), e o hook os julga.
