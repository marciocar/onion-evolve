#!/usr/bin/env bash
# ===========================================================================
# ownership.sh — o LEITOR ÚNICO de posse: «de quem é este repo, qual é a sessão dona e qual é o nome dela».
#
# Decisão do maestro de 2026-11-20 (D_SESSION_ONE_OWNERSHIP_REGISTRY_BY_NAME_1120, grafo
# docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml): UM só registro de posse, lido pelo pulso, pelo merge e
# pela isolação; o endereço é por NOME; nunca duas sessões no mesmo checkout; na abertura, a sessão já sabe se pode
# merjar sozinha. Este é o 1º passo: o leitor. Ele lê só o que JÁ é a lista fechada da catraca de merge:
#   · o `members.yaml` (por padrão o de origin/main do core, como a catraca; `--members` troca o arquivo);
#   · a LISTA PRIVADA de sessões donas, fora do repo (${ONION_PRIVATE_OWNERS_FILE:-~/.config/onion/private-owner-sessions.tsv},
#     `member_id<TAB>dono/repo<TAB>owner_session[<TAB>pasta]`; a 4ª coluna, opcional, é só deste leitor e a catraca a
#     ignora), com as MESMAS condições da catraca (D_PRIVATE_OWNER_SESSIONS_1119):
#     modo sem bit de grupo/outros, membro existente com `kind: adopter` e `remote: n/a`, owner_session igual quando o
#     members.yaml a declara, e nunca lida no CI.
# O grants.tsv, o owners.tsv e o `owner:` dos nós NÃO são lidos aqui: são os outros registros, que este leitor vem
# substituir por migração decidida pelo maestro (a lista de quem lê o quê está no PR que criou este arquivo).
#
# A regra do «merja sozinho?» é a parte ESTÁTICA da catraca do repo próprio do ops/pr-merge-verified.sh (core-only;
# a função _own_repo_gate): (1) o dono do slug é o dono do core; (2) o membro é `kind: source`, ou declara
# `owner_session` e não é `kind: door`, ou entra pela lista privada válida. A parte DINÂMICA (CI verde, ponta da base,
# resíduo, PR de guarda) só se mede no PR, e a resposta diz isso. A paridade da busca no registro com a da catraca é
# provada na bancada (família session_open), rodando o awk extraído do próprio pr-merge-verified.sh.
# TETO HONESTO: é leitor, não fronteira. Quem barra o merge segue sendo o pr-merge-verified.sh.
#
# Uso:
#   ownership.sh who <nome|caminho>          → TSV: member_id kind owner_session session_name local_path via registry
#   ownership.sh merge-alone <nome|caminho>  → «sim<TAB>por quê» (rc 0) | «não<TAB>por quê» (rc 1)
#   ownership.sh list                        → TSV de toda sessão dona: member_id session_name local_path via
#   ownership.sh row <dono/repo>             → «kind<TAB>owner_session» do membro cujo remote é o slug (a busca da catraca)
# Opções: --members <arquivo> · --private <arquivo> · --home <dir> (a pasta do membro privado é <home>/<repo do slug>)
# Ambiente de bancada: ONION_OWNERSHIP_CORE (o slug do core; padrão, a constante da catraca).
# Saída: 0 ok/sim · 1 não (merge-alone) ou nenhum dono (who) · 2 uso ou registro ilegível.
# ===========================================================================
set -uo pipefail

_OWN_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_OWN_CORE_DIR="$(cd "${_OWN_SELF_DIR}/../../.." && pwd)"
# o slug do core é CONSTANTE, como na catraca (_PMV_CORE_CONST): nem o members.yaml nem a config do git dizem quem é o core
OWN_CORE_SLUG="${ONION_OWNERSHIP_CORE:-marciocar/onion-evolve}"
OWN_MEMBERS="" OWN_PRIVATE="${ONION_PRIVATE_OWNERS_FILE:-${HOME:-/nonexistent}/.config/onion/private-owner-sessions.tsv}"
OWN_HOME="${HOME:-/nonexistent}"
OWN_REG="" OWN_REG_SRC="" OWN_PRIV_NOTE="" OWN_TBL=""

_own_die() { printf 'ownership: %s\n' "$1" >&2; exit "${2:-2}"; }
_own_slug_norm() { tr '[:upper:]' '[:lower:]' <<< "$1" | sed -E 's#^(git@[^:]+:|ssh://git@[^/]+/|https?://([^@/]+@)?[^/]+/|github\.com/)##; s#\.git$##; s#/+$##'; }

# o registro: --members vence; senão origin/main do core (o que a catraca lê); a árvore só como recurso, DITO.
# Roda no shell corrente: deixa o texto em OWN_REG e a origem em OWN_REG_SRC.
_own_registry() {
  if [ -n "${OWN_MEMBERS}" ]; then
    [ -r "${OWN_MEMBERS}" ] || _own_die "não li ${OWN_MEMBERS}"
    OWN_REG="$(cat -- "${OWN_MEMBERS}")"; OWN_REG_SRC="arquivo"; return 0
  fi
  if OWN_REG="$(git -C "${_OWN_CORE_DIR}" show origin/main:docs/evolution/federation/members.yaml 2>/dev/null)"; then
    OWN_REG_SRC="origin/main"; return 0
  fi
  [ -r "${_OWN_CORE_DIR}/docs/evolution/federation/members.yaml" ] \
    || _own_die "não li o members.yaml (nem de origin/main nem da árvore de ${_OWN_CORE_DIR})"
  OWN_REG="$(cat -- "${_OWN_CORE_DIR}/docs/evolution/federation/members.yaml")"; OWN_REG_SRC="árvore"
}

# members.yaml → uma linha por membro: id kind owner_session remote(normalizado como a catraca) local_path
_own_members_tsv() {
  awk '
    function norm(v) { sub(/[[:space:]]+#.*$/, "", v); sub(/[[:space:]]*\(.*$/, "", v); gsub(/["'"'"' ]/, "", v); sub(/^(https?:\/\/)?(www\.)?github\.com\//, "", v); sub(/\.git$/, "", v); sub(/\/+$/, "", v); return tolower(v) }
    function val(s, key) { sub("^[[:space:]]*(-[[:space:]]+)?" key ":[[:space:]]*", "", s); sub(/[[:space:]]+#.*$/, "", s); gsub(/["'"'"']/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function flush() { if (id != "") printf "%s\t%s\t%s\t%s\t%s\n", id, (kind == "" ? "?" : kind), (own == "" ? "-" : own), (rem == "" ? "-" : rem), (lp == "" ? "-" : lp); id = ""; kind = ""; own = ""; rem = ""; lp = "" }
    /^[[:space:]]*-[[:space:]]+id:/ { flush(); id = val($0, "id"); sub(/[[:space:]#].*$/, "", id) }
    # o kind SEM tirar aspas, como a catraca: `kind: "source"` não é source lá, e não pode ser aqui (paridade)
    /^[[:space:]]+kind:/ { k = $0; sub(/^[[:space:]]+kind:[[:space:]]*/, "", k); sub(/[[:space:]#].*$/, "", k); kind = k }
    /^[[:space:]]+owner_session:/ { own = val($0, "owner_session"); sub(/[[:space:]#].*$/, "", own) }
    /^[[:space:]]+remote:/ { v = $0; sub(/^[[:space:]]+remote:[[:space:]]*/, "", v); rem = norm(v) }
    /^[[:space:]]+local_path:/ { lp = val($0, "local_path"); if (lp ~ /^\//) { gsub(/\/+/, "/", lp); sub(/\/$/, "", lp) } }
    END { flush() }'
}

# a lista privada, com as condições da catraca; linha inválida é IGNORADA e dita em OWN_PRIV_NOTE (nunca o slug)
# → member_id kind owner_session slug local_path (uma por linha válida)
_own_private_tsv() {  # $1 = members_tsv
  OWN_PRIV_NOTE=""
  if [ "${CI:-}" = true ] || [ "${GITHUB_ACTIONS:-}" = true ]; then OWN_PRIV_NOTE="lista privada não lida no CI"; return 0; fi
  [ -e "${OWN_PRIVATE}" ] || return 0
  [ -f "${OWN_PRIVATE}" ] && [ -r "${OWN_PRIVATE}" ] || { OWN_PRIV_NOTE="lista privada ilegível: ignorada"; return 0; }
  local mode; mode="$(stat -L -c '%a' -- "${OWN_PRIVATE}" 2>/dev/null)"
  if ! [[ "${mode}" =~ ^[0-7]{3,4}$ ]] || [ $(( 8#${mode} & 8#077 )) -ne 0 ]; then
    OWN_PRIV_NOTE="lista privada com modo ${mode:-ilegível}, mais aberto que 600: ignorada (a catraca também a recusa)"; return 0
  fi
  local id sl os lp _r mk mo mr ml seen=" " rows=""
  while IFS=$'\t' read -r id sl os lp _r || [ -n "${id}" ]; do
    id="$(tr -d '[:space:]' <<< "${id}")"; sl="$(tr -d '[:space:]' <<< "${sl}")"; os="$(tr -d '[:space:]' <<< "${os}")"
    lp="$(tr -d '[:space:]' <<< "${lp:-}")"
    case "${id}" in ''|'#'*) continue ;; esac
    mk="" mo="" mr="" ml=""
    read -r mk mo mr ml < <(awk -F'\t' -v w="${id}" '$1 == w { print $2, $3, $4, $5; exit }' <<< "$1")
    if [ -z "${mk:-}" ]; then OWN_PRIV_NOTE="${OWN_PRIV_NOTE:+${OWN_PRIV_NOTE}; }linha privada '${id}': membro inexistente no registro, ignorada"; continue; fi
    if [ "${mk}" != adopter ] || [ "${mr}" != "n/a" ]; then OWN_PRIV_NOTE="${OWN_PRIV_NOTE:+${OWN_PRIV_NOTE}; }linha privada '${id}': o membro não é o neutro (kind: adopter, remote: n/a), ignorada"; continue; fi
    if [ -z "${os}" ] || { [ "${mo}" != "-" ] && [ "${mo}" != "${os}" ]; }; then OWN_PRIV_NOTE="${OWN_PRIV_NOTE:+${OWN_PRIV_NOTE}; }linha privada '${id}': owner_session vazia ou diferente da do registro, ignorada"; continue; fi
    case "${seen}" in *" ${id} "*) OWN_PRIV_NOTE="${OWN_PRIV_NOTE:+${OWN_PRIV_NOTE}; }linha privada '${id}' repetida: ambígua, ignorada"; continue ;; esac
    seen="${seen}${id} "
    sl="$(_own_slug_norm "${sl}")"
    # a pasta vem da 4ª coluna OPCIONAL (a catraca lê só as 3 primeiras); sem ela, desconhecida («-»): nunca adivinhada
    # pelo nome do slug, porque o clone pode ter outro nome. Relativa é sob --home.
    # Sem ela, vale o local_path do membro neutro, se ele tiver um.
    case "${lp}" in ''|-) lp="-"; case "${ml:-}" in /*) lp="${ml}" ;; esac ;; /*) ;; *) lp="${OWN_HOME}/${lp}" ;; esac
    case "${lp}" in /*) lp="$(realpath -m -- "${lp}")" ;; esac
    rows="${rows}${id}"$'\t'"adopter"$'\t'"${os}"$'\t'"${sl}"$'\t'"${lp}"$'\n'
  done < "${OWN_PRIVATE}"
  # o MESMO slug em duas linhas é ambíguo para a catraca (_pmv_private_row recusa): aqui as duas saem, ditas pelo id
  local dup; dup="$(awk -F'\t' 'NF { n[$4]++; ids[$4] = ids[$4] " " $1 } END { for (k in n) if (n[k] > 1) print ids[k] }' <<< "${rows}" | tr '\n' ' ')"
  [ -z "${dup// /}" ] || OWN_PRIV_NOTE="${OWN_PRIV_NOTE:+${OWN_PRIV_NOTE}; }linhas privadas${dup% } com o mesmo slug: ambíguas, ignoradas"
  awk -F'\t' 'NF { n[$4]++; r[NR] = $0; s[NR] = $4 } END { for (i = 1; i <= NR; i++) if ((i in r) && n[s[i]] == 1) print r[i] }' <<< "${rows}"
}

# a tabela de posse, no shell corrente → OWN_TBL: members (via=members.yaml) + privada (via=privada). Colunas:
# member_id kind owner_session session_name local_path via remote
_own_load() {
  local mt pt
  _own_registry
  mt="$(_own_members_tsv <<< "${OWN_REG}")"
  pt="$(_own_private_tsv "${mt}"; printf '\n#OWN_NOTE#%s' "${OWN_PRIV_NOTE}")"   # a nota volta no fim: o subshell a perderia
  OWN_PRIV_NOTE="${pt##*#OWN_NOTE#}"; pt="${pt%#OWN_NOTE#*}"
  OWN_TBL="$(awk -F'\t' 'BEGIN{OFS="\t"} NF {
      # o nome da sessão: a owner_session; sem ela (o core, ou membro sem dona), o nome do repo (a pasta), senão o id
      sn = $3; if ($2 == "source" || sn == "-") { sn = $5; sub(/^.*\//, "", sn); if (sn == "-" || sn == "") sn = $1 }
      print $1, $2, $3, sn, $5, "members.yaml", $4 }' <<< "${mt}"
    awk -F'\t' 'BEGIN{OFS="\t"} NF { print $1, $2, $3, $3, $5, "privada", $4 }' <<< "${pt}")"
  # a linha privada válida SUBSTITUI a do members.yaml do mesmo id (o membro neutro): duas linhas do mesmo membro
  # fariam o nome ou a pasta casar duas vezes (ambíguo)
  OWN_TBL="$(awk -F'\t' 'NR == FNR { if (NF) p[$1] = 1; next } !($6 == "members.yaml" && ($1 in p))' <(printf '%s\n' "${pt}") - <<< "${OWN_TBL}")"
}

# nome ou caminho → a linha da tabela. Nome: «core» é o checkout da fonte; casa owner_session, a pasta do local_path ou
# o id. Caminho absoluto: casa o local_path. Mais de uma linha distinta = ambíguo (rc 2).
_own_find() {  # $1 = nome|caminho ; $2 = tabela
  local q="$1" hits
  if [ "${q}" = core ]; then hits="$(awk -F'\t' '$2 == "source"' <<< "$2")"
  elif [ "${q#/}" != "${q}" ]; then
    q="$(realpath -m -- "${q}")"
    hits="$(awk -F'\t' -v q="${q}" '$5 == q' <<< "$2")"
  else
    hits="$(awk -F'\t' -v q="${q}" '{ b = $5; sub(/^.*\//, "", b) } $3 == q || $4 == q || b == q || $1 == q' <<< "$2")"
  fi
  hits="$(awk 'NF && !seen[$0]++' <<< "${hits}")"
  [ -n "${hits}" ] || return 1
  [ "$(wc -l <<< "${hits}")" -eq 1 ] || { printf 'ownership: «%s» casa %s membros do registro: ambíguo, não escolho\n' "$1" "$(wc -l <<< "${hits}")" >&2; return 2; }
  printf '%s\n' "${hits}"
}

# a parte estática da catraca, para o repo da PRÓPRIA sessão
_own_merge_alone() {  # $1 = linha da tabela → «sim|não<TAB>por quê»
  local id kind own sn lp via rem core_owner="${OWN_CORE_SLUG%%/*}" dyn
  IFS=$'\t' read -r id kind own sn lp via rem <<< "$1"
  dyn="o PR ainda passa pela catraca do ops/pr-merge-verified.sh: CI verde no head, ponta da base e resíduo da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)"
  if [ "${OWN_REG_SRC}" = "árvore" ]; then
    printf 'não\tnão li o members.yaml de origin/main (só a árvore): a catraca lê origin/main, e eu não respondo pelo que ela não leu\n'; return 1
  fi
  case "${kind}" in
    door) printf 'não\t%s é PORTA (kind: door): merge nela publica, e a publicação é do maestro (D_DOOR_PUBLISH_STAYS_WITH_MAESTRO_1113)\n' "${id}"; return 1 ;;
  esac
  if [ "${rem}" = "-" ] || [ "${rem}" = "n/a" ]; then
    printf 'não\t%s não tem remote no registro: sem slug, a catraca não o reconhece (só pela lista privada válida)\n' "${id}"; return 1
  fi
  if [ "${rem%%/*}" != "${core_owner}" ]; then
    # o dono do slug PRIVADO nunca sai (leva o nome do cliente), como na catraca (_lown vazio)
    printf 'não\t%s é de outro dono%s: repo de cliente ou de empresa só o dono merja (D_SESSIONS_MERGE_OWN_PRS_INCL_GUARD_1118)\n' "${id}" "$([ "${via}" = privada ] || printf ' (%s)' "${rem%%/*}")"; return 1
  fi
  if [ "${kind}" = source ]; then
    if [ "${rem}" != "$(_own_slug_norm "${OWN_CORE_SLUG}")" ]; then
      printf 'não\to kind: source do registro aponta %s, e a constante do core é %s: registro mexido, a catraca recusa\n' "${rem}" "${OWN_CORE_SLUG}"; return 1
    fi
    printf 'sim\té o core (kind: source); %s; PR que toca guarda exige o resíduo com elenxo_isolado: true, e o que toca a própria catraca (lista M1) segue do maestro\n' "${dyn}"; return 0
  fi
  if [ "${own}" = "-" ]; then
    printf 'não\t%s está no registro (kind: %s) sem owner_session: declarar a sessão dona é PR no members.yaml; até lá, o merge é do maestro\n' "${id}" "${kind}"; return 1
  fi
  printf 'sim\t%s declara a sessão dona «%s»%s; %s\n' "${id}" "${own}" "$([ "${via}" = privada ] && printf ' (pela lista privada de sessões donas)')" "${dyn}"
  return 0
}

CMD="${1:-}"; [ $# -gt 0 ] && shift
ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --members) OWN_MEMBERS="${2:?--members pede o arquivo}"; shift ;;
    --private) OWN_PRIVATE="${2:?--private pede o arquivo}"; shift ;;
    --home) OWN_HOME="${2:?--home pede a pasta}"; shift ;;
    -*) _own_die "opção desconhecida: $1" ;;
    *) [ -z "${ARG}" ] || _own_die "um argumento por vez"; ARG="$1" ;;
  esac
  shift
done

case "${CMD}" in
  who|merge-alone)
    [ -n "${ARG}" ] || _own_die "uso: ownership.sh ${CMD} <nome|caminho>"
    _own_load
    row="$(_own_find "${ARG}" "${OWN_TBL}")"; rc=$?
    [ "${rc}" -eq 2 ] && exit 2
    [ -z "${OWN_PRIV_NOTE}" ] || printf 'ownership: %s\n' "${OWN_PRIV_NOTE}" >&2
    if [ "${CMD}" = who ]; then
      [ "${rc}" -eq 0 ] || { printf 'ownership: «%s» não está no registro de posse (members.yaml nem lista privada)\n' "${ARG}" >&2; exit 1; }
      awk -F'\t' -v r="${OWN_REG_SRC}" 'BEGIN{OFS="\t"} { print $1, $2, $3, $4, $5, $6, r }' <<< "${row}"
    else
      if [ "${rc}" -ne 0 ]; then
        printf 'não\t«%s» não está na lista fechada (members.yaml de origin/main nem a lista privada de sessões donas): registre por PR\n' "${ARG}"; exit 1
      fi
      _own_merge_alone "${row}"; exit $?
    fi
    ;;
  list)
    _own_load
    [ -z "${OWN_PRIV_NOTE}" ] || printf 'ownership: %s\n' "${OWN_PRIV_NOTE}" >&2
    awk -F'\t' 'BEGIN{OFS="\t"} $3 != "-" { print $1, $4, $5, $6 }' <<< "${OWN_TBL}"
    ;;
  row)
    [ -n "${ARG}" ] || _own_die "uso: ownership.sh row <dono/repo>"
    _own_registry
    want="$(_own_slug_norm "${ARG}")"
    _own_members_tsv <<< "${OWN_REG}" | awk -F'\t' -v w="${want}" 'BEGIN{OFS="\t"} $4 == w { print $2, $3; exit }'
    ;;
  *) _own_die "uso: ownership.sh who|merge-alone <nome|caminho> | list | row <dono/repo> [--members f] [--private f] [--home d]" ;;
esac
