#!/usr/bin/env bash
# Hook UserPromptSubmit do «PODE RODAR» (autorização de um toque, nível 1) — Onion.
#
# DEFEITO DATADO (2026-11-18): o ato que só o maestro roda (o merge de PR que toca a própria catraca) exigia que ele
# copiasse o comando para o terminal dele. Ele aprovou o desenho no mesmo dia: dizer «pode rodar» no prompt da sessão
# e o ato preparado rodar ali, com NÍVEL por ato («isso pode virar até 2fa no futuro»).
#
# O que faz: quando o prompt é EXATAMENTE a frase (aparadas as bordas) e a sessão tem um pedido pendente, grava a
# aprovação (hash do pedido, TTL de 10 min, uso único conferido pelo executor). Mensagem com moldura de outra sessão
# ou de sistema, ou a frase dentro de texto maior, NÃO autoriza, e o hook diz isso em uma linha. Sem a frase: silêncio.
# NUNCA bloqueia o prompt (exit 0 sempre) e NÃO usa "ask" (relatado como auto-aprovado em bypassPermissions).
# Falha FECHADA: sem python3, sem payload legível ou com qualquer erro, não autoriza.
#
# TETO (honestidade): camada de CONFORMIDADE, não fronteira de segurança — no mesmo usuário Unix o agente pode forjar o
# arquivo de aprovação. O hook não vê a entrada do transcript da mensagem atual (o harness a grava depois do hook,
# medido em 2026-11-18); quem confere origin.kind=human no transcript é o executor, na hora do ato.
# Motor e esquema: .claude/utils/approval/ (one_touch.py, act-request.schema.json, README.md).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="${HERE}/../utils/approval/one_touch.py"
[ -f "${ENGINE}" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
python3 -I "${ENGINE}" hook 2>/dev/null
exit 0
