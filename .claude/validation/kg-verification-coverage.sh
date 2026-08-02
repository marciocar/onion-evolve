#!/usr/bin/env bash
# kg-verification-coverage.sh — REGRA 49: nó `plane: PROD` de alto impacto carrega verificação.
#
# A PERGUNTA: dos nós que AFIRMAM COISAS SOBRE PRODUÇÃO e cujo erro custa caro
# (`plane: PROD` + `impact >= 4` + status vivo), quantos nunca foram medidos contra o vivo?
#
# ═══ POR QUE EXISTE ═══
# O `kg-radar.sh` DETECTA frescor (STALE-MISSING/STALE-OLD/UNANCHORED) e PARA AÍ — e o faz como
# "⚠ atenção, NÃO reprova". Consequência medida em 2026-08-02: o passivo pode CRESCER SEM LIMITE.
# São 53 nós vivos, `plane: PROD`, `impact >= 4`, SEM NENHUM `verified_at` — afirmando coisas sobre
# produção sem que ninguém jamais tenha medido.
#
# O CASO FUNDADOR (docs/../meta/kg-freshness.md:34): `C_ancestor_cap_zeroes_floors` afirmava em
# `plane: PROD` que os floors de memória tinham "proteção efetiva ZERO" — FALSO desde 2026-07-26.
# Carregava `verified_against` e `verified_at` do próprio dia: os três vereditos passavam e o radar
# ficava em silêncio. Um nó `impact: 5` mentindo com carimbo do dia, invisível a TODO mecanismo.
#
# ═══ O QUE ESTE GATE FAZ, E O QUE NÃO FAZ (limite honesto, na cara) ═══
# FAZ: garante que nó novo de alto impacto sobre PROD NASÇA com carimbo, e impede o passivo de crescer.
# NÃO FAZ: não checa se o carimbo é VERDADE — só que existe. Igual à REGRA 42, que declara o mesmo
#          limite. Logo ELE NÃO PEGA O CASO FUNDADOR. E isso não é falha: é a divisão correta —
#          o GATE cria a cadência, o WORKER (`/meta:kg-freshness`) testa a verdade contra o vivo.
#          Nenhum script determinístico sabe se `memory.min=402653184` contradiz um label.
#
# ═══ O GATILHO, e é o ponto do desenho ═══
# Este gate NUNCA diz "rode o /meta:kg-freshness". Ele torna RODAR o kg-freshness a ÚNICA forma de
# diminuir o número: para tirar um nó do baseline, você tem de medi-lo. A cadência vem do trabalho
# de reduzir um número que está no CI — RESÍDUO MATERIAL AUDITADO POR TERCEIRO, DESACOPLADO DO ATOR.
# É a única propriedade que sobreviveu a todos os replays de 2026-08-02 (4 de 4 guardas que pegaram).
#
# ═══ A CATRACA (doutrina da casa: REGRA 28/29/42) ═══
#   · passivo existente vai para BASELINE VERSIONADO e é TOLERADO (SOFT);
#   · nó NOVO fora do baseline sem carimbo é HARD;
#   · o baseline SÓ PODE ENCOLHER — acrescentar path é REGRESSÃO (HARD).
#   A métrica de saúde é o BASELINE DIMINUINDO, não o gate passando.
#
# ⚠️ MEIA-VIDA POR CLASSE — GATED, deliberadamente fora daqui.
#   Medido 2026-08-02: nós com `verified_at` VENCIDO (>30d) = ZERO. A doutrina do KG tem 29 dias;
#   nada teve tempo de envelhecer. Regra de expiração sobre conjunto vazio é cerimônia elegante.
#   GATILHO PARA ABRIR: >=20 nós no escopo com `verified_at` mais velho que 30 dias. Aí a classe
#   nasce com dado real. O desenho (derivar a classe do `trace:`/`verified_against:`, sem tocar a
#   gramática) está em docs/analysis/onion-adr-kg-halflife-2026-08.md.
#
# Uso : bash .claude/validation/kg-verification-coverage.sh [<repo_root>] [--emit-baseline] [--format tsv]
# TSV : sev<TAB>tag<TAB>path<TAB>msg  (mesmo contrato do kg-provenance-coverage.sh, para o lint
#       agregar a classe PASSIVO numa linha só — dezenas de linhas iguais afogam o acionável)
# Exit: 0 = sem HARD · 1 = HARD presente · 2 = erro de uso
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EMIT=0; FMT=human
while [ $# -gt 0 ]; do
  case "$1" in
    --emit-baseline) EMIT=1 ;;
    --format)        FMT="${2:-human}"; shift ;;
    -*)              printf 'uso: %s [<repo_root>] [--emit-baseline] [--format tsv]\n' "$0" >&2; exit 2 ;;
    *)               [ -d "$1" ] && REPO_ROOT="$(cd "$1" && pwd)" ;;
  esac
  shift
done
BASELINE="${REPO_ROOT}/.claude/validation/kg-verification-baseline.txt"

# emissor único: em TSV o lint agrega; em human o operador lê direto
emit() { # $1=sev $2=tag $3=path $4=msg
  if [ "${FMT}" = "tsv" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  elif [ "$1" = "HARD" ]; then  printf 'VIOLATION: %s: [kg-verificacao/%s] %s\n' "$3" "$2" "$4"
  else                          printf 'SOFT: %s: [kg-verificacao/%s] %s\n' "$3" "$2" "$4"; fi
}

cd "${REPO_ROOT}" || exit 2

# ── extrai os nós no escopo: plane PROD + impact>=4 + status vivo, SEM verified_at ──────────────
# Um nó fecha quando aparece o próximo `- id:` ou o fim do arquivo — por isso o flush no END e na
# abertura.
#
# ⚠️ ERRO REAL QUE ESTE DESENHO CORRIGE (2026-08-02): a primeira medição fechava o nó no `label:` e
# contou 64. São 53. Onze nós, como `C_COEVOLVE_VALUE` em onion-identity-2026-07.kg.yaml:323-332,
# têm `verified_at:` DEPOIS do `label:` — o scanner lia o nó pela METADE, via `ver=""` e acusava
# falta de carimbo em nó carimbado. Instrumento que lê estado PARCIAL e reporta como FATO: a mesma
# família de `declarado != verificado`, agora dentro do próprio medidor. Por isso o flush é no
# delimitador do nó (`- id:` / EOF), nunca num campo que pode vir em qualquer ordem.
scan() {
  local f
  for f in $(git ls-files '*.kg.yaml' 2>/dev/null | grep -v '/fixtures/'); do
    awk -v F="$f" '
      function flush(   ) {
        if (id != "" && plane == "PROD" && imp >= 4 && (st == "open" || st == "confirmed") && ver == "")
          print F "::" id
        id=""; plane=""; imp=0; ver=""; st=""
      }
      /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { flush(); id=$3; next }
      /^[[:space:]]*plane:[[:space:]]*/           { plane=$2; next }
      /^[[:space:]]*impact:[[:space:]]*/          { imp=$2+0;  next }
      /^[[:space:]]*verified_at:[[:space:]]*/     { ver=$2;    next }
      /^[[:space:]]*status:[[:space:]]*/          { st=$2;     next }
      END { flush() }
    ' "$f"
  done | while IFS= read -r line; do
    # CHAVE DO BASELINE = path::sha1(id), NUNCA o id cru.
    # POR QUÊ (a REGRA 36 pegou isto na 1a rodada, 2026-08-02): ids de nó carregam nome de
    # adotante (a 1a rodada tinha um id assim) e ESTE BASELINE VIAJA na superficie vendorizada — seria
    # vazamento cross-tenant por adoção. O path já é público (está no repo); o id não precisa
    # estar. O hash mantém a catraca funcionando (identidade estável) sem publicar o nome.
    # A mensagem de violação (que NÃO é versionada) segue nomeando o nó, para ser acionável.
    printf '%s::%s\n' "${line%%::*}" "$(printf '%s' "${line##*::}" | sha1sum | cut -c1-12)"
  done | sort -u
}

# o mapa id->hash fica só em memória, para a mensagem poder nomear o nó sem o baseline guardá-lo
scan_named() {
  local f
  for f in $(git ls-files '*.kg.yaml' 2>/dev/null | grep -v '/fixtures/'); do
    awk -v F="$f" '
      function flush(   ) {
        if (id != "" && plane == "PROD" && imp >= 4 && (st == "open" || st == "confirmed") && ver == "")
          print F "::" id
        id=""; plane=""; imp=0; ver=""; st=""
      }
      /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { flush(); id=$3; next }
      /^[[:space:]]*plane:[[:space:]]*/           { plane=$2; next }
      /^[[:space:]]*impact:[[:space:]]*/          { imp=$2+0;  next }
      /^[[:space:]]*verified_at:[[:space:]]*/     { ver=$2;    next }
      /^[[:space:]]*status:[[:space:]]*/          { st=$2;     next }
      END { flush() }
    ' "$f"
  done | sort -u
}

UNVERIFIED="$(scan)"
NAMED="$(scan_named)"

if [ "${EMIT}" -eq 1 ]; then
  printf '# Baseline da REGRA 49 — PASSIVO TOLERADO de nós PROD/impact>=4 sem verified_at.\n'
  printf '# Gerado por: bash .claude/validation/kg-verification-coverage.sh --emit-baseline\n'
  printf '# Esta lista SO PODE ENCOLHER. Acrescentar entrada aqui e REGRESSAO (HARD).\n'
  printf '# Para remover uma entrada: MEÇA o no contra o vivo (/meta:kg-freshness) e carimbe.\n'
  printf '%s\n' "${UNVERIFIED}"
  exit 0
fi

# ── FAIL-CLOSED: baseline ausente não libera tudo (lição da REGRA 29/42) ────────────────────────
if [ ! -f "${BASELINE}" ]; then
  emit HARD NO-BASELINE ".claude/validation/kg-verification-baseline.txt" \
    "baseline AUSENTE — gere com --emit-baseline. Sem ele o gate nao distingue passivo tolerado de no NOVO (fail-closed: nao libera tudo)."
  exit 1
fi

known="$(grep -vE '^[[:space:]]*(#|$)' "${BASELINE}" 2>/dev/null | sort -u)"
hard=0; soft=0

# (1) nó sem carimbo FORA do baseline → HARD (nasce verificado)
while IFS= read -r n; do
  [ -n "${n}" ] || continue
  if ! printf '%s\n' "${known}" | grep -qxF "${n}"; then
    # A mensagem nomeia o NÓ, não só o arquivo: num grafo de 881 nós, "o arquivo tem problema"
    # é inacionável. O path vai no campo que o lint agrega; o id vai no texto.
    nid="$(printf '%s\n' "${NAMED}" | awk -F'::' -v F="${n%%::*}" -v H="${n##*::}" '
             $1==F { h=$2; cmd="printf %s \"" $2 "\" | sha1sum | cut -c1-12"; cmd | getline g; close(cmd);
                     if (g==H) { print $2; exit } }')"
    emit HARD NOVO "${n%%::*}" \
      "no '${nid:-<id oculto>}' e plane:PROD impact>=4 SEM verified_at e FORA do baseline — meca contra o vivo antes de selar (/meta:kg-freshness), ou o grafo afirma sobre producao sem nunca ter olhado."
    hard=$((hard+1))
  fi
done <<< "${UNVERIFIED}"

# (2) entrada obsoleta (nó já carimbado ou já não existe) → SOFT "remova"
while IFS= read -r k; do
  [ -n "${k}" ] || continue
  if ! printf '%s\n' "${UNVERIFIED}" | grep -qxF "${k}"; then
    emit SOFT OBSOLETA ".claude/validation/kg-verification-baseline.txt" \
      "entrada OBSOLETA (no ja carimbado ou removido) — remova do baseline: ${k}"
    soft=$((soft+1))
  fi
done <<< "${known}"

# (3) CATRACA — baseline que CRESCEU vs a versão anterior no git → HARD (regressão)
prev="$(git show HEAD:.claude/validation/kg-verification-baseline.txt 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | sort -u || true)"
if [ -n "${prev}" ]; then
  np=$(printf '%s\n' "${prev}"  | grep -c . || true)
  nk=$(printf '%s\n' "${known}" | grep -c . || true)
  if [ "${nk}" -gt "${np}" ]; then
    emit HARD CATRACA ".claude/validation/kg-verification-baseline.txt" \
      "o baseline CRESCEU (${np} -> ${nk}). Ele SO PODE ENCOLHER: passivo novo e no NOVO sem carimbo, nao entrada de baseline."
    hard=$((hard+1))
  fi
fi

n_tot=$(printf '%s\n' "${UNVERIFIED}" | grep -c . || true)
n_base=$(printf '%s\n' "${known}" | grep -c . || true)
# PASSIVO: uma linha por entrada tolerada — o LINT agrega em uma só (contrato da REGRA 29)
i=0; while [ "${i}" -lt "${n_base}" ]; do
  emit SOFT PASSIVO ".claude/validation/kg-verification-baseline.txt" "no ainda sem verificacao, tolerado pelo baseline"
  i=$((i+1))
done
if [ "${FMT}" != "tsv" ]; then
  printf '  [kg-verificacao] no escopo sem carimbo: %s · passivo tolerado: %s · HARD: %s · SOFT: %s\n' \
    "${n_tot}" "${n_base}" "${hard}" "${soft}"
  printf '  [kg-verificacao] saude = o baseline DIMINUINDO. Para reduzir: /meta:kg-freshness mede o no e voce carimba.\n'
fi

[ "${hard}" -eq 0 ]
