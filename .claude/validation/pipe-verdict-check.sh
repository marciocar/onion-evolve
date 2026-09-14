#!/usr/bin/env bash
# =============================================================================
# pipe-verdict-check.sh — a CLASSE "veredito por <produtor>|grep -q"
#
# POR QUÊ : `<produtor> | grep -q PADRÃO` em posição de VEREDITO é corrida. O leitor fecha o stdin no
#           1º match, o escritor toma EPIPE, e sob `set -o pipefail` o pipeline devolve FALHA com o
#           padrão PRESENTE. Medido em 2026-09-04 (12 processos × 40 tentativas, 145 KB de saída →
#           4 a 18 falhas por processo; ZERO em série) e novamente em 2026-09-05: bancada local
#           1054/0 contra 1 falha no CI de 2 cores.
#           A guarda nasceu vendo só `_emit "…" | grep -q`; ampliada para a CLASSE (qualquer
#           produtor) achou 94 sítios pré-existentes em 23 arquivos — daí a CATRACA.
#
# CURA de cada sítio: conteúdo numa variável + `grep -q PAD <<< "$var"` (0 falhas em 480).
#
# USO     : pipe-verdict-check.sh [ROOT]            → <arquivo><TAB><nº de sítios> (1/linha)
#           pipe-verdict-check.sh --emit-baseline   → o mesmo, com o cabeçalho do baseline
#             (destino: .claude/validation/pipe-verdict-baseline.txt — e o NOME tem de aparecer aqui,
#              porque o regen-baselines.sh resolve o emissor por "aceita --emit-baseline E menciona o
#              baseline"; sem a menção o adotante mantém o baseline COMO VEIO DO CORE)
#                                                     (é o contrato que o regen-baselines.sh resolve,
#                                                      para o ADOTANTE regenerar do corpus DELE em vez
#                                                      de herdar o passivo do core)
#           pipe-verdict-check.sh --selftest
# =============================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="${1:-scan}"
case "${MODE}" in --emit-baseline|--selftest|scan) : ;; -*) echo "uso: pipe-verdict-check.sh [ROOT|--emit-baseline|--selftest]" >&2; exit 2 ;;
  *) [ -d "${MODE}" ] && { ROOT="$(cd "${MODE}" && pwd)"; MODE=scan; } || { echo "uso: pipe-verdict-check.sh [ROOT|--emit-baseline|--selftest]" >&2; exit 2; } ;;
esac

_scan() {  # $1=root · <arquivo><TAB><contagem>, relativo ao root
  local r="$1" dirs=() d
  for d in .claude/validation .claude/utils .claude/hooks .githooks; do [ -d "${r}/${d}" ] && dirs+=("${r}/${d}"); done
  [ "${#dirs[@]}" -gt 0 ] || return 0
  local hits
  # ⚠️ O PRODUTOR NÃO É MAIS UMA LISTA — e a troca foi paga com dois defeitos no mesmo dia.
  # A forma anterior enumerava `_emit|grep|awk|sed|cat|printf`, e em 2026-09-14 a classe mordeu
  # DUAS VEZES por produtores que não estavam na lista:
  #   · `git ls-files -- "$g" | grep -q .`        (lint-artifacts.sh) — acusou REGRA VIVA de morta
  #     no CI, sobre arquivo que ninguém tocou. 139 caminhos, 10 KB: o grep casa e sai, o git leva
  #     EPIPE, o pipefail propaga.
  #   · `bash vendor-manifest.sh --emit-scrub-roots | grep -qx '.claude/workflows'` (lint-selftest.sh)
  #     — `.claude/workflows` é a 8ª de 11 linhas, então sobram 3 para o SIGPIPE. A guarda acusou o
  #     transporte de não carregar um diretório que ele carrega.
  # Nenhum dos dois estava na lista, e os dois são a MESMA classe. É o padrão que esta casa já
  # nomeou: em guarda de lista o defeito dominante é o VOCABULÁRIO, não a lógica — então a guarda
  # passa a asserir a FORMA: QUALQUER produtor em posição de veredito seguido de `| grep -q`.
  # Custo medido da troca: 88 → 109 sítios (+21), todos absorvidos pela catraca como passivo.
  # O que continua fora, por desenho: `| grep -q` dentro de MENSAGEM (ali o truncamento não vira
  # veredito) e linha comentada — os dois filtrados abaixo.
  hits="$(grep -rnE "(^|if |elif |while |until |&& |\|\| |; )!? ?[^|;]+ \| *grep -q" \
            "${dirs[@]}" 2>/dev/null || true)"
  hits="$(grep -vE ':[[:space:]]*#' <<< "${hits}" || true)"
  [ -n "${hits}" ] || return 0
  sed "s|^${r}/||" <<< "${hits}" | awk -F: '{print $1}' | sort | uniq -c | awk '{printf "%s\t%s\n", $2, $1}'
}

if [ "${MODE}" = --selftest ]; then
  fails=0; sb="$(mktemp -d)"; mkdir -p "${sb}/.claude/validation"
  printf 'if printf "%%s" "$x" | grep -q PAD; then :; fi\n' > "${sb}/.claude/validation/mau.sh"
  printf 'if grep -q PAD <<< "$x"; then :; fi\n'            > "${sb}/.claude/validation/bom.sh"
  printf '# if printf "%%s" "$x" | grep -q PAD\n'            > "${sb}/.claude/validation/comentado.sh"
  out="$(_scan "${sb}")"
  grep -q 'mau\.sh' <<< "${out}" || { echo "  ✗ (a) não achou o sítio frágil"; fails=$((fails+1)); }
  grep -q 'bom\.sh' <<< "${out}" && { echo "  ✗ (b) acusou here-string (falso-positivo)"; fails=$((fails+1)); }
  grep -q 'comentado\.sh' <<< "${out}" && { echo "  ✗ (c) acusou COMENTÁRIO"; fails=$((fails+1)); }
  [ "${fails}" -eq 0 ] && echo "  ✅ acha o frágil, ignora here-string e comentário"
  rm -rf "${sb}"
  [ "${fails}" -eq 0 ] && { echo "pipe-verdict-check selftest: OK"; exit 0; }
  echo "pipe-verdict-check selftest: ${fails} falha(s)"; exit 1
fi

if [ "${MODE}" = --emit-baseline ]; then
  cat <<'HDR'
# Baseline da CLASSE "veredito por <produtor>|grep -q" (catraca).
# GERADO por pipe-verdict-check.sh --emit-baseline — não edite à mão.
# POR QUÊ: a guarda nasceu vendo só `_emit "…" | grep -q`; ampliada para a CLASSE em 2026-09-05 achou
# 94 sítios pré-existentes em 23 arquivos. Guarda que nasce vermelha em massa é guarda que alguém
# desliga — a doutrina desta casa é catraca com baseline (REGRAS 29/42/45/49/74).
# FORMATO: <arquivo><TAB><nº de sítios tolerados>. A métrica de saúde é este número DIMINUINDO.
# Sítio NOVO em arquivo fora da lista, ou ACIMA da contagem, é HARD.
# CURA: conteúdo numa variável + `grep -q PAD <<< "$var"` (medida: 0 falhas em 480).
HDR
  _scan "${ROOT}"
  exit 0
fi
_scan "${ROOT}"
