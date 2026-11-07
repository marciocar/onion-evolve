#!/usr/bin/env bash
# =============================================================================
# member-path.sh — o RESOLVEDOR ÚNICO do caminho local de um membro da federação.
#
# POR QUE EXISTE (defeito datado, 2026-11-07). O core é PÚBLICO, e há adotante cujo nome de repo e de
# clone leva o nome do cliente. Para ele o `members.yaml` declara `local_path: n/a`, e aí cada
# ferramenta que lê `local_path` perdia o membro: o `registry-pins.sh --check` dava ILEGÍVEL, a
# REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) declarava a paridade como não
# medida e o `/meta:co-deliver` não achava o destino. Escrever o caminho no registro era trocar uma
# cegueira por um vazamento. Decisão do maestro (07/11): um MAPA LOCAL de id para caminho, fora da
# árvore, e um resolvedor só, que toda ferramenta consulta quando o registro diz `n/a`.
#
# O MAPA: `${ONION_MEMBER_PATHS_FILE:-$HOME/.config/onion/member-paths.tsv}`, permissão 0600,
# uma linha por membro: `<id><TAB><caminho absoluto>`. Comentário (`#`) e linha vazia são ignorados.
# Ele mora na MÁQUINA, nunca no repo: é o dado que o registro público não pode carregar.
#
# A ORDEM (o registro vence o mapa):
#   1. `local_path` declarado é caminho absoluto (ou `~/…`) → ele mesmo. O mapa não sobrescreve o
#      registro: duas fontes para o mesmo fato, com o mapa ganhando, seria um registro que mente.
#   2. declarado é `n/a`, vazio ou prosa (`"(privado …)"`) → a linha do id no mapa, se houver.
#   3. nada → vazio, rc 1. Quem chama decide (ILEGÍVEL, NÃO-MEDIDO, --target): o resolvedor não inventa.
# O resolvedor NÃO testa se o diretório existe: "existe nesta máquina" é pergunta de quem chama, e
# cada um já a faz com a régua dele (clone git, carimbo do Onion, diretório).
#
# Uso:
#   source member-path.sh            → define onion_member_path <id> [<local_path declarado>]
#   member-path.sh <id> [<declarado>] → imprime o caminho (rc 0) ou nada (rc 1)
#   member-path.sh --list            → as linhas válidas do mapa, `id<TAB>caminho` (rc 0, vazio sem mapa)
#   member-path.sh --map-file        → o caminho do mapa em vigor (exista ou não)
#   member-path.sh --selftest        → as polaridades, com mapa e ids inventados
# Exit: 0 resolvido · 1 não resolvido · 2 uso errado.
#
# TETO: (a) o mapa é da conta que roda: outra conta (o `onion` do bridge) não o vê, e isso é de propósito;
#   (b) id duplicado no mapa: vale a 1ª linha, e o `--list` avisa; (c) permissão mais aberta que 0600:
#   o `--list` avisa no stderr e a leitura segue (a função, chamada por membro nas guardas, cala) — o mapa contém caminhos, não segredos, e recusar travaria o carteiro;
#   (d) superfícies que PROJETAM ou PUBLICAM (kg-projection, door-leak-scan, publish-door) NÃO consultam
#   o mapa, por desenho: o que elas leem vira texto público, e o mapa existe justamente para não virar.
#   (e) o gate a2a (a2a-verify.sh) e o escopo do veto do adotante (hooks/lib/adopter-scope.sh) também
#   não: ampliar o que um gate de segurança aceita por arquivo local pede decisão do maestro.
# Exercitado por lint-selftest.sh (run_member_path_selftests).
# =============================================================================

_onion_member_paths_file() { printf '%s' "${ONION_MEMBER_PATHS_FILE:-${HOME:-/nonexistent}/.config/onion/member-paths.tsv}"; }

# As linhas válidas do mapa: id não vazio, caminho absoluto (ou ~/), 1ª ocorrência do id vence.
# `$1 = warn` liga os avisos (permissão, linha recusada, id repetido) no stderr. Só a CLI liga: a função
# roda uma vez por membro dentro dos laços das guardas, e o mesmo aviso sairia N vezes em todo lint.
_onion_member_paths_list() {
  local f warn="${1:-}"; f="$(_onion_member_paths_file)"
  [ -f "${f}" ] && [ -r "${f}" ] || return 0
  local _perm
  if [ "${warn}" = warn ]; then
    _perm="$(stat -c '%a' "${f}" 2>/dev/null || stat -f '%Lp' "${f}" 2>/dev/null || echo '')"
    case "${_perm}" in 600|400|'') : ;; *) echo "member-path: AVISO: ${f} tem permissão ${_perm}; o esperado é 0600 (chmod 600)" >&2 ;; esac
  fi
  awk -F'\t' -v home="${HOME:-}" -v warn="${warn}" '
    /^[[:space:]]*(#|$)/ { next }
    { id=$1; p=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); gsub(/^[[:space:]]+|[[:space:]]+$/, "", p); sub(/\r$/, "", p)
      if (id == "" || p == "") next
      if (substr(p,1,2) == "~/" && home != "") p = home "/" substr(p,3)
      if (substr(p,1,1) != "/") { if (warn == "warn") print "member-path: AVISO: linha do id " id " ignorada: o caminho não é absoluto" > "/dev/stderr"; next }
      sub(/\/+$/, "", p)
      if (id in seen) { if (warn == "warn") print "member-path: AVISO: id " id " repetido no mapa; vale a 1a linha" > "/dev/stderr"; next }
      seen[id]=1; print id "\t" p }' "${f}"
}

# onion_member_path <id> [<local_path declarado>] → caminho em stdout, rc 0; nada, rc 1.
onion_member_path() {
  local id="${1:-}" decl="${2:-}"
  [ -n "${id}" ] || return 1
  decl="${decl#\"}"; decl="${decl%\"}"
  decl="$(printf '%s' "${decl}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  case "${decl}" in
    "~/"*) [ -n "${HOME:-}" ] && { printf '%s\n' "${HOME}/${decl#"~/"}"; return 0; } ;;
    /*)    printf '%s\n' "${decl%/}"; return 0 ;;
  esac
  local p
  p="$(_onion_member_paths_list | awk -F'\t' -v id="${id}" '$1 == id { print $2; exit }')"
  [ -n "${p}" ] || return 1
  printf '%s\n' "${p}"
}

_member_path_selftest() {
  local tmp ok=0 bad=0 got
  tmp="$(mktemp -d)" || return 2
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" RETURN
  printf '# mapa de teste\n\nmembro-alfa\t/srv/clones/alfa\nmembro-beta\t~/clones/beta/\nmembro-gama\trelativo/gama\nmembro-alfa\t/srv/outro\n' > "${tmp}/map.tsv"
  chmod 600 "${tmp}/map.tsv"
  _t() {  # <nome> <esperado> <id> [<declarado>]
    local name="$1" want="$2"; shift 2
    got="$(ONION_MEMBER_PATHS_FILE="${tmp}/map.tsv" HOME=/home/conta-teste onion_member_path "$@" 2>/dev/null)" || got="<rc1>"
    if [ "${got}" = "${want}" ]; then ok=$((ok+1)); echo "  ✅ ${name}"; else bad=$((bad+1)); echo "  ✗ ${name} — esperava '${want}', veio '${got}'"; fi
  }
  _t "registro absoluto vence o mapa"            "/reg/alfa"                     membro-alfa "/reg/alfa"
  _t "registro com aspas e barra final"           "/reg/alfa"                     membro-alfa '"/reg/alfa/"'
  _t "n/a cai no mapa"                            "/srv/clones/alfa"              membro-alfa "n/a"
  _t "vazio cai no mapa"                          "/srv/clones/alfa"              membro-alfa ""
  _t "prosa entre parênteses cai no mapa"         "/srv/clones/alfa"              membro-alfa '"(privado, sem clone)"'
  _t "til do mapa expande e barra final cai"      "/home/conta-teste/clones/beta" membro-beta "n/a"
  _t "caminho relativo no mapa é recusado"        "<rc1>"                         membro-gama "n/a"
  _t "id fora do mapa não inventa"                "<rc1>"                         membro-delta "n/a"
  _t "id repetido: vale a 1a linha"               "/srv/clones/alfa"              membro-alfa
  got="$(ONION_MEMBER_PATHS_FILE="${tmp}/ausente.tsv" onion_member_path membro-alfa n/a 2>&1)" && got="rc0:${got}" || got="<rc1>${got}"
  if [ "${got}" = "<rc1>" ]; then ok=$((ok+1)); echo "  ✅ mapa ausente: rc 1 calado"; else bad=$((bad+1)); echo "  ✗ mapa ausente — veio '${got}'"; fi
  chmod 644 "${tmp}/map.tsv"
  got="$(ONION_MEMBER_PATHS_FILE="${tmp}/map.tsv" _onion_member_paths_list warn 2>&1 >/dev/null)"
  case "${got}" in *"permissão 644"*"repetido"*) ok=$((ok+1)); echo "  ✅ a CLI avisa permissão aberta e id repetido no stderr" ;; *) bad=$((bad+1)); echo "  ✗ avisos da CLI — stderr '${got}'" ;; esac
  got="$(ONION_MEMBER_PATHS_FILE="${tmp}/map.tsv" onion_member_path membro-alfa n/a 2>&1 >/dev/null)"
  if [ -z "${got}" ]; then ok=$((ok+1)); echo "  ✅ a função cala os avisos (roda por membro dentro das guardas)"; else bad=$((bad+1)); echo "  ✗ a função avisou: '${got}'"; fi
  echo "member-path selftest: ${ok} ok · ${bad} falha(s)"
  [ "${bad}" -eq 0 ]
}

# Só a execução direta tem CLI; `source` só define as funções.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  set -uo pipefail
  case "${1:-}" in
    --list)     _onion_member_paths_list warn; exit 0 ;;
    --map-file) _onion_member_paths_file; echo; exit 0 ;;
    --selftest) _member_path_selftest; exit $? ;;
    ""|-*)      echo "uso: member-path.sh <id> [<local_path declarado>] | --list | --map-file | --selftest" >&2; exit 2 ;;
    *)          onion_member_path "$@"; exit $? ;;
  esac
fi
