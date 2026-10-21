#!/usr/bin/env bash
# =============================================================================
# plan-contract-migration.sh — a migração do corpus ao contrato KG-SSOT, PLANEJADA (dry-run) no `--update`
#
# POR QUE EXISTE: fase 2 de D_U1_CAMADA_SDAAL_NO_UPDATE (decisão do maestro de 2026-10-20). A fase 1
# (`remeasure-contract.sh`) mede o contrato no alvo e diz o número; um hub de campo tinha 1.024 nós reprovando no
# MUST `form.required.node.provenance` e migrou à mão, com classificador avulso, sem achar ferramenta. O migrador
# oficial nasceu no kg-ssot (D_U1_MIGRADOR_NO_KG_SSOT): o `vendor/kg-ssot/tools/kg_migrate.py`, desde a 4.13.0,
# que propõe a provenance por um PERFIL que o dono do corpus escreve. Esta fase o conduz: roda o `plan` no alvo,
# com o perfil DELE e o migrador do vendor DELE, e cola o resumo e o caminho da planilha no relatório.
#
# NUNCA APLICA. O `kg_migrate.py apply` grava nos grafos do adotante, e trocar a provenance (ou rebaixar um nó para
# unverifiable) é decisão sobre a verdade do grafo, que fica com o dono dele (ADOPTING.md do kg-ssot). Este script
# só chama o subcomando `plan`, fotografa o alvo antes e depois (git status com ignorados + sha256 dos .kg.yaml
# rastreados) e sai rc 5 se algo mudou. A planilha vai para FORA do alvo (`--out-dir`, default `mktemp -d`); um
# `--out-dir` dentro do alvo é recusado. O comando de `apply` sai impresso, com os mesmos `--exclude`, para o dono
# rodar depois de revisar a planilha.
#
# SEM PERFIL NÃO INVENTA. O perfil é julgamento do dono do corpus (que trace é código, que pasta é pesquisa, que nó
# tem fonte irrecuperável). Sem ele, o script diz que falta, onde ele é procurado e como criá-lo a partir do exemplo
# que o vendor traz (`spec/migrate-examples/`), e sai rc 2. Nunca copia o exemplo para o alvo: os ids e os globs do
# exemplo são de outro corpus (medido em 2026-10-21 contra o hub: o exemplo cru concorda em 1.007 de 1.024 nós; com
# os 3 ids e o glob de pesquisa do próprio hub, em 1.023).
#
# ONDE O PERFIL É PROCURADO (nesta ordem; os dois achados = ambíguo, rc 3; `--profile` vence):
#   .kg-ssot/migrate-profile.yaml  — ao lado do `.kg-ssot/gate.json`, onde o hub de campo pôs o dele
#   kg-migrate.profile.yaml        — o nome do exemplo de comando do manual do kg-ssot (cap. 5)
#
# O CORPUS é o mesmo da fase 1: os .kg.yaml rastreados, fora `vendor/**` (o default do migrador: os fixtures da
# suíte vendorizada são quebrados de propósito) e os excluídos da medição do contrato, traduzidos para o dialeto de
# glob do perfil (no `kg_gate.py`, fnmatch, `*` atravessa `/`; no `kg_migrate.py`, `**` atravessa e `*` não).
#
# USO  : plan-contract-migration.sh <TARGET> [--profile PERFIL.yaml] [--out-dir DIR]   (cole stdout E stderr: `2>&1`)
# EXIT : 0 = plano gerado: o resumo e a planilha estão na saída (o update SEGUE; aplicar é do dono)
#        2 = há dívida MUST e o alvo não tem perfil: a orientação está na saída (o update SEGUE)
#        3 = NÃO MEDIDO (contrato não medido, kg_migrate.py ausente no vendor do alvo, perfil ambíguo ou recusado
#            pelo migrador, dependência ausente, qualquer erro) — escreva NÃO MEDIDO com o motivo, nunca "sem dívida"
#        4 = não roda: o corpus passa no MUST, ou o contrato não se aplica ao alvo (sem vendor, sem grafo)
#        5 = o alvo MUDOU durante o plan — PARE e investigue (o plan não escreve; isto nunca deveria sair)
# =============================================================================
set -uo pipefail
T="${1:?uso: plan-contract-migration.sh <TARGET> [--profile PERFIL.yaml] [--out-dir DIR]}"; shift
PROFILE="" OUT_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) [ $# -ge 2 ] || { echo "MIGRAÇÃO NÃO MEDIDA: --profile exige um caminho" >&2; exit 3; }; PROFILE="$2"; shift 2 ;;
    --out-dir) [ $# -ge 2 ] || { echo "MIGRAÇÃO NÃO MEDIDA: --out-dir exige um diretório" >&2; exit 3; }; OUT_DIR="$2"; shift 2 ;;
    *) echo "MIGRAÇÃO NÃO MEDIDA: argumento desconhecido: $1" >&2; exit 3 ;;
  esac
done
no() { echo "MIGRAÇÃO NÃO MEDIDA: $*" >&2; exit 3; }
[ -d "${T}" ] || no "${T} não é diretório."
T="$(cd "${T}" && pwd -P)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# ── 1. o gatilho: a dívida MUST medida pela fase 1, no alvo, com o vendor DELE ─────────────────────────────────────
[ -f "${HERE}/remeasure-contract.sh" ] || no "remeasure-contract.sh ausente ao lado deste script (a fase 1 decide se esta roda)."
CONTRACT_OUT="$(bash "${HERE}/remeasure-contract.sh" "${T}" 2>&1)"; CRC=$?
case "${CRC}" in
  1) ;;
  0) echo "MIGRAÇÃO não roda: o corpus passa no MUST do contrato vendorizado (remeasure-contract rc 0)."; exit 4 ;;
  4) echo "MIGRAÇÃO não roda: $(printf '%s\n' "${CONTRACT_OUT}" | head -1)"; exit 4 ;;
  *) no "o contrato do alvo não foi medido (remeasure-contract rc ${CRC}: $(printf '%s\n' "${CONTRACT_OUT}" | head -1))." ;;
esac
DEBT="$(printf '%s\n' "${CONTRACT_OUT}" | sed -n 's/.*reprova no contrato vendorizado: \([0-9][0-9]*\) nó(s) em \([0-9][0-9]*\) grafo(s).*/\1 \2/p' | head -1)"
DEBT_NODES="${DEBT%% *}" DEBT_GRAPHS="${DEBT##* }"
[ -n "${DEBT}" ] || no "o remeasure-contract saiu rc 1 sem a linha da dívida (a frase mudou?)."

VENDOR="${T}/vendor/kg-ssot"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "${VENDOR}/.kg-ssot-version" 2>/dev/null | head -1)"
MIG="${VENDOR}/tools/kg_migrate.py"
[ -f "${MIG}" ] || no "o vendor do alvo (kg-ssot ${VERSION:-?}) não traz o tools/kg_migrate.py, que chegou na kg-ssot 4.13.0; ${DEBT_NODES} nó(s) seguem na dívida MUST (${DEBT_GRAPHS} grafo(s) reprovam), e o --update traz o vendor atual."
command -v python3 >/dev/null 2>&1 || no "python3 ausente (o migrador é Python)."

# ── 2. o perfil: do dono do corpus, nunca inventado ────────────────────────────────────────────────────────────────
CANDIDATES=(".kg-ssot/migrate-profile.yaml" "kg-migrate.profile.yaml")
if [ -n "${PROFILE}" ]; then
  case "${PROFILE}" in /*) ;; *) PROFILE="${T}/${PROFILE}" ;; esac
  [ -f "${PROFILE}" ] || no "o perfil dado em --profile não existe: ${PROFILE}"
else
  FOUND=()
  for c in "${CANDIDATES[@]}"; do [ -f "${T}/${c}" ] && FOUND+=("${c}"); done
  if [ "${#FOUND[@]}" -gt 1 ]; then
    no "o alvo tem dois perfis (${FOUND[*]}): diga qual com --profile, ou apague um."
  elif [ "${#FOUND[@]}" -eq 0 ]; then
    EXAMPLES="$(cd "${VENDOR}/spec/migrate-examples" 2>/dev/null && ls -1 -- *.profile.yaml 2>/dev/null | head -5 | paste -sd' ' -)"
    echo "MIGRAÇÃO sem perfil: o contrato acusa ${DEBT_NODES} nó(s) na dívida MUST (${DEBT_GRAPHS} grafo(s) reprovam), e o alvo não tem o perfil de migração (procurado em ${CANDIDATES[0]} e ${CANDIDATES[1]})."
    echo "  O core não escreve o perfil: as regras (que trace é código, que pasta é pesquisa, que nó tem fonte irrecuperável) são julgamento do dono do corpus."
    echo "  Para criar: copie um exemplo do vendor (vendor/kg-ssot/spec/migrate-examples/: ${EXAMPLES:-nenhum exemplo no vendor}) para ${CANDIDATES[0]},"
    echo "  troque os ids de exemplo pelos do seu grafo e os globs pelas suas pastas (schema: vendor/kg-ssot/spec/kg-migrate-profile.schema.json;"
    echo "  manual: vendor/kg-ssot/docs/manual/05-ferramentas.md, seção do kg_migrate.py), versione-o e rode o --update (ou este passo) de novo."
    exit 2
  else
    PROFILE="${T}/${FOUND[0]}"
  fi
fi

# ── 3. a planilha vai para FORA do alvo ────────────────────────────────────────────────────────────────────────────
if [ -z "${OUT_DIR}" ]; then
  OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/onion-migrate-plan.XXXXXX")" || no "mktemp -d falhou."
fi
# resolvido ANTES de criar: um --out-dir dentro do alvo é recusado sem que a pasta nasça nele
OUT_DIR="$(python3 -I -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${OUT_DIR}")" || no "não resolvi o --out-dir."
case "${OUT_DIR}/" in "${T}/"*) no "o --out-dir ${OUT_DIR} fica dentro do alvo: a planilha vai para fora (esta fase não escreve no alvo)." ;; esac
mkdir -p "${OUT_DIR}" || no "não consegui criar ${OUT_DIR}."
SHEET="${OUT_DIR}/kg-migrate-plan.tsv"

# ── 4. foto do alvo, plan, foto de novo ────────────────────────────────────────────────────────────────────────────
snapshot() {
  { git -C "${T}" status --porcelain=v1 --ignored -z 2>/dev/null
    git -C "${T}" ls-files -z -- '*.kg.yaml' 2>/dev/null | (cd "${T}" && xargs -0 -r sha256sum --)
    sha256sum -- "${PROFILE}"
  } | sha256sum | cut -d' ' -f1
}
BEFORE="$(snapshot)"
# o corpus da fase 1 no dialeto do perfil (vendor/** já é default do migrador)
EXCL=(--exclude '**/fixtures/**' --exclude 'docs/materials/**'
      --exclude 'docs/evolution/kg-inbox/_rejected/**' --exclude 'docs/evolution/kg-inbox/_sealed/**')
# -I: nada do cwd nem do diretório do script no sys.path; -B: sem bytecode no vendor carimbado do alvo. O cwd é a
# pasta da planilha, fora do alvo.
PLAN_OUT="$(cd "${OUT_DIR}" && python3 -I -B "${MIG}" plan --profile "${PROFILE}" --root "${T}" --out "${SHEET}" "${EXCL[@]}" 2>&1)"; PRC=$?
AFTER="$(snapshot)"
if [ "${BEFORE}" != "${AFTER}" ]; then
  echo "MIGRAÇÃO: o alvo MUDOU durante o plan (git status ou sha256 dos .kg.yaml) — PARE e investigue; o plan não escreve, isto não deveria acontecer." >&2
  exit 5
fi
if [ "${PRC}" -ne 0 ]; then
  no "o kg_migrate.py plan do alvo saiu rc ${PRC} com o perfil ${PROFILE#"${T}/"}: $(printf '%s\n' "${PLAN_OUT}" | grep -v '^ *$' | tail -1 | cut -c1-300)"
fi
[ -s "${SHEET}" ] || no "o plan saiu rc 0 sem gravar a planilha ${SHEET}."

# ── 5. o resumo, lido da planilha (a fonte), não da prosa do stdout ────────────────────────────────────────────────
SUMMARY="$(python3 -I -B - "${SHEET}" "${PROFILE}" <<'PY'
import collections, csv, sys
import yaml
sheet, profile = sys.argv[1:3]
prof = yaml.safe_load(open(profile, encoding="utf-8")) or {}
scope_ids = {s.get("id") for s in prof.get("scopes") or [] if isinstance(s, dict)}
rows = list(csv.DictReader(open(sheet, encoding="utf-8"), delimiter="\t"))
nodes = [r for r in rows if r["id"] and r["regra"] not in scope_ids]
scopes = [r for r in rows if r["id"] and r["regra"] in scope_ids]
broken = [r for r in rows if r["ação"] == "fora"]
act = collections.Counter(r["ação"] for r in nodes)
review = [r for r in nodes if r["revisar"]]
refused = [r for r in nodes if r["revisar"].startswith("a proposta reprovaria no contrato")]
per_rule = collections.Counter((r["regra"] or "(nenhuma regra)", r["ação"]) for r in nodes)
print(f"N={len(nodes)}")
print(f"  {len(nodes)} nó(s) no plano: {act['provenance']} com provenance proposta · {act['unverifiable']} rebaixado(s) para "
      f"unverifiable · {act['review']} sem proposta (para revisão)")
print(f"  para revisão: {len(review)} nó(s) ({act['review']} sem proposta, {len(review) - act['review']} com proposta e aviso) · "
      f"recusados pelo contrato: {len(refused)} · grafos fora (não parseiam): {len(broken)} · linhas de scope: {len(scopes)} "
      f"({sum(1 for r in scopes if r['ação'] == 'scope')} aplicáveis)")
print("  por regra:")
for (rule, a), v in sorted(per_rule.items(), key=lambda kv: (-kv[1], kv[0])):
    print(f"    {v:5d}  {rule} → {a}")
for r in refused[:5]:
    print(f"    recusado: {r['arquivo']} · {r['id']}: {r['revisar'][:160]}")
PY
)" || no "a planilha ${SHEET} não se lê (PyYAML ausente ou TSV fora da forma)."
PLAN_NODES="$(printf '%s\n' "${SUMMARY}" | sed -n 's/^N=//p')"
REL_PROFILE="${PROFILE#"${T}/"}"
echo "MIGRAÇÃO planejada (dry-run, kg_migrate.py plan do vendor do alvo, kg-ssot ${VERSION:-?}) com o perfil ${REL_PROFILE}:"
printf '%s\n' "${SUMMARY}" | sed '/^N=/d'
if [ "${PLAN_NODES}" = "${DEBT_NODES}" ]; then
  echo "  o plano cobre os ${DEBT_NODES} nó(s) que a medição do contrato acusou no MUST."
else
  echo "  ⚠️ o plano tem ${PLAN_NODES} nó(s) e a medição do contrato acusou ${DEBT_NODES} no MUST: a diferença é dívida que o migrador não cobre (outra regra MUST) ou universo diferente; confira a planilha."
fi
echo "  planilha: ${SHEET}"
echo "  Nada foi escrito no alvo. Aplicar é do dono do corpus, numa branch e DEPOIS de revisar a planilha:"
echo "    python3 -I -B vendor/kg-ssot/tools/kg_migrate.py apply --profile ${REL_PROFILE} --exclude '**/fixtures/**' --exclude 'docs/materials/**' --exclude 'docs/evolution/kg-inbox/_rejected/**' --exclude 'docs/evolution/kg-inbox/_sealed/**'"
exit 0
