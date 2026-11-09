#!/usr/bin/env bash
# deny-retired-list.sh <arquivo> — lê a lista de regras aposentadas e imprime uma regra válida por linha.
# Linha válida: 3 colunas separadas por TAB (regra, data, motivo), regra na forma Ferramenta(padrão), sem CR. Linha com # na
# coluna 1 é comentário. O resto é ignorado com AVISO no stderr: uma linha malformada não retira nada e não passa em silêncio.
# rc sempre 0: lista ausente, pasta ou ilegível vira lista vazia com AVISO, para o merge seguir e os hooks chegarem.
# Consumido por merge-onion-hooks.sh e deny-monotonic.sh.
F="${1:-}"
if [ ! -f "${F}" ] || ! { : < "${F}"; } 2>/dev/null; then
  echo "AVISO: lista de regras aposentadas ausente ou ilegível (${F}) — nada foi retirado." >&2
  exit 0
fi
awk -F'\t' '
  /^#/ || /^$/ { next }
  /\r$/ || NF != 3 || $1 !~ /^[A-Za-z]+\(.+\)$/ || $2 == "" || $3 == "" {
    printf "AVISO: linha %d da lista de regras aposentadas está malformada e foi ignorada.\n", NR > "/dev/stderr"; next
  }
  { print $1 }' "${F}"
exit 0
