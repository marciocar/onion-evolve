#!/usr/bin/env bash
# =============================================================================
# co-deliver.sh — Carteiro-LOCAL do doc-bridge de co-evolução (downstream)
#
# Propósito : Entregar um anúncio downstream (rascunho em federation/outbox/<id>/)
#             no canal inbound/ de um adotante que vive na MESMA máquina, para
#             que o hook "you have mail" (co-evolution-inbox-check.sh) o sinale
#             📥 na próxima sessão do adotante — sem o maestro copiar à mão.
#             É o "Carteiro-local mínimo" liberado (NÃO-gated) pelo ADR
#             onion-adr-ledger-format-location-2026-06.md (Decisão 3).
#
# Invariante: ENTREGA-SEM-COMMIT. Escreve o arquivo como UNTRACKED no inbound/
#             do alvo (o hook conta arquivos do dir, não precisa de commit) —
#             assim respeita "um escritor por repo" (I3): a sessão do core
#             NUNCA commita no repo alheio. O commit + processamento (mover blip,
#             git mv p/ _processed/) é da SESSÃO do adotante, com contexto.
#             Untracked persiste entre checkouts de branch → entrega é
#             branch-agnóstica (o canal tracked do adotante costuma viver em
#             develop, mas o aviso dispara em qualquer branch do mesmo worktree).
#
# Uso       : co-deliver.sh <member-id> [<outbox-file>] --target <path> [--dry-run]
#               <member-id>    : id em docs/evolution/federation/members.yaml
#                                (precisa ser role: hub ou standalone — T1/T3,
#                                adotam o core diretamente; RFC-0003 §2.1. role:
#                                consumer é T2, via-hub — fora do escopo deste
#                                carteiro-local core→direto)
#               <outbox-file>  : basename OU path do rascunho. Omitido = entrega
#                                TODOS os .md de 1º nível do outbox/<id>/.
#               --target <p>   : path LOCAL do repo adotante (obrigatório se o
#                                members.yaml não trouxer um path resolvível).
#               --dry-run      : mostra o plano, não escreve nada.
#
# Gracioso  : uso inválido / member inexistente / role não-hub/standalone / outbox ou alvo
#             ausente → exit 2 (erro de uso, pt-BR em STDERR). Arquivo já presente
#             no inbound/ → no-op idempotente (exit 0). Sem `set -e` p/ controlar
#             os exits graciosos. Determinístico, sem LLM.
#
# Consumido por /meta:co-deliver. Par producer: /meta:co-announce (gera o outbox).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMBERS="${REPO_ROOT}/docs/evolution/federation/members.yaml"
OUTBOX_BASE="${REPO_ROOT}/docs/evolution/federation/outbox"

usage() { echo "uso: co-deliver.sh <member-id> [<outbox-file>] --target <path> [--dry-run]" >&2; exit 2; }

MEMBER="" ; OUTBOX_ARG="" ; TARGET="" ; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 || usage ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage ;;
    -*) echo "ERRO: flag desconhecida: $1" >&2; usage ;;
    *) if [ -z "${MEMBER}" ]; then MEMBER="$1"; elif [ -z "${OUTBOX_ARG}" ]; then OUTBOX_ARG="$1"; else echo "ERRO: argumento extra: $1" >&2; usage; fi; shift ;;
  esac
done

[ -n "${MEMBER}" ] || usage
[ -f "${MEMBERS}" ] || { echo "ERRO: members.yaml não encontrado: ${MEMBERS}" >&2; exit 2; }

# --- Extrai um campo (role/name/path) do bloco do <member-id> no members.yaml ---
member_field() {  # $1 = id desejado ; $2 = nome do campo
  awk -v want="$1" -v field="$2" '
    function clean(s) {  # remove valor: tira comentário inline YAML, aspas e espaços
      sub(/^[^:]*:[[:space:]]*/,"",s); sub(/[[:space:]]*#.*$/,"",s)
      gsub(/[[:space:]]+$/,"",s); gsub(/"/,"",s); gsub(/\047/,"",s); return s
    }
    /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ {
      v=clean($0); cur=(v==want); next
    }
    cur {
      line=$0; gsub(/^[[:space:]]+/,"",line)
      if (line ~ ("^" field ":")) { print clean(line); exit }
    }
  ' "${MEMBERS}"
}

ROLE="$(member_field "${MEMBER}" role)"
NAME="$(member_field "${MEMBER}" name)"
[ -n "${ROLE}" ] || { echo "ERRO: member-id '${MEMBER}' não existe em members.yaml." >&2; exit 2; }
[ "${ROLE}" = "hub" ] || [ "${ROLE}" = "standalone" ] || { echo "ERRO: '${MEMBER}' tem role='${ROLE}' — carteiro-local só entrega a hub/standalone (T1/T3, adotam o core direto; RFC-0003 §2.1). role=consumer é T2 (via-hub), fora deste escopo." >&2; exit 2; }

# --- Resolve o path local do alvo: --target > members.yaml local_path: (path: fallback) ---
# Sinal 2026-07-10-co-deliver-local-path-gap: o campo real do members.yaml é 'local_path:'; o
# helper buscava só 'path:' e forçava --target mesmo com o registro válido.
if [ -z "${TARGET}" ]; then
  CFG_PATH="$(member_field "${MEMBER}" local_path)"
  [ -n "${CFG_PATH}" ] || CFG_PATH="$(member_field "${MEMBER}" path)"
  if [ -n "${CFG_PATH}" ] && [ "${CFG_PATH}" != "." ]; then
    # path relativo do members.yaml resolve contra a RAIZ DO REPO, não o CWD da invocação
    case "${CFG_PATH}" in /*) ;; *) CFG_PATH="${REPO_ROOT}/${CFG_PATH}" ;; esac
    [ -d "${CFG_PATH}" ] && TARGET="${CFG_PATH}"
  fi
  if [ -z "${TARGET}" ]; then
    echo "ERRO: path local do adotante '${MEMBER}' não resolvido. Informe --target <path>" >&2
    echo "      (members.yaml não traz 'local_path:'/'path:' utilizável para este membro)." >&2
    exit 2
  fi
fi
[ -d "${TARGET}" ] || { echo "ERRO: --target não é diretório: ${TARGET}" >&2; exit 2; }
# ⚠️ "É DIRETÓRIO?" NÃO É A PERGUNTA — a pergunta é "É ADOTANTE?". Com o teste anterior, QUALQUER
# diretório gravável da máquina era destino válido, e o critério de sucesso do carteiro virava "o
# `cp` retornou 0". Custo MEDIDO por um adotante (2026-08-31): ele mantinha dois clones do mesmo
# remote e só um era adotante; a entrega caiu no outro — um checkout sem `.claude/`, sem
# `.onion-version`, cujo `.gitignore` ignora `.claude/` inteiro. O arquivo virou árvore órfã e
# untracked num repo que NUNCA poderia sinalizá-lo. Do lado do core a entrega parecia concluída;
# do lado do adotante a mensagem não existia. NENHUM DOS DOIS LADOS TINHA COMO PERCEBER SOZINHO, e
# um aviso de SEGURANÇA ficou 26 dias sem tratamento por causa disso.
# A cura é a proposta do próprio adotante: o destino se resolve por EVIDÊNCIA DE ADOÇÃO.
if [ ! -f "${TARGET}/.claude/.onion-version" ]; then
  echo "ERRO: '${TARGET}' não tem .claude/.onion-version — não é um adotante." >&2
  echo "  O carteiro entrega em quem PROVA ser adotante, não em qualquer diretório gravável." >&2
  echo "  Entregar aqui criaria um arquivo órfão num repo que não tem hook para sinalizá-lo," >&2
  echo "  e o core marcaria a entrega como concluída — falha silenciosa nos dois lados." >&2
  echo "  Se o alvo certo é outro checkout, resolva pelo 'local_path' do members.yaml." >&2
  exit 2
fi
if ! grep -qE '^[[:space:]]*role:[[:space:]]*(adopted|hub|standalone)[[:space:]]*(#.*)?$' "${TARGET}/.claude/.onion-version"; then
  echo "ERRO: '${TARGET}' tem stamp, mas o 'role:' não é adopted nem hub." >&2
  echo "  Downstream vai para CONSUMIDOR. Entregar noutro papel põe o anúncio onde ninguém o lê." >&2
  exit 2
fi
[ -e "${TARGET}/.git" ] || { echo "ERRO: --target não parece um repo git: ${TARGET}" >&2; exit 2; }

# --- Monta a lista de arquivos de outbox a entregar ---
SRC_DIR="${OUTBOX_BASE}/${MEMBER}"
FILES=()
if [ -n "${OUTBOX_ARG}" ]; then
  if [ -f "${OUTBOX_ARG}" ]; then FILES+=("${OUTBOX_ARG}")
  elif [ -f "${SRC_DIR}/${OUTBOX_ARG}" ]; then FILES+=("${SRC_DIR}/${OUTBOX_ARG}")
  else echo "ERRO: outbox-file não encontrado: '${OUTBOX_ARG}' (nem em ${SRC_DIR}/)." >&2; exit 2; fi
else
  [ -d "${SRC_DIR}" ] || { echo "ERRO: não há outbox para '${MEMBER}': ${SRC_DIR}" >&2; exit 2; }
  while IFS= read -r f; do FILES+=("$f"); done < <(find "${SRC_DIR}" -maxdepth 1 -type f -name '*.md' ! -iname 'readme.md' 2>/dev/null | sort)
  [ "${#FILES[@]}" -gt 0 ] || { echo "ERRO: outbox/${MEMBER}/ não tem rascunhos a entregar (1º nível)." >&2; exit 2; }
fi

DEST_DIR="${TARGET}/docs/evolution/inbound"

# --- Aviso honesto: alvo pode não ter o canal/hook provisionado nesta árvore ---
if [ ! -d "${TARGET}/docs/evolution" ]; then
  echo "AVISO: ${TARGET} não tem docs/evolution/ nesta árvore (branch atual)." >&2
  echo "       A entrega cria inbound/ como untracked; o 📥 dispara se o adotante" >&2
  echo "       tiver o hook co-evolution-inbox-check.sh provisionado (via /meta:adopt)." >&2
fi

if [ "${DRY}" -eq 1 ]; then
  echo "── DRY-RUN — Carteiro-local (nada escrito) ──"
  echo "  alvo     : ${NAME:-$MEMBER}  (${TARGET})"
  echo "  destino  : ${DEST_DIR}/"
  for f in "${FILES[@]}"; do echo "  entregar : $(basename "$f")"; done
  exit 0
fi

mkdir -p "${DEST_DIR}" 2>/dev/null || { echo "ERRO: não foi possível criar ${DEST_DIR} (permissão?)." >&2; exit 2; }

delivered=0 ; skipped=0
for f in "${FILES[@]}"; do
  base="$(basename "$f")"
  if [ -e "${DEST_DIR}/${base}" ]; then
    echo "Onion: já entregue (no-op): ${base}" >&2
    skipped=$((skipped + 1))
    continue
  fi
  if cp "$f" "${DEST_DIR}/${base}" 2>/dev/null; then
    echo "Onion: 📥 entregue → ${TARGET}/docs/evolution/inbound/${base}" >&2
    delivered=$((delivered + 1))
  else
    echo "AVISO: falha ao copiar ${base} para ${DEST_DIR} (permissão?)." >&2
  fi
done

echo "Onion: Carteiro-local concluído — ${delivered} entregue(s), ${skipped} no-op." >&2
echo "       Próximo (sessão DO ADOTANTE): ler 📥, commitar + processar (git mv p/ inbound/_processed/)." >&2
echo "       (entrega-sem-commit: o core NÃO commitou no repo alheio — invariante I3)." >&2
exit 0
