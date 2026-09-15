#!/usr/bin/env bash
# regen-ssot-projections.sh — regenera no ALVO as projeções SSOT que o lint vendorizado exige.
#
# Uso: regen-ssot-projections.sh <DEST>
#
# ══ POR QUE EXISTE ════════════════════════════════════════════════════════════════════════════
# `docs/onion/inventory.md` (REGRA 8) e `docs/onion/graph.md` (REGRA 21) são SSOTs GERADAS do
# filesystem, e o hook nativo recém-instalado bloqueia o 1º commit do adotante sem elas. Os
# geradores vendorizados são a autoridade; ROOT = o repo do alvo. Determinístico, sem LLM,
# idempotente.
#
# ⚠️ O `mkdir` NÃO É DETALHE — medido em 2026-09-15. Sem o diretório, o redirecionamento falha com
# "No such file or directory", o `|| true` ENGOLE o rc, e o arquivo NUNCA EXISTE, em silêncio. O
# alvo nascia com HARD da REGRA 8. E o mais instrutivo: o bullet da Fase 3 do adopt TINHA o mkdir,
# o bloco shell da Configuração pós-cópia NÃO tinha — o adotante nascia verde ou vermelho conforme
# QUAL METADE do documento o operador seguisse. Guarda cujo resultado depende de qual parágrafo se
# leu não é guarda. Este helper é a segunda metade da cura: uma implementação, um comportamento.
#
# ⚠️ O `|| true` FICA, e é deliberado: gerador que falha por ambiente do alvo (jq ausente, por ex.)
# não pode abortar a adoção inteira — o lint do alvo cobra depois, com mensagem própria. O que
# mudou é que agora a falha não é MANUFATURADA por diretório ausente.
set -uo pipefail

DEST="${1:?uso: regen-ssot-projections.sh <DEST>}"
[ -d "${DEST}" ] || { echo "ERRO: alvo inexistente: '${DEST}'" >&2; exit 2; }

_n=0
mkdir -p "${DEST}/docs/onion"
for _pair in "inventory.sh:inventory.md" "graph.sh:graph.md"; do
  _gen="${_pair%%:*}"; _out="${_pair##*:}"
  [ -f "${DEST}/.claude/validation/${_gen}" ] || continue
  bash "${DEST}/.claude/validation/${_gen}" --markdown > "${DEST}/docs/onion/${_out}" 2>/dev/null || true
  [ -s "${DEST}/docs/onion/${_out}" ] && _n=$((_n + 1))
done
echo "  ✓ ${_n} projeção(ões) SSOT regenerada(s) no alvo (docs/onion/)"
