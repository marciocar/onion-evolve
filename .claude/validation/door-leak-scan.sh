#!/usr/bin/env bash
# =============================================================================
# door-leak-scan.sh — a varredura de VAZAMENTO da publicação, num lugar só.
#
# É o código do passo (5a) do motor de publicação das portas, o `ops/publish-door.sh` (core-only),
# EXTRAÍDO para que o motor e o lint chamem a MESMA coisa. Antes desta extração o (5a) só existia
# dentro do motor, que roda no fim: medido em 2026-10-13, duas vezes na mesma noite, o ensaio de
# `/meta:publish --all` (core-only) reprovou três portas por vazamento que tinha entrado por PRs mergeados com o
# lint verde — caminho de máquina em comentários e fixtures que viajam, e o id de um repo privado de
# adotante com prefixo `onion-` em 23 comentários de sinal de campo. A REGRA 36 (Superfície VENDORIZADA
# sem nome comercial de cliente) ignora o prefixo `onion-` por desenho, e nenhuma guarda do lint
# varria caminho de máquina nas raízes que viajam. Quem decide o que o lint julga com isto é a
# REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação).
#
# AS TRÊS FAMÍLIAS, todas DERIVADAS (nome no script seria o próprio vazamento):
#   sub  · termo por SUBSTRING, sem caixa: os ids de adotante SEM prefixo `onion-` (kind adopter|method,
#          menos `marcio*`, `selftest-*` e ids com menos de 4 caracteres), mais os termos que o
#          chamador passar em `--terms-file` (os nomes comerciais e a fonte privada, que o motor deriva
#          e cuja ausência ELE trata como falha fechada). Saída SEM o termo: o log pode ser público.
#   word · id de adotante COM prefixo `onion-` (kind adopter|method), PALAVRA INTEIRA e sem caixa, para
#          que um id curto não case dentro de um nome maior do framework. O porte público (kind `port`,
#          ex.: o porte Codex) e as portas (kind `door`) ficam de fora pelo KIND, não por lista.
#   home · caminho sob a home de uma conta REAL: as contas vêm dos `local_path` do registro, de quem
#          roda e das contas humanas da máquina (passwd, uid >= 1000 com home em /home). Nunca uma lista
#          de exemplos tolerados: `/home/<user>/` e `/home/conta/` em fixture são dado de teste.
#
# Uso:
#   door-leak-scan.sh [--members <yaml>] [--families sub,word,home] [--terms-file <f>] <caminho>...
#   door-leak-scan.sh --members <yaml> --emit-word-ids | --emit-sub-ids | --emit-accounts
#   door-leak-scan.sh --members <yaml> --emit-members-tsv   # o registro parseado (o motor o lê daqui)
# Saída (stdout, TSV, uma linha por achado): <família>\t<arquivo>\t<linha|->\t<detalhe>
#   sub → detalhe `-` (o termo NÃO é impresso) · word → o id · home → `/home/<conta>/`
# Exit: 0 = nada achado · 1 = achou · 2 = não pôde julgar (registro passado e ilegível, uso errado).
#
# TETO DECLARADO:
#   · sem `--members`, `sub` e `word` não têm ids: o chamador tem de saber disso e DECLARAR (o lint o
#     faz como NAO-VERIFICADO; o motor sempre passa o registro da ref);
#   · conta de OUTRA máquina que não esteja no registro não é vista (`home`);
#   · id `onion-<x>` de adotante NÃO REGISTRADO não é visto (a classe da lista: [[vendor-scrub-blind-spot]]);
#   · id dentro de URL pública conta como vazamento: `github.com/<dono>/onion-<adotante>` É o nome do
#     repo privado. Só porte e porta (pelo kind) são públicos por desenho;
#   · `.git` é excluído; arquivo binário casa como qualquer outro (o grep -r o lê).
# =============================================================================
set -uo pipefail

MEMBERS=""; FAMILIES="sub,word,home"; TERMS_FILE=""; EMIT=""
PATHS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --members)    MEMBERS="${2:?--members exige um caminho}"; shift 2 ;;
    --families)   FAMILIES="${2:?--families exige a lista}"; shift 2 ;;
    --terms-file) TERMS_FILE="${2:?--terms-file exige um caminho}"; shift 2 ;;
    --emit-word-ids) EMIT="word"; shift ;;
    --emit-sub-ids)  EMIT="sub"; shift ;;
    --emit-accounts) EMIT="home"; shift ;;
    --emit-members-tsv) EMIT="tsv"; shift ;;
    -h|--help) sed -n '2,45p' "${BASH_SOURCE[0]}"; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do PATHS+=("$1"); shift; done ;;
    -*) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
    *) PATHS+=("$1"); shift ;;
  esac
done
case ",${FAMILIES}," in *,sub,*|*,word,*|*,home,*) : ;; *) echo "ERRO: --families sem família conhecida (sub,word,home): ${FAMILIES}" >&2; exit 2 ;; esac
if [ -n "${MEMBERS}" ] && { [ ! -f "${MEMBERS}" ] || [ ! -r "${MEMBERS}" ]; }; then
  echo "ERRO: registro ilegível: ${MEMBERS} — sem ele os ids de adotante não são derivados; isto não é limpo." >&2; exit 2
fi
if [ -n "${TERMS_FILE}" ] && [ ! -r "${TERMS_FILE}" ]; then
  echo "ERRO: --terms-file ilegível: ${TERMS_FILE}" >&2; exit 2
fi

# O registro: uma linha por membro (id, kind, role, remote, pin, local_path), comentário fora.
# Separador \037 (não tab): `IFS=$'\t' read` colapsa campos vazios consecutivos. É o MESMO parser que o
# motor usa para papel e destino — ele o lê daqui também, não de uma cópia.
dls_members_tsv() {
  [ -n "${MEMBERS}" ] || return 0
  awk '
    function clean(s) { sub(/^[^:]*:[[:space:]]*/,"",s); sub(/[[:space:]]+#.*$/,"",s)
                        gsub(/"/,"",s); gsub(/\047/,"",s); sub(/[[:space:]].*$/,"",s); return s }
    function flush() { if (id != "") printf "%s\037%s\037%s\037%s\037%s\037%s\n", id, kind, role, remote, pin, lp }
    /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { flush(); id=clean($0); kind=""; role=""; remote=""; pin=""; lp=""; next }
    id != "" { l=$0; gsub(/^[[:space:]]+/,"",l)
      if (l ~ /^kind:/ && kind=="") kind=clean(l)
      else if (l ~ /^role:/ && role=="") role=clean(l)
      else if (l ~ /^remote:/ && remote=="") remote=clean(l)
      else if (l ~ /^onion_version:/ && pin=="") pin=clean(l)
      else if (l ~ /^local_path:/ && lp=="") lp=clean(l) }
    END { flush() }
  ' "${MEMBERS}"
}
dls_sub_ids() {
  dls_members_tsv | awk -F'\037' '($2=="adopter"||$2=="method") && $1 !~ /^onion-/ && $1 !~ /^marcio/ && $1 !~ /^selftest-/ && length($1)>=4 {print $1}' | sort -u
}
dls_word_ids() {
  dls_members_tsv | awk -F'\037' '($2=="adopter"||$2=="method") && $1 ~ /^onion-/ {print $1}' | sort -u
}
dls_accounts() {
  { dls_members_tsv | awk -F'\037' '{print $6}' | sed -n 's#^/home/\([a-z_][a-z0-9_-]*\)/.*#\1#p'
    id -un 2>/dev/null
    getent passwd 2>/dev/null | awk -F: '$3>=1000 && $3<60000 && $6 ~ "^/home/" {print $1}'
  } | grep -E '^[a-z_][a-z0-9_-]*$' | sort -u
}

case "${EMIT}" in
  tsv)  dls_members_tsv; exit 0 ;;
  word) dls_word_ids; exit 0 ;;
  sub)  { dls_sub_ids; [ -n "${TERMS_FILE}" ] && grep -v '^[[:space:]]*$' "${TERMS_FILE}"; } | sort -u; exit 0 ;;
  home) dls_accounts; exit 0 ;;
esac
[ "${#PATHS[@]}" -gt 0 ] || { echo "ERRO: nenhum caminho a varrer" >&2; exit 2; }

_tmp="$(mktemp -d)"; trap 'rm -rf "${_tmp}"' EXIT
found=0

# (sub) — um termo por vez com -l: o termo nunca chega à saída.
if [[ ",${FAMILIES}," == *,sub,* ]]; then
  { dls_sub_ids; [ -n "${TERMS_FILE}" ] && cat "${TERMS_FILE}"; } | grep -v '^[[:space:]]*$' | sort -u > "${_tmp}/sub"
  while IFS= read -r _t; do
    [ -n "${_t}" ] || continue
    while IFS= read -r _f; do
      [ -n "${_f}" ] || continue
      printf 'sub\t%s\t-\t-\n' "${_f}"; found=1
    done < <(grep -rilF --exclude-dir=.git -- "${_t}" "${PATHS[@]}" 2>/dev/null)
  done < "${_tmp}/sub"
fi

# (word) — uma passada só, palavra inteira, sem caixa; o id casado é a evidência (ids são públicos no
# registro, então imprimi-lo não vaza; o que vaza é ele estar na superfície que viaja).
if [[ ",${FAMILIES}," == *,word,* ]]; then
  dls_word_ids > "${_tmp}/word"
  if [ -s "${_tmp}/word" ]; then
    while IFS= read -r _l; do
      [ -n "${_l}" ] || continue
      _m="${_l##*:}"; _r="${_l%:*}"; _n="${_r##*:}"; _f="${_r%:*}"
      printf 'word\t%s\t%s\t%s\n' "${_f}" "${_n}" "$(printf '%s' "${_m}" | tr '[:upper:]' '[:lower:]')"; found=1
    done < <(grep -rHnoiwF --exclude-dir=.git -f "${_tmp}/word" -- "${PATHS[@]}" 2>/dev/null)
  fi
fi

# (home) — contas reais, nunca exemplos tolerados.
if [[ ",${FAMILIES}," == *,home,* ]]; then
  _accts="$(dls_accounts | paste -sd'|' -)"
  if [ -n "${_accts}" ]; then
    while IFS= read -r _l; do
      [ -n "${_l}" ] || continue
      _m="${_l##*:}"; _r="${_l%:*}"; _n="${_r##*:}"; _f="${_r%:*}"
      printf 'home\t%s\t%s\t%s\n' "${_f}" "${_n}" "${_m}"; found=1
    done < <(grep -rHnoE --exclude-dir=.git "/home/(${_accts})/" -- "${PATHS[@]}" 2>/dev/null)
  fi
fi

[ "${found}" -eq 1 ] && exit 1
exit 0
