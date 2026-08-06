#!/usr/bin/env bash
# kg-trace-resolve.sh — a âncora foi DECLARADA, mas ela RESOLVE?
#
# ═══ POR QUE EXISTE (medido 2026-08-06) ═══
# O bloco PROVENIÊNCIA do kg-radar.sh cobra que uma decisão APONTE para a origem — aresta
# TRACES_TO ou campo `trace:` inline. Ele verifica que a âncora foi **declarada**; nunca que ela
# **existe**. É o `behavior-over-declaration` da casa aplicado à própria âncora: um `trace:` que
# aponta para arquivo movido/renomeado passa no gate e MENTE para quem tenta voltar ao "porquê".
#
# Medido no corpus (54 grafos, 1.659 nós com `trace:`): 13 ponteiros mortos — 7 por arquivo movido
# para `_processed/`, 4 por prefixo perdido (`.claude/commands/git/` → `engineer/`), 2 por
# reorganização de pasta. Todos consertados antes desta guarda entrar, e é por isso que ela nasce
# HARD **sem baseline**: não há passivo tolerado a carregar.
#
# ═══ POR QUE É SCRIPT-IRMÃO, E NÃO CLÁUSULA NO RADAR (a refutação que mudou o desenho) ═══
# A especificação original mandava a cláusula para dentro do `kg-radar.sh --freshness-tsv`. Duas
# medições a derrubaram:
#   (1) ALCANCE — dos 13 casos reais, só 2 caem no escopo do `--freshness-tsv` (que cobre apenas
#       `plane: PROD` ou nó com `verified_against:`). A guarda nasceria vendo 15% do defeito e
#       DECLARANDO cobertura — falso-verde por construção.
#   (2) ARQUITETURA — o kg-radar.sh tem ZERO acesso a filesystem (0 chamadas system()/getline<).
#       É awk puro sobre um arquivo, e essa pureza é load-bearing: é o que o faz rodar sob `env -i`
#       (portabilidade medida no M3). Resolver caminho exige tocar o disco; embutir isso destruiria
#       a propriedade para cobrir menos casos.
# Logo: script-irmão no padrão de kg-radar-integrity.sh / doctrine-freshness.sh.
#
# ═══ O QUE É JULGÁVEL (o corte que decide a taxa de falso-positivo) ═══
# Sem corte, o número sobe para 24 e ~46% são falso-positivo. Três classes são EXCLUÍDAS por
# desenho, porque o repo não é autoridade sobre elas — e a supressão é CONTADA, nunca silenciosa:
#   · caminho ABSOLUTO ou URL   → outra máquina/rede (ex.: /home/onion/onion-bridge/src/server.ts
#                                  na VPS, /etc/caddy/...). Existe; só não aqui.
#   · raiz externa DECLARADA    → `memory/` é o diretório de memória da sessão, fora do repo.
#   · não parece caminho        → nome solto, chave de config (`permissions.additionalDirectories`),
#                                  comando, prosa. `trace:` aceita mais que arquivo.
#
# TETO DECLARADO (limite honesto, não defeito): âncora de NOME SOLTO — sem barra, tipo
# `SYNTHESIS.md` relativo ao diretório do grafo — NÃO é julgada. São 7 casos reais no corpus, e
# eles resolvem hoje; só não ficam sob vigilância (se o alvo sumisse, esta guarda calaria). É o
# preço da regra (b), que mata `roles.yaml` e `permissions.additionalDirectories` com ZERO falso-
# positivo. Julgar nome solto exigiria adivinhar a raiz pretendida — e um aviso que adivinha é o
# que treina o leitor a ignorar. Preferi cobertura menor e crível a cobertura maior e barulhenta.
#
# TRÊS RAÍZES, e cada uma foi paga por um falso-positivo medido:
#   1. raiz do REPO            — o caso comum.
#   2. diretório DO GRAFO      — 7 dos 8 primeiros "quebrados" eram `SYNTHESIS.md` ao lado do grafo;
#                                 um resolvedor de raiz única nascia com 87% de falso-positivo.
#   3. diretório PAI do grafo  — quando o grafo mora em `<base>/graph/x.kg.yaml`, o `trace:` ancora
#                                 naturalmente em `<base>/` (`consolidated/…`, `site/…`).
#
# A RAIZ 3 CUSTOU UM VEXAME, e ele vale registrado: shipei esta regra como HARD **sem baseline**
# tendo verificado só que o CORE tinha zero. No primeiro adotante que a recebeu, ela acusou 11
# ponteiros — TODOS falsos, todos por esta raiz faltando. O corpus do core é cego a ela porque
# aqui todo grafo mora em `docs/onion/graph/` ou `docs/evolution/research/<tema>/`, onde as duas
# primeiras raízes bastam; o adotante organiza por vertical (`docs/<vertical>/graph/`) e a terceira
# aparece. Terceira confirmação, no mesmo dia, de que O CORE É O PIOR ORÁCULO DO QUE VIAJA.
# E a lição de gate: "HARD sem baseline" só é seguro para o repo ONDE se mediu. Ver o teto abaixo.
#
# Uso  : bash .claude/validation/kg-trace-resolve.sh [<repo_root>] [--format tsv]
# Saída: relatório humano (default) ou TSV (grafo·id·node_type·alvo·verdict)
# Exit : 0 = todo `trace:` julgável resolve · 1 = há TARGET-MISSING · 2 = uso inválido
set -euo pipefail

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'kg-trace-resolve: repo_root inválido\n' >&2; exit 2; }
FORMAT=human
for a in "$@"; do case "$a" in --format) : ;; tsv) FORMAT=tsv ;; --format=tsv) FORMAT=tsv ;; esac; done

cd "${REPO_ROOT}"

# Descoberta ao vivo — o glob hardcoded era 36% cego (achado da casa, REGRA do kg-grammar).
GRAPHS="$(git ls-files '*.kg.yaml' 2>/dev/null | grep -v '/fixtures/' || true)"
[ -n "${GRAPHS}" ] || { printf '  (nenhum .kg.yaml rastreado — nada a verificar)\n'; exit 0; }

MISSING=0; JUDGED=0; SKIP_ABS=0; SKIP_EXT=0; SKIP_NOTPATH=0
REPORT=""

while IFS= read -r g; do
  [ -n "${g}" ] || continue
  gdir="$(dirname "${g}")"
  # Só a seção `nodes:` — `trace:` vive em nó, e varrer `edges:` inventaria alvo.
  nodes="$(awk '/^edges:/{exit} {print}' "${g}")"
  while IFS=$'\t' read -r nid ntype target; do
    [ -n "${target}" ] || continue
    case "${target}" in
      /*|http://*|https://*)  SKIP_ABS=$((SKIP_ABS + 1)); continue ;;   # outra máquina/rede
      memory/*)               SKIP_EXT=$((SKIP_EXT + 1)); continue ;;   # raiz externa declarada
    esac
    # Precisa PARECER caminho de arquivo do repo. Três condições, e cada uma foi forjada por um
    # falso-positivo real medido no corpus — sem elas o número sobe de 13 para 24:
    #   (a) só [A-Za-z0-9_./-]  → mata `kg-radar.sh --state` (argumento) e
    #                              `durable-commit.sh (git add .claude)` (prosa); `trace:` aceita
    #                              comando e frase, não só arquivo.
    #   (b) tem barra           → mata nome solto (`roles.yaml`) e chave de config
    #                              (`permissions.additionalDirectories`).
    #   (c) último segmento tem → mata domínio/URL sem esquema: `support.claude.com/.../13837433`
    #       extensão              e `kubernetes.io/.../kustomization/` passam em (a) e (b).
    case "${target}" in *[!A-Za-z0-9_./-]*) SKIP_NOTPATH=$((SKIP_NOTPATH + 1)); continue ;; esac
    case "${target}" in */*) : ;; *) SKIP_NOTPATH=$((SKIP_NOTPATH + 1)); continue ;; esac
    case "${target##*/}" in *.*) : ;; *) SKIP_NOTPATH=$((SKIP_NOTPATH + 1)); continue ;; esac
    JUDGED=$((JUDGED + 1))
    if [ -e "${target}" ] || [ -e "${gdir}/${target}" ] || [ -e "${gdir}/../${target}" ]; then continue; fi
    MISSING=$((MISSING + 1))
    if [ "${FORMAT}" = tsv ]; then
      REPORT="${REPORT}${g}	${nid}	${ntype}	${target}	TARGET-MISSING
"
    else
      REPORT="${REPORT}  ✗ TARGET-MISSING: ${nid} (${ntype}) → ${target}
      em ${g} — o \`trace:\` aponta para caminho inexistente (arquivo movido/renomeado? cite o real)
"
    fi
  done <<EOF
$(printf '%s\n' "${nodes}" | awk '
  /^  - id:/       { if (id != "" && tr != "") printf "%s\t%s\t%s\n", id, (ty == "" ? "-" : ty), tr
                     id = $3; ty = ""; tr = ""; next }
  /^    node_type:/{ ty = $2; next }
  # Corta em QUALQUER dois-pontos: a âncora aceita `arquivo:linha` E `arquivo:secao`.
  /^    trace:/    { sub(/^    trace:[[:space:]]*/, ""); gsub(/^"|"$/, "")
                     sub(/#.*$/, ""); sub(/:.*$/, ""); sub(/[[:space:]]+$/, ""); tr = $0; next }
  END              { if (id != "" && tr != "") printf "%s\t%s\t%s\n", id, (ty == "" ? "-" : ty), tr }
')
EOF
done <<EOF
${GRAPHS}
EOF

if [ "${FORMAT}" = tsv ]; then
  printf '%s' "${REPORT}"
  [ "${MISSING}" -eq 0 ] && exit 0 || exit 1
fi

printf '══ TRACE-RESOLVE — a âncora declarada EXISTE? (✗ reprova) ══\n'
[ -n "${REPORT}" ] && printf '%s' "${REPORT}"
printf '  julgáveis: %d · resolvem: %d · TARGET-MISSING: %d\n' \
  "${JUDGED}" "$((JUDGED - MISSING))" "${MISSING}"
printf '  fora de julgamento (contado, nunca silencioso): %d absoluto/URL · %d raiz externa · %d não-caminho\n' \
  "${SKIP_ABS}" "${SKIP_EXT}" "${SKIP_NOTPATH}"

# ═══ GUARDA DE VACUIDADE — a guarda-da-guarda, e ela existe por INCIDENTE, não por prudência ═══
# 2026-08-06, durante a própria construção: uma edição comentou sem querer o resto da linha do awk
# que casa `trace:`. O parser passou a extrair ZERO nós — e este script imprimiu
# "✅ todo `trace:` julgável resolve" e saiu com exit 0. Uma guarda completamente quebrada
# reportando SUCESSO: fail-open perfeito, invisível, e só pego porque eu tinha um número conhecido
# (1300) para comparar. Ninguém depois de mim teria esse número.
# Por isso o piso: se há grafos e há `trace:` no corpus, é IMPOSSÍVEL que nada seja julgável.
# Zero julgável não é "repo limpo" — é "o parser morreu".
if [ "${JUDGED}" -eq 0 ]; then
  if grep -rqlE '^[[:space:]]+trace:' -- $(printf '%s ' ${GRAPHS}) 2>/dev/null; then
    printf '  ✗ VACUIDADE: existe `trace:` no corpus e NADA foi julgado — o parser quebrou.\n'
    printf '    Uma guarda que não lê nada e diz OK é pior que guarda nenhuma (fail-open).\n'
    exit 1
  fi
  printf '  ✅ nenhum `trace:` no corpus — nada a resolver\n'; exit 0
fi

if [ "${MISSING}" -eq 0 ]; then
  printf '  ✅ todo `trace:` julgável resolve\n'; exit 0
fi
exit 1
