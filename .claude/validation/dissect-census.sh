#!/usr/bin/env bash
# ===========================================================================
# dissect-census.sh — censo das DISSECAÇÕES de ferramenta já pagas pelo corpus.
#
# É o MEDIDOR da peça 3 (contexto medido injetado) do `/meta:dissect`: a saída daqui é o que a
# sessão lê ANTES de abrir qualquer fonte externa. Responde por MEDIÇÃO a pergunta que o modelo
# responde de memória e erra — "já dissecamos esta ferramenta? até que nível? quando?".
#
# ── POR QUE EXISTE (defeito medido, 2026-10-01) ────────────────────────────────────────────
# Numa única rodada de pesquisa a casa (a) re-abriu Zep, Port e Roadie sem ler o que o corpus já
# dizia e (b) registrou "a Onyx não entrega grafo" como achado, quando a doc do próprio
# fornecedor diz `AI-generated knowledge graphs` e o módulo `backend/onyx/kg` está vivo no
# código. Nível 0 repagado é o desperdício; nível 2 errado por folheto é o defeito.
#
# ── DESCOBERTA POR REFERÊNCIA, NUNCA POR NOME CONSTRUÍDO ───────────────────────────────────
# Mesma cláusula 1 que rege o forge-census.sh, e pela mesma razão: construir o caminho/nome do
# artefato a partir do nome do candidato errou 3 vezes em 2026-09-28. Aqui a dissecação se
# ANUNCIA — o grafo carrega `x_dissect_tool:` no meta e `x_dissect_level:`/`x_dissect_verdict:` (contrato v4: extensão leva `x_`; a forma sem prefixo segue lida em grafo herdado) nos
# nós, e o censo LÊ esses marcadores. Grafo que fala de uma ferramenta sem se declarar
# dissecação é invisível a este censo, e isso é verdade útil: a sessão também não o acharia.
#
# ── FRONTEIRA DECLARADA ────────────────────────────────────────────────────────────────────
# Mede o que o corpus DECLARA. Não sabe de ferramenta que ninguém anotou, não julga qualidade
# da dissecação, e não confere se a medição do nível de fato ocorreu (o marcador é
# auto-atestado — mesmo teto honesto do kg-seal-exception.sh).
#
# ── RÉGUA E MODO (SAC-135, decisões do maestro de 2026-10-14) ──────────────────────────────
# A régua da dissecação deixou de ser fixa no Onion: `meta.x_dissect_against: <repo>` declara
# CONTRA QUEM o N1/N3/N4 foram medidos (ausente = `onion`, o comportamento de sempre). E o modo
# estudo (`meta.x_dissect_mode: study`) para no N2 SEM veredito, deixando um nó `question` aberto
# ("adotar?"). O censo mostra a régua e separa ESTUDO de INTERROMPIDA pela COLUNA `estado`:
#   veredito · estudo · interrompida (sem veredito e SEM marcador de estudo — parar no N2 sem o
#   marcador continua sendo interrompida) · estudo-INCOERENTE(<motivos>) · modo-DESCONHECIDO(<v>).
# Modo que o censo não conhece NUNCA cai no caminho normal em silêncio (fail-closed, P0).
#
# ── RÉGUA PADRÃO = O PRÓPRIO REPO, e ESCOPO por componente (SAC-147, decisão de 2026-10-15) ──
# Sem `--against`, a régua é o repo onde o dissect RODA, DERIVADA aqui (`--regua-padrao`), nunca
# digitada: sem carimbo `.claude/.onion-version` (o core) ou com `role: source` / `kind: door` (as
# portas são projeção do core) ⇒ `onion`, o comportamento de sempre; com qualquer outro papel
# (adotado, hub) ⇒ o id do repo = o nome do remote `origin` (fallback: a pasta raiz). O campo
# `framework:` do carimbo NÃO serve de id: medido em 2026-10-15, um adotado carrega
# `framework: onion-evolve` (o nome da fonte), e a régua dele sairia o Onion. Grafo SEM o marcador
# segue lido como `onion` (era o que a régua significava quando ele foi escrito).
# `meta.x_dissect_scope: <pathspec[,pathspec]>` estreita a régua a um COMPONENTE do repo (uma
# ferramenta, funcionalidade ou biblioteca — ex.: trocar o provedor de identidade de um produto).
# Sai na coluna `escopo` (ausente = `-`, o repo inteiro): nível pago só se reusa na MESMA régua E no
# MESMO escopo, e o censo mostra as duas colunas sem julgar a igualdade (comparação literal).
#
# ── VEREDITO NEGATIVO EXIGE SUPERAÇÃO E CRITÉRIO (SAC-151, maestro 2026-10-15) ───────────────
# "um juiz de sim ou não sem tentar superação em uma pesquisa pode restringir possibilidades de
# crescimento e inovação; é preciso ter medição e critérios claros". `rejeitar` e `parquear` são
# vereditos NEGATIVOS e só contam como veredito quando o nó que os carrega declara:
#   · `x_dissect_criterion: "<comando que checa a reprovação>"` — o critério pré-registrado, re-rodável;
#   · `x_dissect_overcoming: <id>` de um nó DESTE grafo (`C_SUPERACAO_…` quando nasce da reprovação;
#     uma evidência que já existe, quando a superação já estava medida) com aresta (from) para o nó
#     da reprovação — a superação ACHADA vira nó —, OU `x_dissect_overcoming: nenhuma` com
#     `x_dissect_overcoming_measure: "<o que se procurou e onde>"` (achada:false exige a razão medida).
# Sem isso o estado sai `veredito-SEM-SUPERACAO(<motivos>)` (fail-closed: não conta como veredito)
# e `--check-verdict <ferramenta>` sai 1. Caso que motivou: a dissecação do markitdown (num adotante de curadoria,
# PR #26) fechou em REJEITAR com a superação medida — o tesseract local lê o PDF escaneado em que a
# ferramenta sai vazia —, e é essa forma que passa a ser exigida.
# 2ª leva (SUPERAÇÃO DE CONSOLO): o nó apontado tem de ENTREGAR — não é o próprio veredito nem deriva
# dele pelas arestas, está confirmed|done com verified_at (não futuro) e verified_against, e não é
# ancorado no próprio critério. Motivos: superacao-circular-*, superacao-nao-medida-status-*,
# superacao-sem-verified_at, superacao-carimbo-futuro-*, superacao-sem-verified_against,
# superacao-ancorada-no-criterio. O status quo rotulado de superação NÃO é visto aqui (declarado).
#
# Uso:  bash .claude/validation/dissect-census.sh [<repo>] [--markdown|--tsv|--regua-padrao]
#       bash .claude/validation/dissect-census.sh [<repo>] --check-verdict <ferramenta>
# Exit: 0 = censo emitido (inclusive "zero dissecação", que é resposta) · 3 = NÃO PUDE MEDIR.
#       --check-verdict: 0 = veredito positivo, ou negativo com critério + superação · 1 = negativo
#       RECUSADO (motivos no stderr) ou sem veredito · 3 = ferramenta não declarada no corpus.
#       Os PLANOS de absorção (N4) têm leitor próprio, do lado do forge: dissect-plans.sh — este
#       script viaja no plugin onion-meta e não pode depender do forge-census, que não viaja.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_dissect_selftests).
# ===========================================================================
set -uo pipefail

REPO="${1:-}"; FMT="${2:---markdown}"; CHECK_TOOL="${3:-}"
case "${REPO}" in --*) CHECK_TOOL="${2:-}"; FMT="${REPO}"; REPO="" ;; esac
[ "${FMT}" != "--check-verdict" ] || [ -n "${CHECK_TOOL}" ] \
  || { echo "dissect-census: --check-verdict exige o nome da ferramenta (o valor de x_dissect_tool:)" >&2; exit 3; }
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "dissect-census: alvo inexistente: ${REPO}" >&2; exit 3; }

# FAIL-CLOSED no índice: o censo é do conjunto RASTREADO (o que viaja e o que o CI vê). Sem
# índice, "nenhuma dissecação" seria falso e caríssimo — zero NÃO é resultado quando a causa é
# não ter podido olhar. É a lição do exit-code-nao-e-a-verificacao.
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "dissect-census: sem índice git em ${REPO} — o censo seria de outro conjunto que o do CI. Recusa." >&2; exit 3; }

# ── RÉGUA PADRÃO deste repo (SAC-147): derivada do carimbo, nunca digitada ──────────────────
# Roda ANTES da exigência de corpus: derivar a régua não depende de haver grafo.
# Imprime `<régua>\t<de onde veio>`. É a SSOT da derivação: o dissect-plans.sh a CHAMA em vez de
# repetir a regra (duas cópias da mesma derivação divergem — a classe do vocabulário duplicado).
# ⚠️ "SEM CARIMBO ⇒ O CORE" só vale quando este script MORA no repo medido. No plugin `onion-meta` ele
#    mora na raiz do plugin e o projeto que o instalou não tem carimbo: sem esta conferência a régua de
#    um produto qualquer saía `onion` (achado da passada adversarial, 2026-10-15). Fonte DESACOPLADA
#    (`role: source` + `decoupled_from:`) é soberana, de linhagem própria: régua = o id dela, não o Onion.
_self_regua() {
  local stamp="${REPO}/.claude/.onion-version" role kind dec url id here mine
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"
  mine="$(cd "${REPO}/.claude/validation" 2>/dev/null && pwd -P)"
  if [ ! -f "${stamp}" ]; then
    if [ -n "${here}" ] && [ "${here}" = "${mine}" ]; then printf 'onion\tsem carimbo .claude/.onion-version (o core)\n'; return; fi
    role="nenhum (sem carimbo; o medidor mora fora do repo, ex. plugin)"
  else
    role="$(awk '/^role:/{print $2; exit}' "${stamp}" | tr -d "\"'\r")"
    kind="$(awk '/^kind:/{print $2; exit}' "${stamp}" | tr -d "\"'\r")"
    dec="$(awk '/^decoupled_from:/{print $2; exit}' "${stamp}" | tr -d "\"'\r")"
    if [ "${kind}" = "door" ]; then printf 'onion\tcarimbo kind: door (porta = projeção do core)\n'; return; fi
    if [ "${role}" = "source" ] && [ -z "${dec}" ]; then printf 'onion\tcarimbo role: source\n'; return; fi
    [ -z "${dec}" ] || role="${role} desacoplada de ${dec}"
  fi
  url="$(git -C "${REPO}" remote get-url origin 2>/dev/null || true)"
  id="$(printf '%s' "${url}" | sed -E 's#/+$##; s#.*[/:]##; s#\.git$##')"
  if [ -n "${id}" ]; then printf '%s\tcarimbo role: %s · id = remote origin\n' "${id}" "${role:-adopted}"; return; fi
  id="$(basename "$(git -C "${REPO}" rev-parse --show-toplevel 2>/dev/null || printf '%s' "${REPO}")")"
  printf '%s\tcarimbo role: %s · id = pasta raiz (sem remote origin)\n' "${id}" "${role:-adopted}"
}
SELF_REGUA_LINE="$(_self_regua)"; SELF_REGUA="${SELF_REGUA_LINE%%	*}"
if [ "${FMT}" = "--regua-padrao" ]; then printf '%s\n' "${SELF_REGUA_LINE}"; exit 0; fi

mapfile -t GRAPHS < <(git -C "${REPO}" ls-files -- '*.kg.yaml' 2>/dev/null | sort -u)
[ "${#GRAPHS[@]}" -gt 0 ] \
  || { echo "dissect-census: nenhum .kg.yaml RASTREADO em ${REPO} — sem corpus não há censo a emitir. Recusa." >&2; exit 3; }

TODAY="$(date +%F)"


# ── Leitura de UM grafo ────────────────────────────────────────────────────────────────────
# Os marcadores são lidos com grep ancorado e o resultado DRENADO: nenhum fechador precoce
# (`grep -q`/`head`) a jusante de escritor grande, que sob `set -o pipefail` devolve 141 e faz
# a peça existente contar como ausente — classe pipefail-epipe-early-closer, curada aqui por
# construção (laços que leem até o fim).
rows=""; parked=""; found=0
for rel in "${GRAPHS[@]}"; do
  f="${REPO}/${rel}"
  [ -f "${f}" ] || continue

  tool="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_tool:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\2/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "${tool}" ] || continue
  found=$((found + 1))

  # NÍVEL ALCANÇADO = o MAIOR nível declarado em qualquer nó. Maior, não último: a ordem no
  # arquivo não é a ordem da escada, e confiar nela seria ler a projeção como fonte.
  level=0
  while IFS= read -r lv; do
    case "${lv}" in ''|*[!0-9]*) continue ;; esac
    [ "${lv}" -gt "${level}" ] && level="${lv}"
  done < <(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_level:[[:space:]]*\([0-9]\+\).*/\2/p' "${f}")

  # RÉGUA: contra quem N1/N3/N4 foram julgados. Ausente = o Onion (o comportamento de sempre).
  against="$(sed -n 's/^[[:space:]]*x_dissect_against:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\1/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "${against}" ] || against="onion"
  # ESCOPO: o componente do repo contra o qual N1/N3/N4 se mediram. Ausente = `-` (o repo inteiro).
  scope="$(sed -n 's/^[[:space:]]*x_dissect_scope:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\1/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "${scope}" ] || scope="-"
  mode="$(sed -n 's/^[[:space:]]*x_dissect_mode:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#[:space:]]*\).*/\1/p' "${f}" | head -1)"

  verdict="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_verdict:[[:space:]]*["'"'"']\{0,1\}\([a-z]*\).*/\2/p' "${f}" | head -1)"
  [ -n "${verdict}" ] || verdict="-"
  # ⚠️ DATA ENTRE ASPAS é a forma que a gramática EXIGE desde o contrato v3 (`yaml.unquoted-date`),
  #    e a 1a versão deste sed só lia a data NUA: a 2a dissecação do corpus (conductor-2026-10,
  #    escrita pela gramática) saiu NAO-DECLARADO no dogfood do SAC-77, com review_after presente.
  #    A aspa (simples ou dupla) é opcional na leitura; o grafo herdado sem aspa segue lido.
  baseline="$(sed -n 's/^[[:space:]]*baseline:[[:space:]]*["'"'"']\{0,1\}\([0-9-]\{10\}\).*/\1/p' "${f}" | head -1)"
  [ -n "${baseline}" ] || baseline="-"
  review="$(sed -n 's/^[[:space:]]*review_after:[[:space:]]*["'"'"']\{0,1\}\([0-9-]\{10\}\).*/\1/p' "${f}" | head -1)"
  [ -n "${review}" ] || review="-"

  # FRESCOR: comparação lexical de ISO-8601 é correta e dispensa `date -d` (que difere entre
  # GNU e BSD). Sem `review_after` a resposta é NAO-DECLARADO, nunca "fresco" por omissão.
  if [ "${review}" = "-" ]; then fresh="NAO-DECLARADO"
  elif [ "${review}" \< "${TODAY}" ]; then fresh="VENCIDO"
  else fresh="fresco"; fi

  # ESTADO: estudo é parada DECLARADA no N2; sem o marcador, a mesma parada é interrompida.
  # Estudo que passa do N2, que traz veredito ou que não deixa a `question` aberta contradiz o
  # próprio modo — sai INCOERENTE com o motivo, nunca "estudo" por omissão.
  if [ "${mode}" = "study" ]; then
    incoh=""
    [ "${level}" -le 2 ] || incoh="${incoh},nivel-acima-de-N2"
    [ "${verdict}" = "-" ] || incoh="${incoh},com-veredito"
    open_q="$(awk '
      function flush() { if (q && o) f = 1; q = 0; o = 0 }
      /^[[:space:]]*- id:/                                   { flush(); next }
      /^edges:/                                              { flush(); next }
      /^[[:space:]]*node_type:[[:space:]]*["\047]?question/  { q = 1 }
      /^[[:space:]]*status:[[:space:]]*["\047]?open/         { o = 1 }
      END { flush(); print f + 0 }' "${f}")"
    [ "${open_q}" = "1" ] || incoh="${incoh},sem-question-aberta"
    if [ -n "${incoh}" ]; then state="estudo-INCOERENTE(${incoh#,})"; else state="estudo"; fi
  elif [ -n "${mode}" ]; then state="modo-DESCONHECIDO(${mode})"
  elif [ "${verdict}" = "rejeitar" ] || [ "${verdict}" = "parquear" ]; then
    # SAC-151: o nó da reprovação é o que carrega x_dissect_verdict; os marcadores moram NELE.
    # Leitura tolerante à forma (achados do refutador, 2026-10-15): aspas e comentário `# …` saem do valor;
    # o id da superação tem de ser do alfabeto do radar; a aresta é lida por ITEM do bloco `edges:` (from,
    # to e edge_type do MESMO item) e só TRACES_TO (a superação nasce da reprovação) ou SUPPORTS (evidência
    # que já existia e sustenta a decisão) contam — REFUTES/CONSTRAINS não são superação.
    # ⚠️ SEPARADOR \037 (US), NUNCA TAB: tab é IFS-WHITESPACE para o `read`, e tabs seguidos COLAPSAM —
    #    com `x_dissect_criterion:` vazio a medida caía em og_ov e o estado acusava `superacao-id-invalido`
    #    (achado de campo da sessão de curadoria, 2026-10-16). O mesmo colapso pegava o id vazio (veredito
    #    no `meta:`, antes de qualquer `- id:`) e o overcoming vazio com medida. Com separador que não é
    #    whitespace, campo vazio fica vazio no lugar dele.
    ogm="$(awk '
      function val(s) { sub(/^[^:]*:[[:space:]]*/, "", s); sub(/[[:space:]]+#.*$/, "", s); gsub(/^["\047]|["\047][[:space:]]*$/, "", s); sub(/[[:space:]]+$/, "", s); return s }
      function flush() { if (isv) { printf "%s\037%s\037%s\037%s\n", id, crit, ov, meas; done = 1 } isv = 0; crit = ""; ov = ""; meas = ""; id = "" }
      done { next }
      /^[[:space:]]*- id:/ { flush(); if (done) next; id = val($0); next }
      /^edges:/ { flush(); next }
      /^[[:space:]]*(x_)?dissect_verdict:/ { isv = 1 }
      /^[[:space:]]*x_dissect_criterion:/ { crit = val($0) }
      /^[[:space:]]*x_dissect_overcoming:/ { ov = val($0) }
      /^[[:space:]]*x_dissect_overcoming_measure:/ { meas = val($0) }
      END { if (!done) flush() }' "${f}")"
    IFS=$'\037' read -r og_id og_crit og_ov og_meas <<< "${ogm}"
    ogwhy=""
    # critério = um COMANDO com argumento (≥ 8 caracteres e um espaço), nunca "sim"
    { [ "${#og_crit}" -ge 8 ] && [[ "${og_crit}" == *" "* ]]; } || ogwhy="${ogwhy},sem-x_dissect_criterion"
    if [ -z "${og_ov}" ]; then ogwhy="${ogwhy},sem-x_dissect_overcoming"
    elif [ "${og_ov}" = "nenhuma" ]; then
      # a razão MEDIDA tem palavras (duas com letra), não pontuação de enchimento
      [ "$(printf '%s' "${og_meas}" | LC_ALL=C tr -s '[:space:]' '\n' | LC_ALL=C grep -c '[A-Za-z]')" -ge 2 ] || ogwhy="${ogwhy},nenhuma-sem-medida"
    elif ! [[ "${og_ov}" =~ ^[A-Za-z0-9_]+$ ]]; then ogwhy="${ogwhy},superacao-id-invalido"
    # veredito SEM id (declarado no `meta:`, antes de qualquer `- id:`): não há nó para a aresta da
    # superação apontar, e com d="" uma aresta SEM `to:` casava `to == d` e a busca de circularidade
    # semeava do vazio (achado do refutador, 2026-10-16). `nenhuma` medida segue valendo no meta:.
    elif [ -z "${og_id}" ]; then ogwhy="${ogwhy},superacao-sem-id-do-veredito"
    else
      grep -qE "^[[:space:]]*- id:[[:space:]]*[\"']?${og_ov}[\"']?[[:space:]]*(#.*)?\$" "${f}" || ogwhy="${ogwhy},superacao-${og_ov}-inexistente"
      awk -v s="${og_ov}" -v d="${og_id}" '
        function val(x) { sub(/^[^:]*:[[:space:]]*/, "", x); sub(/[[:space:]]+#.*$/, "", x); gsub(/^["\047]|["\047][[:space:]]*$/, "", x); sub(/[[:space:]]+$/, "", x); return x }
        function item() { if (fr == s && to == d && (et == "TRACES_TO" || et == "SUPPORTS")) ok = 1; fr = ""; to = ""; et = "" }
        /^edges:/ { e = 1; next }
        e && /^[^[:space:]-]/ { item(); e = 0 }
        !e { next }
        /^[[:space:]]*-[[:space:]]/ { item(); line = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", line); $0 = line }
        /^[[:space:]]*from:/ { fr = val($0) }
        /^[[:space:]]*to:/ { to = val($0) }
        /^[[:space:]]*edge_type:/ { et = val($0) }
        END { item(); exit ok ? 0 : 1 }' "${f}" || ogwhy="${ogwhy},sem-aresta-${og_ov}-para-${og_id:-?}"
      # 2ª leva (SAC-151): superação de CONSOLO. Achado de campo de um adotante de curadoria (PR #30, DADO): a
      # 1ª versão do pagamento da dívida passou aqui com 4 superações que só o Elenxo reprovou. O que a FORMA
      # do grafo deixa ver, recusa-se aqui (o resto vai como pergunta ao juiz, na doutrina):
      #   · CIRCULAR — o próprio nó do veredito, ou um nó que DERIVA dele por OUTRO caminho que não a aresta
      #     declarada da superação. Derivação POR TIPO de aresta (medida no contrato: a decisão aponta a origem
      #     com TRACES_TO): `A SUPPORTS B` e `A CAUSES B` ⇒ B deriva de A; `A TRACES_TO B` e `A DEPENDS_ON B` ⇒
      #     A deriva de B. REFUTES/CONSTRAINS/SUPERSEDES não derivam. A aresta S→D que liga a superação ao
      #     veredito fica FORA da busca: é a forma que a doutrina pede (S TRACES_TO D = nasceu da reprovação;
      #     S SUPPORTS D = já existia e sustenta) — distinguir as duas por estrutura é impossível (declarado).
      #     O ANCESTRAL que sustenta é a forma LEGÍTIMA (a única superação real medida, o OCR local do
      #     markitdown, é `E SUPPORTS D`), logo não é recusado; `D TRACES_TO S` (D cita S como fonte) também não;
      #   · NÃO MEDIDA — status fora de confirmed|done (open = condição ou cura em curso), sem verified_at ou
      #     fora de AAAA-MM-DD, verified_at (10 primeiros caracteres) DEPOIS de hoje, verified_against vazio
      #     ou sem 3 caracteres alfanuméricos (`-`, `?`, `0`) ou n/a|null|none|tbd|todo;
      #   · ANCORADA NO CRITÉRIO — verified_against/trace do nó É o x_dissect_criterion (igualdade sem espaços):
      #     mede a reprovação, não a entrega. Só a igualdade: citar o critério aplicado à variante é a forma
      #     mais forte de medir (achado do refutador, 2026-10-15), e a inclusão a recusaria.
      # Campos lidos só na indentação do próprio nó (id + 2), não em sub-blocos. Critério via ENVIRON (o -v do
      # awk interpreta barra invertida). NÃO detectado (declarado): o STATUS QUO rotulado de superação e o
      # placeholder em prosa num nó confirmed (o verified_against da superação real é um token hifenizado,
      # igual ao de um placeholder) — exigiria palavra-chave frágil; é a pergunta obrigatória da doutrina.
      ogc="$(OG_CRIT="${og_crit}" awk -v s="${og_ov}" -v d="${og_id}" -v today="${TODAY}" '
        function val(x) { sub(/^[^:]*:[[:space:]]*/, "", x); sub(/[[:space:]]+#.*$/, "", x); gsub(/^["\047]|["\047][[:space:]]*$/, "", x); sub(/[[:space:]]+$/, "", x); return x }
        function squash(x) { x = tolower(x); gsub(/["\047`[:space:]]/, "", x); return x }
        function ind(x) { match(x, /^[[:space:]]*/); return RLENGTH }
        function item() { if (fr != "" && to != "" && !(fr == s && to == d)) {
            if (et == "SUPPORTS" || et == "CAUSES") { n++; P[n] = fr; C[n] = to }
            else if (et == "TRACES_TO" || et == "DEPENDS_ON") { n++; P[n] = to; C[n] = fr } }
          fr = ""; to = ""; et = "" }
        /^edges:/ { e = 1; next }
        e && /^[^[:space:]-]/ { item(); e = 0 }
        !e && /^[[:space:]]*- id:/ { cur = val($0); fi = ind($0) + 2; next }
        !e && cur == s && ind($0) == fi && /^[[:space:]]*status:/ { st = val($0) }
        !e && cur == s && ind($0) == fi && /^[[:space:]]*verified_at:/ { va = val($0) }
        !e && cur == s && ind($0) == fi && /^[[:space:]]*verified_against:/ { vg = val($0) }
        !e && cur == s && ind($0) == fi && /^[[:space:]]*trace:/ { tr = val($0) }
        !e { next }
        /^[[:space:]]*-[[:space:]]/ { item(); line = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", line); $0 = line }
        /^[[:space:]]*from:/ { fr = val($0) }
        /^[[:space:]]*to:/ { to = val($0) }
        /^[[:space:]]*edge_type:/ { et = val($0) }
        END {
          item(); why = ""
          if (s == d) { print ",superacao-circular-e-o-proprio-veredito"; exit }
          R[d] = 1; ch = 1; while (ch) { ch = 0; for (i = 1; i <= n; i++) if ((P[i] in R) && !(C[i] in R)) { R[C[i]] = 1; ch = 1 } }
          if (s in R) why = why ",superacao-circular-deriva-do-veredito"
          if (st != "confirmed" && st != "done") why = why ",superacao-nao-medida-status-" (st == "" ? "ausente" : st)
          if (va == "") why = why ",superacao-sem-verified_at"
          else if (va !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) why = why ",superacao-verified_at-ilegivel"
          else if (substr(va, 1, 10) > today) why = why ",superacao-carimbo-futuro-" substr(va, 1, 10)
          lv = tolower(vg); al = vg; gsub(/[^A-Za-z0-9]/, "", al)
          if (vg == "" || length(al) < 3 || lv ~ /^(n\/a|null|none|tbd|todo)$/) why = why ",superacao-sem-verified_against"
          c = squash(ENVIRON["OG_CRIT"])
          if (length(c) >= 8 && (squash(vg) == c || squash(tr) == c)) why = why ",superacao-ancorada-no-criterio"
          print why }' "${f}")"
      ogwhy="${ogwhy}${ogc}"
    fi
    if [ -n "${ogwhy}" ]; then state="veredito-SEM-SUPERACAO(${ogwhy#,})"; else state="veredito"; fi
  elif [ "${verdict}" != "-" ]; then state="veredito"
  else state="interrompida"; fi

  rows="${rows}${tool}	${level}	${verdict}	${baseline}	${review}	${fresh}	${rel}	${against}	${state}	${scope}
"
  # parqueada que o gate RECUSOU não é parque (achado do refutador): sai só na seção dos recusados
  [ "${verdict}" = "parquear" ] && [ "${state}" = "veredito" ] && parked="${parked}${tool}	${rel}
"
done

sorted_rows="$(printf '%s' "${rows}" | sort -t'	' -k2,2nr -k1,1)"

if [ "${FMT}" = "--check-verdict" ]; then
  line="$(printf '%s\n' "${sorted_rows}" | awk -F'\t' -v t="${CHECK_TOOL}" '$1 == t { print; exit }')"
  [ -n "${line}" ] || { echo "dissect-census: ferramenta '${CHECK_TOOL}' não declarada (x_dissect_tool:) em nenhum grafo rastreado" >&2; exit 3; }
  # TAB aqui é seguro (medido, 2026-10-16): toda coluna de `rows` nasce não-vazia (padrão `-`/`onion`/`0`,
  # ferramenta e grafo exigidos), então não há tabs seguidos a colapsar. Coluna nova que possa sair
  # vazia tem de ganhar padrão — ou este read passa a errar de campo como o do veredito negativo errava.
  IFS='	' read -r _t _lv cv_verdict _b _r _fr cv_graph _ag cv_state _sc <<< "${line}"
  case "${cv_state}" in
    veredito) echo "dissect-census: ${CHECK_TOOL} — veredito ${cv_verdict} conta (${cv_graph})"; exit 0 ;;
    veredito-SEM-SUPERACAO*) echo "dissect-census: ${CHECK_TOOL} — veredito NEGATIVO ${cv_verdict} RECUSADO: ${cv_state} (${cv_graph}). Declare x_dissect_criterion e x_dissect_overcoming no nó da reprovação; se a superação apontada não ENTREGA (motivo superacao-*), declare x_dissect_overcoming: nenhuma com x_dissect_overcoming_measure — nenhuma honesta é veredito válido." >&2; exit 1 ;;
    *) echo "dissect-census: ${CHECK_TOOL} — sem veredito que conte: estado ${cv_state} (${cv_graph})" >&2; exit 1 ;;
  esac
fi

if [ "${FMT}" = "--tsv" ]; then
  # régua e estado entram no FIM: as colunas 1-7 seguem onde estavam para quem já as lê.
  printf 'ferramenta\tnivel\tveredito\tbaseline\treview_after\tfrescor\tgrafo\tregua\testado\tescopo\n'
  [ "${found}" -gt 0 ] && printf '%s\n' "${sorted_rows}"
  exit 0
fi

# ── Markdown: a projeção que entra na superfície como contexto injetado ────────────────────
printf '# censo de dissecações · %s grafo(s) rastreado(s) · %s dissecação(ões) declarada(s)\n' \
  "${#GRAPHS[@]}" "${found}"
printf '\nrégua padrão deste repo: **%s** (%s) — vale quando o dissect roda sem `--against`, e é\n' \
  "${SELF_REGUA}" "${SELF_REGUA_LINE#*	}"
printf 'gravada em `meta.x_dissect_against`; `--scope` a estreita a um componente (`meta.x_dissect_scope`).\n'
if [ "${found}" -eq 0 ]; then
  printf '\nNenhum grafo do corpus se declara dissecação (marcador `x_dissect_tool:` no `meta:`).\n'
  printf 'Toda ferramenta entra pelo N0 — não há nível pago a reusar.\n'
else
  # frescor fica na ÚLTIMA coluna de propósito: o evolve-census conta vencidas por `$NF`.
  printf '\nferramenta | nível | veredito | régua | escopo | estado | baseline | review_after | frescor\n'
  printf '%s\n' "${sorted_rows}" | awk -F'\t' 'NF>=10 && $1!=""{
    printf "%s | N%s | %s | %s | %s | %s | %s | %s | %s\n", $1, $2, $3, $8, $10, $9, $4, $5, $6 }'
  if [ -n "${parked}" ]; then
    printf '\n## parqueadas (técnica a investigar — exigem gatilho nomeado)\n'
    printf '%s' "${parked}" | awk -F'\t' '$1!=""{ printf "- %s  (%s)\n", $1, $2 }'
  fi
  _section() {  # $1=título $2=regex do estado (awk)
    local body; body="$(printf '%s\n' "${sorted_rows}" | awk -F'\t' -v re="$2" '$1!="" && $9 ~ re { printf "- %s · N%s · régua %s · escopo %s · %s  (%s)\n", $1, $2, $8, $10, $9, $7 }')"
    [ -z "${body}" ] || printf '\n## %s\n%s\n' "$1" "${body}"
  }
  _section 'estudos (pararam no N2 DE PROPÓSITO, sem veredito — a question "adotar?" segue aberta; decidir é dissecar de novo sem --study, entrando no N3)' '^estudo$'
  _section 'interrompidas (sem veredito e SEM marcador de estudo — retomar do nível alcançado ou fechar com veredito)' '^interrompida$'
  _section 'a corrigir (o grafo contradiz o próprio modo, ou declara modo que este censo não conhece)' '^(estudo-INCOERENTE|modo-DESCONHECIDO)'
  _section 'vereditos NEGATIVOS recusados (rejeitar/parquear sem critério checável ou sem superação — não contam como veredito; ver x_dissect_criterion e x_dissect_overcoming)' '^veredito-SEM-SUPERACAO'
fi
printf '\n(ferramenta com nível fresco ENTRA no nível seguinte — re-derivar nível pago é o\n'
printf 'desperdício que este censo corta. VENCIDO não se cita como se fosse de hoje: licença,\n'
printf 'mantenedor e preço mudam em semanas. TETO DECLARADO: o censo mede o que o corpus\n'
printf 'DECLARA, não sabe de ferramenta que ninguém anotou, e não confere se a medição do nível\n'
printf 'de fato ocorreu — o marcador é auto-atestado. RÉGUA: nível pago só se reusa na MESMA\n'
printf 'régua E no MESMO escopo — N0 e N2 descrevem a ferramenta, mas N1, N3 e N4 foram julgados\n'
printf 'contra a régua e o escopo das colunas, e contra outro alvo ou outro componente são outra\n'
printf 'pergunta. Escopo `-` = o repo inteiro.)\n'
