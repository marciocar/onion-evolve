---
branch: fix/exit-code-pipe-false-positive
date: 2026-10-11
reviewed_diff_sha256: ed4b45096912bf8e8c3e06bdb641163ff1397d2054a89569958938b811cbc988
reviewed_code_sha256: 3a706d0e2d8085ffa066d9535a0edee7ac65675258173aaf221a6ed112729286
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada própria + 2 mutantes executados (sem subagente) — gate mecânico: empty_result_guard
---

# A guarda gritava `$?` de pipe quando o `$?` era de outra instrução

## Defeito medido

Três falsos positivos de `EXIT-CODE-DE-PIPE` numa só sessão, em 2026-10-11. Os três tinham a mesma
forma: `a | head; b >/dev/null 2>&1; echo rc=$?`. O `$?` é do `b`, mas o predicado perguntava se
havia algum `|` antes do último `$?` na linha. É a 5ª classe de falso-positivo da guarda. Guarda que
grita errado ensina a sessão a ignorá-la (lente da guarda, item 4).

## Achados

1. **O predicado olhava a linha, não a instrução.** Agora a linha se parte em instruções (`;`, `&&`,
   `||`, sobre o texto sem aspas), e cada `$?` olha só a instrução imediatamente anterior, na própria
   linha ou na última da linha de cima. Continua valendo "algum `$?`", não só o último (caso s).
   O `$?` entre aspas duplas sobrevive à remoção de aspas, porque `echo "rc=$?"` lê o exit.
2. **O caso (o) da bancada carregava a expectativa errada.** Ele terminava em `echo "don't"; echo $?`,
   em que o `$?` é do `echo`. Foi reescrito com o `$?` logo após o pipe, e o propósito (aspa dentro de
   aspa) se mantém.

## Mutantes

- **Predicado antigo (o arquivo de main):** o (o2) reprova.
- **`antes = prevLast`**, que ignora a instrução anterior da mesma linha: 7 casos reprovam.

## O que NÃO cobre

- **Subshell e grupo** (`( a | b ); echo $?`): o parêntese não separa instrução aqui. Nesses casos a
  guarda segue gritando, ou seja, erra para o lado de falar.
