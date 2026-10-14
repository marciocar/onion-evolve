#!/usr/bin/env bash
# door-seal-pin.sh — carimba no REGISTRO o pin que a porta de fato PUBLICOU, lido do REMOTO.
#
# Uso: ops/door-seal-pin.sh <member-id> [--dry-run] [--members <path>]
#      rc=0 carimbado (ou já em dia) · rc=1 divergência que eu NÃO carimbo · rc=2 precondição ou não pude ler
#
# ══ POR QUE ESTE SCRIPT EXISTE (medido duas vezes em 2026-09-25/26) ═══════════════════════════
# O `onion_version` de um membro `kind: door` no `members.yaml` era mantido À MÃO, e à mão apodrece:
#   · 21ª materialização: a porta foi publicada em 07c81b974880 e o registro seguiu em d425501b14bc.
#   · 22ª, DUAS HORAS DEPOIS: apodreceu de novo, e a REGRA 85 (Porta pública espelha o core, com
#     catraca) acusava 3 commits de defasagem que já não existiam, porque ela lê o REGISTRO.
# Desde a F3 esse campo é CACHE: o fato é o carimbo publicado, que o `publish-door.sh --status` lê do
# remoto. Este script alinha o cache ao fato, quando alguém quiser o cache em dia.
# Medido também: `pin-integrity-check.sh` devolve `pin-untrusted unknown` — ele valida o pin do STAMP
# do alvo e o histórico do `onion/vendor`, NÃO este campo. Perguntas diferentes, nomes parecidos.
#
# ══ A LEITURA É A DO REMOTO, E É A MESMA DO --status (cura de 2026-10-14, PR #1100) ═══════════
# Até aqui este script lia o carimbo do CLONE LOCAL da porta (`local_path`), exigia árvore limpa e
# conferia `HEAD` do clone contra o remoto por `gh api`. Isso fazia sentido quando a publicação era
# feita NAQUELE clone. Desde a F3 o `publish-door.sh` publica a partir de um clone DESCARTÁVEL e não
# toca os clones locais, então eles ficam para trás sozinhos. Medido nas 4 portas em `--dry-run`:
# onion-mini com arquivo não commitado, onion-standalone e onion-core atrás do remoto, onion-plugins
# sem carimbo no clone. O `--status` dizia "em dia" nas quatro e este script recusava as quatro, e o
# cache foi carimbado à mão com o pin que o `--status` leu. Duas leituras do mesmo fato, uma delas
# errada por construção.
# A cura não duplica a leitura: as duas pontas fazem `source` de `ops/door-published-stamp.sh`
# (`door_read_published`). O que vem do remoto JÁ É o publicado, então as guardas "árvore limpa" e
# "clone == remoto" deixam de ter objeto; o que fica é o que o pin tem de provar no CORE (abaixo).
# SEM fallback ao clone local, por decisão: clone local não prova publicação (foi o defeito), e um
# fallback silencioso traria a leitura errada de volta exatamente quando o remoto estiver fora do ar.
# Remoto ilegível recusa com rc=2 e diz por quê. O `local_path` deixa de ser lido aqui.
#
# ══ POR QUE É `ops/` E NÃO REGRA DO LINT ══════════════════════════════════════════════════════
# Precisa do REMOTO pela rede, que o CI não garante, e escreve no registro. Guarda que só passa na
# máquina de uma pessoa não é guarda.
#
# ══ A FRONTEIRA QUE ELE NÃO CRUZA ═════════════════════════════════════════════════════════════
# Ele NÃO empurra e NÃO materializa. Publicar é ato do maestro (I3). Ele roda DEPOIS do push e só
# alinha o registro ao que já é público. O que ele carimba é `onion_version`; as duas linhas de dado do
# `door-staleness-baseline.txt` seguem manuais por decisão do maestro (2026-09-26) — o `--emit-baseline`
# devolve só 2 linhas e o arquivo tem 184, então redirecionar apaga ~170 de histórico.
set -uo pipefail

MEMBER="${1:-}"; shift || true
DRY=0; MEMBERS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --members) MEMBERS="${2:?--members exige path}"; shift 2 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${MEMBER}" ] || { echo "uso: door-seal-pin.sh <member-id> [--dry-run] [--members <path>]" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "${HERE}/.." && pwd)"
: "${MEMBERS:=${CORE}/docs/evolution/federation/members.yaml}"
[ -f "${MEMBERS}" ] || { echo "ERRO: registro ausente: ${MEMBERS}" >&2; exit 2; }
STAMP_LIB="${HERE}/door-published-stamp.sh"
[ -f "${STAMP_LIB}" ] || { echo "ERRO: ${STAMP_LIB} ausente — é a leitura única do carimbo publicado, e eu não a reimplemento." >&2; exit 2; }
# shellcheck source=door-published-stamp.sh
. "${STAMP_LIB}"

# Leitor de campo do membro — mesmo shape do `member_field` do co-deliver.sh (um dado, um acessor).
_field() {
  awk -v want="${MEMBER}" -v field="$1" '
    function clean(s) { sub(/^[^:]*:[[:space:]]*/,"",s); sub(/[[:space:]]*#.*$/,"",s)
                        gsub(/[[:space:]]+$/,"",s); gsub(/"/,"",s); gsub(/\047/,"",s); return s }
    /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { cur=(clean($0)==want); next }
    cur { l=$0; gsub(/^[[:space:]]+/,"",l); if (l ~ ("^" field ":")) { print clean(l); exit } }
  ' "${MEMBERS}"
}

KIND="$(_field kind)"; REMOTE="$(_field remote)"; REGPIN="$(_field onion_version)"
[ -n "${KIND}${REMOTE}${REGPIN}" ] || { echo "ERRO: '${MEMBER}' não existe em ${MEMBERS} (ou não tem nenhum campo legível)." >&2; exit 2; }
# `kind: door` é o objeto desta guarda. Um adotante comum não é espelho do core.
[ "${KIND}" = "door" ] || { echo "ERRO: '${MEMBER}' tem kind='${KIND:-vazio}', não 'door' — este carimbo é só para PORTA (espelho materializado do core)." >&2; exit 2; }

# ── (1) O pin que a porta PUBLICOU — lido do REMOTO, pela mesma leitura do --status ───────────
URL="$(_url_of "${REMOTE}")"
[ -n "${URL}" ] || { echo "ERRO: o registro não dá url clonável para '${MEMBER}' (remote='${REMOTE:-vazio}') — sem remoto não sei o que foi publicado." >&2; exit 2; }
WORK="$(mktemp -d)" || { echo "ERRO: mktemp -d falhou — sem diretório descartável não clono o remoto." >&2; exit 2; }; TMP=""
trap 'rm -rf "${WORK}"; [ -n "${TMP}" ] && rm -f "${TMP}"' EXIT
door_read_published "${URL}" "${WORK}/door"
case "${DPS_STATE}" in
  ok) ;;
  no-stamp) echo "ERRO: o remoto ${URL} (ramo ${DPS_BRANCH}) foi lido e NÃO traz carimbo (.claude/.onion-version nem provenance.json) — porta nunca materializada pelo motor; não carimbo pin que ela não declara." >&2; exit 2 ;;
  *) echo "ERRO: não li o carimbo publicado em ${URL} (estado: ${DPS_STATE}). Sem o remoto eu NÃO carimbo — e não caio para o clone local, porque clone local não prova publicação (PR #1100)." >&2; exit 2 ;;
esac
DOORPIN="${DPS_PIN}"
grep -qE '^[0-9a-f]{7,40}$' <<< "${DOORPIN}" \
  || { echo "ERRO: pin ilegível no carimbo publicado: '${DOORPIN}' — não carimbo o que não consigo ler." >&2; exit 2; }

# ── (2) O pin é commit REAL no core, e está na INTEGRAÇÃO mergeada ──────────────────────────
# A 1ª pega pin forjado/errado de digitação; a 2ª pega porta materializada de branch (o defeito de
# 2026-09-25, cuja cura vive no materializador). Aqui é a segunda barreira, independente dela.
git -C "${CORE}" cat-file -e "${DOORPIN}^{commit}" 2>/dev/null \
  || { echo "ERRO: o pin '${DOORPIN}' NÃO é commit deste core — pin forjado, truncado ou de outro repo." >&2; exit 1; }
_INTEG="$(bash "${CORE}/.claude/validation/resolve-integration-branch.sh" "${CORE}" 2>/dev/null || true)"
: "${_INTEG:=main}"
git -C "${CORE}" fetch -q origin "${_INTEG}" 2>/dev/null || true
if git -C "${CORE}" rev-parse --verify --quiet "origin/${_INTEG}^{commit}" >/dev/null; then
  git -C "${CORE}" merge-base --is-ancestor "${DOORPIN}" "origin/${_INTEG}" \
    || { echo "ERRO: o pin '${DOORPIN}' NÃO está em origin/${_INTEG} — a porta foi materializada de trabalho não mergeado. NÃO carimbo isso no registro." >&2; exit 1; }
else
  echo "ERRO: não consegui resolver origin/${_INTEG} — não afirmo que o pin está na integração sem poder conferir." >&2; exit 2
fi
# Forma CANÔNICA do registro: 12 caracteres. ⚠️ Achado do 1º dogfood desta cura (2026-10-14): o
# provenance.json dos plugins carrega o `ref` de 40, o cache tem 12, e a comparação literal reescreveria
# um cache que o --status (que compara 12) já dá como em dia.
DOORPIN="$(git -C "${CORE}" rev-parse --short=12 "${DOORPIN}^{commit}")"

echo "══ door-seal-pin — ${MEMBER}"
echo "  carimbo publicado        : ${DOORPIN} (remoto ${URL}, ramo ${DPS_BRANCH}${DPS_RELEASE:+, release ${DPS_RELEASE}})"
echo "  na integração            : ✓ ancestral de origin/${_INTEG}"
echo "  pin no registro (cache)  : ${REGPIN:-<vazio>}"

if [ "${REGPIN}" = "${DOORPIN}" ]; then
  echo "✅ registro já em dia — nada a carimbar."; exit 0
fi
if [ "${DRY}" -eq 1 ]; then
  echo "▶️  --dry-run: eu carimbaria ${REGPIN:-<vazio>} → ${DOORPIN} em ${MEMBERS}"; exit 0
fi

# ── (3) CARIMBO CIRÚRGICO — só a linha do membro, e só depois de tudo acima ─────────────────
# `awk` sobre o bloco do membro, preservando comentário e indentação de todo o resto do arquivo.
TMP="$(mktemp)"
awk -v want="${MEMBER}" -v pin="${DOORPIN}" '
  function clean(s) { sub(/^[^:]*:[[:space:]]*/,"",s); gsub(/[[:space:]]+$/,"",s); gsub(/"/,"",s); gsub(/\047/,"",s); return s }
  /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { cur=(clean($0)==want) }
  cur && done!=1 && /^[[:space:]]*onion_version:[[:space:]]*/ {
    match($0, /^[[:space:]]*/); ind=substr($0, 1, RLENGTH)
    print ind "onion_version: " pin "   # cache: carimbo publicado lido do remoto por ops/door-seal-pin.sh"
    done=1; next
  }
  { print }
' "${MEMBERS}" > "${TMP}"
grep -qF "onion_version: ${DOORPIN}" "${TMP}" \
  || { echo "ERRO: o carimbo NÃO apareceu na saída — não sobrescrevo o registro com o que não sei que mudou." >&2; exit 1; }
_before="$(wc -l < "${MEMBERS}")"; _after="$(wc -l < "${TMP}")"
[ "${_before}" -eq "${_after}" ] \
  || { echo "ERRO: a contagem de linhas mudou (${_before} → ${_after}) — um carimbo de UMA linha não muda o tamanho do arquivo. Abortando antes de gravar." >&2; exit 1; }
cat "${TMP}" > "${MEMBERS}"
echo "✅ carimbado: ${REGPIN:-<vazio>} → ${DOORPIN}"
echo "   ⚠️ as duas linhas de dado do door-staleness-baseline.txt seguem MANUAIS (decisão 2026-09-26)."
echo "   ▶️ commite o registro numa leva própria; a REGRA 85 volta a medir a porta em vez da memória."
