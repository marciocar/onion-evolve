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
#   · o baseline SÓ PODE ENCOLHER — acrescentar path é REGRESSÃO (HARD);
#   · e ENCOLHER SÓ VALE POR MEDIÇÃO — sair do escopo por reetiqueta é FUGA (HARD).
#   A métrica de saúde é o BASELINE DIMINUINDO, não o gate passando.
#
# ⚠️ O FAIL-OPEN QUE ESTA CATRACA TINHA — reproduzido em 2026-08-07, curado em 2026-08-08.
#   Bastava trocar UM nó `plane: PROD` / `impact>=4` de `confirmed` para `drifted`, SEM medir nada
#   e sem escrever uma linha de evidência, e o gate caía de 48 para 47 dizendo:
#       [OBSOLETA] entrada OBSOLETA (no ja carimbado ou removido) — remova do baseline
#   O gate AFIRMAVA um carimbo que não existia. Duas raízes, e as duas eram de desenho:
#     1. o predicado de escopo era ALLOWLIST (`st == "open" || st == "confirmed"`), em DUAS cópias.
#        `drifted` e `unverifiable` NASCERAM em 2026-08-06 como saída do `/meta:kg-freshness` — o
#        enum cresceu POR BAIXO do predicado. Allowlist quebra quando o enum cresce; denylist não.
#     2. o `OBSOLETA` não distinguia nó REMOVIDO de nó REETIQUETADO — e essa distinção É a catraca.
#   Sem isso, a única propriedade que funda a REGRA 49 ("a única forma de diminuir o número é MEDIR")
#   tinha porta dos fundos aberta, e ela se abria com um `sed`.
#
# ⚠️ MEIA-VIDA POR CLASSE — GATED, deliberadamente fora daqui.
#   Medido 2026-08-02: nós com `verified_at` VENCIDO (>30d) = ZERO. A doutrina do KG tem 29 dias;
#   nada teve tempo de envelhecer. Regra de expiração sobre conjunto vazio é cerimônia elegante.
#   GATILHO PARA ABRIR: >=20 nós no escopo com `verified_at` mais velho que 30 dias. Aí a classe
#   nasce com dado real. O desenho (derivar a classe do `trace:`/`verified_against:`, sem tocar a
#   gramática) está em `onion-adr-kg-halflife-2026-08` (core-only).
#
# Uso : bash .claude/validation/kg-verification-coverage.sh [<repo_root>] [--emit-baseline] [--format tsv]
# SEPARADORES (invariante, declarado UMA vez): registro INTERNO usa \037 (US); a SAIDA usa \t
#   porque e contrato externo — lint-artifacts.sh agrega a classe PASSIVO por ele. TAB NUNCA
#   volta para dentro: e IFS-whitespace, runs colapsam e campo vazio SOME, deslocando o resto
#   (selftests (t) e (t2)).
# TSV : sev<TAB>tag<TAB>path<TAB>msg  (mesmo contrato do kg-provenance-coverage.sh, para o lint
#       agregar a classe PASSIVO numa linha só — dezenas de linhas iguais afogam o acionável)
# Exit: 0 = sem HARD · 1 = HARD presente · 2 = erro de uso
set -uo pipefail

# Predicado de FIXTURE — caminho ABSOLUTO resolvido ANTES de qualquer `cd`, e ausência é FAIL-CLOSED.
# (A 1ª ligação usava `$(dirname "${BASH_SOURCE[0]}")` no ponto de uso e morria depois de um `cd`:
#  o erro era engolido por `|| true` e o script dizia "nenhum grafo" — verde por vacuidade. 2026-09-05.)
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "ERRO: predicado de fixture ausente (${_KFP}) — sem ele a varredura de grafos ficaria VAZIA e verde por vacuidade." >&2; exit 2; }

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

# ══ O PREDICADO DE ESCOPO — DENYLIST, SITE ÚNICO ═══════════════════════════════════════════════
# Era ALLOWLIST em DUAS cópias (ver o bloco do fail-open no cabeçalho). Agora existe UM literal, e
# ele é o único lugar do repo que decide o que a REGRA 49 enxerga.
#
# A denylist tem exatamente DOIS estados, e são os dois em que o nó DEIXA DE AFIRMAR sobre produção:
#   `superseded` — outro nó carrega a verdade agora;  `refuted` — a afirmação caiu.
# `open`, `confirmed`, `done`, `drifted` e `unverifiable` PERMANECEM no escopo. `drifted` mais que
# todos: é justamente o estado em que a reconciliação é DEVIDA, e era por onde a fuga passava.
#
# CUSTO MEDIDO no corpus real antes de escrever (PROD + impact>=4 + sem carimbo):
#   allowlist antiga: 43 confirmed + 5 open                       = 48
#   denylist nova   : os mesmos 48 + 0 drifted + 0 unverifiable + 0 done = 48
# A porta fecha SEM mexer no número — o que é o teste de que isto é cura, e não aperto disfarçado.
SCOPE_PREDICATE='
function inScope(plane, imp, st, ver) {
  return (plane == "PROD" && imp+0 >= 4 && ver == "" && st != "superseded" && st != "refuted")
}'

# ══ O UNIVERSE — UMA passada, TODOS os nós, TODOS os campos ════════════════════════════════════
# Antes eram DUAS varreduras idênticas (`scan` e `scan_named`) diferindo só no hash da saída — a
# mesma família de duplicação que deixou a allowlist em dois lugares. Agora os arquivos são lidos
# UMA vez e todo o resto é filtro sobre este TSV. E o guarda de direção PRECISA do universo inteiro,
# inclusive dos nós FORA do escopo: é exatamente a SAÍDA do escopo que ele julga.
#
# ⚠️ O flush é no DELIMITADOR do nó (`- id:` / EOF), NUNCA num campo. Erro real de 2026-08-02: a
# primeira medição fechava o nó no `label:` e contou 64 onde eram 53 — onze nós, como
# `C_COEVOLVE_VALUE` em onion-identity-2026-07.kg.yaml, têm `verified_at:` DEPOIS do `label:`, e o
# scanner lia o nó pela METADE, via `ver=""` e acusava falta de carimbo em nó carimbado. Instrumento
# que lê estado PARCIAL e reporta como FATO é `declarado != verificado` dentro do próprio medidor.
# ⚠️ O UNIVERSO VARRE **TUDO**, INCLUSIVE `fixtures/` — e a 7ª coluna diz se o path está no escopo.
# POR QUÊ (porta reproduzida em 2026-08-08): a varredura excluía `/fixtures/`, então UM `git mv` de
# um grafo para qualquer pasta `fixtures/` tirava o arquivo do universo, e as entradas dele do
# baseline viravam "nó que NÃO EXISTE MAIS" — cinco de uma vez, `exit 0`, tudo SOFT, com o gate
# MANDANDO removê-las. Os nós estavam intactos no disco, versionados, afirmando sobre produção.
# Resolver a chave exige o universo INTEIRO; filtrar o ESCOPO é outra pergunta, e agora são duas.
UNIVERSE=""; UNIVERSE_LOADED=0
load_universe() {
  [ "${UNIVERSE_LOADED}" -eq 1 ] && return 0
  local f in_scope
  # Isenção de FIXTURE pelo predicado ÚNICO (kg-fixture-paths.sh, 2026-09-05) — em UMA passada.
  # A 1ª ligação chamava `--is-fixture` DENTRO do laço: 121 forks, 0,02 s → 2,23 s medidos. Os outros
  # 4 consumidores já usavam `--filter` (1 fork); aqui a lista sai uma vez e é consultada em memória.
  local _fx; _fx="$(git ls-files '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --list-exempt-stdin || true)"
  UNIVERSE="$(for f in $(git ls-files '*.kg.yaml' 2>/dev/null); do
    case $'\n'"${_fx}"$'\n' in *$'\n'"${f}"$'\n'*) in_scope=0 ;; *) in_scope=1 ;; esac
    awk -v F="$f" -v D="${in_scope}" '
      function flush(   ) {
        if (id != "") printf "%s\037%s\037%s\037%s\037%s\037%s\037%s\n", F, id, plane, imp, st, ver, D
        id=""; plane=""; imp=0; ver=""; st=""
      }
      /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { flush(); id=$3; next }
      /^[[:space:]]*plane:[[:space:]]*/           { plane=$2; next }
      /^[[:space:]]*impact:[[:space:]]*/          { imp=$2+0;  next }
      /^[[:space:]]*verified_at:[[:space:]]*/     { ver=$2;    next }
      /^[[:space:]]*status:[[:space:]]*/          { st=$2;     next }
      END { flush() }
    ' "$f"
  done)"
  UNIVERSE_LOADED=1
}

# `path::sha1(id)\037id` — registro INTERNO, separado por US (\037) e nao por TAB. O irmao
# `resolve_key` foi corrigido no mesmo diff e este ficou para tras: comentario que descreve o
# formato errado e a semente do proximo parser errado. A CHAVE VERSIONADA nunca carrega o id cru.
# POR QUÊ (a REGRA 36 pegou isto na 1ª rodada, 2026-08-02): ids de nó carregam nome de adotante, e
# ESTE BASELINE VIAJA na superfície vendorizada — seria vazamento cross-tenant por adoção. O path já
# é público (está no repo); o id não precisa estar. O hash mantém a identidade estável sem publicar
# o nome. O id anda JUNTO em memória, só para a MENSAGEM (que não é versionada) poder nomear o nó —
# num corpus de 881 nós, "o arquivo tem problema" é inacionável.
scope_pairs() {
  load_universe
  printf '%s\n' "${UNIVERSE}" \
    | awk -F'\037' "${SCOPE_PREDICATE}"' $7 == 1 && inScope($3, $4, $5, $6) { printf "%s\037%s\n", $1, $2 }' \
    | while IFS=$'\037' read -r p id; do
        [ -n "${id}" ] || continue
        printf '%s::%s\037%s\n' "${p}" "$(printf '%s' "${id}" | sha1sum | cut -c1-12)" "${id}"
      done | sort -u
}

# resolve uma CHAVE do baseline contra o vivo → "id\037plane\037imp\037st\037ver" (US, nao TAB), ou vazio se o
# nó não existe mais. O hash aqui é LAZY: só roda quando há entrada FORA do escopo. No estado
# saudável (baseline == escopo) o custo é ZERO.
# Devolve "id\037plane\037imp\037st\037ver\037ondeAchou\037dentroDoEscopo", ou vazio se o nó nao existe
# em LUGAR NENHUM do corpus. `ondeAchou` é o path REAL — se diferir do path da chave, o grafo foi
# MOVIDO, e mover não é remover.
resolve_key() { # $1 = path::hash
  load_universe
  local p="${1%%::*}" h="${1##*::}" found
  # 1ª passada: no proprio path (o caso normal, e o barato)
  found="$(printf '%s\n' "${UNIVERSE}" | awk -F'\037' -v P="${p}" '$1 == P' \
    | while IFS=$'\037' read -r f id plane imp st ver in_scope; do
        [ "$(printf '%s' "${id}" | sha1sum | cut -c1-12)" = "${h}" ] || continue
        printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\n' "${id}" "${plane}" "${imp}" "${st}" "${ver}" "${f}" "${in_scope}"
      done | head -1)"
  [ -n "${found}" ] && { printf '%s\n' "${found}"; return 0; }
  # 2ª passada: o corpus INTEIRO — sobre um INDICE construido UMA VEZ.
  # ⚠️ CUSTO MEDIDO pelo Elenxo na versao anterior, que hasheava o universo a cada chave orfa:
  #   0 orfas → 0,88s · 5 orfas → 47,26s (~9,4s/chave) · 15 orfas → TIMEOUT (>120s).
  # O gate explodia EXATAMENTE no estado que estas classes existem para julgar. O indice e um
  # sha1sum por NO (nao por no × chave), e sai de O(chaves × nos) para O(nos).
  #
  # ⚠️ DEVOLVE TODOS OS MATCHES, UMA LINHA CADA — e o `head -1` que estava aqui era um FAIL-OPEN que
  # NASCEU neste diff. A chave é `path::sha1(id)`, e a 2ª passada joga o PATH fora: casa só o hash.
  # Medido no corpus: 13 ids DUPLICADOS entre grafos, e um deles (`E_ORBIT`) ESTÁ no baseline. Pior,
  # `.claude/validation/fixtures/...` é o PRIMEIRO do `git ls-files`, então num empate o fixture
  # SEMPRE vencia — e o gate acusava o operador de ter movido o grafo para dentro de um arquivo de
  # teste que ele nunca abriu. Antes deste diff o `grep -v '/fixtures/'` impedia esse vetor.
  # Empate não se desempata por ordem de arquivo: quem não sabe, DIZ que não sabe.
  load_hash_index
  printf '%s\n' "${HASH_INDEX}" | awk -F'\037' -v H="${h}" '$1 == H { sub(/^[^\037]*\037/, ""); print }'
}

# INDICE hash→registro, construido UMA vez e so quando a 2a passada e mesmo necessaria.
HASH_INDEX=""; HASH_INDEX_LOADED=0
load_hash_index() {
  [ "${HASH_INDEX_LOADED}" -eq 1 ] && return 0
  HASH_INDEX="$(printf '%s\n' "${UNIVERSE}" \
    | while IFS=$'\037' read -r f id plane imp st ver in_scope; do
        [ -n "${id}" ] || continue
        printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\n' \
          "$(printf '%s' "${id}" | sha1sum | cut -c1-12)" "${id}" "${plane}" "${imp}" "${st}" "${ver}" "${f}" "${in_scope}"
      done)"
  HASH_INDEX_LOADED=1
}

# ══ A ARESTA QUE JUSTIFICA A SAÍDA — e as três coisas que ela NÃO pode aceitar ═════════════════
# A 1ª versão casava `(ef == ID || eto == ID)` com o tipo DERIVADO do status. O Elenxo desta branch
# a derrubou com três rotas, duas delas medidas no corpus REAL e sem forjar uma linha:
#   · DIREÇÃO — um nó que REFUTA outro ganhava passe livre para se declarar `refuted`. OITO das 48
#     entradas do baseline são `from` de uma aresta REFUTES/SUPERSEDES: fugiam com UM `sed` no
#     `status:`. A convenção do corpus é inequívoca no outro sentido — nas 3 conformidades reais o
#     refutado/superseded é sempre o `to`.
#     (⚠️ a 1ª redação deste comentário NOMEAVA os oito nós, e o `vendor-scrub` reprovou: ids de nó
#     carregam nome de adotante e ESTE ARQUIVO viaja vendorizado. É a mesma REGRA 36 pela qual o
#     baseline guarda hash e não id — cometida no comentário que explica o hash. Conte, não liste.)
#   · DUAS PONTAS — `from: X / to: X / edge_type: REFUTES`, três linhas, comprava RECONCILIADO.
#     Um nó não se refuta sozinho.
#   · TIPO DERIVADO DO STATUS — exigir SUPERSEDES só porque o status é `superseded` acusa a
#     reconciliação que o `kg-radar.sh:620-621` SANCIONA: *"recebe REFUTES mas segue status=…
#     (reconciliar: refuted ou superseded)"*. Quem escolhe `superseded` nesse fork não tem — e não
#     deve ter — aresta SUPERSEDES. Mesma família dos 3 falsos-positivos que o Elenxo da REGRA 57
#     derrubou, e no mesmo grafo (`m2-bridge-logto`) que o contrato chama de "o dogfood CERTO".
# Logo o predicado é: aresta ENTRANDO (o nó é o `to`), com as DUAS PONTAS distintas, de qualquer um
# dos dois tipos de reconciliação. Não é *"existe uma aresta por perto"* — é *"ALGUÉM, que não ele
# mesmo, o reconciliou"*.
#
# Flush no DELIMITADOR (`- from:` / EOF), não posicional: o `kg-seal-check.sh` guarda `to:` e consome
# no `edge_type:`, o que só funciona porque as arestas do corpus estão na ordem canônica — dívida
# declarada no Elenxo dele. Aqui a ordem from/edge_type/to é indiferente.
has_reconciliation_edge() { # $1=arquivo $2=id → exit 0 se ALGUÉM reconciliou o nó
  awk -v ID="$2" '
    function flush(   ) {
      if (ef != "" && ef != eto && eto == ID && (et == "REFUTES" || et == "SUPERSEDES")) found=1
      ef=""; et=""; eto=""
    }
    /^[[:space:]]*-[[:space:]]*from:[[:space:]]*/ { flush(); ef=$3;  next }
    /^[[:space:]]*to:[[:space:]]*/                { eto=$2; next }
    /^[[:space:]]*edge_type:[[:space:]]*/         { et=$2;  next }
    END { flush(); exit(found ? 0 : 1) }
  ' "$1"
}

# ⚠️ IÇADO DE PROPÓSITO, e a linha vale 12 segundos. `load_universe` memoiza numa variável de
# shell, e TODO consumidor abaixo roda em command substitution — a atribuição morria com o subshell
# e o universo era relido a CADA chave. Medido no estado-ALVO da própria catraca (os 48 nós já
# medidos): 19,9s contra 0,67s do script que este substitui. Chamando aqui, no escopo pai, os
# subshells HERDAM: 7,4s, saída byte-idêntica. O gradiente era perverso — quanto mais a doutrina
# fosse obedecida, mais lento ficaria o gate que a cobra.
load_universe

PAIRS="$(scope_pairs)"
UNVERIFIED="$(printf '%s\n' "${PAIRS}" | cut -d$'\037' -f1 | grep -v '^$' || true)"

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
# O baseline do commit ANTERIOR. Lido aqui, e não lá embaixo no bloco (3), porque o laço (2) precisa
# dele: ver TO_JUDGE.
# ⚠️ O `prev` NAO PODE VIR DO HEAD, e este era o defeito mais silencioso da catraca inteira.
# Medido em 2026-08-08: `git show HEAD:` le o baseline COMO COMMITADO no HEAD. No pre-commit isso
# funciona (o HEAD ainda e o commit ANTERIOR), mas no CI o checkout E do commit — logo
# `prev == known` SEMPRE, a comparacao e do commit contra ele mesmo, e a catraca de crescimento
# (bloco 3) NUNCA dispara justamente onde ela deveria valer: no gate auditado por terceiro,
# desacoplado do ator, que e a propriedade escrita no cabecalho deste arquivo.
# A base certa e o PONTO DE RAMIFICACAO — "o baseline cresceu desde que esta branch nasceu?".
# Fallback declarado, em cascata, para quando nao ha merge-base (repo novo, main sem remoto, ou
# rodando NA propria main): HEAD~1. Se nem isso existir, `prev` fica vazio e o bloco (3) se cala —
# que e o comportamento ja existente para repo sem historico.
# ⚠️ E O REF TEM DE **CONTER** O BASELINE — senao `prev` fica vazio e o bypass VOLTA INTEIRO.
# Medido pelo Elenxo num cenario REAL, nao forjado (adotante recem-instalado, cujo baseline NASCE na
# propria branch): o merge-base nao tem o arquivo, `git show` falha, `prev=""`, e ai
# `TO_JUDGE = known` (a chave apagada some do julgamento) E o bloco (3) se cala inteiro
# (`if [ -n "${prev}" ]`). Resultado medido: 48→43, cinco nos PROD/impact>=4 apagados, ZERO medicao,
# exit 0. Ou seja: o commit que fechou uma porta reabriu a mesma pelo outro lado.
# A cura e andar para tras ate o ancestral mais recente que TENHA o baseline — o que responde
# "o baseline encolheu desde a ultima vez que ele existiu?", que e a pergunta que a catraca faz.
_has_baseline() { git cat-file -e "$1:.claude/validation/kg-verification-baseline.txt" 2>/dev/null; }
_baseline_ref() {
  local c b last_same=""
  # A BASE E O PRIMEIRO ANCESTRAL (HEAD inclusive) CUJO BASELINE **DIFERE** DO ATUAL.
  # As duas tentativas anteriores erraram por olhar a IDENTIDADE do commit em vez do CONTEUDO:
  #   · "nunca o HEAD"  → quebrava o pre-commit, onde a mutacao esta no working tree e o HEAD e a
  #     base certa (quatro selftests cairam em SEM-BASE);
  #   · "o HEAD se o baseline dele diferir do meu" → quebrava o caso em que o baseline NAO muda e so
  #     o grafo muda, que e a metade dos cenarios.
  # Perguntar pelo CONTEUDO resolve os dois de uma vez, e resolve tambem o buraco do CI: la o HEAD
  # tem o baseline JA ENCOLHIDO, entao ele nao "difere" e a busca continua ate o commit anterior ao
  # encolhimento — que e exatamente contra quem a catraca precisa comparar.
  # 0o: PRE-COMMIT. Com a arvore SUJA, a mudanca que se julga esta no WORKING TREE e o HEAD e a base
  # — inclusive numa branch sem commit nenhum, onde `merge-base == HEAD` e a regra 1 nao se aplica.
  # Sem este degrau a busca por conteudo andava historia adentro e ressuscitava entradas ha muito
  # quitadas (medido: 5 SOFT de nos carimbados em 2026-08-04, ruido perpetuo no corpus limpo).
  # Pre-commit e pos-commit sao situacoes DIFERENTES, e tratar as duas com uma regra so foi o que
  # me fez errar tres vezes seguidas nesta funcao.
  if ! git diff --quiet HEAD 2>/dev/null && _has_baseline HEAD; then printf 'HEAD'; return 0; fi

  # 1o: o PONTO DE RAMIFICACAO, que e a base semantica de um PR — "o baseline encolheu desde que
  # esta branch nasceu?". So ele evita que a busca por conteudo ande historia adentro e ressuscite
  # entradas ha muito quitadas (medido: sem esta prioridade, o corpus limpo ganhava 5 SOFT de nos
  # legitimamente carimbados em 2026-08-04 — ruido perpetuo).
  b="$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || true)"
  if [ -n "${b}" ] && [ "${b}" != "$(git rev-parse HEAD 2>/dev/null)" ] && _has_baseline "${b}"; then
    printf '%s' "${b}"; return 0
  fi
  # 2o: sem ponto de ramificacao util (rodando NA main, repo de uma branch so, ou base sem o
  # arquivo — o caso do adotante recem-instalado), cai para o CONTEUDO.
  for c in $(git rev-list --max-count=200 HEAD 2>/dev/null); do
    _has_baseline "${c}" || continue
    b="$(git show "${c}:.claude/validation/kg-verification-baseline.txt" 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | sort -u)"
    [ "${b}" != "${known}" ] && { printf '%s' "${c}"; return 0; }
    last_same="${c}"
  done
  # nenhum ancestral DIFERE: ou nada mudou, ou o baseline nasceu identico. Usar o mais recente que o
  # tenha e correto e mantem `prev` nao-vazio (o vazio silencia a guarda inteira — foi o bypass).
  printf '%s' "${last_same:-}"
  return 0
}

BASE_REF="$(_baseline_ref)"
prev="$([ -n "${BASE_REF}" ] && git show "${BASE_REF}:.claude/validation/kg-verification-baseline.txt" 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | sort -u || true)"

# ⚠️ O UNIVERSE DE JULGAMENTO É `prev ∪ known`, NÃO `known`. O Elenxo desta branch reproduziu o
# bypass total: reetiquetar o nó E apagar a linha do baseline NO MESMO COMMIT. Iterando só o baseline
# ATUAL, a chave apagada some do julgamento e ninguém a classifica; e o bloco (3) só reprova quando
# o baseline CRESCE, então encolher era sempre livre. Saída medida antes da correção:
#   `exit=0 · 0 VIOLATION · no escopo sem carimbo: 47 · passivo tolerado: 47 · HARD: 0`
# O custo do bypass tinha subido de UM `sed` para UM `sed` + UM `grep -v` — e o desenho punia quem
# fazia a coisa MENOS encoberta (deixava a linha e levava HARD) e liberava quem apagava o rastro
# inteiro. Com a união, a linha apagada continua sendo cobrada até que o nó explique a própria saída.
TO_JUDGE="$(printf '%s\n%s\n' "${prev}" "${known}" | grep -v '^$' | sort -u || true)"
hard=0; soft=0

# (1) nó sem carimbo FORA do baseline → HARD (nasce verificado)
# O id vem JUNTO da chave (`PAIRS`), então a mensagem nomeia o nó sem nenhuma busca reversa — a
# versão anterior refazia sha1 dentro de um `cmd | getline` por candidato só para reencontrar o nome.
while IFS=$'\037' read -r n nid; do
  [ -n "${n}" ] || continue
  if ! printf '%s\n' "${known}" | grep -qxF "${n}"; then
    emit HARD NOVO "${n%%::*}" \
      "no '${nid:-<id oculto>}' e plane:PROD impact>=4 SEM verified_at e FORA do baseline — meca contra o vivo antes de selar (/meta:kg-freshness), ou o grafo afirma sobre producao sem nunca ter olhado."
    hard=$((hard+1))
  fi
done <<< "${PAIRS}"

# ══ (2) GUARDA DE DIREÇÃO — POR QUE esta entrada saiu do escopo? ═══════════════════════════════
# ANTES: toda saída virava um SOFT único — "OBSOLETA — no ja carimbado ou removido". A mensagem
# AFIRMAVA um carimbo sem nunca ter olhado se ele existia, e era FALSA em todo caso de reetiqueta.
# É o `declarado != verificado` dentro do instrumento que existe para cobrar verificação.
#
# AGORA a saída é CLASSIFICADA contra o vivo. DUAS classes são legítimas e TRÊS são fuga:
#   CARIMBADO        o nó está lá e ganhou `verified_at`                          → SOFT (é a saída que o gate EXISTE para produzir)
#   RECONCILIADO     virou refuted/superseded COM a aresta que justifica          → SOFT
#   REMOVIDO         o nó não existe mais naquele arquivo                         → HARD
#   FUGA-SEM-ARESTA  virou refuted/superseded por reetiqueta NUA, sem aresta      → HARD
#   FUGA-DE-ESCOPO   segue sem carimbo e saiu rebaixando plane/impact             → HARD
#
# ⚠️ ESTA TABELA JA MENTIU, e o defeito e instrutivo: ela dizia `REMOVIDO → SOFT (ato visivel no
# diff)` e "tres classes legitimas" DEPOIS de 2026-08-08, quando o PR da 2a porta ja tinha trocado a
# emissao para HARD. Comportamento mudou, doutrina nao — `declarado != verificado` DENTRO do
# cabecalho do gate que existe para cacar isso, e sobrevivendo a uma passada adversarial inteira.
# O motivo do HARD, que e o que a tabela precisa carregar: o grafo JA TEM a forma honesta de
# aposentar um no — `superseded`/`refuted` COM a aresta, que sai SOFT pelo ramo RECONCILIADO.
# Deletar e o atalho que pula a aresta, e apagar tambem encolhe o baseline sem medir.
# Quem editar a emissao tem de editar ESTA tabela no mesmo commit; nao ha guarda mecanica ligando as
# duas, e por isso o aviso mora aqui, colado nela.
#
# ⚠️ SOBRE A COBERTURA DESTE BLOCO — a versão anterior deste comentário afirmava um número que
# NINGUÉM OBSERVOU, e o Elenxo o falsificou em um comando. Ela dizia: *"sem a checagem de aresta o
# guarda acusaria 3 CONFORMIDADES"*. FALSO. Hoje `--emit-baseline` é IDÊNTICO ao baseline versionado,
# logo este laço NUNCA EXECUTA no corpus real, e nenhum dos 3 nós citados está no baseline. Medição:
#   sed 's/exit(found ? 0 : 1)/exit(1)/' kg-verification-coverage.sh > /tmp/sem-aresta.sh
#   bash /tmp/sem-aresta.sh --format tsv | awk -F'\t' '{print $1,$2}' | sort | uniq -c
#   → 48 SOFT PASSIVO, ZERO HARD
# A checagem é PREVENTIVA, e o que prova que ela discrimina é o selftest (p), não o corpus. Escrever
# consequência não-observada no cabeçalho de um gate cuja tese é `declarado != verificado` é o
# defeito da própria REGRA 49 cometido dentro do instrumento — por isso a correção fica aqui, com o
# comando que a falsifica junto.
#
# ⚠️ E o corolário, que é o fio mais honesto deste PR: as CINCO classes abaixo não têm NENHUMA
# cobertura de campo. Toda a evidência é sintética. O primeiro nó que sair do baseline de verdade —
# via `/meta:kg-freshness` — é o PRIMEIRO dogfood real desta guarda. O verde do CI não substitui isso.
# ⚠️ O INDICE E ICADO AQUI, e a razao e a MESMA que ja pegou o `load_universe` neste arquivo:
# `resolve_key` roda em command substitution, entao qualquer memoizacao feita LA DENTRO morre com o
# subshell e o indice era reconstruido A CADA CHAVE. Medido: 15 chaves orfas = 2m58s. Icado, o custo
# e UM sha1sum por no, uma vez — e so quando existe orfa, para o corpus limpo seguir em ~0,8s.
# (Eu ja tinha consertado exatamente este erro no `load_universe` e o repeti no indice.)
_orphans="$(printf '%s\n' "${TO_JUDGE}" | grep -v '^$' | grep -vxF -f <(printf '%s\n' "${UNVERIFIED}") 2>/dev/null || true)"
if [ -n "${_orphans}" ]; then load_universe; load_hash_index; fi

while IFS= read -r k; do
  [ -n "${k}" ] || continue
  printf '%s\n' "${UNVERIFIED}" | grep -qxF "${k}" && continue
  kp="${k%%::*}"
  # a linha ainda está no baseline, ou o operador já a removeu? muda só o conselho da mensagem
  if printf '%s\n' "${known}" | grep -qxF "${k}"; then hint="remova do baseline"; else hint="a linha ja saiu do baseline"; fi
  rec="$(resolve_key "${k}")"
  n_rec=$(printf '%s' "${rec}" | grep -c . || true)
  # AMBIGUIDADE: mais de um nó do corpus casa esta chave. Não dá para dizer se mudou de path, se
  # sumiu, ou se sempre houve homônimo — então o gate DECLARA que não sabe, em vez de escolher por
  # ordem de arquivo. Mesmo contrato do `_skip` dos irmãos: ignorância declarada, nunca verde mudo.
  if [ "${n_rec}" -gt 1 ]; then
    emit HARD ID-AMBIGUO "${kp}" \
      "a chave casa ${n_rec} nos do corpus (ha ids DUPLICADOS entre grafos) — o gate NAO SABE qual e o desta entrada e recusa escolher por ordem de arquivo. Desambigue renomeando um dos ids, ou meca o no e remova a entrada. Candidatos: $(printf '%s' "${rec}" | cut -d$'\037' -f6 | tr '\n' ' ')"
    soft=$((soft+1)); continue
  fi
  # ── APAGAR NAO DESCARREGA A MEDICAO ─────────────────────────────────────────────────────────
  # Era SOFT: "no que NAO EXISTE MAIS — remova do baseline". Mas o baseline SO PODE ENCOLHER POR
  # MEDICAO, e apagar o no encolhe sem medir nada. O grafo JA TEM a forma honesta de aposentar um
  # no: `superseded`/`refuted` COM a aresta que justifica — que e o ramo RECONCILIADO, logo abaixo,
  # e continua SOFT. Deletar e o atalho que pula a aresta.
  if [ -z "${rec}" ]; then
    emit HARD REMOVIDO "${kp}" \
      "no APAGADO do corpus (nao existe em NENHUM grafo) — apagar nao descarrega a medicao que o baseline cobra. Se o no morreu de verdade, aposente-o pela forma que o grafo tem: superseded/refuted COM a aresta de reconciliacao, que sai SOFT. Chave: ${k}"
    hard=$((hard+1)); continue
  fi
  IFS=$'\037' read -r rid rplane rimp rst rver rpath r_in_scope <<< "${rec}"

  # ⚠️ O CARIMBO VEM ANTES DO PATH, e a ordem inversa era o defeito CRÍTICO do Elenxo desta branch:
  # um nó COM `verified_at` movido levava HARD dizendo "SEM ser medido", e o remédio que o gate
  # prescrevia (medir) NÃO limpava o HARD — quem obedecesse continuava vermelho. O instrumento
  # afirmava sobre um campo que nunca leu, que é o `declarado != verificado` cometido dentro do gate
  # que existe para cobrá-lo. E o ramo SOFT mandava MANTER no baseline entradas já quitadas,
  # congelando a métrica que o rodapé deste arquivo declara como saúde.
  # A doutrina da catraca é "ENCOLHER SÓ VALE POR MEDIÇÃO" — e nó medido descarregou ONDE QUER QUE MORE.
  if [ -n "${rver}" ]; then
    if [ "${rpath}" != "${kp}" ]; then
      emit SOFT CARIMBADO ".claude/validation/kg-verification-baseline.txt" \
        "no '${rid}' foi MEDIDO (verified_at: ${rver}) e hoje vive em ${rpath} — ${hint}: ${k}"
    else
      emit SOFT CARIMBADO ".claude/validation/kg-verification-baseline.txt" \
        "no '${rid}' foi MEDIDO (verified_at: ${rver}) — ${hint}: ${k}"
    fi
    soft=$((soft+1)); continue
  fi

  # ── MOVER NAO E REMOVER ─────────────────────────────────────────────────────────────────────
  # Porta reproduzida em 2026-08-08: UM `git mv` de um grafo para qualquer pasta `fixtures/` tirava
  # CINCO entradas do baseline de uma vez — `exit 0`, cinco SOFT, e o gate MANDANDO remove-las, com
  # os nos intactos no disco. `fixtures/` e a convencao de exclusao da casa (kg-radar-integrity.sh),
  # entao mover PARA la e o esvaziamento em lote; mover para outro path VIVO e reorganizacao.
  if [ "${rpath}" != "${kp}" ]; then
    # ⚠️ MUDAR DE ARQUIVO E' UMA COISA; TER HOMONIMO E' OUTRA — e o hash sozinho nao distingue.
    # O corpus tem 13 ids DUPLICADOS entre grafos, e um deles (`E_ORBIT`) esta no baseline. Apagando
    # o grafo dele, a 2a passada acha o homonimo em OUTRO arquivo e conclui "mudou de path" —
    # transferindo a divida, em silencio, para um no que ninguem tocou.
    # O TESTE QUE DISTINGUE: mover significa que o no NAO EXISTIA no destino antes. Se ja existia no
    # ponto de ramificacao, e homonimo — e a resposta honesta e "nao sei qual e".
    # ⚠️ `BASE_REF` VAZIO NAO PODE VIRAR TESTE: `git show ":path"` com ref vazia le o INDICE, que
    # acabou de receber o arquivo movido — e o teste diria "ja existia" sobre um `git mv` legitimo.
    # Fail-open de ref vazia, medido aqui mesmo. Sem ponto de ramificacao nao ha como distinguir
    # homonimo de mudanca, e isso vai DITO na mensagem em vez de ser adivinhado.
    if [ -n "${BASE_REF}" ] && git show "${BASE_REF}:${rpath}" 2>/dev/null | grep -qE "^[[:space:]]*-[[:space:]]*id:[[:space:]]*${rid}[[:space:]]*$"; then
      emit HARD ID-AMBIGUO "${kp}" \
        "o no '${rid}' JA EXISTIA em ${rpath} antes desta branch — logo ele nao MUDOU de ${kp} para la: sao HOMONIMOS, e o gate NAO SABE qual era o desta entrada. Desambigue renomeando um dos ids, ou meca o no e remova a entrada."
      hard=$((hard+1)); continue
    fi
    # ⚠️ "SEGUE NO ESCOPO" TEM DE SER MEDIDO, NAO DECLARADO. `rdentro` diz apenas "o path nao esta
    # sob fixtures/" — nada sobre plane/impact/status/carimbo. O Elenxo mostrou a frase saindo sobre
    # um no `superseded`, que a propria denylist deste script poe FORA do escopo: o gate afirmava
    # sobre uma condicao que nunca avaliou, no arquivo cujo cabecalho existe para cobrar isso.
    if [ "${r_in_scope}" = "1" ] && printf '%s\037%s\037%s\037%s\n' "${rplane}" "${rimp}" "${rst}" "${rver}" \
         | awk -F'\037' "${SCOPE_PREDICATE}"' { exit inScope($1,$2,$3,$4) ? 0 : 1 }'; then
      emit SOFT MUDOU-DE-PATH ".claude/validation/kg-verification-baseline.txt" \
        "no '${rid}' MUDOU DE ARQUIVO (${kp} → ${rpath}) e segue no escopo — reescreva a chave no baseline, nao a remova: ${k}$([ -z "${BASE_REF}" ] && printf ' [sem ponto de ramificacao: NAO deu para checar se e homonimo]')"
      soft=$((soft+1))
    else
      emit HARD MUDOU-DE-PATH "${rpath}" \
        "no '${rid}' mudou de ${kp} para ${rpath} e NAO esta mais no escopo (path fora: $([ "${r_in_scope}" = "1" ] && printf nao || printf sim) · plane:${rplane:-<vazio>} impact:${rimp:-0} status:${rst:-<vazio>}) SEM carimbo — o no segue no disco, versionado, afirmando sobre producao, e o baseline encolheu sozinho. Mover nao e medir: ou meca (/meta:kg-freshness), ou traga o grafo de volta ao escopo."
      hard=$((hard+1))
    fi
    continue
  fi
  case "${rst}" in
    refuted|superseded)
      if has_reconciliation_edge "${kp}" "${rid}"; then
        emit SOFT RECONCILIADO ".claude/validation/kg-verification-baseline.txt" \
          "no '${rid}' saiu do escopo como '${rst}' COM aresta de reconciliacao (REFUTES|SUPERSEDES) ENTRANDO, vinda de OUTRO no — ${hint}: ${k}"
        soft=$((soft+1))
      else
        emit HARD FUGA-SEM-ARESTA "${kp}" \
          "no '${rid}' virou '${rst}' SEM carimbo e SEM aresta de reconciliacao ENTRANDO (REFUTES ou SUPERSEDES, vinda de OUTRO no — aresta SAINDO nao reconcilia, e no nao se refuta sozinho). Ou meca contra o vivo (/meta:kg-freshness), ou escreva a aresta que justifica o '${rst}'."
        hard=$((hard+1))
      fi ;;
    *)
      emit HARD FUGA-DE-ESCOPO "${kp}" \
        "no '${rid}' saiu do escopo SEM carimbo (hoje plane:${rplane:-<vazio>} impact:${rimp:-0} status:${rst:-<vazio>}) — o baseline so encolhe por MEDICAO, nunca por rebaixar plane/impact."
      hard=$((hard+1)) ;;
  esac
done <<< "${TO_JUDGE}"

# (3) CATRACA — baseline que CRESCEU vs a versão anterior no git → HARD (regressão).
# `prev` é lido lá em cima, junto do `known`, porque o laço (2) depende dele (TO_JUDGE = prev ∪ known).
if [ -z "${prev}" ] && [ -n "${known}" ]; then
  # IGNORANCIA DECLARADA, nunca verde mudo (mesmo contrato do `_skip` dos irmaos): sem ancestral com
  # baseline nao da para dizer se ele encolheu, e calar seria exatamente o bypass reaberto.
  emit SOFT SEM-BASE ".claude/validation/kg-verification-baseline.txt" \
    "nenhum ancestral de HEAD contem o baseline — a catraca NAO SABE se ele encolheu, e diz isso em vez de passar em silencio. (Esperado so em repo recem-adotado, onde o baseline nasce nesta branch.)"
  soft=$((soft+1))
fi
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
