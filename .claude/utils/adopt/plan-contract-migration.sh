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
# só chama o subcomando `plan`, fotografa o alvo antes e depois e sai rc 5 se algo mudou. A planilha vai para FORA
# do alvo (`--out-dir`, default `mktemp -d` no TMPDIR); um `--out-dir` ou um TMPDIR dentro do alvo é recusado antes
# de qualquer pasta nascer, e a planilha é sempre um arquivo NOVO (um symlink plantado no lugar dela é apagado, não
# seguido). O comando de `apply` sai impresso, com os mesmos `--exclude`, para o dono rodar depois de revisar.
#
# A FOTO (o que ela vê e o que não vê, declarado): o `git status --porcelain --ignored`, o conteúdo dos .kg.yaml
# rastreados, o conteúdo de todo arquivo não rastreado e não ignorado, e o perfil; o hash é do Python (hashlib), não
# do `sha256sum`, que falta em macOS (sem ele a foto saía vazia dos dois lados e "batia": passada adversarial de
# 2026-10-21). Ela NÃO lê o conteúdo de arquivo ignorado nem o `.git/`; a planilha nunca aponta para dentro do alvo.
#
# SEM PERFIL NÃO INVENTA. O perfil é julgamento do dono do corpus (que trace é código, que pasta é pesquisa, que nó
# tem fonte irrecuperável). Sem ele, o script diz que falta, onde ele é procurado e como criá-lo a partir do exemplo
# que o vendor traz (`spec/migrate-examples/`), e sai rc 2. Nunca copia o exemplo para o alvo: os ids e os globs do
# exemplo são de outro corpus (medido em 2026-10-21 contra o hub: o exemplo cru concorda em 1.007 de 1.024 nós; com
# os 3 ids e o glob de pesquisa do próprio hub, em 1.023).
#
# ONDE O PERFIL É PROCURADO (nesta ordem; os dois achados = ambíguo, rc 3; `--profile` vence, e o relativo é
# resolvido contra o ALVO, não contra o cwd):
#   .kg-ssot/migrate-profile.yaml  — ao lado do `.kg-ssot/gate.json`, onde o hub de campo pôs o dele
#   kg-migrate.profile.yaml        — o nome do exemplo de comando do manual do kg-ssot (cap. 5)
#
# O UNIVERSO: o migrador lê os .kg.yaml rastreados fora de `vendor/**` (default fixo dele) e dos `--exclude`, que aqui
# são os excluídos da fase 1 traduzidos para o dialeto de glob do perfil (no `kg_gate.py`, fnmatch, `*` atravessa
# `/`; no `kg_migrate.py`, `**` atravessa e `*` não: `*/fixtures/*` vira `*/**/fixtures/**`). A fase 1 NÃO exclui
# `vendor/**`, então os dois universos podem divergir; por isso o plano é conferido por IDENTIDADE contra os nós da
# dívida que a fase 1 grava (ONION_CONTRACT_NODES_OUT), e o nó da dívida que o plano não cobre sai listado.
#
# USO  : plan-contract-migration.sh <TARGET> [--profile PERFIL.yaml] [--out-dir DIR]   (cole stdout E stderr: `2>&1`)
# EXIT : 0 = plano gerado: o resumo e a planilha estão na saída (o update SEGUE; aplicar é do dono)
#        2 = há dívida MUST e o alvo não tem perfil: a orientação está na saída (o update SEGUE)
#        3 = NÃO MEDIDO (contrato não medido, kg_migrate.py ausente no vendor do alvo, perfil ambíguo ou recusado
#            pelo migrador, dependência ausente, foto impossível, qualquer erro) — escreva NÃO MEDIDO com o motivo
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
command -v python3 >/dev/null 2>&1 || no "python3 ausente (o migrador e a foto do alvo são Python)."
realp() { python3 -I -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"; }
inside() { case "$1/" in "${T}/"*) return 0 ;; esac; return 1; }

# o TMPDIR resolvido ANTES de qualquer mktemp: dentro do alvo, nada nasce (passada adversarial: a pasta nascia nele)
TMPBASE="$(realp "${TMPDIR:-/tmp}")" || no "não resolvi o TMPDIR."
inside "${TMPBASE}" && no "o TMPDIR (${TMPBASE}) fica dentro do alvo: aponte-o para fora (esta fase não escreve no alvo)."
NODES="$(mktemp "${TMPBASE}/onion-contract-nodes.XXXXXX")" || no "mktemp falhou em ${TMPBASE}."
trap 'rm -f "${NODES}"' EXIT

# ── 1. o gatilho: a dívida MUST medida pela fase 1, no alvo, com o vendor DELE ─────────────────────────────────────
[ -f "${HERE}/remeasure-contract.sh" ] || no "remeasure-contract.sh ausente ao lado deste script (a fase 1 decide se esta roda)."
CONTRACT_OUT="$(ONION_CONTRACT_NODES_OUT="${NODES}" bash "${HERE}/remeasure-contract.sh" "${T}" 2>&1)"; CRC=$?
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

# ── 3. a planilha vai para FORA do alvo, num arquivo novo ──────────────────────────────────────────────────────────
if [ -z "${OUT_DIR}" ]; then
  OUT_DIR="$(mktemp -d "${TMPBASE}/onion-migrate-plan.XXXXXX")" || no "mktemp -d falhou."
fi
# resolvido ANTES de criar: um --out-dir dentro do alvo é recusado sem que a pasta nasça nele
OUT_DIR="$(realp "${OUT_DIR}")" || no "não resolvi o --out-dir."
inside "${OUT_DIR}" && no "o --out-dir ${OUT_DIR} fica dentro do alvo: a planilha vai para fora (esta fase não escreve no alvo)."
mkdir -p "${OUT_DIR}" || no "não consegui criar ${OUT_DIR}."
SHEET="${OUT_DIR}/kg-migrate-plan.tsv"
# um symlink (ou planilha velha) no lugar da planilha é apagado, nunca seguido: o migrador abre com open(w)
rm -f -- "${SHEET}" || no "não consegui limpar ${SHEET}."
[ -e "${SHEET}" ] || [ -L "${SHEET}" ] && no "${SHEET} continua existindo depois do rm: recusado."

# ── 4. foto do alvo, plan, foto de novo ────────────────────────────────────────────────────────────────────────────
snapshot() {
  python3 -I -B - "${T}" "${PROFILE}" <<'PY'
import hashlib, os, subprocess, sys
root, profile = sys.argv[1:3]
h = hashlib.sha256()
def git(*a):
    r = subprocess.run(["git", "-C", root, *a], capture_output=True, check=True)
    return r.stdout
def eat(path):
    h.update(path.encode("utf-8", "surrogateescape") + b"\0")
    if os.path.islink(path):
        h.update(b"L" + os.readlink(path).encode("utf-8", "surrogateescape"))
    elif os.path.isfile(path):
        with open(path, "rb") as fh:
            h.update(hashlib.sha256(fh.read()).digest())
status = git("status", "--porcelain=v1", "--ignored", "-z")
h.update(status)
for name in sorted(n for n in git("ls-files", "-z", "--", "*.kg.yaml").split(b"\0") if n):
    eat(os.path.join(root, os.fsdecode(name)))
# todo arquivo não rastreado e não ignorado, com o conteúdo (o status só mostra o diretório novo, não o que há nele)
for name in sorted(n for n in git("ls-files", "-z", "--others", "--exclude-standard").split(b"\0") if n):
    eat(os.path.join(root, os.fsdecode(name)))
eat(profile)
print(h.hexdigest())
PY
}
BEFORE="$(snapshot)" && [ -n "${BEFORE}" ] || no "a foto do alvo antes do plan falhou (git ou python): sem foto, não há prova de que nada foi escrito."
EXCL=(--exclude '*/**/fixtures/**' --exclude 'docs/materials/**'
      --exclude 'docs/evolution/kg-inbox/_rejected/**' --exclude 'docs/evolution/kg-inbox/_sealed/**')
# -I: nada do cwd nem do diretório do script no sys.path; -B: sem bytecode no vendor carimbado do alvo. O cwd é a
# pasta da planilha, fora do alvo.
PLAN_OUT="$(cd "${OUT_DIR}" && python3 -I -B "${MIG}" plan --profile "${PROFILE}" --root "${T}" --out "${SHEET}" "${EXCL[@]}" 2>&1)"; PRC=$?
AFTER="$(snapshot)" && [ -n "${AFTER}" ] || no "a foto do alvo depois do plan falhou: sem foto, não há prova de que nada foi escrito."
if [ "${BEFORE}" != "${AFTER}" ]; then
  echo "MIGRAÇÃO: o alvo MUDOU durante o plan (git status ou conteúdo dos .kg.yaml, dos não rastreados ou do perfil) — PARE e investigue; o plan não escreve, isto não deveria acontecer." >&2
  exit 5
fi
if [ "${PRC}" -ne 0 ]; then
  no "o kg_migrate.py plan do alvo saiu rc ${PRC} com o perfil ${PROFILE#"${T}/"}: $(printf '%s\n' "${PLAN_OUT}" | grep -v '^ *$' | tail -1 | cut -c1-300)"
fi
[ -f "${SHEET}" ] && [ ! -L "${SHEET}" ] && [ -s "${SHEET}" ] || no "o plan saiu rc 0 sem gravar a planilha ${SHEET}."

# ── 5. o resumo, lido da planilha (a fonte), conferido por identidade contra a dívida da fase 1 ────────────────────
SUMMARY="$(python3 -I -B - "${SHEET}" "${PROFILE}" "${NODES}" <<'PY'
import collections, csv, sys
import yaml
sheet, profile, nodes_file = sys.argv[1:4]
prof = yaml.safe_load(open(profile, encoding="utf-8")) or {}
scope_ids = {s.get("id") for s in prof.get("scopes") or [] if isinstance(s, dict)}
rows = list(csv.DictReader(open(sheet, encoding="utf-8"), delimiter="\t"))
nodes = [r for r in rows if r["id"] and r["regra"] not in scope_ids]
scopes = [r for r in rows if r["id"] and r["regra"] in scope_ids]
broken = [r for r in rows if r["ação"] == "fora"]
act = collections.Counter(r["ação"] for r in nodes)
review = [r for r in nodes if r["revisar"]]
refused = [r for r in nodes if r["revisar"].startswith("a proposta reprovaria no contrato")]
scope_review = [r for r in scopes if r["ação"] != "scope"]
per_rule = collections.Counter((r["regra"] or "(nenhuma regra)", r["ação"]) for r in nodes)
import json
# multiset dos dois lados: um id repetido no grafo é uma ocorrência por nó (a fase 1 o lê como 'nó X (#2)'), e o
# arquivo vem pelo caminho real dos dois lados (o migrador resolve symlink)
recs = [json.loads(x) for x in open(nodes_file, encoding="utf-8").read().splitlines() if x.strip()]
no_id = [r for r in recs if r["id"] is None]
debt = collections.Counter((r["file"], r["id"]) for r in recs if r["id"] is not None)
planned = collections.Counter((r["arquivo"], r["id"]) for r in nodes)
missing, extra = sorted((debt - planned).elements()), sorted((planned - debt).elements())
dup = {k for k, v in debt.items() if v > 1}
print(f"  {len(nodes)} nó(s) no plano: {act['provenance']} com provenance proposta · {act['unverifiable']} rebaixado(s) para "
      f"unverifiable · {act['review']} sem proposta (para revisão)")
print(f"  para revisão: {len(review)} nó(s) ({act['review']} sem proposta, {len(review) - act['review']} com ação e aviso) · "
      f"recusados pelo contrato: {len(refused)} · grafos fora (não parseiam): {len(broken)} · linhas de scope: {len(scopes)} "
      f"({len(scopes) - len(scope_review)} aplicáveis, {len(scope_review)} para revisão)")
print("  por regra:")
for (rule, a), v in sorted(per_rule.items(), key=lambda kv: (-kv[1], kv[0])):
    print(f"    {v:5d}  {rule} → {a}")
for r in refused[:5]:
    print(f"    recusado: {r['arquivo']} · {r['id']}: {r['revisar'][:160]}")
if not missing and not extra and not no_id:
    print(f"  o plano cobre, nó a nó, os {len(recs)} nó(s) que a medição do contrato acusou no MUST.")
else:
    print(f"  ⚠️ o plano e a medição do contrato divergem nó a nó: {len(missing) + len(no_id)} nó(s) da dívida MUST fora do plano, "
          f"{len(extra)} no plano fora da dívida.")
    for f, i in missing[:10]:
        why = ("vendor/** (o migrador sempre o exclui)" if f.startswith("vendor/")
               else "id repetido no grafo: a planilha tem menos linhas que ocorrências" if (f, i) in dup
               else "fora do universo do migrador (confirmed/PROD sem provenance) ou de um --exclude: outro código MUST")
        print(f"    fora do plano: {f} · {i} — {why}; o apply não o migra")
    for r in no_id[:10]:
        print(f"    fora do plano: {r['file']} · {r['place']} — nó sem id (o migrador só planeja nó com id)")
    for f, i in extra[:10]:
        print(f"    no plano sem estar na dívida: {f} · {i}")
PY
)" || no "a planilha ${SHEET} não se lê (PyYAML ausente ou TSV fora da forma)."
REL_PROFILE="${PROFILE#"${T}/"}"
echo "MIGRAÇÃO planejada (dry-run, kg_migrate.py plan do vendor do alvo, kg-ssot ${VERSION:-?}) com o perfil ${REL_PROFILE}:"
printf '%s\n' "${SUMMARY}"
echo "  planilha: ${SHEET}"
echo "  Nada rastreado nem não rastreado do alvo mudou (a foto não lê o conteúdo de arquivo ignorado). Aplicar é do dono do corpus, numa branch, na RAIZ do alvo e DEPOIS de revisar a planilha:"
printf '    python3 -I -B vendor/kg-ssot/tools/kg_migrate.py apply --profile %q' "${REL_PROFILE}"
printf ' --exclude %q' "${EXCL[@]:1:1}" "${EXCL[@]:3:1}" "${EXCL[@]:5:1}" "${EXCL[@]:7:1}"
printf '\n'
exit 0
