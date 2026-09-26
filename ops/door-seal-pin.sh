#!/usr/bin/env bash
# door-seal-pin.sh — carimba no REGISTRO o pin que a porta de fato PUBLICOU.
#
# Uso: ops/door-seal-pin.sh <member-id> [--dry-run] [--members <path>]
#      rc=0 carimbado (ou já em dia) · rc=1 divergência que eu NÃO carimbo · rc=2 precondição
#
# ══ POR QUE ESTE SCRIPT EXISTE (medido duas vezes em 2026-09-25/26) ═══════════════════════════
# O `onion_version` de um membro `kind: door` no `members.yaml` é LIDO pela REGRA 85 (Porta pública
# espelha o core, com catraca) para decidir defasagem. Ele era mantido À MÃO — e à mão apodrece:
#   · 21ª materialização: a porta foi publicada em 07c81b974880 e o registro seguiu em d425501b14bc.
#     Avancei à mão e escrevi, no próprio members.yaml, que "número mantido à mão apodrece".
#   · 22ª, DUAS HORAS DEPOIS: apodreceu de novo. A REGRA 85 acusava 3 commits de defasagem que já
#     não existiam, porque ela lê o REGISTRO, não a porta.
# Medido também: `pin-integrity-check.sh` devolve `pin-untrusted unknown` — ele valida o pin do
# STAMP do alvo e o histórico do `onion/vendor`, NÃO este campo. Perguntas diferentes, nomes
# parecidos; juntá-las por semelhança de nome seria o erro.
#
# ══ POR QUE É `ops/` E NÃO REGRA DO LINT ══════════════════════════════════════════════════════
# Mesmo motivo do `ops/audit-adopters-registry.sh`, e o motivo é mais forte que o arquivo: ele
# precisa do CLONE DA PORTA no disco e do REMOTO pela rede, e nenhum dos dois existe no CI. Guarda
# que só passa na máquina de uma pessoa não é guarda — é armadilha para todo mundo.
#
# ══ A FRONTEIRA QUE ELE NÃO CRUZA ═════════════════════════════════════════════════════════════
# Ele NÃO empurra e NÃO materializa. Publicar é ato do maestro (I3), e foi exatamente essa fronteira
# que impediu, em 2026-09-25, uma porta sair com código não mergeado quando o materializador ainda
# lia `HEAD`. Este script roda DEPOIS do push e só faz uma coisa: alinhar o registro ao que já é
# público. O que ele carimba é `onion_version`; as duas linhas de dado do `door-staleness-baseline.txt`
# seguem manuais por decisão do maestro (2026-09-26) — e há uma razão MEDIDA para cuidado ali: o
# `--emit-baseline` devolve só 2 linhas e o arquivo tem 184, então redirecionar apaga ~170 de
# histórico, e essa saída destrutiva passa por `rc` e por `[ -s ]`.
set -uo pipefail

MEMBER="${1:-}"; shift || true
DRY=0; MEMBERS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --members) MEMBERS="${2:?--members exige path}"; shift 2 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${MEMBER}" ] || { echo "uso: door-seal-pin.sh <member-id> [--dry-run] [--members <path>]" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "${HERE}/.." && pwd)"
: "${MEMBERS:=${CORE}/docs/evolution/federation/members.yaml}"
[ -f "${MEMBERS}" ] || { echo "ERRO: registro ausente: ${MEMBERS}" >&2; exit 2; }

# Leitor de campo do membro — mesmo shape do `member_field` do co-deliver.sh (um dado, um acessor).
_field() {
  awk -v want="${MEMBER}" -v field="$1" '
    function clean(s) { sub(/^[^:]*:[[:space:]]*/,"",s); sub(/[[:space:]]*#.*$/,"",s)
                        gsub(/[[:space:]]+$/,"",s); gsub(/"/,"",s); gsub(/\047/,"",s); return s }
    /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { cur=(clean($0)==want); next }
    cur { l=$0; gsub(/^[[:space:]]+/,"",l); if (l ~ ("^" field ":")) { print clean(l); exit } }
  ' "${MEMBERS}"
}

KIND="$(_field kind)"; LOCAL="$(_field local_path)"; REMOTE="$(_field remote)"; REGPIN="$(_field onion_version)"
[ -n "${KIND}${LOCAL}${REMOTE}${REGPIN}" ] || { echo "ERRO: '${MEMBER}' não existe em ${MEMBERS} (ou não tem nenhum campo legível)." >&2; exit 2; }
# `kind: door` é o objeto desta guarda. Um adotante comum não é espelho do core, e carimbar o pin
# dele daqui seria afirmar sobre um repo que ninguém materializa.
[ "${KIND}" = "door" ] || { echo "ERRO: '${MEMBER}' tem kind='${KIND:-vazio}', não 'door' — este carimbo é só para PORTA (espelho materializado do core)." >&2; exit 2; }
[ -d "${LOCAL}/.git" ] || { echo "ERRO: clone da porta ausente em '${LOCAL}' — sem ele não sei o que foi publicado." >&2; exit 2; }

# ── (1) O pin que a porta declara — LIDO DO QUE ESTÁ COMMITADO, nunca da árvore ─────────────
# ⚠️ DEFEITO ACHADO PELO PRÓPRIO DOGFOOD, na 1ª vez que rodei isto de verdade (2026-09-26): a v1 lia
# o stamp da ÁRVORE DE TRABALHO. Logo, rodado depois de materializar e ANTES de commitar/empurrar, ele
# lia o pin NOVO (que só existe no disco) e comparava `HEAD` do clone com o remoto — e `HEAD` ainda era
# o commit antigo, igual ao remoto. As duas conferências passavam e ele carimbava como PUBLICADO um pin
# que não estava em lugar nenhum além do disco. Exatamente o que este script existe para impedir.
# A causa é de LEITURA, não de lógica: o pin tem de vir do MESMO objeto git que o remoto pode conter.
# Duas guardas, porque uma sozinha não fecha:
#   (i) a árvore da porta tem de estar LIMPA — materialização não-commitada não é publicação;
#   (ii) o pin vem de `git show HEAD:`, então um stamp editado à mão no disco não engana.
# E a bancada tinha um caso "clone ≠ remoto"... que esboçava um remoto DIFERENTE, cenário que não é o
# do fluxo real. Caso que testa um mundo que não acontece não é cobertura ([[mutant-anchor-is-a-defect-candidate]]).
_DIRTY="$(git -C "${LOCAL}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
[ "${_DIRTY}" = "0" ] || { echo "ERRO: a árvore da porta tem ${_DIRTY} arquivo(s) não-commitado(s) — materialização no disco NÃO é publicação. Commite e empurre primeiro; carimbar agora afirmaria público o que ninguém pode ver." >&2; exit 1; }
STAMP_TREE="${LOCAL}/.claude/.onion-version"
[ -f "${STAMP_TREE}" ] || { echo "ERRO: stamp ausente em ${STAMP_TREE} — a porta não declara pin." >&2; exit 2; }
DOORPIN="$(git -C "${LOCAL}" show HEAD:.claude/.onion-version 2>/dev/null | grep -m1 '^onion_version:' | sed 's/^onion_version:[[:space:]]*//; s/[[:space:]]*#.*$//')"
[ -n "${DOORPIN}" ] || { echo "ERRO: não li \`onion_version\` do stamp COMMITADO da porta (HEAD:.claude/.onion-version) — e eu não leio da árvore, porque árvore não é o que o remoto contém." >&2; exit 2; }
printf '%s' "${DOORPIN}" | grep -qE '^[0-9a-f]{7,40}$' \
  || { echo "ERRO: pin ilegível no stamp da porta: '${DOORPIN}' — não carimbo o que não consigo ler." >&2; exit 2; }

# ── (2) O pin é commit REAL no core, e está na INTEGRAÇÃO mergeada ──────────────────────────
# As duas perguntas são distintas e as duas importam: a 1ª pega pin forjado/errado de digitação; a
# 2ª pega porta materializada de branch — o defeito de 2026-09-25, cuja cura vive no materializador.
# Aqui é a segunda barreira, independente dela.
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

# ── (3) O PUSH ACONTECEU? — provado pelo REMOTO, nunca pelo clone ───────────────────────────
# O clone local pode ter commit não empurrado; carimbar por ele afirmaria público o que é privado.
OWNER_REPO="$(printf '%s' "${REMOTE}" | sed -E 's#^https?://##; s#^github\.com/##; s#\.git$##')"
printf '%s' "${OWNER_REPO}" | grep -qE '^[^/]+/[^/]+$' \
  || { echo "ERRO: não derivei owner/repo de remote='${REMOTE}'." >&2; exit 2; }
DOORBRANCH="$(git -C "${LOCAL}" branch --show-current)"
[ -n "${DOORBRANCH}" ] || { echo "ERRO: a porta está em HEAD destacado — não sei que branch conferir." >&2; exit 2; }
REMOTE_SHA="$(gh api "repos/${OWNER_REPO}/commits/${DOORBRANCH}" --jq '.sha' 2>/dev/null || true)"
[ -n "${REMOTE_SHA}" ] || { echo "ERRO: não consegui ler o remoto (gh api repos/${OWNER_REPO}/commits/${DOORBRANCH}). Sem o remoto eu NÃO afirmo que a porta está publicada — o clone local não prova push." >&2; exit 2; }
LOCAL_SHA="$(git -C "${LOCAL}" rev-parse HEAD)"
[ "${REMOTE_SHA}" = "${LOCAL_SHA}" ] \
  || { echo "ERRO: o clone da porta (${LOCAL_SHA:0:12}) NÃO bate com o remoto (${REMOTE_SHA:0:12}) — há commit não empurrado, ou o remoto andou. Empurre primeiro; carimbar agora afirmaria público o que não é." >&2; exit 1; }

echo "══ door-seal-pin — ${MEMBER}"
echo "  pin declarado pela porta : ${DOORPIN}"
echo "  na integração            : ✓ ancestral de origin/${_INTEG}"
echo "  publicado                : ✓ remoto ${REMOTE_SHA:0:12} == clone ${LOCAL_SHA:0:12}"
echo "  pin no registro          : ${REGPIN:-<vazio>}"

if [ "${REGPIN}" = "${DOORPIN}" ]; then
  echo "✅ registro já em dia — nada a carimbar."; exit 0
fi
if [ "${DRY}" -eq 1 ]; then
  echo "▶️  --dry-run: eu carimbaria ${REGPIN:-<vazio>} → ${DOORPIN} em ${MEMBERS}"; exit 0
fi

# ── (4) CARIMBO CIRÚRGICO — só a linha do membro, e só depois de tudo acima ─────────────────
# `awk` sobre o bloco do membro, preservando comentário e indentação de todo o resto do arquivo.
TMP="$(mktemp)"; trap 'rm -f "${TMP}"' EXIT
awk -v want="${MEMBER}" -v pin="${DOORPIN}" '
  function clean(s) { sub(/^[^:]*:[[:space:]]*/,"",s); gsub(/[[:space:]]+$/,"",s); gsub(/"/,"",s); gsub(/\047/,"",s); return s }
  /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { cur=(clean($0)==want) }
  cur && done!=1 && /^[[:space:]]*onion_version:[[:space:]]*/ {
    match($0, /^[[:space:]]*/); ind=substr($0, 1, RLENGTH)
    print ind "onion_version: " pin "   # carimbado por ops/door-seal-pin.sh (remoto conferido)"
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
echo "   ▶️ commite o registro; a REGRA 85 volta a medir a porta em vez da memória."
