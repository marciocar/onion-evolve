#!/usr/bin/env bash
# =============================================================================
# radar-aufhebung-check.sh — rodada de radar selada reconcilia o corpus que superou
#
# POR QUE EXISTE (medido 2026-09-23): é a ÚNICA dívida deste ciclo que PIORA
# SOZINHA. O `/meta:radar` declara como invariante *"write(KG) por rodada: grafo
# próprio com SUPERSEDES sobre os nós da baseline anterior que a rodada derrubar
# (Aufhebung)"*. Das 6 baselines com `kg:`, DUAS apontavam para rodada com ZERO
# SUPERSEDES — e a consequência não é estética: o corpus
# `claude-code-2.1-onion-2026-08` cobre 2.1.211–2.1.233 enquanto a baseline E3 já
# media 2.1.278, e a REGRA 67 acusa revisita vencida que vai VENCER DE NOVO
# faça-se o que se fizer, porque nenhuma rodada jamais reconciliou o que superou.
#
# ⚠️ ESTA GUARDA QUASE NASCEU PUNINDO QUEM OBEDECE, e isso merece ficar escrito.
# A aresta `SUPERSEDES` do motor é INTRA-ARQUIVO — medido nos 2 SUPERSEDES da
# rodada-mãe, ambos com alvo no próprio grafo. Mas o `/meta:radar` manda, na mesma
# página, (i) escrever *grafo próprio por rodada* E (ii) superseder *a baseline
# anterior*. As duas são incompatíveis com o modelo de aresta: quem obedece (i)
# não alcança (ii). A rodada-mãe só consegue porque APENDA no próprio grafo.
# Enquanto o motor não aprender aresta cross-file, `meta.supersedes_external:` é a
# única forma honesta de registrar a Aufhebung que de fato ocorreu.
#
# DOIS DESFECHOS LEGÍTIMOS, e a razão de existirem é a mesma: forçar SUPERSEDES
# inventado seria PIOR que a dívida.
#   · `meta.supersedes_none: <razão>`     — a rodada genuinamente não derrubou nada
#   · `meta.supersedes_external: <ref>`   — a Aufhebung é cross-file (ver acima)
#
# Uso  : bash .claude/validation/radar-aufhebung-check.sh [REPO_ROOT]
# Saída: uma linha `SEM-AUFHEBUNG<TAB><grafo>` por rodada acusada, e ao fim
#        `TOTAL<TAB><n>`. Exit 0 sempre que pôde julgar; 2 quando NÃO pôde.
# =============================================================================
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
BL="${ROOT}/docs/onion/radar-baselines.yaml"

# Baseline AUSENTE é silêncio legítimo (adotante sem radar); ILEGÍVEL não é.
[ -e "${BL}" ] || { echo "TOTAL	0"; exit 0; }
[ -r "${BL}" ] || { echo "ERRO	${BL} existe e não é legível — não pude julgar (≠ zero)"; exit 2; }

n=0
vistos=""
while read -r g; do
  [ -n "${g}" ] || continue
  # a MESMA rodada costuma servir vários eixos; contar duas vezes inflaria a catraca
  case " ${vistos} " in *" ${g} "*) continue ;; esac
  vistos="${vistos} ${g}"
  [ -f "${ROOT}/${g}" ] || continue
  # desfechos declarados — ver o cabeçalho
  grep -qE '^[[:space:]]*supersedes_(none|external):' "${ROOT}/${g}" && continue
  if ! grep -qE '^[[:space:]]+edge_type:[[:space:]]*SUPERSEDES' "${ROOT}/${g}"; then
    printf 'SEM-AUFHEBUNG\t%s\n' "${g}"
    n=$((n + 1))
  fi
done < <(grep -E '^[[:space:]]+kg:' "${BL}" | sed -E "s/.*kg:[[:space:]]*//; s/^[\"']//; s/[\"']$//")

printf 'TOTAL\t%d\n' "${n}"
exit 0
