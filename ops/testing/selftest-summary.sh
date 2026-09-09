#!/usr/bin/env bash
# =============================================================================
# selftest-summary.sh — a saída da bancada vira EVIDÊNCIA legível no CI (ONDA 0.4)
#
# Uso : bash ops/testing/selftest-summary.sh --report <ABS.tsv> [--titulo T] [--run-url URL]
#       → markdown no stdout, para `>> "$GITHUB_STEP_SUMMARY"`
#
# POR QUE UM SCRIPT E NÃO SHELL DENTRO DO YAML
#   Shell embutido em workflow é a única peça do gate que NENHUMA guarda exercita: não roda
#   local, não entra na bancada, e só se descobre que quebrou quando o job que deveria explicar
#   a falha aparece vazio — justo no dia em que alguém precisa dele. Como script, ele ganha
#   família na bancada e a REGRA 59 (Modo que a produção consome é exercitado pela bancada)
#   passa a vigiar a flag com que o workflow o chama.
#
# ELE REPORTA, NÃO JULGA — e a fronteira é deliberada
#   O veredito é do passo da bancada; este gerador nunca reprova um build. Um sumário que
#   também julgasse criaria dois juízes para o mesmo fato, e o dia em que discordassem
#   ninguém saberia qual acreditar. Ele sai 0 sempre que conseguiu dizer a VERDADE — inclusive
#   quando a verdade é "não foi medido".
#
# O TERCEIRO DESFECHO, QUE É A RAZÃO DE ELE EXISTIR
#   Relatório ausente ou sem linha `TOTAL` é a assinatura da bancada que MORREU antes da soma
#   (worker morto, OOM, SIGPIPE — os três já medidos nesta casa). Nesse caso ele imprime
#   `⊘ NÃO MEDIDO` e NOMEIA a suspeita. Nunca zeros: um sumário com `0 falhas` sobre uma
#   bancada que abortou é exatamente o painel inventado que esta onda apagou, agora no CI.
# =============================================================================
set -euo pipefail

REPORT=""; TITULO="Auto-teste das guardas"; RUN_URL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --report)   shift; REPORT="${1:-}" ;;
    --report=*) REPORT="${1#*=}" ;;
    --titulo)   shift; TITULO="${1:-}" ;;
    --titulo=*) TITULO="${1#*=}" ;;
    --run-url)  shift; RUN_URL="${1:-}" ;;
    --run-url=*) RUN_URL="${1#*=}" ;;
    *) echo "selftest-summary: arg desconhecido: $1 (use --report <ABS.tsv> [--titulo] [--run-url])" >&2; exit 2 ;;
  esac
  shift
done

[ -n "${REPORT}" ] || { echo "selftest-summary: --report <ABS.tsv> é obrigatório" >&2; exit 2; }

_nao_medido() {   # $1 = a suspeita, nomeada
  printf '## ⊘ %s — NÃO MEDIDO\n\n' "${TITULO}"
  printf '**Não há relatório para somar.** Isto NÃO é "zero falhas": é ausência de medição.\n\n'
  printf -- '- causa provável: %s\n' "$1"
  printf -- '- relatório esperado em: `%s`\n' "${REPORT}"
  printf -- '- a bancada morrer antes da soma já foi medido aqui três vezes (worker morto por memória, SIGPIPE, aborto de faixa)\n'
  [ -n "${RUN_URL}" ] && printf -- '- run: %s\n' "${RUN_URL}"
  printf '\n> Um sumário que imprimisse `0 falhas` aqui seria o painel inventado, agora no CI.\n'
}

if [ ! -f "${REPORT}" ]; then
  _nao_medido "o arquivo de relatório não existe — a bancada não chegou a escrevê-lo"
  exit 0
fi
if ! grep -qP '^TOTAL\t' "${REPORT}"; then
  _nao_medido "o relatório existe mas NÃO tem linha \`TOTAL\` — a bancada abortou antes da soma"
  exit 0
fi

awk -F'\t' -v titulo="${TITULO}" -v runurl="${RUN_URL}" '
  $1 == "familia" { next }
  $1 == "TOTAL"   { tp=$2; tf=$3; ts=$4; tsec=$5; next }
  NF >= 5 {
    linhas++; fam[$1]=1
    if ($3+0 > 0) { falhas[$1] += $3 }
    if ($4+0 > 0) { skips[$1]  += $4 }
    if ($5+0 > lenta_seg) { lenta_seg=$5+0; lenta=$1 }
  }
  END {
    nfam = 0; for (k in fam) nfam++
    icone = (tf+0 > 0) ? "❌" : (ts+0 > 0 ? "⚠️" : "✅")
    printf "## %s %s\n\n", icone, titulo
    printf "| passaram | falharam | pularam | famílias | linhas | segundos |\n"
    printf "|---------:|---------:|--------:|---------:|-------:|---------:|\n"
    printf "| **%d** | **%d** | **%d** | %d | %d | %d |\n\n", tp, tf, ts, nfam, linhas, tsec

    if (tf+0 > 0) {
      printf "### Famílias que falharam\n\n"
      for (k in falhas) printf "- `%s` — %d falha(s)\n", k, falhas[k]
      printf "\n"
    }
    if (ts+0 > 0) {
      printf "### Famílias com ⊘ (guarda NÃO exercida — no CI isto reprova sob STRICT)\n\n"
      for (k in skips) printf "- `%s` — %d ⊘\n", k, skips[k]
      printf "\n"
    }
    if (tf+0 == 0 && ts+0 == 0) printf "Nenhuma família falhou ou pulou.\n\n"
    if (lenta != "") printf "Família mais lenta: `%s` (%ds).\n\n", lenta, lenta_seg
    printf "<sub>Gerado por `ops/testing/selftest-summary.sh` a partir do `--report` da bancada — "
    printf "nenhum número aqui foi digitado.</sub>\n"
    if (runurl != "") printf "\n<sub>run: %s</sub>\n", runurl
  }
' "${REPORT}"

# A SOMA FECHA? Verificação FORA do awk, para poder falar alto sem poluir o markdown.
_soma="$(awk -F'\t' '$1!="familia" && $1!="TOTAL" && NF>=5 {s+=$2} END{print s+0}' "${REPORT}")"
_total="$(awk -F'\t' '$1=="TOTAL"{print $2+0}' "${REPORT}")"
if [ "${_soma}" != "${_total}" ]; then
  printf '\n> ⚠️ **A SOMA NÃO FECHA**: as famílias somam %s e o TOTAL diz %s. O relatório está\n' "${_soma}" "${_total}"
  printf '> truncado ou o agregador da bancada regrediu — trate o número acima como suspeito.\n'
fi
