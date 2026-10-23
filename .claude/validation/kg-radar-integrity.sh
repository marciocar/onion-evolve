#!/usr/bin/env bash
# kg-radar-integrity.sh — REGRA 52: todo .kg.yaml do repo passa no radar de INTEGRIDADE.
#
# A PERGUNTA: os grafos do repo estão estruturalmente SÃOS **hoje** — todos eles, não só
# os que alguém tocou?
#
# ═══ POR QUE EXISTE (a lacuna medida em 2026-08-03) ═══
# O `kg-radar.sh` é o motor soberano dos grafos e o ÚNICO mecanismo que reprova CONTRADIÇÃO
# ESTRUTURAL (`--integrity`, exit 1): nó que recebe `REFUTES` e segue `status: confirmed`.
# E **nada o executava por cadência** — nem lint, nem CI, nem pre-commit.
#
# Ele chegava ao CI apenas de duas formas INDIRETAS e parciais:
#   · REGRA 43 (kg-born-marker) — só para os grafos que ALGUM doc cita em `kg:` no frontmatter;
#   · REGRA 31 (kg-view) — só para os grafos que têm lente gerada.
# Logo: um grafo que ninguém cita em migalha e que não tem lente NUNCA era verificado.
#
# ═══ A RULE JÁ CONVOCAVA — E POR QUE ISSO NÃO BASTA ═══
# `.claude/rules/kg-grammar.md:41` já manda `bash kg-radar.sh <arquivo> # exit 0 obrigatório`.
# Essa regra path-scoped é CERTA no propósito dela (ensinar a gramática ANTES de escrever, para
# a guarda não nascer verde-vazia), mas estruturalmente não pode dar três coisas:
#   (a) só carrega quando alguém TOCA um `.kg.yaml` — grafo não-tocado fica fora;
#   (b) depende do ator OBEDECER — o eixo que o corpus desta casa mediu falhando
#       (`posttooluse-exit-2-is-the-only-channel`, `shell-guard-paid-four-times-same-axis`);
#   (c) não pega DEGRADAÇÃO PASSIVA: um `REFUTES` que chega depois deixa o nó alvo em
#       contradição SEM QUE NINGUÉM EDITE o arquivo — nenhuma rule dispara aí.
# Este gate é a mesma convocação, promovida de cognitiva a MECÂNICA e desacoplada do ator.
#
# ═══ SEM CATRACA, E ISSO É UMA MEDIÇÃO, NÃO UM DESCUIDO ═══
# Medido em 2026-08-03: 51 grafos no escopo, **0 reprovam** `--integrity`. Não há passivo a
# tolerar, então a regra nasce LIMPA — qualquer regressão futura reprova na hora.
# A medição foi provada NÃO-VAZIA (o erro que a kg-grammar.md existe para prevenir): um grafo
# de teste com `REFUTES` sobre nó `confirmed` sai 1 com "✗ CONTRADIÇÃO"; fixture sã sai 0.
# Se um dia o passivo aparecer, o padrão da casa é baseline versionado (REGRAS 29/42/45/49).
#
# ═══ O QUE FAZ, E O QUE NÃO FAZ (limite honesto) ═══
# FAZ: reprova contradição ESTRUTURAL — a única classe que um script decide sozinho.
# NÃO FAZ: não julga se um `label` é VERDADE, nem se um `verified_at` é honesto. Isso é da
#          REGRA 49 (cadência de carimbo) e do `/meta:kg-freshness` (mede contra o vivo).
#          Mesma divisão declarada lá: o GATE cria a cadência, o WORKER testa a verdade.
#
# Descoberta dos grafos: `git ls-files '*.kg.yaml'` filtrado pelo predicado ÚNICO
# `kg-fixture-paths.sh --filter` — a forma canônica (`.claude/rules/kg-grammar.md`); o glob
# hardcoded que existia antes era 36% cego.
# FIXTURE fica FORA por desenho: lá vivem grafos propositalmente inválidos que alimentam o teste
# — gateá-los reprovaria o repo por TER testes. E a isenção deixou de ser um `grep -v '/fixtures/'`
# copiado em seis lugares: um adotante que portou o radar para JS pôs as fixtures em
# `packages/kg/src/__fixtures__/` (convenção Vitest), o grep não casou, e os 5 grafos inválidos
# viraram 5 HARD no dia 1 da adoção dele (medido 2026-09-05). O predicado cobre a CLASSE de
# convenções e é auditável por `--list-exempt` — isenção em massa não passa calada.
#
# ⚠ PONTO CEGO DECLARADO (achado na revisão de 2026-08-03): `git ls-files` só vê o RASTREADO.
# Um `.kg.yaml` recém-criado e ainda não commitado — o estado exato de uma investigação nova —
# é invisível a este gate. A irmã REGRA 29 usa `find` e por isso pega untracked (foi assim que
# ela flagrou um documento de análise minutos após ele nascer). Não trocamos aqui de propósito:
# o alvo desta regra é o ACERVO do repo, e o pre-commit roda depois do `git add`. Se o gap
# doer, a cura é `find` + filtro de `.git/`, não um segundo gate.
#
# Uso : bash .claude/validation/kg-radar-integrity.sh [<repo_root>] [--format tsv]
# TSV : sev<TAB>tag<TAB>path<TAB>msg   (mesmo contrato dos irmãos: 29, 42, 45, 49)
# Exit: 0 = sem HARD · 1 = HARD presente · 2 = erro de uso
set -uo pipefail

# Predicado de FIXTURE — caminho ABSOLUTO resolvido ANTES de qualquer `cd`, e ausência é FAIL-CLOSED.
# (A 1ª ligação usava `$(dirname "${BASH_SOURCE[0]}")` no ponto de uso e morria depois de um `cd`:
#  o erro era engolido por `|| true` e o script dizia "nenhum grafo" — verde por vacuidade. 2026-09-05.)
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "ERRO: predicado de fixture ausente (${_KFP}) — sem ele a varredura de grafos ficaria VAZIA e verde por vacuidade." >&2; exit 2; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FMT=human
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FMT="${2:-human}"; shift ;;
    -*)       printf 'uso: %s [<repo_root>] [--format tsv]\n' "$0" >&2; exit 2 ;;
    *)        [ -d "$1" ] && REPO_ROOT="$(cd "$1" && pwd)" ;;
  esac
  shift
done

RADAR="${REPO_ROOT}/.claude/validation/kg-radar.sh"

emit() { # $1=sev $2=tag $3=path $4=msg
  if [ "${FMT}" = "tsv" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  elif [ "$1" = "HARD" ]; then  printf 'VIOLATION: %s: [kg-integridade/%s] %s\n' "$3" "$2" "$4"
  else                          printf 'SOFT: %s: [kg-integridade/%s] %s\n' "$3" "$2" "$4"; fi
}

cd "${REPO_ROOT}" || exit 2

# Sem o radar não há o que delegar — no-op gracioso (contrato dos irmãos: helper ausente não
# inventa veredito). Declarar que não sabe é o comportamento correto.
[ -f "${RADAR}" ] || exit 0

hard=0; total=0; proposta=0; fora=0

# ══ INTEGRIDADE CONSUMIDA DO CONTRATO (D_RADAR_CONSOME_INTEGRIDADE_DO_CONTRATO_1023) ══════════════
# A forma e a integridade do grafo são do contrato KG-SSOT; este gate não as reimplementa quando o
# leitor de referência está vendorizado. UMA chamada do `kg_validate.py --format json` sobre o corpus
# inteiro (medido em 2026-10-23: 187 grafos em ~9 s, contra ~75 s do laço de um radar por grafo) e o
# veredito sai dos CÓDIGOS, nunca da prosa. Mapa medido, defeito a defeito, contra o radar:
#   · DUPLICADAS (vêm do contrato, MUST): id repetido, chave repetida, aresta solta (from/to/trigger),
#     ponta local de external_edges, nó órfão, edge_type, node_type, plane, layer, status, impact,
#     confidence, alfabeto do id;
#   · MAIS RÍGIDA NA CASA (catraca: nada afrouxa): REFUTES sobre alvo pendente é SHOULD no contrato
#     (integrity.refutes-unreconciled) e HARD aqui — escalada;
#   · MAIS FROUXA NA CASA, de propósito: `on:` legado e `valid_from` inteiro são MUST no contrato e só
#     AVISO aqui (os adotantes carregam o passivo) — viram SOFT, nunca HARD;
#   · DA CASA, sem par no contrato: o MODO PROPOSTA (grau 0 e referência para fora relaxados num
#     fragmento) — aplicado aqui por cima dos códigos.
# Arquivo que o contrato não PARSEIA (parse.*) não foi julgado no resto: vai para o radar próprio.
# Sem o leitor (plugin sem vendor, python3 ausente, rc fora de 0/1 ou JSON ilegível), o laço antigo
# de um radar por grafo segue inteiro — a mesma régua de antes, declarada, nunca verde por ausência.
VAL="${ONION_KG_INTEGRITY_VALIDATOR:-${REPO_ROOT}/vendor/kg-ssot/tools/kg_validate.py}"
GRAPHS="$(git ls-files '*.kg.yaml' | bash "${_KFP}" --filter)"
CONTRACT_TSV=""
if [ -n "${GRAPHS}" ] && [ -f "${VAL}" ] && command -v python3 >/dev/null 2>&1; then
  _ct="$(mktemp -d)"; trap 'rm -rf "${_ct}"' EXIT
  _vrc=0
  # shellcheck disable=SC2086
  python3 -I -B "${VAL}" --format json -- ${GRAPHS} >"${_ct}/v.json" 2>"${_ct}/v.err" || _vrc=$?
  if [ "${_vrc}" -eq 0 ] || [ "${_vrc}" -eq 1 ]; then
    _trc=0
    python3 -I -B - "${_ct}/v.json" "${_ct}/out.tsv" <<'PY' || _trc=$?
import json, re, sys
src, out = sys.argv[1], sys.argv[2]
HARD_MUST = {
    "integrity.duplicate-id", "parse.duplicate-key", "integrity.dangling-from", "integrity.dangling-to",
    "integrity.dangling-trigger", "integrity.dangling-external-local", "integrity.orphan-node",
    "form.enum.edge.edge_type", "form.enum.top.external_edges.edge_type", "form.enum.node.node_type",
    "form.enum.node.plane", "form.enum.node.layer", "form.enum.node.status", "form.range.node.impact",
    "form.range.node.confidence", "form.pattern.node.id", "form.pattern.edge.from", "form.pattern.edge.to",
}
RELAXABLE = {"integrity.orphan-node", "integrity.dangling-from", "integrity.dangling-to",
             "integrity.dangling-trigger", "integrity.dangling-external-local"}
ESCALATE = {"integrity.refutes-unreconciled"}
SOFT_MAP = {"yaml.forbidden-key-on": "ON-LEGADO", "form.type.node.valid_from": "VALID-FROM-INTEIRO"}
rep = json.load(open(src, encoding="utf-8"))
if not isinstance(rep, dict) or rep.get("schema_version") != "kg-ssot.verdict/1":
    sys.exit(3)
clean = lambda v: str(v).replace("\t", " ").replace("\n", " ")
rows = []
for r in rep["results"]:
    path = r["source"]
    occ = r.get("occurrences", [])
    if r.get("truncated"):
        rows.append(("RADAR", path, "veredito truncado"))
        continue
    if any(str(o.get("code", "")).startswith("parse.") and o.get("code") != "parse.duplicate-key" for o in occ):
        rows.append(("RADAR", path, "o contrato não parseou o arquivo"))
        continue
    text = open(path, encoding="utf-8").read()
    proposal = path.endswith(".proposal.kg.yaml") or re.search(r"(?m)^  target:[ \t]*\S", text) is not None
    hard, relaxed, soft = [], 0, {}
    for o in occ:
        code, lvl = str(o.get("code", "")), o.get("level")
        if code in SOFT_MAP:
            soft[SOFT_MAP[code]] = soft.get(SOFT_MAP[code], 0) + 1
        elif (lvl == "MUST" and code in HARD_MUST) or code in ESCALATE:
            if proposal and code in RELAXABLE:
                relaxed += 1
            else:
                hard.append("%s (%s)" % (code, clean(o.get("place", o.get("path", "")))))
    if hard:
        rows.append(("HARD", path, "; ".join(hard[:2]) + (" …+%d" % (len(hard) - 2) if len(hard) > 2 else "")))
    elif proposal:
        rows.append(("PROPOSTA", path, "%d referência(s) de grafo fechado relaxada(s) pelo contrato" % relaxed))
    else:
        rows.append(("OK", path, ""))
    for tag, n in soft.items():
        rows.append((tag, path, str(n)))
with open(out, "w", encoding="utf-8") as fh:
    fh.write("".join("\t".join(x) + "\n" for x in rows))
PY
    [ "${_trc}" -eq 0 ] && [ -f "${_ct}/out.tsv" ] && CONTRACT_TSV="${_ct}/out.tsv"
  fi
fi

if [ -n "${CONTRACT_TSV}" ]; then
  RADAR_LIST=""
  while IFS=$'\t' read -r kind g msg; do
    [ -n "${kind}" ] || continue
    case "${kind}" in
      OK) total=$(( total + 1 )) ;;
      HARD)
        total=$(( total + 1 ))
        emit HARD CONTRADICAO "${g}" "grafo REPROVA na integridade do contrato KG-SSOT — reconcilie antes de seguir: ${msg} (detalhe: python3 -I -B vendor/kg-ssot/tools/kg_validate.py ${g})"
        hard=$(( hard + 1 )) ;;
      PROPOSTA)
        total=$(( total + 1 )); proposta=$(( proposta + 1 ))
        case "${g}" in *docs/evolution/kg-inbox/*) continue ;; esac
        fora=$(( fora + 1 ))
        emit SOFT MODO-PROPOSTA "${g}" "grafo passou em MODO PROPOSTA — grau 0 e referência para fora do arquivo NÃO foram cobrados aqui (${msg}). Isto é legítimo num fragmento da fila de propostas e SUSPEITO em qualquer outro lugar: o gate do grafo fechado é a SELAGEM" ;;
      VALID-FROM-INTEIRO)
        emit SOFT VALID-FROM-INTEIRO "${g}" "${msg} nó(s) com valid_from inteiro sem aspas (ex.: valid_from: 2026) — leitor YAML tipado lê NÚMERO, não data parcial; escreva \"2026\"" ;;
      ON-LEGADO)
        emit SOFT ON-LEGADO "${g}" "${msg} aresta(s) TRANSITIONS com a chave on: (legado) — YAML 1.1 lê on como booleano e o evento parece órfão para leitor tipado; renomeie para trigger:" ;;
      RADAR) RADAR_LIST="${RADAR_LIST}${g}"$'\n' ;;
    esac
  done < "${CONTRACT_TSV}"
  GRAPHS="${RADAR_LIST}"
  [ "${FMT}" != "tsv" ] && printf '  [kg-integridade] integridade lida do contrato KG-SSOT (%s)\n' "$(basename "$(dirname "$(dirname "${VAL}")")")"
else
  [ "${FMT}" != "tsv" ] && [ -n "${GRAPHS}" ] && printf '  [kg-integridade] leitor do contrato indisponível (%s): integridade pelo radar próprio, grafo a grafo\n' "${VAL}"
fi

while IFS= read -r g; do
  [ -n "${g}" ] || continue
  total=$(( total + 1 ))
  # A saída do radar é para o humano; aqui só o EXIT decide. Capturamos a linha da contradição
  # para a mensagem ser acionável (num grafo grande, "o arquivo tem problema" é inacionável).
  out="$(bash "${RADAR}" "${g}" --integrity 2>&1)"
  rc=$?
  if [ "${rc}" -ne 0 ]; then
    detalhe="$(printf '%s\n' "${out}" | grep -E '✗|CONTRADI' | head -2 | tr '\n' ' ' | sed 's/  */ /g')"
    emit HARD CONTRADICAO "${g}" \
      "grafo REPROVA no radar de integridade (exit ${rc}) — reconcilie antes de seguir: ${detalhe:-<sem detalhe; rode: bash .claude/validation/kg-radar.sh ${g} --integrity>}"
    hard=$(( hard + 1 ))
  elif grep -q 'MODO PROPOSTA' <<< "${out}"; then
    # ⚠️ RELAXAMENTO NÃO PODE DESAPARECER AQUI. Achado adversarial 2026-09-11: o `kg-radar.sh`
    #    declara no código que o MODO PROPOSTA "nunca é silencioso" — e era, exatamente neste
    #    gate, que é o único que roda por CADÊNCIA. Como o modo sai rc=0, o `out` era descartado
    #    e este laço imprimia "sem contradicao estrutural em nenhum grafo do repo" sobre um
    #    grafo com duas cobranças DESLIGADAS por auto-declaração do próprio arquivo.
    #    É o ✅ inventado que esta onda persegue, uma camada acima — e num gate de cadência ele
    #    dura até alguém desconfiar, que é a definição de invisível.
    proposta=$(( proposta + 1 ))
    # ESCOPO: dentro da fila de propostas o relaxamento É o contrato documentado, e avisar a cada
    # rodada é ruído que treina a pessoa a ignorar o aviso — o oposto do que esta cura quer. Lá o
    # grafo é CONTADO (o resumo abaixo o mostra) mas não gera linha. FORA da fila, cada um é
    # nomeado: é ali que o relaxamento não deveria estar acontecendo.
    case "${g}" in
      *docs/evolution/kg-inbox/*) continue ;;
    esac
    fora=$(( fora + 1 ))
    emit SOFT MODO-PROPOSTA "${g}" \
      "grafo passou em MODO PROPOSTA — grau 0 e referência para fora do arquivo NÃO foram cobrados aqui ($(sed -n 's/^[[:space:]]*ℹ[[:space:]]*\(relaxado pelo MODO PROPOSTA.*\)/\1/p' <<< "${out}" | head -1 || true)). Isto é legítimo num fragmento da fila de propostas e SUSPEITO em qualquer outro lugar: o gate do grafo fechado é a SELAGEM"
  fi
  # `valid_from` inteiro nu: o radar só AVISA (os adotantes carregam passivo); aqui o aviso vira
  # SOFT para não morrer na saída humana de um modo que o lint descarta. Um SOFT por grafo, contado.
  vfi="$(grep -c 'VALID-FROM-INTEIRO' <<< "${out}" || true)"
  if [ "${vfi:-0}" -gt 0 ]; then
    emit SOFT VALID-FROM-INTEIRO "${g}" \
      "${vfi} nó(s) com valid_from inteiro sem aspas (ex.: valid_from: 2026) — leitor YAML tipado lê NÚMERO, não data parcial; escreva \"2026\""
  fi
  # `on:` legado como gatilho de TRANSITIONS: o radar lê e avisa; aqui vira SOFT nomeando o arquivo.
  onl="$(grep -c 'ON-LEGADO' <<< "${out}" || true)"
  if [ "${onl:-0}" -gt 0 ]; then
    emit SOFT ON-LEGADO "${g}" \
      "${onl} aresta(s) TRANSITIONS com a chave on: (legado) — YAML 1.1 lê on como booleano e o evento parece órfão para leitor tipado; renomeie para trigger:"
  fi
# ⚠️ A isenção de FIXTURE vem do predicado ÚNICO kg-fixture-paths.sh (2026-09-05): antes cada
#    consumidor repetia `grep -v '/fixtures/'` e o `__fixtures__/` do Vitest ESCAPAVA — 5 grafos
#    deliberadamente inválidos de um adotante viraram 5 HARD no dia 1 da adoção dele.
done <<< "${GRAPHS}"

if [ "${FMT}" != "tsv" ]; then
  printf '  [kg-integridade] grafos verificados: %s · reprovando: %s\n' "${total}" "${hard}"
  if [ "${proposta}" -gt 0 ]; then
    printf '  [kg-integridade] %s grafo(s) em MODO PROPOSTA (%s fora da fila kg-inbox) — cobranças de grafo FECHADO relaxadas ali.\n' "${proposta}" "${fora}"
  fi
  if [ "${hard}" -eq 0 ]; then
    if [ "${proposta}" -gt 0 ]; then
      # O resumo NAO pode dizer "nenhum" quando houve relaxamento: seria a mesma frase para dois
      # fatos diferentes, e quem le o gate por cadencia so ve a frase.
      printf '  [kg-integridade] sem contradicao estrutural nos grafos COBRADOS (ver os em MODO PROPOSTA acima).\n'
    else
      printf '  [kg-integridade] sem contradicao estrutural em nenhum grafo do repo.\n'
    fi
  fi
fi

[ "${hard}" -eq 0 ]
