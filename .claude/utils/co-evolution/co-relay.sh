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
  echo "  alvo     : ${TARGET}  (CORE)"
  echo "  destino  : ${DEST_DIR}/"
  for f in "${FILES[@]}"; do echo "  relayar  : $(basename "$f")"; done
  exit 0
fi

mkdir -p "${DEST_DIR}" 2>/dev/null || { echo "ERRO: não foi possível criar ${DEST_DIR} (permissão?)." >&2; exit 2; }

relayed=0 ; skipped=0
for f in "${FILES[@]}"; do
  base="$(basename "$f")"
  if [ -e "${DEST_DIR}/${base}" ]; then
    echo "Onion: já relayado (no-op): ${base}" >&2
    skipped=$((skipped + 1))
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
