#!/usr/bin/env bash
# =============================================================================
# tokens-to-theme.sh — sink de TEMA (adapter `theme` do design-sink)
#
# ══ POR QUE ELE EXISTE, e por que não é uma flag do css-vars ═════════════════
# DOIS adotantes independentes chegaram ao mesmo buraco, com semanas de distância
# e produtos diferentes (um portal web, um app Expo universal):
#
#   "`tokens-to-css-vars.sh` resolve os aliases corretamente, mas emite tudo
#    plano num único `:root`:  --color-surface-base E --color-dark-surface-base.
#    Isso não é um tema utilizável. A UI precisa que `--color-surface-base` MUDE
#    DE VALOR conforme o tema; um segundo NOME não muda nada sozinho, e o
#    componente teria de escolher a var na mão — que é exatamente o acoplamento
#    que os papéis semânticos existem para evitar."
#
# O css-vars não está errado: ele faz o que documenta (achatar a SSOT). O que
# faltava era um sink que projetasse MODO. Por isso adapter irmão, não flag —
# a saída tem forma diferente, não parâmetro diferente.
#
# ══ OS TRÊS ESTADOS, e o terceiro é o que todo mundo esquece ═════════════════
#   :root                                         → claro (default)
#   @media (prefers-color-scheme: dark)
#     :root:not([data-theme="light"])             → escuro POR SISTEMA
#   :root[data-theme="dark"]                      → escuro POR ESCOLHA
#
# O estado "seguir o sistema" NÃO estampa nada no root, então só a media query o
# separa. E sem o `:not([data-theme="light"])` a escolha EXPLÍCITA do usuário por
# claro PERDE para o SO — o modo de falha que o adotante nomeou e que só aparece
# na tela de quem escolheu claro num SO escuro.
#
# ══ PARIDADE É AVISO, NUNCA SILÊNCIO ════════════════════════════════════════
# Papel que existe num modo e não no outro herda a cor do modo errado, em
# silêncio, e só se descobre olhando. Um adotante registrou que foi essa guarda
# que o impediu de promover uma paleta cujo `info-strong` só existia no claro.
#
# Uso     : tokens-to-theme.sh [<dir-do-projeto>] [--prefix <ramo>]
#           --prefix: o ramo de modo escuro na SSOT (default: `color.dark`)
# Saída   : CSS em STDOUT. Papéis sob NOME CANÔNICO nos três estados.
# FECHADO : sem `jq` com design-context presente → exit 2 (a mesma doutrina que o
#           gate adotou em 2026-09-16: guarda que não roda não aprova).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT="${REPO_ROOT}"; DARK_PREFIX="color.dark"
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) DARK_PREFIX="${2:-color.dark}"; shift 2 ;;
    --prefix=*) DARK_PREFIX="${1#--prefix=}"; shift ;;
    *) PROJECT="$1"; shift ;;
  esac
done
DC="${PROJECT}/docs/design-context"

if [ ! -d "${DC}" ]; then
  echo "AVISO: design-context ausente em ${PROJECT} — nada a emitir." >&2
  echo ":root {}"; exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERRO: jq ausente e ${DC#${PROJECT}/} EXISTE — o sink de tema não pode ser exercido." >&2
  exit 2
fi

declare -A TOK
while IFS= read -r f; do
  while IFS=$'\t' read -r path val; do
    [ -n "${path}" ] || continue
    TOK["${path}"]="${val}"
  done < <(jq -r 'paths(scalars) as $p | select($p[-1]=="$value")
                  | [($p[:-1]|join(".")), (getpath($p)|tostring)] | @tsv' "${f}" 2>/dev/null)
  # `_candidates/` é staging do /design:generate, e as candidatas usam os MESMOS paths da
  # foundation promovida — incluí-las faria o tema sair de uma paleta que ninguém escolheu.
done < <(find "${DC}" -type f -name '*.tokens.json' -not -path '*/_candidates/*' | sort)

resolve() {  # segue {alias} até valor final; guarda de ciclo (mesmo contrato do css-vars)
  local v="$1" depth=0 key
  while [[ "${v}" =~ ^\{(.+)\}$ ]]; do
    key="${BASH_REMATCH[1]}"; depth=$((depth + 1)); [ "${depth}" -gt 16 ] && { printf '%s' "${v}"; return; }
    [ -z "${TOK[${key}]+x}" ] && { printf '%s' "${v}"; return; }
    v="${TOK[${key}]}"
  done
  printf '%s' "${v}"
}

# Particiona: papel CLARO (color.* fora do ramo escuro) × papel ESCURO (o ramo).
declare -A LIGHT=() DARK=()
for path in "${!TOK[@]}"; do
  case "${path}" in
    "${DARK_PREFIX}".*) DARK["${path#"${DARK_PREFIX}".}"]="${TOK[${path}]}" ;;
    color.*)            LIGHT["${path#color.}"]="${TOK[${path}]}" ;;
  esac
done

# ── PARIDADE — aviso, nunca silêncio ────────────────────────────────────────
# SSOT sem ramo escuro NENHUM não é falta de paridade — é projeto que não tem tema duplo, e
# listar os 28 papéis ali seria ruído que ensina a ignorar o aviso que importa (o de UM papel
# faltando). Só se há ramo escuro é que a assimetria vira achado.
_missing_dark=""; _missing_light=""
if [ "${#DARK[@]}" -gt 0 ]; then
  for r in "${!LIGHT[@]}"; do [ -z "${DARK[${r}]+x}" ] && _missing_dark="${_missing_dark} ${r}"; done
  for r in "${!DARK[@]}";  do [ -z "${LIGHT[${r}]+x}" ] && _missing_light="${_missing_light} ${r}"; done
  [ -n "${_missing_dark}" ] && echo "AVISO paridade: papel(is) SEM contraparte escura —${_missing_dark}" >&2
  [ -n "${_missing_light}" ]  && echo "AVISO paridade: papel(is) SÓ no escuro —${_missing_light}" >&2
else
  echo "nota: SSOT sem ramo '${DARK_PREFIX}.*' — emitindo só o tema claro (não é falta de paridade)." >&2
fi

_emit_block() {  # $1=indentação · $2=nome do array associativo
  # ⚠️ `local ind="$1" -n arr="$2"` NÃO declara nameref — o `-n` vira nome de variável e o bash
  # reclama "not a valid identifier", emitindo `--color-0: LIGHT`. Nameref exige declaração
  # própria. Pego no 1º dogfood, que é para isso que ele serve.
  local ind="$1" r
  local -n arr="$2"
  for r in $(printf '%s\n' "${!arr[@]}" | LC_ALL=C sort); do
    printf '%s--color-%s: %s;\n' "${ind}" "$(printf '%s' "${r}" | tr '.' '-')" "$(resolve "${arr[${r}]}")"
  done
}

echo "/* Gerado de docs/design-context por design-sink/tokens-to-theme.sh — NÃO editar à mão. */"
echo ":root {"; _emit_block "  " LIGHT; echo "}"
if [ "${#DARK[@]}" -gt 0 ]; then
  echo ""
  echo "/* escuro POR SISTEMA — o :not() preserva a escolha explícita do usuário por claro */"
  echo "@media (prefers-color-scheme: dark) {"
  echo "  :root:not([data-theme=\"light\"]) {"; _emit_block "    " DARK; echo "  }"
  echo "}"
  echo ""
  echo "/* escuro POR ESCOLHA */"
  echo ":root[data-theme=\"dark\"] {"; _emit_block "  " DARK; echo "}"
fi
exit 0
