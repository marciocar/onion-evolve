# Checklist de manutenção do core

**Por que este arquivo existe, e o que ele NÃO é.** O backlog de risco vive no grafo
([`fios-abertos.kg.yaml`](graph/fios-abertos.kg.yaml)), onde o `kg-radar` ordena por peso e o gate de
frescor envelhece o que ninguém tocou. Rotina não é risco: item cujo custo é **tempo**, não **erro**,
não pode disputar atenção com item cujo custo é erro. É essa linha que impede o grafo de virar lista
de tarefas — e é por isso que ela está escrita em dois lugares (aqui e no `meta:` do grafo).

Cada item abaixo traz **como medir** — porque "está limpo?" respondido de memória é a forma de
`declarado ≠ verificado` que esta casa persegue.

---

## Branches

| o quê | como medir | estado em 2026-08-08 |
|---|---|---|
| branches remotas mergeadas não deletadas | `gh pr list --state merged --limit 60 --json headRefName -q '.[].headRefName'` cruzado com `git branch -r` | **~40** — o auto-delete no merge está **desligado**; ligá-lo dissolve o passivo e impede o próximo |
| branches locais mortas | `git branch --merged main \| grep -v main` | 3 |
| branches `discuss/*` paradas | `git for-each-ref --sort=committerdate --format='%(committerdate:short) %(refname:short)' refs/remotes/origin/discuss` | 4 paradas há ~27 dias, somando **35 commits**. Decisão do maestro: retomar ou arquivar — **não** é backlog de engenharia |

⚠️ **Antes de apagar qualquer branch:** `git cherry main <branch>` marca `+` mesmo em branch cujo PR
foi **mergeado por squash** (o SHA some no squash). Cruze com `gh pr list --state all` antes de
concluir "não aplicado". E confira a árvore: uma branch **atrás** do main mostra diff de regressão —
foi assim que a `feat/maestro-aside` apareceu como "trabalho pendente" sendo 8683 deleções atrás.

## Worktrees

`git worktree list` — e para cada um, se o branch está em `origin`. Worktree em diretório temporário
de job é **efêmero**: o commit sobrevive se o branch estiver em `origin`, o checkout não.

## `/tmp` na VPS

```bash
df -h /                                            # o número que importa
sudo du -sh /tmp/* 2>/dev/null | sort -rh | head   # quem ocupa
find /tmp -maxdepth 1 -name 'tmp.*' -type d | wc -l
```

**Medido em 2026-08-08:** disco em **26%** (287 G livres) — sem risco. `/tmp` tem 14 G, dos quais
**8,6 G são de `/tmp/claude-1000`** (o próprio Claude Code), não dos sandboxes de selftest. Dos 9.275
diretórios `tmp.*`, **6.608 estão vazios**.

**Por que o limpador nunca dispara, e é o achado desta linha:** a política é
`D /tmp 1777 root root 30d`, mas o `systemd-tmpfiles` usa o timestamp **mais recente** entre
mtime/atime/ctime. O diretório mais antigo tem `mtime=2026-07-09` e **`atime=2026-08-07`** — qualquer
varredura de `/tmp` (inclusive um `find` de diagnóstico) **rejuvenesce o atime e zera o relógio**.
O limpador roda todo dia e nunca acha nada com 30 dias.

## Higiene de sessão

- **`consumed-mode-check.sh`** — hoje **desligado** (zero consumidores) e **sem `--selftest`** (a
  linha 56 trata `$1` como raiz de repo, então a flag vira diretório inválido, exit 2). Rodado à
  mão, acha **4 modos de produção sem teste**. Não é rotina — é o item
  `I_CONSUMED_MODE_CHECK_GANHA_TESTE_E_LIGA` no grafo. Fica citado aqui só para não parecer esquecido.
- **A bancada exige corrida SOLO** (`lint-selftest.sh`, ~13 min). Duas em paralelo produzem falha
  falsa: já aconteceu, e eu li a primeira como determinística.
