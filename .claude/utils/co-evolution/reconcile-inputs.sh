#!/usr/bin/env bash
# =============================================================================
# reconcile-inputs.sh — emite os INSUMOS DETERMINÍSTICOS da conciliação de backlog
# do /meta:co-announce --reconcile.
#
# O gap: o co-announce bare só pesca a entrada do topo do CHANGELOG. Uma entrada
# `alvo: todos` cujo anúncio nunca foi (ou foi só parcialmente) transportado fica
# ABERTA e invisível. Este helper NÃO decide cobertura (isso é juízo semântico,
# responder-gated no comando) — ele só levanta, do filesystem, as duas metades que
# o cruzamento precisa:
#   [ENTRIES]  entradas do CHANGELOG com alvo: acionável + destinatários resolvidos
#   [OUTBOX]   inventário de anúncios já produzidos por adotante (staging + _processed)
#
# O comando /meta:co-announce --reconcile cruza as duas (match por entrada×destinatário),
# aplica as guardas (superseded, pós-adoção) e propõe o open-set. Determinístico,
# sem juízo — reusa resolve-target.sh (F1.2). Exercitado por lint-selftest.sh.
#
# Uso:  reconcile-inputs.sh            → seções [ENTRIES] e [OUTBOX] em stdout
#       reconcile-inputs.sh --entries  → só [ENTRIES]
#       reconcile-inputs.sh --outbox   → só [OUTBOX]
#
# Formato (TSV, uma linha por registro):
#   [ENTRIES]\n  <date>\t<recipients-csv>\t<alvo-raw>\t<subject>
#   [OUTBOX]\n   <id>\t<staging|processed>\t<filename>
# recipients-csv vazio nunca aparece (entrada sem destinatário é omitida).
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
CHANGELOG="${ROOT}/docs/evolution/federation/CHANGELOG.md"
OUTBOX="${ROOT}/docs/evolution/federation/outbox"
RESOLVE="${HERE}/resolve-target.sh"

MODE="${1:-all}"

emit_entries() {
  echo "[ENTRIES]"
  [ -f "${CHANGELOG}" ] || return 0
  # Memoização: o mesmo alvo (`todos`, `<id>`, …) repete em dezenas de entradas — resolver uma vez por
  # alvo distinto colapsa ~N chamadas de resolve-target (→ python/yaml) para ~poucas. `MISS` = não-cacheado.
  declare -A CACHE
  # cada cabeçalho: "## <date> · <subject> · <CLASS> · alvo: <alvo>"
  while IFS= read -r line; do
    hdr="${line#*:}"                                   # tira "N:"
    hdr="${hdr#\#\# }"                                 # tira "## "
    date="${hdr%%  · *}"; date="${hdr%% · *}"          # 1º campo
    # alvo = tudo após o último " · alvo:"
    case "${hdr}" in
      *" · alvo: "*) target="${hdr##* · alvo: }" ;;
      *) continue ;;                                   # sem alvo declarado → ignora
    esac
    # subject = entre "<date> · " e o " · <CLASS> · alvo:"
    subj="${hdr#"${date}" · }"
    subj="$(printf '%s' "${subj}" | sed -E 's/ · (COMPATÍVEL|BREAKING|COMPATIVEL) · alvo:.*$//')"
    # destinatários resolvidos (resolve-target normaliza o parêntese) — memoizado por alvo
    recips="${CACHE[$target]:-MISS}"
    if [ "${recips}" = "MISS" ]; then
      recips="$(bash "${RESOLVE}" "${target}" 2>/dev/null | paste -sd, -)"
      CACHE[$target]="${recips}"
    fi
    [ -n "${recips}" ] || continue                     # nenhum/futuros/irresolvível → omite
    printf '%s\t%s\t%s\t%s\n' "${date}" "${recips}" "${target}" "${subj}"
  done < <(grep -nE '^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} · ' "${CHANGELOG}")
}

emit_outbox() {
  echo "[OUTBOX]"
  [ -d "${OUTBOX}" ] || return 0
  for d in "${OUTBOX}"/*/; do
    [ -d "${d}" ] || continue
    id="$(basename "${d}")"
    [ "${id}" = "_processed" ] && continue
    for f in "${d}"*.md; do
      [ -e "${f}" ] || continue
      printf '%s\tstaging\t%s\n' "${id}" "$(basename "${f}")"
    done
    for f in "${d}_processed/"*.md; do
      [ -e "${f}" ] || continue
      printf '%s\tprocessed\t%s\n' "${id}" "$(basename "${f}")"
    done
  done
}

case "${MODE}" in
  --entries) emit_entries ;;
  --outbox)  emit_outbox ;;
  all|"")    emit_entries; echo; emit_outbox ;;
  *) echo "uso: reconcile-inputs.sh [--entries|--outbox]" >&2; exit 2 ;;
esac
