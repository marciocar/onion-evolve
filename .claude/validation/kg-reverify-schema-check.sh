#!/usr/bin/env bash
# kg-reverify-schema-check.sh — guarda estrutural do KgReverifySchema de /meta:kg-freshness.
#
# POR QUE ESTA GUARDA EXISTE (defeito medido em 2026-08-12, PR #584):
#   A primeira versão do schema declarava `required:` DUAS VEZES no mesmo objeto literal. Em
#   JavaScript a segunda SOBRESCREVE a primeira em silêncio — `method`, `observed`, `verdict` e
#   `blocked_by` deixaram de ser obrigatórios, e um retorno com apenas os três campos de cobertura
#   passava na validação. A guarda nasceu parcialmente verde-vazia.
#
#   E a ironia que precisa ficar escrita: o MESMO PR catalogava, no grafo, cinco nós com
#   `verified_at:` duplicado — a MESMA classe (chave repetida silenciosamente sobrescrita). O autor
#   nomeou a classe, curou as instâncias À MÃO, e reincidiu nela no arquivo seguinte do mesmo PR.
#   Cura one-off não se repete sozinha; é o que [[fix-must-become-mechanism]] afirma, demonstrado
#   contra o próprio autor da doutrina.
#
# POR QUE ELA NÃO VALIDA DOCUMENTOS:
#   Validar JSON Schema exigiria `ajv`, dependência nova num framework que é configuração pura
#   (não há `package.json` no repo). Mas a classe de defeito que de fato ocorreu é ESTRUTURAL —
#   chave duplicada, `if`/`then` sem `required` — e isso se mede sem validador nenhum.
#   Uma bancada com ajv provaria sobre ajv; o substrato real é o tool-layer do Workflow. Aqui se
#   mede o que é mensurável sem substrato: a FORMA do schema.
#
# O QUE ELA NÃO COBRE (teto declarado, não descuido):
#   Não prova que a semântica de validação faz o que se espera no substrato real. Isso só se mede
#   rodando /meta:kg-freshness e observando um worker ser rejeitado.
#
# Uso:  bash .claude/validation/kg-reverify-schema-check.sh [--selftest]
# Exit: 0 = conforme · 1 = violação HARD · 2 = erro de execução (nunca zero silencioso)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"
CMD="${ROOT}/.claude/commands/meta/kg-freshness.md"

VIOL=0
_viol() { printf 'VIOLATION: %s: [kg-reverify-schema/%s] %s\n' "${CMD#"${ROOT}/"}" "$1" "$2"; VIOL=$((VIOL + 1)); }

# Campos que o contrato do comando declara indispensáveis. Cada um paga por uma cláusula da spec:
# sem `method` o veredito é opinião; sem `observed` não há verbatim; sem `blocked_by` a GUARDA 1
# não tem o que restringir; sem os três de cobertura a GUARDA 2 não existe.
REQUIRED_FIELDS=(node_id kg_file method observed verdict divergence blocked_by
              claims_total claims_measured coverage)

_extrair_schema() {
  # Recorta o literal `const KgReverifySchema = { ... };` do markdown.
  awk '/^const KgReverifySchema = \{/{f=1} f{print} f&&/^\};/{exit}' "$1"
}

_check_file() {
  local target="$1"
  [ -r "${target}" ] || { echo "ERRO: não consigo ler ${target}" >&2; exit 2; }

  local schema
  schema="$(_extrair_schema "${target}")"
  [ -n "${schema}" ] || { _viol SCHEMA-AUSENTE "não achei o literal 'const KgReverifySchema = {' — o comando perdeu seu schema, ou ele mudou de nome"; return; }

  # (a) `required` duplicado no objeto RAIZ — o defeito que criou esta guarda.
  #     Conta ocorrências na indentação de topo (2 espaços), que é onde vive o required raiz.
  local n_root
  n_root="$(printf '%s\n' "${schema}" | grep -cE '^  required:' || true)"
  if [ "${n_root}" -gt 1 ]; then
    _viol REQUIRED-DUPLICADO "o objeto raiz declara 'required:' ${n_root} vezes — a última SOBRESCREVE as anteriores em silêncio e os campos das outras deixam de ser obrigatórios. Use UMA lista só."
  elif [ "${n_root}" -eq 0 ]; then
    _viol REQUIRED-AUSENTE "o objeto raiz não declara 'required:' — sem ele NENHUM campo é obrigatório e a guarda inteira é decorativa"
  fi

  # (b) todo campo indispensável está no bloco required raiz
  local req_block
  req_block="$(printf '%s\n' "${schema}" | awk '/^  required:/{f=1} f{print} f&&/\],?$/{exit}')"
  local field
  for field in "${REQUIRED_FIELDS[@]}"; do
    printf '%s' "${req_block}" | grep -q "\"${field}\"" \
      || _viol CAMPO-NAO-OBRIGATORIO "'${field}' não está no 'required' raiz — um worker que o OMITA passa na validação"
  done

  # (c) todo `if:` e todo `then:` das guardas condicionais declara `required:` DENTRO do seu escopo.
  #     JSON Schema aplica `properties` só a chaves PRESENTES: sem `required`, OMITIR o campo
  #     satisfaz a guarda. É como a GUARDA 1 furou na primeira versão.
  #     Escopo por chaves BALANCEADAS, não por linha — no arquivo real o `required:` da GUARDA 2
  #     mora na linha SEGUINTE ao `then: {`, e uma checagem por-linha o daria como ausente.
  local findings
  findings="$(printf '%s\n' "${schema}" | python3 -c '
import sys, re
src = sys.stdin.read()
# remove comentarios de linha para nao contar `if:` citado em prosa
src = "\n".join(re.sub(r"//.*$", "", l) for l in src.split("\n"))
problems = []
n = 0
for m in re.finditer(r"\b(if|then)\s*:\s*\{", src):
    n += 1
    kind = m.group(1)
    i = m.end() - 1          # posiciona na chave de abertura
    prof = 0
    for j in range(i, len(src)):
        if src[j] == "{": prof += 1
        elif src[j] == "}":
            prof -= 1
            if prof == 0: break
    body = src[i:j+1]
    if not re.search(r"\brequired\s*:", body):
        problems.append(kind)
print(n)
print(" ".join(problems))
')" || { echo "ERRO: python3 falhou ao analisar o schema" >&2; exit 2; }

  local n_cond missing
  n_cond="$(printf '%s\n' "${findings}" | sed -n 1p)"
  missing="$(printf '%s\n' "${findings}" | sed -n 2p)"

  if [ "${n_cond}" -eq 0 ]; then
    _viol GUARDA-AUSENTE "o schema não tem nenhuma condicional 'if:'/'then:' — as GUARDAS sumiram"
  fi

  # (d) FORMATO-RECUSADO-PELA-API — catraca nascida do 1º run real (2026-08-29): a API recusa
  #     `oneOf`/`allOf`/`anyOf` no TOPO do input_schema (400, medido 8/8 no run wf_6aa135ec-1e2),
  #     e este schema viveu 17 dias nessa forma com a guarda dizendo OK. A guarda agora recusa a
  #     forma que o substrato recusa. Só chave REAL conta (indentação de topo, 2 espaços) —
  #     comentário `//` citando o histórico não dispara.
  if printf '%s\n' "${schema}" | grep -qE '^  (allOf|anyOf|oneOf):'; then
    _viol FORMATO-RECUSADO-PELA-API "o schema usa allOf/anyOf/oneOf no TOPO — a API recusa essa forma (400, medido 2026-08-29) e as guardas nunca rodam. Use a cadeia if/then/else aninhada com raiz na COBERTURA (equivalência provada por tabela-verdade; raiz no verdict DIVERGE em 2 casos)"
  fi
  case " ${missing} " in
    *" if "*) _viol IF-SEM-REQUIRED "há bloco 'if:' sem 'required:' no escopo — um 'if' assim NÃO dispara quando a chave é OMITIDA, e a guarda vira verde-vazia para quem simplesmente não escreve o campo" ;;
  esac
  case " ${missing} " in
    *" then "*) _viol THEN-SEM-REQUIRED "há bloco 'then:' sem 'required:' no escopo — sem ele, OMITIR o campo satisfaz a guarda" ;;
  esac
}

# ── selftest: fixtures que provam que a guarda ACUSA, não só que ela passa ──────────────────────
# Regra da casa: teste que afirma AUSÊNCIA sobrevive à fixture morta; teste que afirma PRESENÇA
# morre junto com ela. Por isso cada caso abaixo checa o TEXTO da acusação, não só o exit.
if [ "${1:-}" = "--selftest" ]; then
  TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
  failures=0
  _case() { # nome · conteúdo · padrão esperado na saída ("" = espera saída limpa)
    local name="$1" body="$2" expected="$3" output rc
    printf '%s\n' "${body}" > "${TMP}/c.md"
    output="$(CMD="${TMP}/c.md" _check_file "${TMP}/c.md" 2>&1)" && rc=0 || rc=$?
    if [ -n "${expected}" ]; then
      if printf '%s' "${output}" | grep -q "${expected}"; then echo "  ✓ acusa: ${name}"
      else echo "  ✗ NÃO acusou: ${name} (esperava ${expected})"; failures=$((failures + 1)); fi
    else
      if [ -z "${output}" ]; then echo "  ✓ passa limpo: ${name}"
      else echo "  ✗ falso-positivo: ${name} -> ${output}"; failures=$((failures + 1)); fi
    fi
    VIOL=0
  }

  # A fixture BOM espelha a FORMA CANÔNICA REAL (cadeia aninhada, raiz na cobertura) — até
  # 2026-08-29 ela canonizava o `allOf` que a API recusa, e a bancada validava um formato morto.
  BOM='const KgReverifySchema = {
  type: "object",
  required: ["node_id", "kg_file", "method", "observed", "verdict", "divergence", "blocked_by",
             "claims_total", "claims_measured", "coverage"],
  properties: { node_id: { type: "string" } },
  if: { required: ["coverage"], properties: { coverage: { const: "PARCIAL" } } },
  then: { required: ["verdict", "blocked_by"], properties: {} },
  else: {
    if: { required: ["verdict"], properties: { verdict: { const: "UNVERIFIABLE" } } },
    then: { required: ["blocked_by"], properties: {} },
    else: { required: ["blocked_by"], properties: {} },
  },
};'
  # a forma MORTA (allOf no topo), preservada como caso de acusação da catraca nova
  MORTO='const KgReverifySchema = {
  type: "object",
  required: ["node_id", "kg_file", "method", "observed", "verdict", "divergence", "blocked_by",
             "claims_total", "claims_measured", "coverage"],
  properties: { node_id: { type: "string" } },
  allOf: [
    { if: { required: ["verdict"], properties: {} },
      then: { required: ["blocked_by"], properties: {} } },
  ],
};'
  # o DEFEITO REAL de 2026-08-12, preservado como caso de aceite
  DUP="${BOM/\  properties: \{ node_id/  required: [\"claims_total\"],
  properties: { node_id}"

  echo "── selftest kg-reverify-schema-check ──"
  _case "schema conforme"                    "${BOM}" ""
  _case "required duplicado (defeito 08-12)" "${DUP}" "REQUIRED-DUPLICADO"
  _case "campo fora do required"             "${BOM/\"method\", /}" "CAMPO-NAO-OBRIGATORIO"
  _case "then sem required"                  "${BOM/then: \{ required: \[\"blocked_by\"\], /then: \{ }" "THEN-SEM-REQUIRED"
  _case "if sem required"                    "${BOM/if: \{ required: \[\"verdict\"\], /if: \{ }" "IF-SEM-REQUIRED"
  _case "schema sumiu do comando"            "# comando sem schema nenhum" "SCHEMA-AUSENTE"
  _case "allOf no topo (forma que a API recusa)" "${MORTO}" "FORMATO-RECUSADO-PELA-API"

  if [ "${failures}" -gt 0 ]; then echo "${failures} caso(s) falharam"; exit 1; fi
  echo "7/7 — a guarda acusa o que deve e passa o que deve"
  exit 0
fi

_check_file "${CMD}"
if [ "${VIOL}" -gt 0 ]; then exit 1; fi
echo "OK ✓ KgReverifySchema estruturalmente conforme (required único, ${#REQUIRED_FIELDS[@]} campos obrigatórios, if/then ancorados)"
exit 0
