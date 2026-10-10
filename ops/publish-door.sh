#!/usr/bin/env bash
# =============================================================================
# publish-door.sh — o MOTOR do /meta:publish: publica uma PORTA do Onion a partir de origin/main.
#
# Uso:
#   ops/publish-door.sh <porta> [--push] [--expect-pin <sha>] [--clone <dir>] [--keep]
#                               [--role <papel> --force-role-change] [--from <ref>]
#   ops/publish-door.sh --all [--push]
#   ops/publish-door.sh --status
#   (--members <registro> substitui o registro de origin/main — só para bancada, e é anunciado)
#
#   <porta>  id de um membro `kind: door` do members.yaml (onion-core, onion-standalone, onion-plugins,
#            onion-mini). O PAPEL vem do registro (que a REGRA 92 mantém em paridade com o carimbo).
#   --push   publica de fato. SEM ele a rodada é ENSAIO: materializa, verifica e commita num clone
#            descartável, e para antes do push. É a confirmação explícita: a superfície (/meta:publish)
#            só passa --push depois de perguntar ao maestro, e passa junto o --expect-pin do ensaio.
#   --expect-pin  recusa se origin/main andou desde o ensaio: o pin publicado é o pin confirmado.
#   --from   ENSAIO de uma branch (ver o efeito de uma cura antes do merge). Recusado com --push e
#            com --clone (o commit de uma branch não mergeada não pode ficar no clone de ninguém).
#   --status lê o CARIMBO PUBLICADO de cada porta no REMOTO e mede a defasagem contra origin/main.
#
# rc: 0 ok · 1 a verificação reprovou (nada publicado) · 2 precondição ou recusa · 3 fonte irresolúvel
#     ou não pude medir (nunca vira "está tudo bem") · 4 PUBLICADO, mas uma pós-condição falhou (leia).
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
# Este motor é o caminho ÚNICO: a fonte é SEMPRE origin/main — o que viaja, os SCRIPTS que
# materializam (rodam de uma worktree destacada, não do disco de quem chama) e o REGISTRO que diz
# papel e destino (lido da ref, não da árvore de trabalho) —, a verificação acontece no que foi
# MONTADO, e o selo é o carimbo da própria porta, lido do remoto.
#
# ══ O QUE ELE NÃO FAZ ════════════════════════════════════════════════════════════════════════
# · NÃO toca o core: nenhum commit, nenhum arquivo, nenhuma worktree sobrando — conferido no fim
#   sobre o que é DESTE motor (HEAD e árvore do checkout; nenhuma worktree dele). Worktree de OUTRA
#   sessão nascendo no meio não é alteração deste motor (a 1ª versão contava todas e dava falso
#   positivo com agentes concorrentes — passada adversarial da F3). O `git fetch` só move a ref remota.
# · NÃO empurra sem --push, e NÃO empurra commit que não verificou: o clone tem de estar EXATAMENTE em
#   origin/<ramo> antes de materializar, e o push leva exatamente um commit, o verificado.
# · NÃO escreve no members.yaml: o pin vive no carimbo da porta (selo sem PR no core).
# · NÃO publica a 1ª materialização do onion-mini (registro com pin n/a): ela é a F5 (SAC-94). O
#   --push recusa, e o ensaio também, enquanto o repo dela guardar outro conteúdo (a destilação).
# =============================================================================
set -uo pipefail
export GIT_TERMINAL_PROMPT=0   # remoto privado ou inexistente não pode virar prompt de senha num TTY

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "${HERE}/.." && pwd)"
MEMBERS_REL="docs/evolution/federation/members.yaml"

MODE="publish"; DOOR=""; CLONE=""; ROLE_OVERRIDE=""; FORCE_ROLE=0; PUSH=0; KEEP=0; FROM_REF=""
EXPECT_PIN=""; MEMBERS_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --status) MODE="status"; shift ;;
    --all) MODE="all"; shift ;;
    --clone) CLONE="${2:?--clone exige um diretório}"; shift 2 ;;
    --role) ROLE_OVERRIDE="${2:?--role exige um papel}"; shift 2 ;;
    --force-role-change) FORCE_ROLE=1; shift ;;
    --push) PUSH=1; shift ;;
    --keep) KEEP=1; shift ;;
    --from) FROM_REF="${2:?--from exige uma ref}"; shift 2 ;;
    --expect-pin) EXPECT_PIN="${2:?--expect-pin exige um sha}"; shift 2 ;;
    --members) MEMBERS_OVERRIDE="${2:?--members exige um caminho}"; shift 2 ;;
    -h|--help) sed -n '2,24p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "ERRO: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${DOOR}" ] && DOOR="$1" || { echo "ERRO: porta já informada ('${DOOR}')." >&2; exit 2; }; shift ;;
  esac
done

_integ() {
  local i; i="$(bash "${CORE}/.claude/validation/resolve-integration-branch.sh" "${CORE}" 2>/dev/null || true)"
  printf '%s' "${i:-main}"
}
INTEG="$(_integ)"
git -C "${CORE}" fetch -q origin "${INTEG}" 2>/dev/null || true

# ── O REGISTRO vem da REF, não da árvore de trabalho de quem chama ───────────────────────────
# Passada adversarial da F3: com o members.yaml lido do DISCO, uma edição não commitada do `remote:`
# mandava a porta para outro destino sem aviso. Papel, destino e ids de adotante são parte do que
# se publica — então vêm do mesmo commit que o conteúdo. `--members` só existe para a bancada.
MEMBERS=""
_TMPM="$(mktemp)"
_load_members() {  # $1 = ref
  if [ -n "${MEMBERS_OVERRIDE}" ]; then
    [ -f "${MEMBERS_OVERRIDE}" ] || { echo "ERRO: registro ausente: ${MEMBERS_OVERRIDE}" >&2; return 2; }
    echo "  ⚠️ --members: registro fora da ref (${MEMBERS_OVERRIDE}) — uso de bancada, não de publicação." >&2
    MEMBERS="${MEMBERS_OVERRIDE}"; return 0
  fi
  git -C "${CORE}" show "$1:${MEMBERS_REL}" > "${_TMPM}" 2>/dev/null && [ -s "${_TMPM}" ] \
    || { echo "ERRO: não li ${MEMBERS_REL} em $1 — sem o registro da integração não sei papel nem destino." >&2; return 3; }
  MEMBERS="${_TMPM}"
  if ! git -C "${CORE}" diff --quiet "$1" -- "${MEMBERS_REL}" 2>/dev/null; then
    echo "  ℹ️ o members.yaml da sua árvore difere de $1 — vale o de $1 (o que está mergeado)." >&2
  fi
}

# ── O registro: uma linha por membro (id, kind, role, remote, pin, local_path), comentário fora ──
# Separador \037 (não tab): `IFS=$'\t' read` colapsa campos vazios consecutivos.
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
# TETO DECLARADO: a contagem usa as raízes que viajam para QUALQUER papel (`--emit-scrub-roots`), não
# o manifesto de cada porta — para standalone, plugins e mini ela pode contar commit que não chega
# nelas. Superestima, nunca subestima; é informativa.
_status() {
  local tip doors measured=0 total=0
  tip="origin/${INTEG}"
  git -C "${CORE}" rev-parse --verify --quiet "${tip}^{commit}" >/dev/null || {
    echo "ERRO: não consegui resolver ${tip} — sem a ponta da integração não há defasagem a medir." >&2; return 3; }
  _load_members "${tip}" || return $?
  doors="$(_members_tsv | awk -F'\037' '$2=="door"')"
  [ -n "${doors}" ] || { echo "ERRO: nenhuma porta (kind: door) no registro de ${tip} — isto não é 'tudo em dia'." >&2; return 3; }
  local tmp; tmp="$(mktemp -d)"
  printf '══ /meta:publish --status — carimbo PUBLICADO × %s (%s)\n' "${tip}" "$(git -C "${CORE}" rev-parse --short=12 "${tip}")"
  printf '%-18s %-10s %-14s %-14s %-11s %s\n' "porta" "papel" "pin publicado" "pin registro" "defasagem" "estado"
  local id kind role remote pin lp url br stamp rpin rrole n state prov
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

if [ "${MODE}" = "status" ]; then _status; _rc=$?; rm -f "${_TMPM}"; exit "${_rc}"; fi

# =============================================================================
# --all — cada porta numa rodada própria (um clone descartável por porta)
# =============================================================================
if [ "${MODE}" = "all" ]; then
  git -C "${CORE}" rev-parse --verify --quiet "origin/${INTEG}^{commit}" >/dev/null \
    || { echo "ERRO: não consegui resolver origin/${INTEG}." >&2; exit 3; }
  _load_members "origin/${INTEG}" || exit $?
  _doors_all="$(_members_tsv | awk -F'\037' '$2=="door" {print $1}')"
  [ -n "${_doors_all}" ] || { echo "ERRO: nenhuma porta (kind: door) no registro — --all sem objeto não é sucesso." >&2; exit 3; }
  _worst=0
  while IFS= read -r _id; do
    [ -n "${_id}" ] || continue
    echo; echo "████ ${_id}"
    _a=("${_id}"); [ "${PUSH}" -eq 1 ] && _a+=(--push)
    [ -n "${MEMBERS_OVERRIDE}" ] && _a+=(--members "${MEMBERS_OVERRIDE}")
    [ -n "${EXPECT_PIN}" ] && _a+=(--expect-pin "${EXPECT_PIN}")
    _r=0; bash "${BASH_SOURCE[0]}" "${_a[@]}" || _r=$?
    [ "${_r}" -gt "${_worst}" ] && _worst="${_r}"
  done <<< "${_doors_all}"
  rm -f "${_TMPM}"
  exit "${_worst}"
fi

# =============================================================================
# publicar UMA porta
# =============================================================================
[ -n "${DOOR}" ] || { echo "uso: ops/publish-door.sh <porta>|--all|--status [--push]" >&2; exit 2; }

# ── (1) A FONTE: origin/<integração>, nunca o HEAD local ─────────────────────────────────────
SRC_REF="origin/${INTEG}"
if [ -n "${FROM_REF}" ]; then
  [ "${PUSH}" -eq 0 ] || { echo "ERRO: --from '${FROM_REF}' com --push — porta pública só nasce de origin/${INTEG}. --from é ensaio." >&2; exit 2; }
  [ -z "${CLONE}" ] || { echo "ERRO: --from com --clone deixaria um commit de branch não mergeada no clone '${CLONE}', e um --push seguinte o levaria a público. Ensaio de branch é só em clone descartável." >&2; exit 2; }
  SRC_REF="${FROM_REF}"
fi
if ! git -C "${CORE}" rev-parse --verify --quiet "${SRC_REF}^{commit}" >/dev/null; then
  echo "ERRO: não consegui resolver '${SRC_REF}'. A porta é projeção da INTEGRAÇÃO mergeada; sem ela eu não publico nada (e não caio no HEAD local, que pode ser uma branch de PR aberto)." >&2
  exit 3
fi
PIN="$(git -C "${CORE}" rev-parse --short=12 "${SRC_REF}")"
PIN_FULL="$(git -C "${CORE}" rev-parse "${SRC_REF}")"
# O pin que o maestro CONFIRMOU no ensaio é o que se publica: main que andou no intervalo recusa.
if [ -n "${EXPECT_PIN}" ] && [ "${PIN_FULL#${EXPECT_PIN}}" = "${PIN_FULL}" ]; then
  echo "ERRO: ${SRC_REF} está em ${PIN}, não no pin confirmado (${EXPECT_PIN}) — a integração andou desde o ensaio. Ensaie de novo e confirme o pin novo." >&2
  exit 2
fi

_load_members "${SRC_REF}" || exit $?
ROW="$(_members_tsv | awk -F'\037' -v id="${DOOR}" '$1==id')"
[ -n "${ROW}" ] || { echo "ERRO: '${DOOR}' não está no registro de ${SRC_REF}." >&2; exit 2; }
IFS=$'\037' read -r _ KIND REG_ROLE REG_REMOTE REG_PIN _LP <<< "${ROW}"
[ "${KIND}" = "door" ] || { echo "ERRO: '${DOOR}' tem kind='${KIND}', não 'door' — só PORTA se publica por aqui (adotante se atualiza pelo /meta:adopt --update)." >&2; exit 2; }
ROLE="${ROLE_OVERRIDE:-${REG_ROLE}}"
[ -n "${ROLE}" ] || { echo "ERRO: '${DOOR}' sem role: no registro — não materializo sem saber o corte." >&2; exit 2; }
REMOTE_URL="$(_url_of "${REG_REMOTE}")"
[ -n "${REMOTE_URL}" ] || { echo "ERRO: '${DOOR}' sem remoto clonável no registro (remote='${REG_REMOTE}')." >&2; exit 2; }
if [ "${PUSH}" -eq 1 ] && [ "${REG_PIN}" = "n/a" ]; then
  echo "ERRO: '${DOOR}' nunca foi materializada pelo carimbo (pin n/a no registro). A 1ª materialização dela é uma fase própria (onion-mini: F5, SAC-94)." >&2
  exit 2
fi

# ── O estado do core ANTES — o que é DESTE motor ─────────────────────────────────────────────
_core_state() {
  printf '%s|%s' "$(git -C "${CORE}" rev-parse HEAD 2>/dev/null)" \
    "$(git -C "${CORE}" status --porcelain 2>/dev/null | sha256sum | cut -c1-16)"
}
CORE_BEFORE="$(_core_state)"

T="$(mktemp -d)"; WT="${T}/src"
CLONE_GIVEN=""
# Os filhos (o materialize-door destaca a PRÓPRIA worktree) criam temporários DENTRO de T: assim
# "nenhuma worktree deste motor sobrou" é uma pergunta sobre um prefixo que é só dele.
mkdir -p "${T}/tmp"
_cleanup() {
  git -C "${CORE}" worktree remove --force "${WT}" >/dev/null 2>&1 || true
  git -C "${CORE}" worktree prune >/dev/null 2>&1 || true
  if [ "${KEEP}" -eq 1 ] && [ -z "${CLONE_GIVEN}" ]; then
    echo "  (--keep) clone preservado em ${T}/${DOOR}"
  else
    rm -rf "${T}"
  fi
  rm -f "${_TMPM}"
}
trap _cleanup EXIT
git -C "${CORE}" worktree add --detach -q "${WT}" "${SRC_REF}" >/dev/null 2>&1 \
  || { echo "ERRO: não consegui destacar uma worktree em ${SRC_REF}." >&2; exit 3; }

# ── (2) O CLONE da porta: descartável por default; o do maestro só limpo, em dia e do remoto certo ──
if [ -n "${CLONE}" ]; then
  CLONE_GIVEN=1
  git -C "${CLONE}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: --clone '${CLONE}' não é repositório git." >&2; exit 2; }
  DEST="$(cd "${CLONE}" && pwd)"
  # o materializador deriva o NOME da porta (README, `framework:` do carimbo) do basename do destino
  [ "$(basename "${DEST}")" = "${DOOR}" ] \
    || { echo "ERRO: o clone '${DEST}' não se chama '${DOOR}' — o materializador escreveria o nome errado no README e no carimbo." >&2; exit 2; }
  # LIMPO INCLUSIVE DO IGNORADO: a materialização apaga tudo menos .git, e um `.env` excluído pelo
  # .gitignore não aparece no `--porcelain` simples (passada adversarial: o token sumiu do clone).
  _dirty="$(git -C "${DEST}" status --porcelain --ignored 2>/dev/null | grep -c . || true)"
  [ "${_dirty}" -eq 0 ] || { echo "ERRO: o clone '${DEST}' tem ${_dirty} caminho(s) não commitado(s) ou ignorado(s) (git status --porcelain --ignored). A materialização APAGA a superfície — não faço isso sobre o que não está no git." >&2; exit 2; }
  _origin="$(git -C "${DEST}" remote get-url origin 2>/dev/null || true)"
  _norm() { printf '%s' "$1" | sed -E 's#^(https?://|git@)##; s#^github\.com:#github.com/#; s#\.git$##; s#/$##'; }
  [ "$(_norm "${_origin}")" = "$(_norm "${REMOTE_URL}")" ] \
    || { echo "ERRO: o origin do clone ('${_origin}') não é o remoto da porta no registro ('${REMOTE_URL}')." >&2; exit 2; }
else
  # O NOME do diretório é o da porta, e não é estética: o materialize-door escreve o README (`git clone
  # .../<nome>`) e o `framework:` do carimbo a partir do basename do destino. O 1º ensaio clonava em
  # `door/` e a porta sairia apresentando-se como `door` (achado no dogfood, 2026-10-10).
  DEST="${T}/${DOOR}"
  git clone -q "${REMOTE_URL}" "${DEST}" 2>/dev/null || { echo "ERRO: não consegui clonar ${REMOTE_URL}." >&2; exit 2; }
fi
BRANCH="$(git -C "${DEST}" symbolic-ref --short HEAD 2>/dev/null || true)"
[ -n "${BRANCH}" ] || { echo "ERRO: o clone da porta está em HEAD destacado — não sei que ramo publicar." >&2; exit 2; }
# EM DIA COM O REMOTO, EXATAMENTE: o push leva tudo que o clone tem à frente do remoto, e a verificação
# só olha a árvore. Commit local anterior (outro ensaio, trabalho à mão) iria a público sem verificação
# (passada adversarial da F3: um ensaio --from deixou um commit de branch no clone, e o publish seguinte
# o empurraria junto). Atrás do remoto também recusa: o push seria rejeitado, ou pior, forçado.
git -C "${DEST}" fetch -q origin "${BRANCH}" 2>/dev/null || { echo "ERRO: não consegui buscar origin/${BRANCH} do clone." >&2; exit 2; }
if [ "$(git -C "${DEST}" rev-parse HEAD 2>/dev/null)" != "$(git -C "${DEST}" rev-parse "origin/${BRANCH}" 2>/dev/null)" ]; then
  echo "ERRO: o clone não está em origin/${BRANCH} (HEAD $(git -C "${DEST}" rev-parse --short=12 HEAD) ≠ $(git -C "${DEST}" rev-parse --short=12 "origin/${BRANCH}" 2>/dev/null)). Commit local à frente iria a público sem verificação; alinhe o clone (ou rode sem --clone)." >&2
  exit 2
fi
echo "══ /meta:publish ${DOOR} — papel '${ROLE}' · fonte ${SRC_REF} (${PIN}) · destino ${REMOTE_URL}@${BRANCH} · $([ "${PUSH}" -eq 1 ] && echo PUBLICAÇÃO || echo ENSAIO)"

# PORTA QUE NUNCA FOI MATERIALIZADA e cujo repo tem OUTRO conteúdo (o onion-mini é hoje a destilação
# curada, sem `.claude/`): o materialize-door recusa limpar destino que não parece porta, e com razão.
# Dizer isso aqui, com a fase nomeada (1º ensaio do mini, 2026-10-10: saía rc 1 apontando o lugar errado).
if [ "${REG_PIN}" = "n/a" ] && [ ! -d "${DEST}/.claude" ] \
   && [ -n "$(ls -A "${DEST}" 2>/dev/null | grep -v '^\.git$' || true)" ]; then
  echo "ERRO: '${DOOR}' nunca foi materializada pelo motor (pin n/a) e o repo dela guarda outro conteúdo, sem .claude/. Substituí-lo é a 1ª materialização, uma fase própria (onion-mini: F5, SAC-94) — este motor não apaga o que não reconhece como porta." >&2
  exit 2
fi

# ── (3) PARIDADE DE PAPEL antes de materializar ──────────────────────────────────────────────
# Registro × carimbo publicado (HEAD do clone). Divergência RECUSA: foi lendo uma fonte em vez da
# outra que a onion-core perdeu 85 arquivos em 2026-09-30. Trocar o papel é ato deliberado: --role
# com --force-role-change (ex.: a onion-core de hub para source, decidido na matriz).
STAMP_HEAD="$(git -C "${DEST}" show HEAD:.claude/.onion-version 2>/dev/null || true)"
STAMP_ROLE="$(_stamp_field "${STAMP_HEAD}" role)"
# Porta que o registro diz JÁ materializada (pin real) e cujo repo não traz carimbo nenhum: o destino
# não é o que o registro diz (repo errado, porta apagada) — recusa em vez de materializar por cima.
if [ "${REG_PIN}" != "n/a" ]; then
  if [ "${ROLE}" = "plugins" ]; then
    git -C "${DEST}" ls-tree -r --name-only HEAD -- plugins 2>/dev/null | grep -q '/\.claude-plugin/provenance\.json$' \
      || { echo "ERRO: o registro diz que '${DOOR}' foi publicada (pin ${REG_PIN}), mas o repo não tem nenhum plugins/*/.claude-plugin/provenance.json — destino não reconhecido." >&2; exit 2; }
  elif [ -z "${STAMP_HEAD}" ]; then
    echo "ERRO: o registro diz que '${DOOR}' foi publicada (pin ${REG_PIN}), mas o repo não tem .claude/.onion-version — destino não reconhecido como esta porta." >&2
    exit 2
  fi
fi
if [ -n "${STAMP_ROLE}" ] && [ "${STAMP_ROLE}" != "${REG_ROLE}" ] && [ "${FORCE_ROLE}" -ne 1 ]; then
  echo "ERRO: papel divergente — o registro diz '${REG_ROLE}' e o carimbo PUBLICADO da porta diz '${STAMP_ROLE}'. Não publico com as duas fontes contando histórias diferentes (REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela))." >&2
  exit 2
fi
if [ -n "${ROLE_OVERRIDE}" ] && [ "${ROLE_OVERRIDE}" != "${STAMP_ROLE:-${REG_ROLE}}" ] && [ "${FORCE_ROLE}" -ne 1 ]; then
  echo "ERRO: --role '${ROLE_OVERRIDE}' muda o que a porta distribui (hoje '${STAMP_ROLE:-${REG_ROLE}}'). Diga isso em voz alta: --force-role-change." >&2
  exit 2
fi

# ── (4) MATERIALIZAR pelos scripts DA WORKTREE (o motor também é de origin/main) ─────────────
# O pin vai EXPLÍCITO ao materializador (--from <sha>): sem isso ele refaria o fetch, e uma main que
# andasse no meio sairia como recusa confusa no (5b).
_mrc=0
if [ "${ROLE}" = "plugins" ]; then
  TMPDIR="${T}/tmp" bash "${WT}/.claude/utils/marketplace/materialize-marketplace-repo.sh" "${DEST}" --no-commit 2>&1 | sed 's/^/  │ /'
  _mrc="${PIPESTATUS[0]}"
else
  _ma=("${DEST}" --role "${ROLE}" --from "${PIN_FULL}"); [ "${FORCE_ROLE}" -eq 1 ] && _ma+=(--force-role-change)
  TMPDIR="${T}/tmp" bash "${WT}/ops/materialize-door.sh" "${_ma[@]}" 2>&1 | sed 's/^/  │ /'
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
#   · caminho de máquina sob a home de uma conta REAL.
# ⚠️ OS NOMES COMERCIAIS FALHAM FECHADO (passada adversarial da F3): o projection-safety.sh acha o
#    registro pelo CWD, e chamado de fora do core devolvia VAZIO com rc 0 — a varredura saía limpa sem
#    ter procurado. Agora ele recebe o registro explícito, roda do core, e o rc é lido; registro com
#    marcador de confidencialidade e zero termo derivado é "não medi", não "limpo".
_ps_out=""; _ps_rc=0
_ps_out="$(cd "${CORE}" && bash "${WT}/.claude/validation/projection-safety.sh" --emit-terms --members "${MEMBERS}" 2>&1)" || _ps_rc=$?
_terms_names="$(printf '%s\n' "${_ps_out}" | grep -vE '^(CONFIDENCIAL|PRIVADO)$' | grep -v '^[[:space:]]*$' || true)"
if [ "${_ps_rc}" -ne 0 ]; then
  echo "✗ (5a) os nomes comerciais NÃO puderam ser derivados (projection-safety rc=${_ps_rc}): ${_ps_out:0:200}" >&2; FAIL=1
elif [ -z "${_terms_names}" ] && grep -qE 'CONFIDENCIAL|PRIVADO' "${MEMBERS}"; then
  echo "✗ (5a) o registro tem marcador de confidencialidade e nenhum nome comercial foi derivado — varrer assim seria teatro." >&2; FAIL=1
fi
_terms_sub="$( { printf '%s\n' "${_terms_names}"
                 [ -f "${CORE}/docs/evolution/federation/client-terms.txt" ] && grep -vE '^[[:space:]]*(#|$)' "${CORE}/docs/evolution/federation/client-terms.txt"
                 _members_tsv | awk -F'\037' '($2=="adopter"||$2=="method") && $1 !~ /^onion-/ && $1 !~ /^marcio/ && $1 !~ /^selftest-/ && length($1)>=4 {print $1}'
               } 2>/dev/null | grep -v '^[[:space:]]*$' | sort -u || true)"
_terms_word="$(_members_tsv | awk -F'\037' '($2=="adopter"||$2=="method") && $1 ~ /^onion-/ {print $1}' | sort -u || true)"
_leaks=""
while IFS= read -r _t; do
  [ -n "${_t}" ] || continue
  _hit="$(grep -rilF --exclude-dir=.git -- "${_t}" "${DEST}" 2>/dev/null | sed "s|^${DEST}/||" | head -5 | tr '\n' ' ')"
  [ -n "${_hit}" ] && _leaks="${_leaks}    termo de adotante em: ${_hit}"$'\n'
done <<< "${_terms_sub}"
while IFS= read -r _t; do
  [ -n "${_t}" ] || continue
  _hit="$(grep -rilwF --exclude-dir=.git -- "${_t}" "${DEST}" 2>/dev/null | sed "s|^${DEST}/||" | head -5 | tr '\n' ' ')"
  [ -n "${_hit}" ] && _leaks="${_leaks}    id '${_t}' (prefixo onion-) em: ${_hit}"$'\n'
done <<< "${_terms_word}"
# As CONTAS reais são DERIVADAS — dos `local_path` do registro, de quem roda e das contas humanas da
# máquina (passwd, uid >= 1000 com home em /home) —, nunca uma lista de exemplos tolerados: `/home/conta/`
# e `/home/x/` em fixture são dado de teste, e uma lista de "genéricos permitidos" falharia pelo
# vocabulário (1º dogfood: a forma larga acusou 3 fixtures inócuas ao lado das 2 contas reais; a
# passada adversarial achou a 3ª conta real, que só o passwd conhecia). Teto declarado: conta de OUTRA
# máquina que não esteja no registro não é vista.
_accts="$( { _members_tsv | awk -F'\037' '{print $6}' | sed -n 's#^/home/\([a-z_][a-z0-9_-]*\)/.*#\1#p'
             id -un 2>/dev/null
             getent passwd 2>/dev/null | awk -F: '$3>=1000 && $3<60000 && $6 ~ "^/home/" {print $1}'
           } | grep -E '^[a-z_][a-z0-9_-]*$' | sort -u | paste -sd'|' -)"
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
elif [ "${FAIL}" -eq 0 ]; then
  echo "  (5a) vazamento: nenhum termo de adotante (REGRA 36 + ids onion-*), nenhum caminho de máquina"
fi

# (5b) PARIDADE DE PAPEL no que foi montado: o carimbo que vai a público diz o papel pedido.
if [ "${ROLE}" = "plugins" ]; then
  _refs="$(find "${DEST}/plugins" -path '*/.claude-plugin/provenance.json' -exec sed -n 's/.*"ref"[[:space:]]*:[[:space:]]*"\([0-9a-f]*\)".*/\1/p' {} + 2>/dev/null | sort -u)"
  if [ "${_refs}" = "${PIN_FULL}" ]; then
    echo "  (5b) paridade: todo provenance.json aponta ${PIN} (${SRC_REF})"
  else
    echo "✗ (5b) provenance.json não aponta ${SRC_REF} (${PIN}): $(printf '%s' "${_refs}" | tr '\n' ' ')" >&2; FAIL=1
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
    printf '%s\n' "${_lo}" | grep -E '^VIOLATION' | head -10 | sed 's/^/      /' >&2
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
# Como o clone começou EXATAMENTE em origin/<ramo> (passo 2), "nada a commitar" significa que o
# remoto já carrega este conteúdo — não é afirmação sobre um índice local defasado.
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
POST_FAIL=0
if [ "${PUSH}" -ne 1 ]; then
  echo
  if [ "${COMMITTED}" -eq 1 ]; then
    echo "✅ ENSAIO concluído: verificado e commitado no clone, NÃO publicado (pin ${PIN_FULL})."
    echo "   Para publicar: /meta:publish ${DOOR} — que pergunta antes e passa --push --expect-pin ${PIN}."
  else
    echo "✅ ENSAIO concluído: verificado; a porta já espelha ${SRC_REF}, nada a publicar."
  fi
  [ "${KEEP}" -eq 1 ] || [ -n "${CLONE_GIVEN}" ] || echo "   (o clone descartável será removido; --keep o preserva para inspeção)"
elif [ -n "${NOT_MEASURED}" ]; then
  echo "✗ --push RECUSADO: verificação não medida (${NOT_MEASURED# }). Publicar sem medir é afirmar o que não sei." >&2
  exit 2
elif [ "${COMMITTED}" -eq 1 ]; then
  # exatamente UM commit vai a público: o verificado (o passo 2 garantiu a base)
  _ahead="$(git -C "${DEST}" rev-list --count "origin/${BRANCH}..HEAD" 2>/dev/null || echo '?')"
  [ "${_ahead}" = "1" ] || { echo "✗ o clone tem ${_ahead} commit(s) à frente de origin/${BRANCH}, não 1 — não empurro o que não verifiquei." >&2; exit 2; }
  git -C "${DEST}" push -q origin "HEAD:${BRANCH}" 2>&1 | sed 's/^/  │ /'
  _prc="${PIPESTATUS[0]}"
  [ "${_prc}" -eq 0 ] || { echo "✗ push recusado pelo remoto (rc=${_prc}) — nada publicado." >&2; exit 2; }
  _local="$(git -C "${DEST}" rev-parse HEAD)"
  _remote="$(git ls-remote "${REMOTE_URL}" "refs/heads/${BRANCH}" 2>/dev/null | awk '{print $1}')"
  if [ "${_remote}" != "${_local}" ]; then
    echo "✗ PUBLICADO, mas a CONFERÊNCIA falhou: o remoto (${_remote:0:12}) não bate com o commit empurrado (${_local:0:12}). Confira à mão." >&2
    POST_FAIL=1
  else
    echo "  (7) publicado e CONFERIDO no remoto: ${BRANCH} = ${_local:0:12} · carimbo pin ${PIN}"
    echo "      O selo é o carimbo da porta: /meta:publish --status o lê do remoto. Nenhum PR no core."
  fi
  if [ "${ROLE}" != "${REG_ROLE}" ]; then
    echo "  ⚠️ o papel PUBLICADO ('${ROLE}') difere do registro ('${REG_ROLE}'): alinhe o role: da porta no members.yaml na próxima leva (REGRA 92), e atualize o clone local dela."
  fi
else
  _remote="$(git ls-remote "${REMOTE_URL}" "refs/heads/${BRANCH}" 2>/dev/null | awk '{print $1}')"
  if [ "${_remote}" = "$(git -C "${DEST}" rev-parse HEAD)" ]; then
    echo "  (7) nada a empurrar: o remoto (${_remote:0:12}) já carrega este conteúdo."
  else
    echo "✗ o remoto (${_remote:0:12}) andou desde o clone — rode de novo." >&2; exit 2
  fi
fi

# ── (8) O CORE NÃO MUDOU — no que é DESTE motor ──────────────────────────────────────────────
trap - EXIT; _cleanup
CORE_AFTER="$(_core_state)"
_mine="$(git -C "${CORE}" worktree list --porcelain 2>/dev/null | grep '^worktree ' | grep -F "${T}" || true)"
if [ "${CORE_AFTER}" != "${CORE_BEFORE}" ] || [ -n "${_mine}" ]; then
  echo "✗ O MOTOR ALTEROU O CORE (antes ${CORE_BEFORE} · depois ${CORE_AFTER}${_mine:+ · worktree sobrando: ${_mine}}) — defeito do motor." >&2
  [ "${PUSH}" -eq 1 ] && [ "${COMMITTED:-0}" -eq 1 ] && { echo "   (a porta FOI publicada antes desta conferência)" >&2; exit 4; }
  exit 1
fi
echo "  (8) core intacto: HEAD e árvore iguais a antes, nenhuma worktree deste motor sobrando"
[ "${POST_FAIL}" -eq 0 ] || exit 4
exit 0
