#!/usr/bin/env bash
# =============================================================================
# federation-radar.sh — radar de SAÚDE-DE-VERIFICAÇÃO da federação ("o core não é surpreendido").
#
# ADR: onion-adr-federation-kg-audit-overlay-2026-07 (a foto da federação = overlay AUDIT do eixo
# declarado≠verificado). Consolida os checks que hoje vivem espalhados (pin-integrity-check.sh,
# reconcile-inputs.sh, /meta:federation-*) num veredito de ATENÇÃO. Reusa:
#   - graph.sh --triples      (estrutura: tier/adopts/lineage — do members.yaml)
#   - reconcile-inputs.sh     (estado de anúncio: staging vs processed)
#   - members.yaml            (marcadores de pin não-verificado)
#
# 4 checks (declarado≠verificado): ① pin declarado≠verificado · ② anúncio staging-não-transportado ·
# ③ hub sem sub-adotado · ④ (coberto por ① — linhagem sem pin verificado).
# ADVISORY: exit 0 + relatório de ATENÇÃO (não é gate — é "não-surpreendido"). Determinístico.
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite empty (medido 2026-08-04).
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"
MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"
GRAPH="${ROOT}/.claude/validation/graph.sh"
RECON="${ROOT}/.claude/utils/co-evolution/reconcile-inputs.sh"

attention=0
echo "══ FEDERATION RADAR — saúde-de-verificação (declarado≠verificado) ══"

# ① pin declarado ≠ verificado (linhagem/pin marcado não-confiável)
echo
echo "① pin declarado ≠ verificado:"
if [ -f "${MEMBERS}" ]; then
  hits="$(grep -nE 'pin[: ].*(untrusted|nao-verificavel|não-verificável|desconhecido|forjado|proposed)' "${MEMBERS}" 2>/dev/null || true)"
  if [ -n "${hits}" ]; then
    printf '%s\n' "${hits}" | sed -E 's/^([0-9]+):.*/   ⚠ members.yaml:\1 — pin não-verificado/' | head
    attention=$((attention + $(printf '%s\n' "${hits}" | grep -c .)))
  else echo "   ✅ nenhum"; fi
else echo "   (members.yaml ausente — pulado)"; fi

# ② anúncio em staging, não-transportado
echo
echo "② anúncio em staging (gerado, não-transportado):"
if [ -f "${RECON}" ]; then
  st="$(bash "${RECON}" --outbox 2>/dev/null | awk -F'\t' '$2=="staging"{print}')"
  m="$(printf '%s' "${st}" | grep -c . || true)"
  if [ "${m:-0}" -gt 0 ]; then
    printf '%s\n' "${st}" | awk -F'\t' '{print "   ⚠ "$1" ← "$3}' | head
    attention=$((attention + m))
  else echo "   ✅ nenhum"; fi
else echo "   (reconcile-inputs.sh ausente — pulado)"; fi

# ③ hub sem sub-adotado (tier hub, mas ninguém o adota)
echo
echo "③ hub sem sub-adotado (tier hub sem 'x adopts hub'):"
if [ -f "${GRAPH}" ]; then
  trip="$(bash "${GRAPH}" --triples 2>/dev/null || true)"
  hubs="$(printf '%s\n' "${trip}" | awk -F'\t' '$2=="tier" && $3=="hub"{print $1}')"
  found=0
  if [ -n "${hubs}" ]; then
    while IFS= read -r h; do
      [ -n "${h}" ] || continue
      if ! printf '%s\n' "${trip}" | awk -F'\t' -v h="${h}" '$2=="adopts" && $3==h{f=1} END{exit !f}'; then
        echo "   ⚠ ${h} é hub mas não tem sub-adotado (T2) — hub declarado ≠ hub verificado"
        found=$((found+1)); attention=$((attention+1))
      fi
    done <<< "${hubs}"
  fi
  [ "${found}" -eq 0 ] && echo "   ✅ nenhum (ou sem hubs)"
else echo "   (graph.sh ausente — pulado)"; fi

echo
if [ "${attention}" -gt 0 ]; then
  echo "▶ ATENÇÃO: ${attention} ponto(s) a re-verificar (declarado≠verificado). Advisory — não bloqueia."
else
  echo "✅ federação sem pontos de atenção de verificação."
fi
exit 0
