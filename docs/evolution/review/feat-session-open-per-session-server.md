---
branch: feat/session-open-per-session-server
pr: 1744
date: 2026-11-22
reviewed_diff_sha256: 0048229bcd095f67f4b73679b7d44d60dc0b0cbe6ca62ce815b7bc4036404736
reviewed_code_sha256: fb3dfa32474d956ba4df7eb4acd39c81b38268e39560b63b99fd983645e2bef3
findings_total: 11
findings_real: 10
findings_blocking: 1
tokens: 0
duration_min: 15
findings_fixed: 5
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: self
nota: "passada da própria sessão, sem subagente (cota semanal de agentes esgotada até 24/11 21:00 UTC); tokens não medidos"
---

# Passada adversarial: `feat/session-open-per-session-server`

## O que muda

- `ops/session-open.sh` cria cada sessão no **próprio servidor tmux** (`tmux -L <nome>`). Em 2026-11-22 o servidor único
  (`default`) caiu e levou as cinco sessões de uma vez. A sessão legada, aberta no `default` antes da mudança, ainda é
  achada e anexada lá, nunca duplicada. O caminho de entrar (`attach_hint`) diz o servidor certo, e o `--list` mostra
  em que servidor cada uma está.
- `ops/session-boot.sh` (novo): `plan|install|status|remove` da unidade do systemd do usuário `onion-sessions.service`,
  que roda `session-open.sh --all` no boot. Só no boot, por desenho: um timer reabriria a sessão que o maestro fechou
  com /exit.
- Bancada `session_open`: o tmux de mentira passa a distinguir servidor (`-L` → `SO_TSESS_L`, sem → `SO_TSESS`);
  casos novos (b2) servidor próprio e (b3) legado no default, com mutante que derruba cada um.

## Achados

| # | achado | real? | destino |
|---|---|---|---|
| 1 | O mutante do (b2) sobrevivia: em `--dry-run` o `new-session` não chega ao log do tmux de mentira, e o caminho de criação também imprime o `-L` | sim | Corrigido: o caso exige a frase «já existe» e a ausência de `new-session` na SAÍDA do ensaio; o mutante agora cai |
| 2 | Dentro de um tmux, `switch-client` não alcança sessão de outro servidor | sim | Corrigido: dentro de tmux o abridor diz para sair (Ctrl-b d) e dá o comando com `-L`, em vez de tentar trocar |
| 3 | `tmux ls` deixa de mostrar as sessões novas (cada uma noutro servidor) | sim | Limite declarado: o `session-open.sh --list` é a lista; a mensagem de recusa que citava `tmux ls` passou a citar o `--list` |
| 4 | A unidade de boot poderia abrir o core e duplicar a sessão que roda o abridor | não | O `--all` deixa o core fora por desenho (cabeçalho do abridor); a unidade só chama o `--all` |

## Mutantes

- Família `session_open`: 85 casos verdes, cada um com o seu mutante derrubado (`lint-selftest.sh --families session_open`, rc 0).
- Medido contra o estado real da VPS: `--list` acha as 4 sessões reabertas hoje no servidor `default` (legado) e as 2
  fora do tmux, sem criar nada.

## Limites declarados

- `session-boot.sh` não tem bancada própria: ele só escreve a unidade e chama o `systemctl --user`; o `plan` é o ensaio.
- O `baton-pulse.sh` ainda sugere `tmux new -s` na cura de `SESSION_NOT_IN_TMUX`, como forma sem o abridor; a forma
  principal da mesma linha é o `session-open.sh`, que agora cria com `-L`.

## Revisão isolada (2026-11-23)

Subagente general-purpose (opus), isolado, mandato REFUTAR. Veredito: **FIXES_NEEDED**, um bloqueio medido; curado. A
família `session_open` passou nele (84 casos) e de novo depois das curas.

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 5 | Unit oneshot: um `--all` com rc 3/5 (sessão ambígua ou claude já vivo) falha a unit e o systemd 255 mata o cgroup, com todos os servidores tmux recém-abertos (reproduzido com `systemd-run --user`) | sim, medido | **sim** | Curado: `KillMode=process` e `SuccessExitStatus=3 5` |
| 6 | Mesmo com sucesso, `stop`/`remove` da unit derrubaria as sessões | sim | não | Curado pelo `KillMode=process` |
| 7 | O `install` gravava o caminho da worktree que o rodou; removida a worktree, o boot quebra | sim | não | Curado: grava o caminho do checkout principal (git-common-dir) |
| 8 | `valid_name` aceitava `.`, que o tmux grava como `_` (o `has-session` não acharia) | sim, latente | não | Curado: `.` fora do nome |
| 9 | Os casos rodam em `--dry-run`: um mutante que tire o `-L` só da linha real passa | sim | não | Declarado; caso sem dry-run com tmux de mentira fica para outro PR |
| 10 | Sem selftest do `session-boot.sh` (plan/install/status/remove) | sim | não | Declarado; família própria com `SESSION_BOOT_SYSTEMCTL` de mentira fica para outro PR |
| 11 | De dentro de um tmux, o abridor perde o `switch-client` | sim, declarado | não | Aceito: instrui a sair e anexar |
