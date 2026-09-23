#!/usr/bin/env bash
# =============================================================================
# radar-aufhebung-check.sh — rodada de radar selada reconcilia o corpus que superou
#
# POR QUE EXISTE (medido 2026-09-23): o `/meta:radar` declara como invariante
# *"write(KG) por rodada: grafo próprio com SUPERSEDES sobre os nós da baseline
# anterior que a rodada derrubar (Aufhebung)"* — e as rodadas não o cumprem. O
# corpus superado segue vencendo a revisita da REGRA 67 para sempre, porque
# ninguém escreveu o que caiu.
#
# ── O UNIVERSO É O QUE A 1ª VERSÃO ERROU, E O ERRO INVERTIA A TESE ───────────
# A 1ª versão varria só os `kg:` de `radar-baselines.yaml` — ou seja, a rodada
# ATUAL de cada eixo. Uma passada adversarial mediu: **6 de 7 rodadas seladas têm
# zero SUPERSEDES, e a guarda contava 1**. O ponteiro do eixo E3 já passou por
# CINCO rodadas (`maestro-vivo → 09-02 → 09-03 → 09-04 → 09-04-r4 → r5`), e cada
# troca REMOVEU a dívida anterior da contagem sem reconciliar nada. O cabeçalho
# anterior dizia "cada rodada nova adiciona mais um órfão"; o mecanismo fazia o
# oposto — cada rodada nova DESPEJAVA o órfão anterior, e a catraca "encolhia"
# sozinha. Denominador errado: eram eixos, não rodadas seladas.
# Agora o universo é a UNIÃO de (a) todo grafo sob `docs/evolution/research/radar-*/`
# — a convenção que o próprio `/meta:radar` manda usar — com (b) os `kg:` das
# baselines, que pega as rodadas fora daquela convenção (`maestro-vivo`,
# `fable-5-1-superacao`).
#
# ── A ARESTA NÃO CRUZA ARQUIVO, e isto quase fez a guarda punir quem obedece ──
# Medido: `kg-radar.sh:91` é `FILE="${1:-}"` — um arquivo por invocação, zero
# suporte cross-file. Mas o `/meta:radar` manda, na mesma página, (i) grafo
# PRÓPRIO por rodada E (ii) superseder a baseline ANTERIOR. Incompatíveis: quem
# obedece (i) não alcança (ii). A rodada-mãe só consegue porque APENDA no próprio
# grafo. Enquanto o motor não aprender aresta cross-file, `supersedes_external` é
# a única forma honesta de registrar a Aufhebung que ocorreu.
#
# DOIS DESFECHOS DECLARADOS, ambos de 1ª classe — forçar SUPERSEDES inventado
# seria PIOR que a dívida. Ambos exigem VALOR e vivem no bloco `meta:`:
#   · `meta.supersedes_none: <razão>`   — a rodada genuinamente não derrubou nada
#   · `meta.supersedes_external: <ref>` — a Aufhebung é cross-file
# ⚠️ O VALOR É OBRIGATÓRIO, e não é preciosismo: na 1ª versão um
# `supersedes_none:` VAZIO calava a guarda, provado no grafo real. Bastava a
# palavra — o fail-open exato que a regra existe para impedir.
#
# Uso  : bash radar-aufhebung-check.sh [REPO_ROOT] [--emit-baseline]
# Saída: `SEM-AUFHEBUNG<TAB><grafo>` por rodada acusada · `PONTEIRO-QUEBRADO<TAB><g>`
#        por `kg:` pendurado · `TOTAL<TAB><n>` ao fim.
#        `--emit-baseline` escreve o baseline CHAVEADO (uma linha por rodada
#        tolerada) — os 11 baselines irmãos são chaveados e auditáveis por diff;
#        um inteiro nu não diz QUAL rodada está tolerada, e `tr -dc '0-9'` sobre
#        ele transformava "1 (era 2)" em teto 12.
# Exit : 0 pôde julgar · 2 NÃO pôde (≠ zero).
# =============================================================================
set -uo pipefail

# O emissor NOMEIA o seu baseline: o resolvedor da bancada (regen-ensure-from (g)) casa
# `--emit-baseline` + o nome do arquivo para provar que cada baseline resolve EXATAMENTE um
# emissor. Sem esta linha o baseline resolvia ZERO emissores e a bancada completa reprovava — foi
# assim que a passada adversarial pegou a 1a versao.
BASELINE_NAME="radar-aufhebung-baseline.txt"

ROOT=""; EMIT=0
for a in "$@"; do
  case "${a}" in
    --emit-baseline) EMIT=1 ;;
    -*) echo "ERRO	flag desconhecida: ${a}" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] && ROOT="${a}" ;;
  esac
done
[ -n "${ROOT}" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BL="${ROOT}/docs/onion/radar-baselines.yaml"

# ── universo: convenção de diretório UNIÃO ponteiros de baseline ─────────────
_universe() {
  find "${ROOT}/docs/evolution/research" -mindepth 2 -maxdepth 2 \
       -path '*/radar-*/*.kg.yaml' -type f 2>/dev/null \
    | sed "s#^${ROOT}/##"
  if [ -r "${BL}" ]; then
    # corta comentário de fim de linha ANTES de tudo: o estilo `kg: x  # nota` já
    # existe neste arquivo, e sem o corte o caminho saía com o comentário colado,
    # o `[ -f ]` falhava e a rodada sumia em silêncio
    sed -nE 's/^[[:space:]]+kg:[[:space:]]*//p' "${BL}" \
      | sed -E 's/[[:space:]]+#.*$//; s/^["'"'"']//; s/["'"'"']$//; s/[[:space:]]+$//'
  fi
}

# `meta:` termina na primeira chave de topo seguinte (`nodes:`/`edges:`). Fora
# dele, um `supersedes_none:` dentro de um NÓ — ou dentro de um block scalar de
# prosa, forma nativa deste corpus — não é declaração, é texto.
_declares() { # $1=arquivo  → 0 se declarou COM VALOR NÃO-VAZIO no meta
  # ⚠️ o valor é tirado das ASPAS antes de julgar: `supersedes_none: "   "` tem
  # caractere não-espaço depois dos dois-pontos (a aspa) e passava por um teste
  # ingênuo — mesma família do campo vazio, só que disfarçada.
  awk '
    /^[a-zA-Z_]/ && !/^meta:/ { exit 1 }
    /^[[:space:]]+supersedes_(none|external):/ {
      v = $0
      sub(/^[[:space:]]+supersedes_(none|external):[[:space:]]*/, "", v)
      gsub(/^["'"'"']|["'"'"']$/, "", v)
      gsub(/[[:space:]]/, "", v)
      if (v != "") { found = 1; exit 0 }
    }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# aresta REAL: valor EXATO no fim da linha. Prefixo (`SUPERSEDESX_INVENTADO`) e
# menção em prosa não contam — ambos passavam na 1ª versão.
_has_edge() { grep -qE '^[[:space:]]+edge_type:[[:space:]]*SUPERSEDES[[:space:]]*(#.*)?$' "$1"; }

[ -e "${BL}" ] || { [ "${EMIT}" -eq 1 ] || echo "TOTAL	0"; exit 0; }
[ -r "${BL}" ] || { echo "ERRO	${BL} existe e não é legível — não pude julgar (≠ zero)"; exit 2; }

accused=(); dangling=(); seen=""
while read -r g; do
  [ -n "${g}" ] || continue
  case " ${seen} " in *" ${g} "*) continue ;; esac   # a mesma rodada serve N eixos
  seen="${seen} ${g}"
  if [ ! -f "${ROOT}/${g}" ]; then
    # ponteiro pendurado NÃO é silêncio: some da conta sem ninguém saber
    dangling+=("${g}"); continue
  fi
  _declares "${ROOT}/${g}" && continue
  _has_edge "${ROOT}/${g}" || accused+=("${g}")
done < <(_universe | sort -u)

if [ "${EMIT}" -eq 1 ]; then
  echo "# Catraca de AUFHEBUNG DE RODADA DE RADAR — rodadas seladas toleradas SEM nenhuma"
  echo "# aresta SUPERSEDES e sem \`meta.supersedes_none\`/\`supersedes_external\` declarado."
  echo "# CHAVEADO (uma linha por rodada), como os 11 baselines irmãos: inteiro nu não diz QUAL"
  echo "# rodada está tolerada, e some no diff quando uma sai e outra entra."
  echo "# Regenere: bash .claude/validation/radar-aufhebung-check.sh . --emit-baseline"
  echo "#"
  # ⚠️ SEM PIPE. A 1a versao filtrava o array vazio com `printf … | grep -v`, e a guarda
  # `shell-pipefail` da casa reprovou no CI: `<produtor> | grep -q|grep -v` sob `pipefail` e uma
  # corrida — o leitor que sai cedo manda SIGPIPE ao escritor e o rc do pipeline vira o dele.
  # Itere o array e teste o elemento; nao ha filtro a fazer se nao ha elemento.
  for g in ${accused[@]+"${accused[@]}"}; do [ -n "${g}" ] && printf '%s\n' "${g}"; done
  exit 0
fi

for g in ${accused[@]+"${accused[@]}"};  do [ -n "${g}" ] && printf 'SEM-AUFHEBUNG\t%s\n' "${g}"; done
for g in ${dangling[@]+"${dangling[@]}"}; do [ -n "${g}" ] && printf 'PONTEIRO-QUEBRADO\t%s\n' "${g}"; done
printf 'TOTAL\t%d\n' "${#accused[@]}"
exit 0
