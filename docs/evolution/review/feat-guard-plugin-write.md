---
branch: feat/guard-plugin-write
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: 219a8c94cb6082f49f3e9ef1ea46f6f6c94be87d4d08e7ca07dc203983d716df
reviewed_code_sha256: 071355ff80ff20c0b2db031ed50e9bded9b70842f1b0bed40444a57aba331bc2
findings_total: 29
findings_real: 29
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: refutadores independentes (3 e 5) e a sessão principal
nota: >
  Três passadas adversariais reprovaram e a cura entrou neste PR. A 1ª, da sessão principal, sobre
  aad2d62d3: 13 achados (6 altos, 7 médios). A do refutador 3, sobre a12ed5f69: 6 achados. A do
  refutador 5, sobre f6d65f57a: 10 achados. Todos são reais; 21 viraram cura e 8 viraram teto
  declarado, com caso no --selftest. A verificação do diferencial sobre 039728af3 foi feita pela
  sessão principal. tokens e duration_min ficam 0 porque não foram medidos.
---

# Veto à escrita de plugin em .claude/skills e a varredura do disco

Três passadas reprovaram, e cada achado virou cura ou teto declarado, sempre com caso na bancada.
Cada cura teve o caso reprovando ANTES dela, medido na cópia sem a cura, e passando depois.

## 1ª passada — sessão principal, sobre aad2d62d3

Foram 6 achados altos e 7 médios, todos curados sobre origin/main. Estão no nó
`E_ELENXO_REPROVOU_E_CUROU` do grafo da forja,
`docs/evolution/research/guard-plugin-write-2026-11/plugin-write-2026-11.kg.yaml`.

## Refutador 3 — sobre a12ed5f69 (cura em f6d65f57a)

| # | Achado | Destino |
|---|--------|---------|
| 1 | Redirecionamento colado à palavra anterior gravava: `echo x>f`, `ls>f`, `x>>f`, `x>\|f`, `x>&f`, `"x">f`, `cat>f <<E`, `~`, `.claude-plugin`, `cd x;echo x>hooks`, `F=…;echo x>"$F"`, `bash -c 'echo x>f'` | cura: `_pw_unglue`, que sabe de aspas, `$'…'`, barra invertida e crase; `a1>f` também foi curado |
| 2 | O `--selftest` reprovava fora de uma raiz git, no caso do JSON truncado | cura: o `_raw` roda na pasta do projeto, e a família roda de fora de git |
| 3 | `> x` nu depois de `case …)`, `time` e `coproc` | cura: `_PW_BARE_AFTER_CLOSE`, que também cura `( ) >`, `{ } >`, `done >`, `fi >` e `esac >`, antes no teto |
| 4 | Chaves de sequência (`{h..h}ooks`) | cura: a sequência expande com teto de 256 palavras, e a chave literal não para mais a palavra |
| 5 | `.git` como link quebrado: o Write passava e o Bash barrava | cura: `[ -L "$1/.git" ]` |
| 6 | Write com JSON truncado sai rc 0 | teto declarado, com caso |

A 1ª rodada da família deixou 2 mutantes vivos. J33e nomeava um caso que não dependia da cura e
foi trocado pelo da aspa escapada. J33f mostrou um ramo redundante, que foi removido.

## Refutador 5 — sobre f6d65f57a (cura em 039728af3)

| # | Achado | Destino |
|---|--------|---------|
| 1 | Composto com entrada antes do `>`: `done < a > f`, `{ cat; } < a > f`, `( ) </dev/null >f`, `select … done </dev/null > f` | cura: os lookaheads aceitam `\d*[<>]`, o que cura também `< a > f` nu |
| 2 | `curl -so`, `-fsSLo`, `-o<caminho>`, `wget -qO` | cura: o grupo de opções curtas se lê até a letra que consome valor |
| 3 | `$'\x68ooks'` e `$"hooks"` | cura: o pré-filtro deixa passar o `$'` e o `$"…"` é lido como texto |
| 4 | `mkfifo` | cura: `mkfifo` e `mknod` na forma |
| 5 | `exec >` e `exec 1>` | cura: `exec` na lista do fecho, o que cura também `exec 3>`, antes no teto |
| 6 | `--selftest` por caminho relativo dava rc 127 | cura: o caminho absoluto do hook, mais a checagem (a1b) na família |
| 7 | `tar -c`/`--create` com o arquivo na forma | teto declarado, com caso |
| 8 | `git -C … init` na forma | teto declarado, com caso |
| 9 | Sobreacusa: `tee … <<< "…/hooks"` | teto declarado, com caso SOBREACUSA |
| 10 | Sobreacusa: `{hooks\,y}` (o shlex come a barra antes do juiz) | teto declarado, com caso SOBREACUSA |

## Verificação do diferencial — sessão principal, sobre 039728af3

O harness do refutador 5 rodou sobre `git archive 039728af3`. Os 10 furos que ele chamou de
BLOQUEIA barram com rc 2: os 4 compostos com `<`, os 3 de curl, o `wget -qO`, `$'\x68ooks'` e
`$"hooks"`. Os 4 controles honestos (git status, echo para docs/, while para docs/, curl para /tmp)
passam com rc 0 e não gravam.

## Bancada no último commit da cura

- Família `plugin_write_guard`: rc 0. Cópia limpa com 223 acusa, 180 cala e 35 teto. 230 mutantes
  mordem e nenhum ficou vivo.
- `lint-artifacts.sh`: rc 0, 0 HARD.
