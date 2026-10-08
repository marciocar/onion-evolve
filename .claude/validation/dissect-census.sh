#!/usr/bin/env bash
# ===========================================================================
# dissect-census.sh — censo das DISSECAÇÕES de ferramenta já pagas pelo corpus.
#
# É o MEDIDOR da peça 3 (contexto medido injetado) do `/meta:dissect`: a saída daqui é o que a
# sessão lê ANTES de abrir qualquer fonte externa. Responde por MEDIÇÃO a pergunta que o modelo
# responde de memória e erra — "já dissecamos esta ferramenta? até que nível? quando?".
#
# ── POR QUE EXISTE (defeito medido, 2026-10-01) ────────────────────────────────────────────
# Numa única rodada de pesquisa a casa (a) re-abriu Zep, Port e Roadie sem ler o que o corpus já
# dizia e (b) registrou "a Onyx não entrega grafo" como achado, quando a doc do próprio
# fornecedor diz `AI-generated knowledge graphs` e o módulo `backend/onyx/kg` está vivo no
# código. Nível 0 repagado é o desperdício; nível 2 errado por folheto é o defeito.
#
# ── DESCOBERTA POR REFERÊNCIA, NUNCA POR NOME CONSTRUÍDO ───────────────────────────────────
# Mesma cláusula 1 que rege o forge-census.sh, e pela mesma razão: construir o caminho/nome do
# artefato a partir do nome do candidato errou 3 vezes em 2026-09-28. Aqui a dissecação se
# ANUNCIA — o grafo carrega `x_dissect_tool:` no meta e `x_dissect_level:`/`x_dissect_verdict:` (contrato v4: extensão leva `x_`; a forma sem prefixo segue lida em grafo herdado) nos
# nós, e o censo LÊ esses marcadores. Grafo que fala de uma ferramenta sem se declarar
# dissecação é invisível a este censo, e isso é verdade útil: a sessão também não o acharia.
#
# ── FRONTEIRA DECLARADA ────────────────────────────────────────────────────────────────────
# Mede o que o corpus DECLARA. Não sabe de ferramenta que ninguém anotou, não julga qualidade
# da dissecação, e não confere se a medição do nível de fato ocorreu (o marcador é
# auto-atestado — mesmo teto honesto do kg-seal-exception.sh).
#
# Uso:  bash .claude/validation/dissect-census.sh [<repo>] [--markdown|--tsv]
# Exit: 0 = censo emitido (inclusive "zero dissecação", que é resposta) · 3 = NÃO PUDE MEDIR.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_dissect_selftests).
# ===========================================================================
set -uo pipefail

REPO="${1:-}"; FMT="${2:---markdown}"
case "${REPO}" in --*) FMT="${REPO}"; REPO="" ;; esac
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "dissect-census: alvo inexistente: ${REPO}" >&2; exit 3; }

# FAIL-CLOSED no índice: o censo é do conjunto RASTREADO (o que viaja e o que o CI vê). Sem
# índice, "nenhuma dissecação" seria falso e caríssimo — zero NÃO é resultado quando a causa é
# não ter podido olhar. É a lição do exit-code-nao-e-a-verificacao.
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "dissect-census: sem índice git em ${REPO} — o censo seria de outro conjunto que o do CI. Recusa." >&2; exit 3; }

mapfile -t GRAPHS < <(git -C "${REPO}" ls-files -- '*.kg.yaml' 2>/dev/null | sort -u)
[ "${#GRAPHS[@]}" -gt 0 ] \
  || { echo "dissect-census: nenhum .kg.yaml RASTREADO em ${REPO} — sem corpus não há censo a emitir. Recusa." >&2; exit 3; }

TODAY="$(date +%F)"

# ── Leitura de UM grafo ────────────────────────────────────────────────────────────────────
# Os marcadores são lidos com grep ancorado e o resultado DRENADO: nenhum fechador precoce
# (`grep -q`/`head`) a jusante de escritor grande, que sob `set -o pipefail` devolve 141 e faz
# a peça existente contar como ausente — classe pipefail-epipe-early-closer, curada aqui por
# construção (laços que leem até o fim).
rows=""; parked=""; found=0
for rel in "${GRAPHS[@]}"; do
  f="${REPO}/${rel}"
  [ -f "${f}" ] || continue

  tool="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_tool:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\2/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "${tool}" ] || continue
  found=$((found + 1))

  # NÍVEL ALCANÇADO = o MAIOR nível declarado em qualquer nó. Maior, não último: a ordem no
  # arquivo não é a ordem da escada, e confiar nela seria ler a projeção como fonte.
  level=0
  while IFS= read -r lv; do
    case "${lv}" in ''|*[!0-9]*) continue ;; esac
    [ "${lv}" -gt "${level}" ] && level="${lv}"
  done < <(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_level:[[:space:]]*\([0-9]\+\).*/\2/p' "${f}")

  verdict="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_verdict:[[:space:]]*["'"'"']\{0,1\}\([a-z]*\).*/\2/p' "${f}" | head -1)"
  [ -n "${verdict}" ] || verdict="-"
  baseline="$(sed -n 's/^[[:space:]]*baseline:[[:space:]]*\([0-9-]\{10\}\).*/\1/p' "${f}" | head -1)"
  [ -n "${baseline}" ] || baseline="-"
  review="$(sed -n 's/^[[:space:]]*review_after:[[:space:]]*\([0-9-]\{10\}\).*/\1/p' "${f}" | head -1)"
  [ -n "${review}" ] || review="-"

  # FRESCOR: comparação lexical de ISO-8601 é correta e dispensa `date -d` (que difere entre
  # GNU e BSD). Sem `review_after` a resposta é NAO-DECLARADO, nunca "fresco" por omissão.
  if [ "${review}" = "-" ]; then fresh="NAO-DECLARADO"
  elif [ "${review}" \< "${TODAY}" ]; then fresh="VENCIDO"
  else fresh="fresco"; fi

  rows="${rows}${tool}	${level}	${verdict}	${baseline}	${review}	${fresh}	${rel}
"
  [ "${verdict}" = "parquear" ] && parked="${parked}${tool}	${rel}
"
done

sorted_rows="$(printf '%s' "${rows}" | sort -t'	' -k2,2nr -k1,1)"

if [ "${FMT}" = "--tsv" ]; then
  printf 'ferramenta\tnivel\tveredito\tbaseline\treview_after\tfrescor\tgrafo\n'
  [ "${found}" -gt 0 ] && printf '%s\n' "${sorted_rows}"
  exit 0
fi

# ── Markdown: a projeção que entra na superfície como contexto injetado ────────────────────
printf '# censo de dissecações · %s grafo(s) rastreado(s) · %s dissecação(ões) declarada(s)\n' \
  "${#GRAPHS[@]}" "${found}"
if [ "${found}" -eq 0 ]; then
  printf '\nNenhum grafo do corpus se declara dissecação (marcador `x_dissect_tool:` no `meta:`).\n'
  printf 'Toda ferramenta entra pelo N0 — não há nível pago a reusar.\n'
else
  printf 'ferramenta | nível | veredito | baseline | review_after | frescor\n'
  printf '%s\n' "${sorted_rows}" | awk -F'\t' 'NF>=6 && $1!=""{
    printf "%s | N%s | %s | %s | %s | %s\n", $1, $2, $3, $4, $5, $6 }'
  if [ -n "${parked}" ]; then
    printf '\n## parqueadas (técnica a investigar — exigem gatilho nomeado)\n'
    printf '%s' "${parked}" | awk -F'\t' '$1!=""{ printf "- %s  (%s)\n", $1, $2 }'
  fi
fi
printf '\n(ferramenta com nível fresco ENTRA no nível seguinte — re-derivar nível pago é o\n'
printf 'desperdício que este censo corta. VENCIDO não se cita como se fosse de hoje: licença,\n'
printf 'mantenedor e preço mudam em semanas. TETO DECLARADO: o censo mede o que o corpus\n'
printf 'DECLARA, não sabe de ferramenta que ninguém anotou, e não confere se a medição do nível\n'
printf 'de fato ocorreu — o marcador é auto-atestado.)\n'
