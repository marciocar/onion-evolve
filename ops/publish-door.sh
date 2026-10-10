#!/usr/bin/env bash
# =============================================================================
# publish-door.sh — o MOTOR do /meta:publish: publica uma PORTA do Onion a partir de origin/main.
#
# Uso:
#   ops/publish-door.sh <porta> [--clone <dir>] [--remote-url <url>] [--role <papel> --force-role-change]
#                               [--push] [--keep] [--members <registro>]
#   ops/publish-door.sh --all [--push] [--members <registro>]
#   ops/publish-door.sh --status [--members <registro>]
#
#   <porta>  id de um membro `kind: door` do members.yaml (onion-core, onion-standalone, onion-plugins,
#            onion-mini). O PAPEL vem do registro (que a REGRA 92 mantém em paridade com o carimbo).
#   --push   publica de fato. SEM ele a rodada é ENSAIO: materializa, verifica e commita num clone
#            descartável, e para antes do push. É a confirmação explícita: a superfície (/meta:publish)
#            só passa --push depois de perguntar ao maestro.
#   --status lê o CARIMBO PUBLICADO de cada porta no REMOTO e mede a defasagem contra origin/main.
#
# rc: 0 ok · 1 a verificação reprovou (nada publicado) · 2 precondição ou recusa · 3 fonte irresolúvel
#     ou não pude medir (nunca vira "está tudo bem").
#
# ══ POR QUE ESTE SCRIPT EXISTE (F3 do plano das portas, SAC-92, D_MATRIZ_DE_PORTAS_2026_10) ═════
# Até a F2 havia TRÊS caminhos de publicação, e cada um errava de um jeito medido:
#   · `ops/materialize-door.sh` para core e standalone — correto na fonte (origin/main desde 09-25),
#     mas parava antes do commit, e depois do push o pin tinha de voltar ao core por PR
#     (`door-seal-pin.sh` + baseline à mão): cada publicação gerava um PR de registro;
#   · a skill onion-publish + `materialize-marketplace-repo.sh` para os plugins — esse lê a ÁRVORE DE
#     TRABALHO de quem roda, não origin/main: publicar de uma branch de PR publicaria código não
#     mergeado num repo público (a mesma classe que o materialize-door curou em 2026-09-25);
#   · o onion-mini sem maquinaria nenhuma.
# Este motor é o caminho ÚNICO: a fonte é SEMPRE uma worktree destacada em origin/main — inclusive
# os SCRIPTS que materializam, que rodam da worktree e não do disco de quem chama —, a verificação
# acontece no que foi MONTADO, e o selo é o carimbo da própria porta, lido do remoto.
#
# ══ O QUE ELE NÃO FAZ ════════════════════════════════════════════════════════════════════════
# · NÃO toca o core: nenhum commit, nenhum arquivo, nenhuma worktree sobrando. É conferido no fim
#   (HEAD, árvore e lista de worktrees antes = depois); se mudou, rc 1. O `git fetch` atualiza só a
#   ref remota origin/<integração>, que é leitura do remoto, não escrita no trabalho de ninguém.
# · NÃO empurra sem --push. E NÃO escreve no members.yaml: o pin vive no carimbo da porta (selo sem
#   PR no core). O registro guarda o membro; o `onion_version` dele virou cache.
# · NÃO publica a 1ª materialização do onion-mini (registro com pin n/a): ela é a F5 (SAC-94), com
#   README e CLAUDE.md didáticos que ainda não existem. O ensaio roda; o --push recusa.
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "${HERE}/.." && pwd)"
MEMBERS="${CORE}/docs/evolution/federation/members.yaml"

MODE="publish"; DOOR=""; CLONE=""; REMOTE_URL=""; ROLE_OVERRIDE=""; FORCE_ROLE=0; PUSH=0; KEEP=0; FROM_REF=""
while [ $# -gt 0 ]; do
  case "$1" in
    --status) MODE="status"; shift ;;
    --all) MODE="all"; shift ;;
    --clone) CLONE="${2:?--clone exige um diretório}"; shift 2 ;;
    --remote-url) REMOTE_URL="${2:?--remote-url exige uma url}"; shift 2 ;;
    --role) ROLE_OVERRIDE="${2:?--role exige um papel}"; shift 2 ;;
    --force-role-change) FORCE_ROLE=1; shift ;;
    --push) PUSH=1; shift ;;
    --keep) KEEP=1; shift ;;
    --from) FROM_REF="${2:?--from exige uma ref}"; shift 2 ;;
    --members) MEMBERS="${2:?--members exige um caminho}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${DOOR}" ] && DOOR="$1" || { echo "ERRO: porta já informada ('${DOOR}')." >&2; exit 2; }; shift ;;
  esac
done
[ -f "${MEMBERS}" ] || { echo "ERRO: registro ausente: ${MEMBERS}" >&2; exit 2; }

# ── O registro: uma linha por membro (id, kind, role, remote, pin, local_path), comentário fora ──
# Mesmo shape do `_field` do door-seal-pin.sh. O valor de cada campo é o 1º token depois de `campo:`,
# sem comentário inline nem aspas — `remote: https://x (privado)` vira `https://x`.
_members_tsv() {
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

# url clonável a partir do `remote:` do registro. github.com/x/y → https; caminho absoluto ou url
# completa ficam como estão; `n/a` e texto livre não têm url.
_url_of() {
  local r="$1"
  case "${r}" in
    ""|n/a|"("*) printf '' ;;
    http://*|https://*|git@*|file://*|/*) printf '%s' "${r}" ;;
    github.com/*) printf 'https://%s.git' "${r%.git}" ;;
    *) printf '' ;;
  esac
}

_integ() {
  local i; i="$(bash "${CORE}/.claude/validation/resolve-integration-branch.sh" "${CORE}" 2>/dev/null || true)"
  printf '%s' "${i:-main}"
}

# Lê um campo do carimbo de porta (`write-stamp.sh --kind door`), com o dialeto antigo como fallback.
_stamp_field() { printf '%s\n' "$1" | grep -m1 "^$2:" | sed "s/^$2:[[:space:]]*//; s/[[:space:]]*#.*\$//; s/[[:space:]]*\$//"; }
_stamp_pin() {
  local p; p="$(_stamp_field "$1" source_commit)"
  [ -n "${p}" ] || p="$(_stamp_field "$1" onion_version)"
  printf '%s' "${p}"
}

# =============================================================================
# --status — a defasagem de cada porta, lida do REMOTO
# =============================================================================
# O pin do registro é CACHE: desde a F3 ninguém o avança por PR. O fato é o carimbo publicado, e é
# ele que se lê aqui — por git (ls-remote + clone raso sem checkout), sem `gh` nem credencial: as
# portas são públicas, e o mesmo caminho funciona contra um remoto local na bancada.
_status() {
  local integ tip doors measured=0 total=0
  integ="$(_integ)"
  git -C "${CORE}" fetch -q origin "${integ}" 2>/dev/null || true
  tip="origin/${integ}"
  git -C "${CORE}" rev-parse --verify --quiet "${tip}^{commit}" >/dev/null || {
    echo "ERRO: não consegui resolver ${tip} — sem a ponta da integração não há defasagem a medir." >&2; return 3; }
  doors="$(_members_tsv | awk -F'\037' '$2=="door"')"
  [ -n "${doors}" ] || { echo "status: nenhuma porta (kind: door) no registro — nada a medir."; return 0; }
  local tmp; tmp="$(mktemp -d)"
  printf '══ /meta:publish --status — carimbo PUBLICADO × %s (%s)\n' "${tip}" "$(git -C "${CORE}" rev-parse --short=12 "${tip}")"
  printf '%-18s %-10s %-14s %-14s %-11s %s\n' "porta" "papel" "pin publicado" "pin registro" "defasagem" "estado"
  local id kind role remote pin lp url br sha stamp rpin rrole n state
  while IFS=$'\037' read -r id kind role remote pin lp; do
    [ -n "${id}" ] || continue
    total=$((total + 1))
    url="$(_url_of "${remote}")"
    rpin=""; rrole=""; n="—"; state=""
    if [ -z "${url}" ]; then
      state="NÃO-MEDIDO (sem remoto no registro)"
    elif ! br="$(git ls-remote --symref "${url}" HEAD 2>/dev/null | awk '/^ref:/{sub("refs/heads/","",$2); print $2; exit}')" || [ -z "${br}" ]; then
      state="NÃO-MEDIDO (remoto ilegível: ${url})"
    else
      rm -rf "${tmp:?}/${id}"
      if ! git clone -q --depth 1 --no-checkout --branch "${br}" "${url}" "${tmp}/${id}" >/dev/null 2>&1; then
        state="NÃO-MEDIDO (clone raso falhou)"
      else
        stamp="$(git -C "${tmp}/${id}" show "HEAD:.claude/.onion-version" 2>/dev/null || true)"
        if [ -n "${stamp}" ]; then
          rpin="$(_stamp_pin "${stamp}")"; rrole="$(_stamp_field "${stamp}" role)"
        else
          # porta de MARKETPLACE: o carimbo é o provenance.json do plugin (campo `ref`), sem `role:`
          local prov
          prov="$(git -C "${tmp}/${id}" ls-tree -r --name-only HEAD -- plugins 2>/dev/null | grep -m1 '/\.claude-plugin/provenance\.json$' || true)"
          if [ -n "${prov}" ]; then
            rpin="$(git -C "${tmp}/${id}" show "HEAD:${prov}" 2>/dev/null | sed -n 's/.*"ref"[[:space:]]*:[[:space:]]*"\([0-9a-f]*\)".*/\1/p' | head -1)"
            rrole="plugins*"
          fi
        fi
        if [ -z "${rpin}" ]; then
          state="SEM-CARIMBO (porta nunca materializada pelo motor$([ "${pin}" = "n/a" ] && printf ' — F5'))"
          measured=$((measured + 1))
        elif ! git -C "${CORE}" rev-parse --verify --quiet "${rpin}^{commit}" >/dev/null; then
          state="PIN-FORA-DA-HISTÓRIA (${rpin} não é commit deste core)"
          measured=$((measured + 1))
        else
          n="$(bash "${CORE}/.claude/validation/door-staleness-check.sh" "${CORE}" --count "${rpin}" --tip "${tip}" 2>/dev/null || true)"
          case "${n}" in ''|*[!0-9]*) state="NÃO-MEDIDO (contagem falhou)"; n="—" ;;
            0) state="em dia"; measured=$((measured + 1)) ;;
            *) state="DEFASADA — /meta:publish ${id}"; measured=$((measured + 1)) ;;
          esac
          if [ -n "${pin}" ] && [ "${pin}" != "n/a" ] && [ "${pin:0:12}" != "${rpin:0:12}" ]; then
            state="${state} · cache do registro difere"
          fi
        fi
      fi
    fi
    printf '%-18s %-10s %-14s %-14s %-11s %s\n' "${id}" "${rrole:-${role}?}" "${rpin:0:12}" "${pin:0:12}" "${n}" "${state}"
  done <<< "${doors}"
  rm -rf "${tmp}"
  echo
  echo "  papel com '?' = o do REGISTRO (a porta não declara papel); 'plugins*' = marketplace, carimbo no provenance.json."
  echo "  A defasagem conta commits da superfície que viaja entre o pin PUBLICADO e ${tip}. Informativo: nenhum PR depende disto."
  if [ "${measured}" -eq 0 ]; then
    echo "ERRO: ${total} porta(s) no registro e NENHUMA medida — isto não é 'tudo em dia'." >&2
    return 3
  fi
  return 0
}

if [ "${MODE}" = "status" ]; then _status; exit $?; fi

# =============================================================================
# --all — cada porta numa rodada própria (um clone descartável por porta)
# =============================================================================
if [ "${MODE}" = "all" ]; then
  _worst=0
  while IFS=$'\037' read -r _id _k _rest; do
    [ -n "${_id}" ] || continue
    echo; echo "████ ${_id}"
    _a=("${_id}" --members "${MEMBERS}"); [ "${PUSH}" -eq 1 ] && _a+=(--push)
    _r=0; bash "${BASH_SOURCE[0]}" "${_a[@]}" || _r=$?
    [ "${_r}" -gt "${_worst}" ] && _worst="${_r}"
  done < <(_members_tsv | awk -F'\037' '$2=="door"')
  exit "${_worst}"
fi

# =============================================================================
# publicar UMA porta
# =============================================================================
[ -n "${DOOR}" ] || { echo "uso: ops/publish-door.sh <porta>|--all|--status [--push]" >&2; exit 2; }
ROW="$(_members_tsv | awk -F'\037' -v id="${DOOR}" '$1==id')"
[ -n "${ROW}" ] || { echo "ERRO: '${DOOR}' não está no registro (${MEMBERS})." >&2; exit 2; }
IFS=$'\037' read -r _ KIND REG_ROLE REG_REMOTE REG_PIN _LP <<< "${ROW}"
[ "${KIND}" = "door" ] || { echo "ERRO: '${DOOR}' tem kind='${KIND}', não 'door' — só PORTA se publica por aqui (adotante se atualiza pelo /meta:adopt --update)." >&2; exit 2; }
ROLE="${ROLE_OVERRIDE:-${REG_ROLE}}"
[ -n "${ROLE}" ] || { echo "ERRO: '${DOOR}' sem role: no registro — não materializo sem saber o corte." >&2; exit 2; }
[ -n "${REMOTE_URL}" ] || REMOTE_URL="$(_url_of "${REG_REMOTE}")"
[ -n "${REMOTE_URL}" ] || { echo "ERRO: '${DOOR}' sem remoto clonável no registro (remote='${REG_REMOTE}')." >&2; exit 2; }
if [ "${PUSH}" -eq 1 ] && [ "${REG_PIN}" = "n/a" ]; then
  echo "ERRO: '${DOOR}' nunca foi materializada pelo carimbo (pin n/a no registro). A 1ª materialização dela é uma fase própria (onion-mini: F5, SAC-94) — rode sem --push para ensaiar." >&2
  exit 2
fi

# ── O estado do core ANTES — publicar não pode alterá-lo ─────────────────────────────────────
_core_state() {
  printf '%s|%s|%s' "$(git -C "${CORE}" rev-parse HEAD 2>/dev/null)" \
    "$(git -C "${CORE}" status --porcelain 2>/dev/null | sha256sum | cut -c1-16)" \
    "$(git -C "${CORE}" worktree list --porcelain 2>/dev/null | grep -c '^worktree ' || true)"
}
CORE_BEFORE="$(_core_state)"

# ── (1) A FONTE: worktree destacada em origin/<integração>, nunca o HEAD local ───────────────
INTEG="$(_integ)"
git -C "${CORE}" fetch -q origin "${INTEG}" 2>/dev/null || true
SRC_REF="origin/${INTEG}"
# `--from <ref>` é ENSAIO DE BRANCH (ver o efeito de uma cura antes do merge) e nunca publica: a porta
# pública é projeção da integração mergeada, e o --push com --from recusa aqui, antes de clonar nada.
if [ -n "${FROM_REF}" ]; then
  [ "${PUSH}" -eq 0 ] || { echo "ERRO: --from '${FROM_REF}' com --push — porta pública só nasce de origin/${INTEG}. --from é ensaio." >&2; exit 2; }
  SRC_REF="${FROM_REF}"
fi
if ! git -C "${CORE}" rev-parse --verify --quiet "${SRC_REF}^{commit}" >/dev/null; then
  echo "ERRO: não consegui resolver '${SRC_REF}'. A porta é projeção da INTEGRAÇÃO mergeada; sem ela eu não publico nada (e não caio no HEAD local, que pode ser uma branch de PR aberto)." >&2
  exit 3
fi
PIN="$(git -C "${CORE}" rev-parse --short=12 "${SRC_REF}")"
PIN_FULL="$(git -C "${CORE}" rev-parse "${SRC_REF}")"
T="$(mktemp -d)"; WT="${T}/src"
_cleanup() {
  git -C "${CORE}" worktree remove --force "${WT}" >/dev/null 2>&1 || true
  git -C "${CORE}" worktree prune >/dev/null 2>&1 || true
  if [ "${KEEP}" -eq 1 ] && [ -z "${CLONE_GIVEN:-}" ]; then
    echo "  (--keep) clone preservado em ${T}/${DOOR}"
  else
    rm -rf "${T}"
  fi
}
trap _cleanup EXIT
git -C "${CORE}" worktree add --detach -q "${WT}" "${SRC_REF}" >/dev/null 2>&1 \
  || { echo "ERRO: não consegui destacar uma worktree em ${SRC_REF}." >&2; exit 3; }
echo "══ /meta:publish ${DOOR} — papel '${ROLE}' · fonte ${SRC_REF} (${PIN}) · $([ "${PUSH}" -eq 1 ] && echo PUBLICAÇÃO || echo ENSAIO)"

# ── (2) O CLONE da porta: descartável por default; o do maestro só limpo e do remoto certo ───
CLONE_GIVEN=""
if [ -n "${CLONE}" ]; then
  CLONE_GIVEN=1
  git -C "${CLONE}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: --clone '${CLONE}' não é repositório git." >&2; exit 2; }
  _dirty="$(git -C "${CLONE}" status --porcelain 2>/dev/null | grep -c . || true)"
  [ "${_dirty}" -eq 0 ] || { echo "ERRO: o clone '${CLONE}' tem ${_dirty} arquivo(s) não commitado(s). A materialização é autoritativa e APAGA a superfície — não faço isso sobre trabalho de ninguém." >&2; exit 2; }
  _origin="$(git -C "${CLONE}" remote get-url origin 2>/dev/null || true)"
  _norm() { printf '%s' "$1" | sed -E 's#^(https?://|git@)##; s#^github\.com:#github.com/#; s#\.git$##; s#/$##'; }
  [ "$(_norm "${_origin}")" = "$(_norm "${REMOTE_URL}")" ] \
    || { echo "ERRO: o origin do clone ('${_origin}') não é o remoto da porta no registro ('${REMOTE_URL}')." >&2; exit 2; }
  DEST="$(cd "${CLONE}" && pwd)"
  # o materializador deriva o NOME da porta (README, `framework:` do carimbo) do basename do destino
  [ "$(basename "${DEST}")" = "${DOOR}" ] \
    || { echo "ERRO: o clone '${DEST}' não se chama '${DOOR}' — o materializador escreveria o nome errado no README e no carimbo." >&2; exit 2; }
else
  # O NOME do diretório é o da porta, e não é estética: o materialize-door escreve o README (`git clone
  # .../<nome>`) e o `framework:` do carimbo a partir do basename do destino. O 1º ensaio clonava em
  # `door/` e a porta sairia apresentando-se como `door` (achado no dogfood, 2026-10-10).
  DEST="${T}/${DOOR}"
  git clone -q "${REMOTE_URL}" "${DEST}" 2>/dev/null || { echo "ERRO: não consegui clonar ${REMOTE_URL}." >&2; exit 2; }
fi
BRANCH="$(git -C "${DEST}" symbolic-ref --short HEAD 2>/dev/null || true)"
[ -n "${BRANCH}" ] || { echo "ERRO: o clone da porta está em HEAD destacado — não sei que ramo publicar." >&2; exit 2; }

# ── (3) PARIDADE DE PAPEL antes de materializar ──────────────────────────────────────────────
# Registro × carimbo publicado (HEAD do clone). Divergência RECUSA: foi lendo uma fonte em vez da
# outra que a onion-core perdeu 85 arquivos em 2026-09-30. Trocar o papel é ato deliberado: --role
# com --force-role-change (ex.: a onion-core de hub para source, decidido na matriz).
STAMP_HEAD="$(git -C "${DEST}" show HEAD:.claude/.onion-version 2>/dev/null || true)"
STAMP_ROLE="$(_stamp_field "${STAMP_HEAD}" role)"
if [ -n "${STAMP_ROLE}" ] && [ "${STAMP_ROLE}" != "${REG_ROLE}" ] && [ "${FORCE_ROLE}" -ne 1 ]; then
  echo "ERRO: papel divergente — o registro diz '${REG_ROLE}' e o carimbo PUBLICADO da porta diz '${STAMP_ROLE}'. Não publico com as duas fontes contando histórias diferentes (REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela))." >&2
  exit 2
fi
if [ -n "${ROLE_OVERRIDE}" ] && [ "${ROLE_OVERRIDE}" != "${STAMP_ROLE:-${REG_ROLE}}" ] && [ "${FORCE_ROLE}" -ne 1 ]; then
  echo "ERRO: --role '${ROLE_OVERRIDE}' muda o que a porta distribui (hoje '${STAMP_ROLE:-${REG_ROLE}}'). Diga isso em voz alta: --force-role-change." >&2
  exit 2
fi

# ── (4) MATERIALIZAR pelos scripts DA WORKTREE (o motor também é de origin/main) ─────────────
_mrc=0
if [ "${ROLE}" = "plugins" ]; then
  bash "${WT}/.claude/utils/marketplace/materialize-marketplace-repo.sh" "${DEST}" --no-commit 2>&1 | sed 's/^/  │ /'
  _mrc="${PIPESTATUS[0]}"
else
  _ma=("${DEST}" --role "${ROLE}"); [ "${FORCE_ROLE}" -eq 1 ] && _ma+=(--force-role-change)
  [ -n "${FROM_REF}" ] && _ma+=(--from "${PIN_FULL}")
  bash "${WT}/ops/materialize-door.sh" "${_ma[@]}" 2>&1 | sed 's/^/  │ /'
  _mrc="${PIPESTATUS[0]}"
fi
[ "${_mrc}" -eq 0 ] || { echo "✗ a materialização recusou (rc=${_mrc}) — nada a publicar." >&2; exit 1; }
git -C "${DEST}" add -A || { echo "ERRO: git add no clone falhou." >&2; exit 2; }

# ── (5) VERIFICAR O QUE FOI MONTADO ──────────────────────────────────────────────────────────
FAIL=0; NOT_MEASURED=""
# (5a) VAZAMENTO. Três famílias de termo, todas DERIVADAS (nome no script seria o próprio vazamento):
#   · os da REGRA 36 (nomes comerciais marcados + client-terms.txt + ids de adotante) — substring;
#   · os ids de adotante com prefixo `onion-` (onion-<pessoa>), que a REGRA 36 ignora por desenho e
#     são o ponto cego medido duas vezes ([[vendor-scrub-blind-spot]]) — palavra inteira, para que
#     `onion-dist` não case dentro de `onion-distribution`;
#   · caminho de máquina `/home/<conta>/` (a forma que a REGRA 99 proíbe nos grafos).
_terms_sub="$( { bash "${WT}/.claude/validation/projection-safety.sh" --emit-terms 2>/dev/null | grep -vE '^(CONFIDENCIAL|PRIVADO)$'
                 [ -f "${CORE}/docs/evolution/federation/client-terms.txt" ] && grep -vE '^[[:space:]]*(#|$)' "${CORE}/docs/evolution/federation/client-terms.txt"
                 _members_tsv | awk -F'\037' '($2=="adopter"||$2=="method") && $1 !~ /^onion-/ && $1 !~ /^marcio/ && $1 !~ /^selftest-/ && length($1)>=4 {print $1}'
               } 2>/dev/null | grep -v '^[[:space:]]*$' | sort -u || true)"
_terms_word="$(_members_tsv | awk -F'\037' '($2=="adopter"||$2=="method") && $1 ~ /^onion-/ {print $1}' | sort -u || true)"
_leaks=""
while IFS= read -r _t; do
  [ -n "${_t}" ] || continue
  _hit="$(grep -rilF --exclude-dir=.git -- "${_t}" "${DEST}" 2>/dev/null | sed "s|^${DEST}/||" | head -3 | tr '\n' ' ')"
  [ -n "${_hit}" ] && _leaks="${_leaks}    termo de adotante em: ${_hit}"$'\n'
done <<< "${_terms_sub}"
while IFS= read -r _t; do
  [ -n "${_t}" ] || continue
  _hit="$(grep -rilwF --exclude-dir=.git -- "${_t}" "${DEST}" 2>/dev/null | sed "s|^${DEST}/||" | head -3 | tr '\n' ' ')"
  [ -n "${_hit}" ] && _leaks="${_leaks}    id '${_t}' (prefixo onion-) em: ${_hit}"$'\n'
done <<< "${_terms_word}"
# As CONTAS reais são DERIVADAS — dos `local_path` do registro e de quem roda —, nunca uma lista de
# exemplos tolerados: `/home/conta/` e `/home/x/` em fixture de bancada são dado de teste, e uma
# lista de "genéricos permitidos" falharia pelo vocabulário (1º dogfood, 2026-10-10: a forma larga
# `/home/<qualquer>/` acusou 3 fixtures inócuas ao lado das 2 contas reais). Teto declarado: conta da
# máquina que não aparece no registro nem é quem roda não é vista.
_accts="$( { _members_tsv | awk -F'\037' '{print $6}' | sed -n 's#^/home/\([a-z_][a-z0-9_-]*\)/.*#\1#p'; id -un 2>/dev/null; } \
           | grep -v '^$' | sort -u | paste -sd'|' -)"
if [ -n "${_accts}" ]; then
  _home_real="$(grep -rnoE --exclude-dir=.git "/home/(${_accts})/" "${DEST}" 2>/dev/null | sed "s|^${DEST}/||" || true)"
  if [ -n "${_home_real}" ]; then
    _nh="$(printf '%s\n' "${_home_real}" | grep -c .)"
    _leaks="${_leaks}    caminho de máquina (conta real), ${_nh} ocorrência(s):"$'\n'"$(printf '%s\n' "${_home_real}" | head -10 | sed 's/^/      /')"$'\n'
  fi
fi
if [ -n "${_leaks}" ]; then
  echo "✗ (5a) VAZAMENTO no bundle — a porta é PÚBLICA:" >&2
  printf '%s' "${_leaks}" >&2
  FAIL=1
else
  echo "  (5a) vazamento: nenhum termo de adotante (REGRA 36 + ids onion-*), nenhum caminho de máquina"
fi

# (5b) PARIDADE DE PAPEL no que foi montado: o carimbo que vai a público diz o papel pedido.
if [ "${ROLE}" = "plugins" ]; then
  _refs="$(find "${DEST}/plugins" -path '*/.claude-plugin/provenance.json' -exec sed -n 's/.*"ref"[[:space:]]*:[[:space:]]*"\([0-9a-f]*\)".*/\1/p' {} + 2>/dev/null | sort -u)"
  if [ "${_refs}" = "${PIN_FULL}" ]; then
    echo "  (5b) paridade: todo provenance.json aponta ${PIN} (origin/${INTEG})"
  else
    echo "✗ (5b) provenance.json não aponta origin/${INTEG} (${PIN}): $(printf '%s' "${_refs}" | tr '\n' ' ')" >&2; FAIL=1
  fi
else
  _new="$(cat "${DEST}/.claude/.onion-version" 2>/dev/null || true)"
  _nrole="$(_stamp_field "${_new}" role)"; _npin="$(_stamp_pin "${_new}")"
  if [ "${_nrole}" = "${ROLE}" ] && [ "${_npin:0:12}" = "${PIN}" ]; then
    echo "  (5b) paridade: carimbo montado diz role=${_nrole}, source_commit=${_npin}"
  else
    echo "✗ (5b) o carimbo montado diz role='${_nrole}' pin='${_npin}' — esperado '${ROLE}' e ${PIN}." >&2; FAIL=1
  fi
fi

# (5c) O GATE DA PRÓPRIA PORTA. Porta com lint tem de sair com 0 HARD; o mini não leva lint por
#      desenho. Plugins: `claude plugin validate --strict` no catálogo e em cada plugin.
if [ "${ROLE}" = "plugins" ]; then
  if command -v claude >/dev/null 2>&1; then
    _bad=""
    for _p in "${DEST}" "${DEST}"/plugins/*/; do
      [ -d "${_p}" ] || continue
      claude plugin validate --strict "${_p%/}" >/dev/null 2>&1 || _bad="${_bad} ${_p#${DEST}}"
    done
    if [ -z "${_bad}" ]; then echo "  (5c) claude plugin validate --strict: catálogo e plugins válidos"
    else echo "✗ (5c) claude plugin validate --strict reprovou:${_bad}" >&2; FAIL=1; fi
  else
    NOT_MEASURED="${NOT_MEASURED} plugin-validate"
    echo "  (5c) ⚠️ CLI claude ausente — validate --strict NÃO MEDIDO (o --push recusa sem ele)"
  fi
elif [ -f "${DEST}/.claude/validation/lint-artifacts.sh" ]; then
  _lo="$( (cd "${DEST}" && bash .claude/validation/lint-artifacts.sh) 2>&1 || true)"
  _hard="$(printf '%s\n' "${_lo}" | sed -n 's/.*Violações HARD[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | tail -1)"
  if [ "${_hard}" = "0" ]; then echo "  (5c) lint da porta: 0 HARD"
  elif [ -z "${_hard}" ]; then echo "✗ (5c) o lint da porta não chegou ao sumário — não sei quantos HARD (rodar à mão no clone)." >&2; FAIL=1
  else
    echo "✗ (5c) lint da porta: ${_hard} HARD" >&2
    printf '%s\n' "${_lo}" | grep -E '^\s*(❌|✗|HARD)' | head -10 | sed 's/^/      /' >&2
    FAIL=1
  fi
elif [ "${ROLE}" = "mini" ]; then
  echo "  (5c) o papel mini não leva o lint (allowlist didática) — gate da porta não se aplica"
else
  echo "✗ (5c) o papel '${ROLE}' leva o lint e ele NÃO veio no bundle — porta sem o próprio gate." >&2; FAIL=1
fi

if [ "${FAIL}" -ne 0 ]; then
  echo "✗ VERIFICAÇÃO REPROVOU — nada foi commitado nem publicado." >&2
  exit 1
fi

# ── (6) COMMIT no clone ──────────────────────────────────────────────────────────────────────
if git -C "${DEST}" diff --cached --quiet 2>/dev/null; then
  echo "  (6) a porta já espelha ${SRC_REF} (${PIN}) — nada a commitar, nada a publicar."
  COMMITTED=0
else
  git -C "${DEST}" commit -q -m "chore(door): materializa do core no pin ${PIN} (papel ${ROLE})" \
    || { echo "ERRO: o commit no clone falhou." >&2; exit 2; }
  COMMITTED=1
  echo "  (6) commit no clone: $(git -C "${DEST}" rev-parse --short=12 HEAD) — $(git -C "${DEST}" diff --stat HEAD~1 HEAD 2>/dev/null | tail -1)"
fi

# ── (7) PUSH, só com --push, e a CONFERÊNCIA no remoto ───────────────────────────────────────
if [ "${PUSH}" -ne 1 ]; then
  echo
  echo "✅ ENSAIO concluído: verificado e commitado no clone, NÃO publicado."
  echo "   Para publicar: /meta:publish ${DOOR} (que pergunta antes de passar --push)."
  [ "${KEEP}" -eq 1 ] || [ -n "${CLONE_GIVEN}" ] || echo "   (o clone descartável será removido; --keep o preserva para inspeção)"
elif [ -n "${NOT_MEASURED}" ]; then
  echo "✗ --push RECUSADO: verificação não medida (${NOT_MEASURED# }). Publicar sem medir é afirmar o que não sei." >&2
  exit 2
elif [ "${COMMITTED}" -eq 1 ]; then
  git -C "${DEST}" push -q origin "HEAD:${BRANCH}" 2>&1 | sed 's/^/  │ /'
  _prc="${PIPESTATUS[0]}"
  [ "${_prc}" -eq 0 ] || { echo "✗ push recusado pelo remoto (rc=${_prc})." >&2; exit 2; }
  _local="$(git -C "${DEST}" rev-parse HEAD)"
  _remote="$(git ls-remote "${REMOTE_URL}" "refs/heads/${BRANCH}" 2>/dev/null | awk '{print $1}')"
  if [ "${_remote}" != "${_local}" ]; then
    echo "✗ CONFERÊNCIA: o remoto (${_remote:0:12}) não bate com o commit publicado (${_local:0:12})." >&2; exit 1
  fi
  echo "  (7) publicado e CONFERIDO no remoto: ${BRANCH} = ${_local:0:12} · carimbo pin ${PIN}"
  echo "      O selo é o carimbo da porta: /meta:publish --status o lê do remoto. Nenhum PR no core."
  if [ "${ROLE}" != "${REG_ROLE}" ]; then
    echo "  ⚠️ o papel PUBLICADO ('${ROLE}') difere do registro ('${REG_ROLE}'): alinhe o role: da porta no members.yaml na próxima leva (REGRA 92), e atualize o clone local dela."
  fi
fi

# ── (8) O CORE NÃO MUDOU ─────────────────────────────────────────────────────────────────────
trap - EXIT; _cleanup
CORE_AFTER="$(_core_state)"
if [ "${CORE_AFTER}" != "${CORE_BEFORE}" ]; then
  echo "✗ PUBLICAR ALTEROU O CORE (antes ${CORE_BEFORE} · depois ${CORE_AFTER}) — isto é defeito do motor." >&2
  exit 1
fi
echo "  (8) core intacto: HEAD, árvore e worktrees iguais a antes"
exit 0
