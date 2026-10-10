---
reviewed_diff_sha256: ab60073988ab0b938e02ad9bba35d7e7703d9580132f47f22bfe145409874837
reviewed_code_sha256: 15d64122cc89aa82ea31e0bf9ee0218b8472142f729bd1296994a4213bc2a2ef
findings_total: 2
findings_real: 0
tokens: 86493
duration_min: 2
verdict: APROVADO
elenxo: sim
nota: >
  O refutador opus foi instruído a achar veredito mudado, regressão escondida no baseline, mutante
  que não morde e sobras da classe nos motores, e APROVOU. Ele rodou um harness sob pipefail com três
  destinos (com plugins, sem plugins, caminho inexistente) e o veredito saiu igual na forma antiga e na
  nova. O mutante (tirar ops do for) reprova o caso (d). As duas observações dele são de severidade
  baixa e ficaram declaradas.
---

# Resíduo — `fix/publish-door-pipe-verdict`

O 1º ensaio da F6 (2026-10-10) recusou o onion-plugins com "destino não reconhecido", e os
`provenance.json` estavam lá. A causa foi `git ls-tree | grep -q` sob pipefail. A guarda
`pipe-verdict-check` não via o sítio porque não varria `ops/`. Depois da cura, o ensaio saiu com
rc 0, 6 plugins, `validate --strict` e 0 HARD no bundle.

| # | achado | desfecho |
|---|---|---|
| 1 | `pipe-verdict-check.sh` sobe de 2 para 3 no baseline | não é sítio: é a fixture do caso (d), dentro de um `printf` |
| 2 | sobras da classe early-closer no `publish-door.sh` (l.188 `ls-tree \| grep -m1 … \|\| true`, `head` em mensagem) | **teto declarado**: nenhuma está em posição de veredito por código de saída, e o valor capturado se mantém sem `set -e` |

Também foi selado aqui o lote da F5 em `door-role-parity-2026-09.kg.yaml` (`--seal`), que tinha
entrado na main pendente.
