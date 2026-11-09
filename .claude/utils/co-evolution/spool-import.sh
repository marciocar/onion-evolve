#!/usr/bin/env bash
# =============================================================================
# spool-import.sh — importa para o inbox/ deste repo os sinais que o carteiro deixou no SPOOL
#
# Propósito : Metade de chegada da entrega por spool do co-relay.sh. Quando o remetente roda com o
#             sandbox do Claude Code ligado, a escrita no inbox/ do destino pode dar "Read-only file
#             system" mesmo com o caminho no sandbox.filesystem.allowWrite: uma regra de permissão
#             `Edit(//<destino>/**)` no deny do remetente vira um denyWrite do sandbox, montado em
#             leitura DEPOIS da exceção do inbox, que fica por baixo (medido em 2026-11-07, Claude Code
#             2.1.319, bwrap 0.9.0; ver o SPOOL no cabeçalho do co-relay.sh). Aí o carteiro escreve num
#             diretório FORA dos repos, um por destinatário, e esta peça, rodando NA SESSÃO DO DESTINO
#             (hook SessionStart, hook UserPromptSubmit e /meta:co-evolve), traz o sinal para o inbox/ dela.
#
# Spool     : ${ONION_SPOOL_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/onion-spool}/<slug>/
#             <slug> = o caminho físico (pwd -P) da raiz do destino, com todo caractere fora de
#             [A-Za-z0-9] trocado por '-' (a mesma convenção do ~/.claude/projects). O remetente não
#             tem members.yaml; o caminho é o nome que os dois lados derivam sem combinar nada.
#
# Regras    : só *.md de 1º nível (o carteiro escreve `.<nome>.tmp.*` e renomeia: arquivo pela
#             metade nunca é lido). Link simbólico nunca é lido: o cp copiaria o alvo dele para o inbox/.
#             Para cada sinal, depois de renomeado para um nome de posse com ponto no próprio spool (a
#             versão nova que o carteiro entregar nesse meio-tempo fica no nome original, e a próxima
#             passada a traz; posse de processo morto volta ao nome original):
#               · sem homônimo no inbox/        → move (cp + rm) para o inbox/, UNTRACKED (I3 intacto:
#                                                 ninguém commita; a triagem é da sessão do destino);
#               · homônimo byte-idêntico        → já chegou: apaga a cópia do spool;
#               · homônimo diferente, untracked → atualização ainda não triada: substitui (o mesmo que o
#                                                 carteiro faz na entrega direta);
#               · homônimo diferente, TRACKED   → o destino já commitou a versão anterior: FICA no spool
#                                                 e conta como pendente (nunca mexe na árvore commitada).
#             A guarda de destino, a de destino público, a marca reviewed_for_public e o dedup contra
#             _processed/ já rodaram no remetente, que LÊ o destino (a leitura o sandbox não barra).
#
# Saída     : stdout = uma linha "imported=<n> pending=<n>" (para o hook); avisos em stderr.
#             Sempre exit 0 quando chamado com --hook (a sessão nunca deixa de abrir por causa disto);
#             sem --hook, exit 1 se algum sinal não pôde ser importado por erro de escrita.
#             `pending` soma o retido por homônimo, por link, por erro e, com --hook, o que passou do teto.
# Teto      : com --hook, no máximo ONION_SPOOL_IMPORT_MAX (padrão 100) sinais por chamada: o hook tem 5 s
#             de timeout, e 3000 sinais o mataram em rc 124 sem aviso. Só conta o que SAI do spool, senão 100
#             retidos no começo da lista barram para sempre o sinal novo. Como retido custa um `git ls-files`,
#             há também um orçamento de ONION_SPOOL_IMPORT_SECS segundos (padrão 3). O resto fica para a próxima.
# Limite    : quem escreve no spool sem o carteiro (cp à mão) pula as guardas do remetente; é o mesmo
#             limite de quem copia direto no inbox/, que existe desde o 1º dia. O spool nasce 0700.
# Uso       : spool-import.sh [--repo <raiz>] [--hook] [--dry-run]
# =============================================================================
set -uo pipefail

REPO="" ; HOOK=0 ; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 || exit 2 ;;
    --hook) HOOK=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) echo "uso: spool-import.sh [--repo <raiz>] [--hook] [--dry-run]" >&2; exit 2 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REPO="$(cd "${REPO}" 2>/dev/null && pwd -P)" || { echo "imported=0 pending=0"; exit 0; }

spool_slug() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
SPOOL_ROOT="${ONION_SPOOL_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/onion-spool}"
SPOOL="${SPOOL_ROOT}/$(spool_slug "${REPO}")"
INBOX="${REPO}/docs/evolution/inbox"

imported=0 ; pending=0 ; failed=0 ; worked=0
MAX="${ONION_SPOOL_IMPORT_MAX:-100}"
BUDGET="${ONION_SPOOL_IMPORT_SECS:-3}"

take_claim() {  # $1 = sinal, $2 = nome de posse → 0 se a posse é de um arquivo regular; senão já contou o que houve
  if ! mv -f "$1" "$2" 2>/dev/null; then
    # sumiu = outra sessão levou. Ainda lá = spool sem escrita, que não pode ficar mudo.
    if [ -e "$1" ] || [ -L "$1" ]; then
      echo "AVISO: não consegui tomar ${1##*/} no spool (sem escrita?) — o sinal fica em ${SPOOL}/." >&2
      pending=$((pending + 1)); failed=$((failed + 1))
    fi
    return 1
  fi
  # o teste de link do laço vem antes do rename: quem troca o arquivo por link nesse intervalo é pego aqui, antes do cp
  if [ -L "$2" ]; then
    echo "AVISO: ${1##*/} virou link simbólico no spool — não importo; fica em ${SPOOL}/." >&2
    mv -n "$2" "$1" 2>/dev/null
    rm -f "$2"
    pending=$((pending + 1))
    return 1
  fi
}

if [ -d "${SPOOL}" ]; then
  # o que uma passada morta deixou: `kill -0` é builtin, e processo vivo (outra sessão) mantém o que é seu
  if [ "${DRY}" -eq 0 ]; then
    for c in "${SPOOL}"/.*.claim.*; do
      [ -f "${c}" ] && [ ! -L "${c}" ] || continue
      kill -0 "${c##*.}" 2>/dev/null && continue
      n="${c##*/}"; n="${n#.}"; n="${n%.claim.*}"
      mv -n "${c}" "${SPOOL}/${n}" 2>/dev/null
      [ -e "${c}" ] && rm -f "${c}"
    done
    for t in "${INBOX}"/.*.spool-tmp.*; do
      [ -f "${t}" ] || continue
      kill -0 "${t##*.}" 2>/dev/null || rm -f "${t}"
    done
  fi
  for f in "${SPOOL}"/*.md; do
    [ -e "${f}" ] || [ -L "${f}" ] || continue
    base="${f##*/}"
    case "${base}" in .*|[Rr][Ee][Aa][Dd][Mm][Ee].md) continue ;; esac
    if [ -L "${f}" ]; then
      echo "AVISO: ${base} no spool é link simbólico — não importo; fica em ${SPOOL}/." >&2
      pending=$((pending + 1))
      continue
    fi
    [ -f "${f}" ] || continue
    if [ "${HOOK}" -eq 1 ] && [ "${worked}" -ge "${MAX}" ]; then pending=$((pending + 1)); continue; fi
    if [ "${HOOK}" -eq 1 ] && [ "${SECONDS}" -ge "${BUDGET}" ]; then pending=$((pending + 1)); continue; fi
    dest="${INBOX}/${base}"
    # pasta no lugar do sinal: o `mv` colocaria o arquivo DENTRO dela, e a contagem diria importado
    if [ -d "${dest}" ]; then
      echo "AVISO: ${dest} é uma pasta — não importo; o sinal fica em ${SPOOL}/." >&2
      pending=$((pending + 1))
      continue
    fi
    if [ -e "${dest}" ]; then
      if cmp -s "${f}" "${dest}"; then
        [ "${DRY}" -eq 1 ] && continue
        c="${SPOOL}/.${base}.claim.$$"
        take_claim "${f}" "${c}" || continue
        if cmp -s "${c}" "${dest}"; then rm -f "${c}"; worked=$((worked + 1)); else mv -n "${c}" "${f}" 2>/dev/null; [ -e "${c}" ] && rm -f "${c}"; fi
        continue
      fi
      if git -C "${REPO}" ls-files --error-unmatch "docs/evolution/inbox/${base}" >/dev/null 2>&1; then
        echo "AVISO: ${base} chegou pelo spool com conteúdo novo, mas o inbox/ já COMMITOU a versão anterior — fica em ${SPOOL}/ (renomeie para entregar)." >&2
        pending=$((pending + 1))
        continue
      fi
    fi
    if [ "${DRY}" -eq 1 ]; then echo "importaria: ${base}" >&2; imported=$((imported + 1)); continue; fi
    mkdir -p "${INBOX}" 2>/dev/null
    claim="${SPOOL}/.${base}.claim.$$"
    tmp="${INBOX}/.${base}.spool-tmp.$$"
    take_claim "${f}" "${claim}" || continue
    if cp "${claim}" "${tmp}" 2>/dev/null && mv -f "${tmp}" "${dest}" 2>/dev/null; then
      rm -f "${claim}"
      imported=$((imported + 1)); worked=$((worked + 1))
    else
      rm -f "${tmp}" 2>/dev/null
      mv -n "${claim}" "${f}" 2>/dev/null
      [ -e "${claim}" ] && rm -f "${claim}"
      echo "AVISO: não consegui escrever ${dest} — o sinal fica em ${SPOOL}/." >&2
      pending=$((pending + 1)); failed=$((failed + 1))
    fi
  done
fi
echo "imported=${imported} pending=${pending}"
[ "${HOOK}" -eq 1 ] && exit 0
[ "${failed}" -eq 0 ]
