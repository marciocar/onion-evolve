# Etapa R da parte em papel

Rodada pelo condutor em 2026-11-05, antes de (d), por `hook_exec.py --etapa-r`. Worktree descartável em `origin/main` = `3f09996ab372bc3d79743f792cbe729349f12a36`, ramo de tópico novo `topic/paper-problem-route-hooks`, fora do repo. O comando não executa: vai ao hook como JSON em stdin. Os alvos reais (unidade sem script, caminho servido, script de deploy, clone de membro) foram lidos na hora do tsv e do `members.yaml` da worktree, e ficam fora daqui: só o rc entra.

**Ambiente (`env -i`):** `PATH=<venv do core>:/usr/local/bin:/usr/bin:/bin`, `HOME` real, `LANG=C.UTF-8` (o da sessão do condutor), `TMPDIR=/tmp`, `CLAUDE_PROJECT_DIR=<a worktree descartável>`.

**sha256 dos hooks:**

| Hook | sha256 |
|---|---|
| `pretooluse-env-guard.sh` | `fdd0196ecb236eaa990fa4068ef1852a45676bcd6296b052b79fd9ae9c2b3e60` |
| `pretooluse-protect-main.sh` | `8c247104f01dce81bba08aff85531915f7577ebca4aa155c5dfd4fc616f1ee14` |
| `pretooluse-merge-gate.sh` | `16d636b7be5390e0de8aaa37fc3ee85f608cf11d0b37c0059ec4487ac2ebeb2b` |
| `pretooluse-moat-gate.sh` | `c7e3004f7bc2b10f003eee226ac083188409c45007f5da0a2a91d818a6ff4dc3` |

**Resultado: 17 chamadas (16 linhas, V9 em Bash e em Read), 0 divergência do esperado, 0 rc fora de {0, 2}.** Nenhuma forma V deu rc 0, então nenhuma forma sai de `C`.

rc por hook, na ordem env-guard, protect-main, merge-gate, moat-gate (Read só vai ao env-guard):

| Id | esperado | obtido | diverge | rc por hook |
|---|---|---|---|---|
| V1 | 2 | 2 | não | 0,2,2,0 |
| V2 | 2 | 2 | não | 0,0,2,0 |
| V3 | 2 | 2 | não | 0,0,2,0 |
| V4 | 2 | 2 | não | 0,0,0,2 |
| V5 | 2 | 2 | não | 0,0,0,2 |
| V6 | 2 | 2 | não | 0,0,0,2 |
| V7 | 2 | 2 | não | 0,0,0,2 |
| V8 | 2 | 2 | não | 0,0,0,2 |
| V9-bash | 2 | 2 | não | 2,0,0,0 |
| V9-read | 2 | 2 | não | 2 |
| P1 | 0 | 0 | não | 0,0,0,0 |
| P2 | 0 | 0 | não | 0,0,0,0 |
| P3 | 0 | 0 | não | 0,0,0,0 |
| P4 | 0 | 0 | não | 0,0,0,0 |
| P5 | 0 | 0 | não | 0,0,0,0 |
| P6 | 0 | 0 | não | 0,0,0,0 |
| P7 | 0 | 0 | não | 0,0,0,0 |
