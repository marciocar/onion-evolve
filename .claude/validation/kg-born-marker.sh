#!/usr/bin/env bash
# =============================================================================
# kg-born-marker.sh — GATE DE INTEGRIDADE DO MARCADOR kg: (proveniência virada p/ DENTRO)
#
# LIMITE   : este gate NÃO detecta investigação que nasceu FORA do grafo e não deixou
#            rastro — isso é estruturalmente indetectável (a investigação pode não
#            tocar o repo). Ele NÃO força o nascimento; garante a INTEGRIDADE do que
#            se DECLARA. Quem declara `kg:` no frontmatter APONTA para um grafo real e
#            são; quem não declara NÃO é violação (a mesma honestidade que o Nível B da
#            REGRA 42 tem sobre a rede lexical). O nascimento de fato é disciplina +
#            default-path (a FASE write(KG) canônica no template da onion-orchestration),
#            NÃO este gate. Não leia "sem kg:" como "não nasceu no grafo" — leia como
#            "não declarou, e o gate não tem como saber".
#
# Propósito : Irmão INTERNO da REGRA 29 (kg-provenance-coverage.sh). A 29 pergunta, de
#             FORA do grafo p/ dentro: "este RELATÓRIO existe no grafo?" (algum nó o
#             cita). Esta pergunta é de DENTRO da migalha/doc p/ o grafo: "o grafo que
#             esta migalha DECLARA ter nascido dela é REAL e passa no radar?". A 29
#             cobre proveniência por COBERTURA (citação); esta cobre proveniência por
#             MARCADOR (o `kg:` autodeclarado). Não é duplicata: a 29 varre .kg.yaml→doc;
#             esta varre doc→.kg.yaml, e valida o alvo no radar.
#
# Origem de campo (memória do maestro 2026-07-23, "radar sub-usado"): o passo write(KG)
#             da skill onion-orchestration era ADVICE — e advice-que-depende-de-lembrar
#             FALHOU de novo. Uma sessão correu 8 passadas do contrato de inferência
#             (Elenxo) e a saída EVAPOROU em prosa; só virou grafo DEPOIS, à mão
#             (docs/onion/graph/inference-contract-audit-2026-07.kg.yaml), quando o radar
#             então reconstruiu a escada inteira + a tese-núcleo por peso. O radar é
#             RUNTIME, não lint ocasional — e estava SUB-USADO. Este gate é a perna
#             estrutural da correção em camadas: o marcador `kg:` é o PRESSUPOSTO, e o
#             gate o PROVA (pendurado/quebrado/radar-falha → HARD, com mutation test).
#
# ---------------------------------------------------------------------------
# POR QUE NÃO HÁ CATRACA/BASELINE (e por que isso é CORRETO, não frouxidão)
# ---------------------------------------------------------------------------
#   A REGRA 29 precisa de catraca porque cobra AUSÊNCIA (doc sem nó = violação): sem
#   baseline ela reprovaria dezenas de arquivos legados no 1º dia e seria desligada —
#   foi o erro da catraca que a 29 documenta. AQUI é o oposto: a AUSÊNCIA do marcador
#   `kg:` NÃO é violação. As ~72 migalhas existentes NÃO declaram `kg:` hoje — e por
#   isso o gate nasce SILENCIOSO, sem retro-reprovar ninguém. Só o `kg:` DECLARADO-mas-
#   inválido reprova. `missing != violation` ⇒ não há passivo a tolerar ⇒ não há
#   baseline nem catraca a manter. (Esta é a distinção load-bearing da tarefa: pôr
#   baseline aqui seria repetir o erro que a 29 existe para não repetir.)
#
# ---------------------------------------------------------------------------
# ESCOPO — onde um marcador kg: é ESPERADO (migalha epistêmica + doc de achado)
# ---------------------------------------------------------------------------
#   VARRE (não-recursivo salvo indicado):
#     · .claude/diary/*.md              — migalhas epistêmicas (/meta:diary)
#     · docs/analysis/*.md              — docs de achado (não-recursivo)
#     · docs/evolution/research/**/*.md — SYNTHESIS + frentes (recursivo)
#   Em CADA arquivo, procura o campo de frontmatter `kg:`. Arquivo SEM `kg:` é
#   IGNORADO — não é violação (ver bloco acima). O gate NÃO filtra por `type:`: se um
#   arquivo qualquer do escopo DECLARA `kg:`, o marcador é cobrado. (A pergunta guiada
#   sobre QUANDO declarar — tipos decision/error/learning/reflection — vive no
#   /meta:diary create, camada 3 do mecanismo; este gate só valida o que se declara.)
#
# ---------------------------------------------------------------------------
# O QUE O GATE PROVA, para cada kg: DECLARADO (qualquer NÃO ⇒ HARD)
# ---------------------------------------------------------------------------
#   (a) o path EXISTE?                         não → HARD [MISSING-PATH] (pendurado)
#   (b) é um arquivo .kg.yaml?                 não → HARD [NOT-KG]
#   (c) passa kg-radar --integrity E --schema? não → HARD [RADAR-FAIL] (integridade/schema)
#   (marcador presente mas VAZIO)              →     HARD [EMPTY] (declarado sem alvo)
#   A mensagem sempre diz QUAL condição falhou.
#
# ---------------------------------------------------------------------------
# CI-SAFE — DECIDIDO SÓ COM O REPO + kg-radar local (ZERO rede)
# ---------------------------------------------------------------------------
#   Todos os insumos são internos: os arquivos do escopo, o path que o `kg:` aponta
#   (repo-relativo) e o radar determinístico (shell/awk puro, sem LLM, sem rede). Um
#   clone limpo num runner de CI produz o mesmo veredito que a máquina do maestro. Sem
#   TTL/relógio (não há eixo temporal aqui — é integridade estrutural).
#
# Uso       : kg-born-marker.sh [REPO_DIR] [opções]
#     --format text|tsv   text (default, pt-BR) | tsv (SEV\tTAG\tPATH\tMSG)
#     --summary           acrescenta a linha de contagens
#
# Exit codes: 0 = nenhuma violação HARD · 1 = ao menos uma HARD ·
#             2 = erro de uso · 0 com aviso (stderr) = degrade gracioso (radar ausente)
#
# Determinístico, sem LLM. Consumido pela REGRA 43 do lint-artifacts.sh e coberto pelo
# lint-selftest.sh (fixtures em mktemp: kg: válido→passa; pendurado/não-grafo/radar-
# reprova→HARD; sem kg:→passa; + mutation test da severidade HARD). Acompanha
# .claude/validation/ nos repos adotados.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADAR="${SCRIPT_DIR}/kg-radar.sh"

REPO_DIR=""
FORMAT="text"
SUMMARY=0

usage() {
  printf 'Uso: kg-born-marker.sh [REPO_DIR] [--format text|tsv] [--summary]\n' >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --format)   [ $# -ge 2 ] || { printf '❌ --format exige text|tsv.\n' >&2; exit 2; }; FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --summary)  SUMMARY=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)
      if [ -z "${REPO_DIR}" ]; then REPO_DIR="$1"; else
        printf '❌ kg-born-marker: argumento inesperado "%s".\n' "$1" >&2; exit 2
      fi
      shift ;;
  esac
done

case "${FORMAT}" in text|tsv) ;; *) printf '❌ --format inválido: %s\n' "${FORMAT}" >&2; exit 2 ;; esac

REPO_DIR="${REPO_DIR:-.}"
if [ ! -d "${REPO_DIR}" ]; then
  printf '⚠️  kg-born-marker: "%s" não é um diretório — nada a avaliar.\n' "${REPO_DIR}" >&2
  exit 0
fi
REPO_DIR="$(cd "${REPO_DIR}" && pwd)"

# --- Degrade gracioso: sem o radar, (c) não é verificável -----------------------
# NÃO libera tudo: (a) existe e (b) é .kg.yaml continuam valendo (estruturais, sem
# radar). Só a checagem de integridade/schema fica suspensa, com AVISO em stderr —
# nunca sair verde em silêncio (o no-op silencioso é o modo de falha que esta casa
# mais paga).
RADAR_OK=1
if [ ! -f "${RADAR}" ]; then
  RADAR_OK=0
  printf '⚠️  kg-born-marker: kg-radar.sh ausente (%s) — checagem de integridade/schema SUSPENSA; existência e extensão seguem valendo.\n' "${RADAR}" >&2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

HARD=0
: > "${TMP}/out"

# say SEV TAG PATH MSG — TAG existe para o consumidor (lint) poder rotular a classe.
say() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${TMP}/out"
  [ "$1" = "HARD" ] && HARD=$((HARD + 1)) || true
}

# ---------------------------------------------------------------------------
# extract_kg <arquivo-abs> — emite uma linha por campo `kg:` do FRONTMATTER.
#   Formato: '@<valor>' (o '@' é sentinela: distingue "kg: vazio" [linha só '@'] de
#   "sem kg:" [nenhuma linha]). Só o frontmatter (entre o 1º '---' e o próximo '---');
#   se a linha 1 não é '---', não há frontmatter → nada a emitir.
# ---------------------------------------------------------------------------
extract_kg() {
  awk '
    NR==1 && $0 !~ /^---[[:space:]]*$/ { exit }   # sem frontmatter
    NR==1 { next }
    /^---[[:space:]]*$/ { exit }                  # fim do frontmatter
    /^kg:[[:space:]]*/ {
      v=$0; sub(/^kg:[[:space:]]*/,"",v)
      sub(/[[:space:]]+#.*$/,"",v)                # comentário inline (só após espaço)
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",v)
      gsub(/^"|"$/,"",v); gsub(/^'\''|'\''$/,"",v)
      print "@" v
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# ESCOPO — coleta os arquivos onde um marcador kg: é esperado
# ---------------------------------------------------------------------------
: > "${TMP}/files"
[ -d "${REPO_DIR}/.claude/diary" ] && \
  find "${REPO_DIR}/.claude/diary" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort >> "${TMP}/files"
[ -d "${REPO_DIR}/docs/analysis" ] && \
  find "${REPO_DIR}/docs/analysis" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort >> "${TMP}/files"
[ -d "${REPO_DIR}/docs/evolution/research" ] && \
  find "${REPO_DIR}/docs/evolution/research" -type f -name '*.md' 2>/dev/null | sort >> "${TMP}/files"

# ---------------------------------------------------------------------------
# VALIDAÇÃO — para cada arquivo, cada marcador kg: declarado é PROVADO
# ---------------------------------------------------------------------------
while IFS= read -r abs; do
  [ -n "${abs}" ] || continue
  rel="${abs#${REPO_DIR}/}"

  # Um arquivo pode (teoricamente) declarar mais de um kg:; cada um é cobrado.
  while IFS= read -r marker; do
    [ -n "${marker}" ] || continue    # sem kg: → nenhuma linha → nada a fazer
    val="${marker#@}"

    # (marcador vazio) — declarado sem alvo.
    if [ -z "${val}" ]; then
      say "HARD" "EMPTY" "${rel}" "campo kg: DECLARADO mas VAZIO — aponte para o .kg.yaml onde a investigação nasceu, ou remova o campo"
      continue
    fi

    # Normaliza o path do marcador (repo-relativo; aceita absoluto e ./).
    case "${val}" in
      /*) tgt_abs="${val}" ;;
      *)  tgt_abs="${REPO_DIR}/${val#./}" ;;
    esac
    tgt_rel="${tgt_abs#${REPO_DIR}/}"

    # (a) o path EXISTE?
    if [ ! -e "${tgt_abs}" ]; then
      say "HARD" "MISSING-PATH" "${rel}" "kg: '${val}' PENDURADO — o path não existe no repo. Aponte para um .kg.yaml real"
      continue
    fi

    # (b) é um arquivo .kg.yaml?
    case "${tgt_abs}" in
      *.kg.yaml) [ -f "${tgt_abs}" ] || { say "HARD" "NOT-KG" "${rel}" "kg: '${val}' não é um ARQUIVO regular (.kg.yaml)"; continue; } ;;
      *) say "HARD" "NOT-KG" "${rel}" "kg: '${val}' não é um .kg.yaml — o marcador tem de apontar para o GRAFO da investigação"; continue ;;
    esac

    # (c) passa kg-radar --integrity E --schema (exit 0)?
    if [ "${RADAR_OK}" -eq 1 ]; then
      if ! bash "${RADAR}" "${tgt_abs}" --integrity >/dev/null 2>&1; then
        say "HARD" "RADAR-FAIL" "${rel}" "kg: '${tgt_rel}' REPROVA no kg-radar --integrity — o grafo declarado é inconsistente. Rode: bash .claude/validation/kg-radar.sh ${tgt_rel} --integrity"
        continue
      fi
      if ! bash "${RADAR}" "${tgt_abs}" --schema >/dev/null 2>&1; then
        say "HARD" "RADAR-FAIL" "${rel}" "kg: '${tgt_rel}' REPROVA no kg-radar --schema — versão de schema incompatível. Rode: bash .claude/validation/kg-radar.sh ${tgt_rel} --schema"
        continue
      fi
    fi
    # Passou em tudo: silêncio (marcador íntegro).
  done < <(extract_kg "${abs}")
done < "${TMP}/files"

# ---------------------------------------------------------------------------
# SAÍDA
# ---------------------------------------------------------------------------
if [ "${FORMAT}" = "tsv" ]; then
  cat "${TMP}/out"
else
  n_files=$(wc -l < "${TMP}/files" | tr -d ' ')
  printf '=== Integridade do marcador kg: (escopo: .claude/diary + docs/analysis + docs/evolution/research) ===\n'
  printf '  Arquivos no escopo   : %s\n' "${n_files}"
  printf '  Marcadores inválidos : %s\n' "${HARD}"
  printf '  Radar                : %s\n' "$([ "${RADAR_OK}" -eq 1 ] && printf 'ativo' || printf 'AUSENTE (integridade/schema suspensa)')"
  printf '\n'
  if [ -s "${TMP}/out" ]; then
    while IFS=$'\t' read -r sev tag path msg; do
      [ -n "${sev}" ] || continue
      printf '❌ HARD [%s] %s: %s\n' "${tag}" "${path}" "${msg}"
    done < "${TMP}/out"
  else
    printf '✅ nenhum marcador kg: inválido (o gate nasce silencioso quando ninguém declara kg:).\n'
  fi
fi

if [ "${SUMMARY}" -eq 1 ]; then
  printf 'SUMMARY\tHARD=%s\n' "${HARD}"
fi

[ "${HARD}" -eq 0 ] || exit 1
exit 0
