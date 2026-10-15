#!/usr/bin/env bash
# =============================================================================
# co-relay.sh — Carteiro-LOCAL do doc-bridge de co-evolução (UPSTREAM)
#
# Propósito : Espelho upstream do co-deliver.sh. Entregar um SINAL do adotante
#             (markdown datado em docs/evolution/inbox/) no canal inbox/ do CORE
#             que vive na MESMA máquina, para que o hook "you have mail" o sinale
#             📬 na próxima sessão do core — sem o maestro copiar à mão e sem a
#             sessão do adotante commitar cross-repo (o incidente que originou
#             este sub-protocolo: sinal S2 2026-06-25).
#
# -----------------------------------------------------------------------------
# RECADO PARA A PRÓXIMA INSTÂNCIA (leia antes de mexer) — literate breadcrumb
# -----------------------------------------------------------------------------
# Modelo dos 3 ATOS (ADR onion-adr-comms-transport-vs-execution + sub-protocolo
# do regime manual, onion-adr-manual-relay-subprotocol):
#   Ato 1  TRANSPORTAR  (copiar arquivo)   -> determinístico  -> ESTE script
#   Ato 2  NOTIFICAR    (contar arquivos)  -> determinístico  -> hook SessionStart
#   Ato 3  LER/INTERPRETAR/COMMITAR        -> exige juízo     -> sessão HOME do core
#
# Invariante: ENTREGA-SEM-COMMIT. Escreve o sinal como UNTRACKED no inbox/ do CORE
#             (o hook conta arquivos do dir, não precisa de commit) — assim respeita
#             "um escritor por repo" (I3): a sessão do adotante NUNCA commita no repo
#             alheio. O COMMIT + triagem (git mv p/ inbox/_processed/) é da SESSÃO
#             DO CORE, com contexto. Untracked persiste entre checkouts → entrega
#             branch-agnóstica: como NÃO commita, NÃO existe "commit na branch errada".
#
# Guarda de papel: lê o STAMP .claude/.onion-version (campo role:). Só ADOTANTE
#             (role: adopted) relaya upstream. NUNCA usar onion-version.sh para isto:
#             aquele script HARDCODA role:source (é a identidade da FONTE) e, sendo
#             cópia byte-idêntica no adotante, mentiria 'source' → falso-amigo.
#
# PAPÉIS:     maestro = humano (autoridade final, Ato-3) · maestro principal = core
#             (onion-evolve, rege a evolução). A sessão home do destino commita.
#
# Uso       : co-relay.sh [<signal-file>] --target <path-do-core> [--from <dir>] [--dry-run]
#               <signal-file> : basename OU path. Omitido = todos os .md de 1º nível
#                               da fonte (default docs/evolution/inbox/).
#               --target <p>  : path LOCAL do CORE (OBRIGATÓRIO — o adotante não tem
#                               members.yaml para resolver o alvo).
#               --from <dir>  : fonte alternativa do(s) sinal(is) (default: o inbox).
#               --dry-run     : mostra o plano, não escreve nada.
#
# Gracioso  : uso inválido / não-adotante / alvo ausente ou não-git → exit 2 (erro
#             de uso, pt-BR em STDERR). Sinal já presente no inbox/ do core → no-op
#             idempotente (exit 0). DEDUP POR CONTEÚDO: byte-idêntico a arquivo no
#             inbox/ OU no inbox/_processed/ do core → no-op "já entregue/processado"
#             (cura a re-entrega pós-triagem, incidente 2026-07-03); mesmo nome com
#             conteúdo DIFERENTE segue entregando (sinal atualizado, não duplicata).
#             Sem `set -e` p/ controlar os exits graciosos.
#             Determinístico, sem LLM. Espelha .claude/utils/co-evolution/co-deliver.sh.
#
# Consumido por /meta:co-relay. Par simétrico downstream: /meta:co-deliver.
# =============================================================================
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STAMP="${REPO_ROOT}/.claude/.onion-version"

usage() { echo "uso: co-relay.sh [<signal-file>] --target <path-do-core> [--from <dir>] [--dry-run]" >&2; exit 2; }

SIGNAL_ARG="" ; TARGET="" ; FROM_DIR="" ; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 || usage ;;
    --from)   FROM_DIR="${2:-}"; shift 2 || usage ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage ;;
    -*) echo "ERRO: flag desconhecida: $1" >&2; usage ;;
    *) if [ -z "${SIGNAL_ARG}" ]; then SIGNAL_ARG="$1"; else echo "ERRO: argumento extra: $1" >&2; usage; fi; shift ;;
  esac
done

# --- Guarda de papel: SÓ ADOTANTE (lê o STAMP, nunca onion-version.sh) ---
role_field() {  # extrai 'role:' do stamp (tira comentário inline, aspas, espaços)
  grep -E '^[[:space:]]*role:' "$1" 2>/dev/null | head -1 \
    | sed -E 's/^[[:space:]]*role:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/"//g; s/'\''//g'
}
if [ ! -f "${STAMP}" ]; then
  echo "ERRO: ${STAMP} ausente — co-relay roda no ALVO (role: adopted, hub ou standalone)." >&2
  echo "      Sem stamp = core/fonte ou pré-adoção; o core não relaya upstream (use /meta:co-announce)." >&2
  exit 2
fi
ROLE="$(role_field "${STAMP}")"
# ⚠️ `hub` ENTRA, e a omissão custou um sinal entregue à mão (2026-09-17). A condição antiga era
# `!= "adopted"`, enquanto a mensagem de stamp-ausente logo acima já prometia "adopted ou hub" e o
# espelho downstream `co-deliver.sh` valida `role:(adopted|hub)` e só entrega a hub/standalone
# (T1/T3, RFC-0003 §2.1). Ou seja: o core ENTREGAVA anúncios à porta por desenho declarado, e a
# porta não podia responder — o doc-bridge mecanizado num sentido só, justamente na superfície
# PÚBLICA, que é a que mais gera sinal de primeira impressão. A assimetria era desta linha.
case "${ROLE}" in
  adopted|hub|standalone) : ;;
  *)
    echo "ERRO: role='${ROLE:-vazio}' no stamp — co-relay é só para ALVO (role: adopted, hub ou standalone)." >&2
    echo "      O core (role: source) anuncia downstream via /meta:co-announce, não relaya upstream." >&2
    exit 2 ;;
esac

# --- Resolve alvo (o CORE): --target é sempre obrigatório (sem members.yaml no adotante) ---
[ -n "${TARGET}" ] || { echo "ERRO: --target <path-do-core> é obrigatório (o adotante não tem members.yaml)." >&2; usage; }
[ -d "${TARGET}" ] || { echo "ERRO: --target não é diretório: ${TARGET}" >&2; exit 2; }
[ -e "${TARGET}/.git" ] || { echo "ERRO: --target não parece um repo git: ${TARGET}" >&2; exit 2; }
TARGET="$(cd "${TARGET}" && pwd)"   # normaliza para path absoluto

# --- Guarda do DESTINO (F3 do configurador A2A, 2026-10-15): upstream é o core OU o hub do adotante ------
# A rede do hub nasce junto com a do core: o filho de um hub (T2, carimbo `adopted`) manda sinal ao PRÓPRIO
# hub, que vive na mesma máquina. Até aqui o destino só precisava ser um repo git, e o carteiro relayava
# para qualquer checkout, inclusive o de outro adotante: um canal lateral que a topologia proíbe
# (standalone não tem canal lateral; consumer só fala com o seu hub). O destino agora se prova:
#   · sem carimbo .claude/.onion-version = o core (a fonte não tem carimbo; o onion-version.sh o hardcoda);
#   · carimbo role: hub = um hub, e só o carimbo `adopted` (quem pode ser filho de hub) relaya para ele;
#   · qualquer outro carimbo (adopted, standalone, porta) = par lateral → recusa.
# QUAL hub é o pai: o carimbo `adopted` não distingue o filho de um hub do standalone do core (os dois
# carimbam `adopted`; achado do refutador da F3, medido em adotantes reais desta máquina). Sem o registro, a
# prova que o carteiro tem é o `adopted_from` do carimbo do remetente: tem de ser o remote `origin` do hub ou
# o caminho dele. Quem adotou o core (adopted_from = o core) não relaya para hub nenhum.
T_STAMP="${TARGET}/.claude/.onion-version"
if [ -f "${T_STAMP}" ]; then
  T_ROLE="$(role_field "${T_STAMP}")"
  if [ "${T_ROLE}" != "hub" ]; then
    echo "ERRO: o destino '${TARGET}' tem carimbo role='${T_ROLE:-vazio}' — não é o core nem um hub. Upstream é o core ou o seu hub; relayar para outro adotante é canal lateral." >&2
    exit 2
  fi
  if [ "${ROLE}" != "adopted" ]; then
    echo "ERRO: o destino é um hub, e este repo tem carimbo role='${ROLE}'. Só o filho de um hub (carimbo adopted) relaya para o hub; ${ROLE} fala com o core." >&2
    exit 2
  fi
  _norm_remote() {  # https://h/o/r(.git) · git@h:o/r(.git) · ssh://git@h/o/r → h/o/r
    printf '%s' "$1" | sed -E 's#^[a-zA-Z+]+://##; s#^[^@/]+@##; s#:#/#; s#\.git/?$##; s#/+$##'
  }
  SRC_FROM="$(grep -E '^[[:space:]]*adopted_from:' "${STAMP}" 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*adopted_from:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/"//g; s/'\''//g')"
  HUB_REMOTE="$(git -C "${TARGET}" remote get-url origin 2>/dev/null || true)"
  if [ -z "${SRC_FROM}" ] || { [ "${SRC_FROM%/}" != "${TARGET}" ] && { [ -z "${HUB_REMOTE}" ] || [ "$(_norm_remote "${SRC_FROM}")" != "$(_norm_remote "${HUB_REMOTE}")" ]; }; }; then
    echo "ERRO: o destino é um hub, mas este repo não o adota: adopted_from='${SRC_FROM:-ausente}' não é o remote nem o caminho do hub (${HUB_REMOTE:-sem origin}). Quem adota o core relaya para o core; relayar para um hub que não é o seu é canal lateral." >&2
    exit 2
  fi
  T_LABEL="HUB"
else
  T_LABEL="CORE"
fi

# --- Resolve a fonte do(s) sinal(is) ---
[ -n "${FROM_DIR}" ] || FROM_DIR="${REPO_ROOT}/docs/evolution/inbox"

FILES=()
if [ -n "${SIGNAL_ARG}" ]; then
  if [ -f "${SIGNAL_ARG}" ]; then FILES+=("${SIGNAL_ARG}")
  elif [ -f "${FROM_DIR}/${SIGNAL_ARG}" ]; then FILES+=("${FROM_DIR}/${SIGNAL_ARG}")
  else echo "ERRO: signal-file não encontrado: '${SIGNAL_ARG}' (nem em ${FROM_DIR}/)." >&2; exit 2; fi
else
  [ -d "${FROM_DIR}" ] || { echo "ERRO: fonte de sinais não existe: ${FROM_DIR}" >&2; exit 2; }
  while IFS= read -r f; do FILES+=("$f"); done < <(find "${FROM_DIR}" -maxdepth 1 -type f -name '*.md' ! -iname 'readme.md' 2>/dev/null | sort)
  [ "${#FILES[@]}" -gt 0 ] || { echo "ERRO: ${FROM_DIR}/ não tem sinais a relayar (1º nível)." >&2; exit 2; }
fi

DEST_DIR="${TARGET}/docs/evolution/inbox"

# --- Aviso honesto: o core pode não ter o canal nesta árvore (branch atual) ---
if [ ! -d "${TARGET}/docs/evolution" ]; then
  echo "AVISO: ${TARGET} não tem docs/evolution/ nesta árvore (branch atual)." >&2
  echo "       A entrega cria inbox/ como untracked; o 📬 dispara se o core tiver" >&2
  echo "       o hook co-evolution-inbox-check.sh provisionado." >&2
fi

if [ "${DRY}" -eq 1 ]; then
  echo "── DRY-RUN — Carteiro-local upstream (nada escrito) ──"
  echo "  fonte    : ${FROM_DIR}/"
  echo "  alvo     : ${TARGET}  (${T_LABEL})"
  echo "  destino  : ${DEST_DIR}/"
  for f in "${FILES[@]}"; do echo "  relayar  : $(basename "$f")"; done
  exit 0
fi

mkdir -p "${DEST_DIR}" 2>/dev/null || { echo "ERRO: não foi possível criar ${DEST_DIR} (permissão?)." >&2; exit 2; }

relayed=0 ; skipped=0
for f in "${FILES[@]}"; do
  base="$(basename "$f")"
  # COLISÃO DE NOME decide por CONTEÚDO, não pela existência (sinal de um adotante, 2026-10-07):
  # esta checagem saía "já relayado" ANTES do dedup abaixo, e a versão atualizada de um sinal nunca
  # chegava (medido: `cmp` diferiu no byte 2871 e o carteiro calou) — o contrário do que o cabeçalho
  # promete. Idêntico → no-op. Diferente e o destino UNTRACKED (o core ainda não triou) → entrega por
  # cima: é a mesma entrega-sem-commit, atualizada. Diferente e o destino TRACKED → o core já commitou
  # aquela versão; sobrescrever mexeria na árvore dele (I3), então recusa e diz como seguir.
  if [ -e "${DEST_DIR}/${base}" ]; then
    if cmp -s "$f" "${DEST_DIR}/${base}"; then
      echo "Onion: já relayado, conteúdo idêntico (no-op): ${base}" >&2
      skipped=$((skipped + 1))
      continue
    fi
    if git -C "${TARGET}" ls-files --error-unmatch "docs/evolution/inbox/${base}" >/dev/null 2>&1; then
      echo "AVISO: ${base} mudou, mas o core JÁ COMMITOU a versão anterior — não sobrescrevo a árvore dele. Entregue a atualização com nome novo (ex.: ${base%.md}-v2.md)." >&2
      skipped=$((skipped + 1))
      continue
    fi
    if cp "$f" "${DEST_DIR}/${base}" 2>/dev/null; then
      echo "Onion: 📬 ATUALIZADO (o destino era a entrega anterior, ainda não triada) → ${TARGET}/docs/evolution/inbox/${base}" >&2
      relayed=$((relayed + 1))
    else
      echo "AVISO: falha ao atualizar ${base} em ${DEST_DIR} (permissão?)." >&2
    fi
    continue
  fi
  # Dedup por CONTEÚDO vs inbox/ E _processed/ do core — cura da corrida do assíncrono
  # (incidente 2026-07-03: 3 sinais re-entregues pelo carteiro depois de o core já tê-los
  # triado por outro caminho → 📬 fantasma a cada boot). Byte-idêntico = já entregue/
  # processado → no-op. Mesmo NOME com conteúdo DIFERENTE segue entregando: é sinal
  # ATUALIZADO (nova rodada), não duplicata.
  dup=""
  for existing in "${DEST_DIR}"/*.md "${DEST_DIR}/_processed"/*.md; do
    [ -f "${existing}" ] || continue
    if cmp -s "$f" "${existing}"; then dup="${existing}"; break; fi
  done
  if [ -n "${dup}" ]; then
    echo "Onion: já entregue/processado no core (conteúdo idêntico a $(basename "${dup}")) — no-op: ${base}" >&2
    skipped=$((skipped + 1))
    continue
  fi
  if cp "$f" "${DEST_DIR}/${base}" 2>/dev/null; then
    echo "Onion: 📬 relayado → ${TARGET}/docs/evolution/inbox/${base}" >&2
    relayed=$((relayed + 1))
  else
    echo "AVISO: falha ao copiar ${base} para ${DEST_DIR} (permissão?)." >&2
  fi
done

echo "Onion: Carteiro-local upstream concluído — ${relayed} relayado(s), ${skipped} no-op." >&2
echo "       Próximo (sessão DO CORE): ler 📬, commitar + triar (git mv p/ inbox/_processed/)." >&2
echo "       (entrega-sem-commit: o adotante NÃO commitou no repo alheio — invariante I3)." >&2
exit 0
