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

# Predicado de FIXTURE — caminho ABSOLUTO resolvido ANTES de qualquer `cd`, e ausência é FAIL-CLOSED.
# (A 1ª ligação usava `$(dirname "${BASH_SOURCE[0]}")` no ponto de uso e morria depois de um `cd`:
#  o erro era engolido por `|| true` e o script dizia "nenhum grafo" — verde por vacuidade. 2026-09-05.)
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "ERRO: predicado de fixture ausente (${_KFP}) — sem ele a varredura de grafos ficaria VAZIA e verde por vacuidade." >&2; exit 2; }

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'kg-trace-resolve: repo_root inválido\n' >&2; exit 2; }
FORMAT=human
EMIT_INDEX=0; INDEX=""
for a in "$@"; do case "$a" in --format) : ;; tsv) FORMAT=tsv ;; --format=tsv) FORMAT=tsv ;; --emit-index) EMIT_INDEX=1 ;; esac; done

cd "${REPO_ROOT}"

# Descoberta ao vivo — o glob hardcoded era 36% cego (achado da casa, REGRA do kg-grammar).
# ⚠️ A isenção de FIXTURE vem do predicado ÚNICO kg-fixture-paths.sh (2026-09-05): antes cada
#    consumidor repetia `grep -v '/fixtures/'` e o `__fixtures__/` do Vitest ESCAPAVA — 5 grafos
#    deliberadamente inválidos de um adotante viraram 5 HARD no dia 1 da adoção dele.
GRAPHS="$(git ls-files '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --filter || true)"
[ -n "${GRAPHS}" ] || { printf '  (nenhum .kg.yaml rastreado — nada a verificar)\n'; exit 0; }

MISSING=0; JUDGED=0; SKIP_ABS=0; SKIP_EXT=0; SKIP_NOTPATH=0
REPORT=""

while IFS= read -r g; do
  [ -n "${g}" ] || continue
  gdir="$(dirname "${g}")"
  # Só a seção `nodes:` — `trace:` vive em nó, e varrer `edges:` inventaria alvo.
  # RASTREIA A SEÇÃO em vez de assumir ORDEM. A versão anterior cortava no primeiro `^edges:`,
  # o que só funciona se `nodes:` vier antes — e YAML não tem ordem. Medido na revisão adversarial
  # (2026-08-06): um grafo com `edges:` primeiro é ACEITO pelo kg-radar (exit 0, reporta as
  # decisões) e ficava INTEIRO invisível aqui — zero julgável, zero excluído, zero contado. Falso
  # negativo que não aparece em bucket nenhum é pior que falso positivo: some sem deixar rastro.
  nodes="$(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { insec = ($0 ~ /^nodes:[[:space:]]*$/); next } insec { print }' "${g}")"
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
    # (c) O TESTE DE DOMÍNIO MUDOU DE LUGAR — e isso amplia a cobertura sem perder precisão.
    #     Antes: "o último segmento precisa ter extensão". Matava domínio (`support.claude.com/...`)
    #     mas também matava CAMINHO REAL sem extensão — medido: 14 âncoras vivas ficavam fora de
    #     vigilância, entre elas `.githooks/pre-commit`, `.claude/skills/` e 4 diretórios de
    #     `docs/evolution/federation/outbox/`. Custo não declarado no cabeçalho: se qualquer uma
    #     fosse movida, a REGRA 55 calaria.
    #     Agora: o teste mira o PRIMEIRO segmento, que é onde mora o hostname. Um domínio tem
    #     ponto ali (`support.claude.com`, `kubernetes.io`); um caminho do repo, não (`docs`,
    #     `.claude` — que começa com ponto, e por isso a exceção do prefixo é necessária, senão
    #     toda a superfície `.claude/` seria descartada).
    _first="${target%%/*}"
    case "${_first}" in
      .*)  : ;;                                                    # `.claude/…`, `.githooks/…`
      *.*) SKIP_NOTPATH=$((SKIP_NOTPATH + 1)); continue ;;         # hostname → não julgável
    esac
    JUDGED=$((JUDGED + 1))
    # A 3ª raiz (pai do grafo) NÃO se aplica quando o grafo está na raiz do repo: ali `..` sai
    # DO REPO. Medido: um `trace:` apontando para um repo-irmão resolvia verde na máquina do
    # maestro e vermelho no clone do CI — gate dependente de quem tem o quê no disco ao lado.
    # ── ÍNDICE DE LEITURA (--emit-index) ──────────────────────────────────────────────────────
    # O MESMO parser que julga a âncora emite o índice que o hook de leitura consome. Um segundo
    # extrator de `trace:` seria a 2ª cópia da gramática — a classe que esta casa chama de dois
    # leitores discordando sobre quem é nó (e que a REGRA 82 existe para pegar).
    if [ "${EMIT_INDEX}" -eq 1 ]; then
      if [ -e "${target}" ]; then INDEX="${INDEX}${target}	${nid}	${g}
"
      elif [ -e "${gdir}/${target}" ]; then INDEX="${INDEX}${gdir}/${target}	${nid}	${g}
"
      fi
    fi
    if [ -e "${target}" ] || [ -e "${gdir}/${target}" ]; then continue; fi
    if [ "${gdir}" != "." ] && [ -e "${gdir}/../${target}" ]; then continue; fi
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
  /^[[:space:]]+- id:/ { sub(/\r$/, "")
                     if (id != "" && tr != "") printf "%s\t%s\t%s\n", id, (ty == "" ? "-" : ty), tr
                     id = $3; ty = ""; tr = ""; next }
  /^[[:space:]]+node_type:/ { sub(/\r$/, ""); ty = $2; next }
  # Corta em QUALQUER dois-pontos: a âncora aceita `arquivo:linha` E `arquivo:secao`.
  # ORDEM DAS LIMPEZAS IMPORTA, e a anterior estava errada em duas formas YAML válidas:
  #   · CRLF   — um arquivo com fim-de-linha Windows fazia TODO o grafo cair em "não-caminho"
  #              (o \r entrava no alvo e o filtro de caracteres o rejeitava). Some primeiro.
  #   · aspas  — tirar aspas ANTES do comentário deixava `docs/x.md" # nota` virar `docs/x.md"`.
  #              Comentário sai primeiro; aspas depois. E aceita aspa SIMPLES, que é YAML válido
  #              e era silenciosamente descartada.
  /^[[:space:]]+trace:/ { sub(/\r$/, ""); sub(/^[[:space:]]+trace:[[:space:]]*/, "")
                     sub(/[[:space:]]+#.*$/, ""); gsub(/^["\047]|["\047]$/, "")
                     sub(/#.*$/, ""); sub(/:.*$/, ""); sub(/[[:space:]]+$/, ""); tr = $0; next }
  END              { if (id != "" && tr != "") printf "%s\t%s\t%s\n", id, (ty == "" ? "-" : ty), tr }
')
EOF
done <<EOF
${GRAPHS}
EOF

# ═══ GUARDA DE VACUIDADE — antes da bifurcação de formato, e isso é o ponto ═══
# HISTÓRIA, em duas camadas, porque a segunda é mais instrutiva que a primeira:
#
# (1) 2026-08-06, construindo: uma edição comentou sem querer o resto da linha do awk que casa
#     `trace:`. O parser passou a ler ZERO nós — e o script imprimiu "✅ todo trace: julgável
#     resolve" com exit 0. Guarda quebrada reportando SUCESSO. Nasceu esta guarda.
#
# (2) HORAS DEPOIS, revisão adversarial do proprio PR: a guarda estava DEPOIS do `exit` do ramo
#     TSV — e TSV é EXATAMENTE o modo que o lint invoca (lint-artifacts.sh, check_kg_trace_resolve).
#     Medido com o mesmo mutante: modo humano exit 1 com ✗ VACUIDADE; modo TSV exit 0, saída vazia,
#     REGRA 55 VERDE. Ou seja: a cura do fail-open era ela mesma fail-open no unico caminho que
#     roda em CI. E o mutation test (e) do selftest exercitava o modo HUMANO — validava a
#     superficie que ninguem usa. GUARDA-DA-GUARDA QUE TESTA O MODO ERRADO NAO E GUARDA.
#     Por isso o bloco subiu para ANTES da bifurcação, e em TSV emite uma linha propria.
#
# (3) E o predicado mudou: `JUDGED == 0` sozinho MENTE. Um repo cujas âncoras sejam todas
#     nao-julgaveis por desenho (um adotante novo com dois grafos ancorando por nome solto — o
#     "teto declarado" logo acima) tinha JUDGED=0 com o parser PERFEITO, e recebia
#     "✗ o parser quebrou": diagnostico falso, HARD vermelho no dia 1, saida unica sendo inventar
#     uma barra no proprio `trace:`. Gemeo exato do bug da 3a raiz. Os contadores de skip PROVAM
#     que o parser leu — logo so ha vacuidade quando NADA foi lido, julgavel ou nao.
VACUO=0
if [ "${JUDGED}" -eq 0 ] && [ "$((SKIP_ABS + SKIP_EXT + SKIP_NOTPATH))" -eq 0 ]; then
  # Só agora vale perguntar ao disco: o parser leu zero de tudo. Se existe `trace:` no corpus,
  # ele morreu. Alimentação por stdin (não por $(...) sem aspas): caminho com espaço fazia
  # word-split, o grep falhava, e o `2>/dev/null` transformava o erro em "não há trace:" —
  # fail-open dentro da guarda anti-fail-open (achado da mesma revisão).
  if printf '%s\n' "${GRAPHS}" | xargs -d '\n' grep -lE '^[[:space:]]+trace:' -- 2>/dev/null | grep -q .; then
    VACUO=1
  fi
fi

if [ "${EMIT_INDEX}" -eq 1 ]; then
  # Falha FECHADA na vacuidade: índice vazio faria o hook de leitura ficar MUDO para sempre,
  # e mudo é indistinguível de "não há grafo" — o fail-open exato que este índice existe para curar.
  if [ "${VACUO}" -eq 1 ] || [ -z "${INDEX}" ]; then
    echo "ERRO kg-trace-resolve --emit-index: índice VAZIO (parser leu 0 nós com trace resolvível)" >&2
    exit 3
  fi
  printf '%s' "${INDEX}" | LC_ALL=C sort -u
  exit 0
fi

if [ "${FORMAT}" = tsv ]; then
  # A linha de vacuidade viaja no MESMO formato de 5 campos que o consumidor já parseia,
  # para o wire-in não precisar de caminho especial.
  [ "${VACUO}" -eq 1 ] && printf '%s\t%s\t%s\t%s\t%s\n' '-' 'PARSER' '-' '(nenhum nó lido)' 'VACUIDADE'
  printf '%s' "${REPORT}"
  { [ "${MISSING}" -eq 0 ] && [ "${VACUO}" -eq 0 ]; } && exit 0 || exit 1
fi

printf '══ TRACE-RESOLVE — a âncora declarada EXISTE? (✗ reprova) ══\n'
[ -n "${REPORT}" ] && printf '%s' "${REPORT}"
printf '  julgáveis: %d · resolvem: %d · TARGET-MISSING: %d\n' \
  "${JUDGED}" "$((JUDGED - MISSING))" "${MISSING}"
printf '  fora de julgamento (contado, nunca silencioso): %d absoluto/URL · %d raiz externa · %d não-caminho\n' \
  "${SKIP_ABS}" "${SKIP_EXT}" "${SKIP_NOTPATH}"

if [ "${VACUO}" -eq 1 ]; then
  printf '  ✗ VACUIDADE: existe `trace:` no corpus e o parser não leu NADA — nem julgável, nem excluído.\n'
  printf '    Uma guarda que não lê nada e diz OK é pior que guarda nenhuma (fail-open).\n'
  exit 1
fi
if [ "${JUDGED}" -eq 0 ]; then
  printf '  ✅ nenhum `trace:` julgável no corpus (o parser leu; tudo caiu nas exclusões declaradas)\n'
  exit 0
fi
if [ "${MISSING}" -eq 0 ]; then
  printf '  ✅ todo `trace:` julgável resolve\n'; exit 0
fi
exit 1
