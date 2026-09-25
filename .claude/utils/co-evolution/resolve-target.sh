#!/usr/bin/env bash
# =============================================================================
# resolve-target.sh — resolve o `alvo:` de um anúncio de co-evolução para os IDs de membro que casam.
#
# F1.2 do roadmap de federação (RFC-0004): mata o RUÍDO do targeting. Hoje o `alvo:` só faz per-id OU
# broadcast-p/-todos (ignora specialization/mode/tier que o members.yaml JÁ carrega). Este resolver
# adiciona TARGETING POR SELETOR (policy-as-data), reusando as triplas de membro que o graph.sh passou a
# emitir do members.yaml (F1.1 — a semente).
#
# Uso:  resolve-target.sh <seletor>   → IDs de membro (um por linha) que casam (vazio = ninguém)
#   <seletor>:
#     nenhum | futuros [adotantes]      → vazio (entrada informativa / futuros — sem destinatário atual)
#     todos | adotantes                 → todos os membros que adotam o CORE direto (T1/T3).
#                                       Critério ESTRUTURAL (tripla `adopts`), não lista de papéis:
#                                       papel novo no registro entra por construção. T2 (adota um hub)
#                                       fica fora por desenho — recebe pelo hub (RFC-0003 §2.1).
#     <id>                              → esse membro, se existir
#     <key>:<value>[,<key>:<value>...]  → AND (interseção) sobre atributos:
#         key ∈ { mode | tier (alias role) | specialization (alias spec) }
#         ex.: mode:regulated · tier:hub · specialization:nx-monorepo · mode:regulated,tier:standalone
#
# Reusa graph.sh --triples (members.yaml). Gracioso: sem triplas de membro (sem python+yaml) → vazio.
# Determinístico. Exercitado por lint-selftest.sh (run_resolve_target_selftests).
# =============================================================================
set -uo pipefail

SEL="${1:-}"; [ -n "${SEL}" ] || { echo "uso: resolve-target.sh <seletor>" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
GRAPH="${ROOT}/.claude/validation/graph.sh"

# Normaliza: descarta anotação entre parênteses, chaves {} e espaços de borda.
SEL="$(printf '%s' "${SEL}" | sed -E 's/\(.*//; s/[{}]//g; s/^[[:space:]]+//; s/[[:space:]]+$//')"

TRIPLES="$(bash "${GRAPH}" --triples 2>/dev/null || true)"
# ── ID DO CORE NO REGISTRO: CONSTANTE DECLARADA, não estatística ────────────────────────────────
# A 1ª versão derivava isto como "o `parent:` mais frequente do members.yaml", com o raciocínio de que
# o core é, por construção, quem a maioria adota. Um caso de bancada matou o raciocínio: num registro
# com UM membro cujo `parent` é um hub, o mais-frequente É esse hub — então o helper elegia o hub como
# core e ENTREGAVA a um T2 exatamente o anúncio que a RFC-0003 §2.1 manda o hub propagar. A heurística
# se auto-satisfazia no caso que mais importa barrar, e só apareceu porque escrevi o caso.
# Constante, com override por ambiente para bancada e para o dia em que o repo for renomeado. Se o id
# mudar e ninguém tocar aqui, a falha é ALTA e imediata (ninguém recebe), não silenciosa.
CORE_ID="${ONION_CORE_MEMBER_ID:-onion-evolve}"
_by_pred() { printf '%s\n' "${TRIPLES}" | awk -F'\t' -v p="$1" -v v="$2" '$2==p && $3==v{print $1}' | LC_ALL=C sort -u; }

_match_one() {  # <key> <value> → ids com o atributo
  local k="$1" v="$2" pred
  case "${k}" in
    mode)                 pred=mode ;;
    tier|role)            pred=tier ;;
    specialization|spec)  pred=specialization ;;
    *) echo "ERRO: chave de seletor desconhecida: '${k}' (use mode|tier|specialization)." >&2; return 3 ;;
  esac
  _by_pred "${pred}" "${v}"
}

case "${SEL}" in
  nenhum|futuros|"futuros adotantes") exit 0 ;;                      # sem destinatário
  todos|adotantes)
    # ── A PERGUNTA ESTRUTURAL, NÃO A LISTA DE PAPÉIS (curado 2026-09-25, medido) ──────────────
    # Até aqui isto era `tier hub` ∪ `tier standalone` — uma LISTA de papéis. A unificação de
    # vocabulário de 2026-09-24 (`consumer` → `adopted` no registro) criou um papel novo que a lista
    # não conhecia, e o efeito foi SILENCIOSO: `sge`, único membro `role: adopted`, saía de fora dos
    # destinatários de todo anúncio, e nenhum gate acusava. Ninguém teria notado até alguém perguntar
    # por que aquele adotante nunca recebeu nada.
    # A cura não é acrescentar `adopted` à lista — é parar de enumerar. O critério da RFC-0003 §2.1 é
    # "adota o CORE direto" (T1/T3) versus "adota um hub" (T2, recebe pelo hub), e essa é exatamente a
    # tripla `adopts`, que o `members.yaml` já carrega. Papel novo passa a entrar por construção.
    # ([[guarda-por-lista-falha-pelo-vocabulario]] — em guarda de lista o defeito dominante é o
    #  VOCABULÁRIO, não a lógica.)
    _by_pred adopts "${CORE_ID}" ;;
  *:*)
    # seletor key:value[,key:value] → AND (interseção)
    local_init=""; result=""
    IFS=',' read -ra _parts <<< "${SEL}"
    for part in "${_parts[@]}"; do
      part="$(printf '%s' "${part}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "${part}" ] || continue
      k="${part%%:*}"; v="${part#*:}"; v="$(printf '%s' "${v}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      set_i="$(_match_one "${k}" "${v}")" || exit 3
      if [ -z "${local_init}" ]; then result="${set_i}"; local_init=1
      else result="$(comm -12 <(printf '%s\n' "${result}") <(printf '%s\n' "${set_i}"))"; fi
    done
    printf '%s\n' "${result}" | grep -v '^$' || true ;;
  *)
    # id nu: existe como membro (tem tripla de tier)?
    if printf '%s\n' "${TRIPLES}" | awk -F'\t' -v m="${SEL}" '$1==m && $2=="tier"{f=1} END{exit !f}'; then
      printf '%s\n' "${SEL}"
    else
      echo "AVISO: '${SEL}' não é membro no members.yaml (nem seletor key:value)." >&2
    fi ;;
esac
