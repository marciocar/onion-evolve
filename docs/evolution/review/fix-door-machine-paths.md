---
branch: fix/door-machine-paths
date: 2026-10-13
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: família moat_gate 109/0 com LC_ALL=C e git grep nas raízes que viajam
---

# A superfície que viaja deixa de levar caminho de máquina, e as portas voltam a publicar

## O que aconteceu

O ensaio de `/meta:publish --all` (2026-10-13, fonte `e5e9a265`) reprovou três portas (standalone, core e
plugins) no passo (5a), VAZAMENTO no bundle: caminhos de máquina da VPS em `.claude/hooks/pretooluse-moat-gate.sh`
(comentário), `.claude/hooks/lib/moat-judge.py` (comentário) e `.claude/validation/lint-selftest.sh`
(fixture da família `moat_gate`), todos vindos do PR #1077. Nenhum segredo: só o caminho da casa da VPS.
O mini passou (allowlist).

## A cura

- Os dois comentários ficam genéricos.
- A família `moat_gate` gera a fixture da tabela de alvos com a raiz de casa trocada por uma FICTÍCIA
  (`/srv/vps-home`), por `sed` sobre a cópia de `ops/moat-targets.tsv`, e os casos citam a mesma raiz. O
  dado continua sendo o SUT: os alvos são os de produção, só com a raiz de casa reescrita.
- `git grep` pelo caminho de casa nas raízes de `vendor-manifest.sh --emit-scrub-roots`: zero.

## Passada adversarial

1. **A cura matou o que a bancada provava?** A 1ª versão da troca reescreveu também a própria expressão do
   `sed` (`s#X#X#`), a fixture ficou com os caminhos reais e os casos (d7), (d8), (d20) e (f4) caíram, com o
   mutante acusando FIXTURE MORTA. Real, curado: o `sed` casa `/home/<usuário>/` genérico. Depois: 109/0.
2. **Por que o lint do PR #1077 não pegou?** Nenhuma guarda do lint varre caminho de máquina nas raízes que
   viajam; só o motor de publicação (5a) faz isso, no fim. Declarado como achado: a classe merece guarda no
   lint, para quebrar no PR e não na publicação.
