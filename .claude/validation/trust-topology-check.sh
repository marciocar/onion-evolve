#!/usr/bin/env bash
# trust-topology-check.sh — Valida topologia de confiança antes de qualquer relay entre instâncias Onion.
# Economy of Motors: Shell = determinístico; nunca falha silenciosamente (sem || true).
# RFC-0003 §2.5 + invariante: toda tentativa logada (autorizada ou não).
#
# Uso:
#   trust-topology-check.sh --from <id> --to <id> --action relay|advise|correct [--repo <path>] [--dry-run]
#   trust-topology-check.sh --check-log-dest   # julga o destino A2A_TRUST_LOG (motivo no stdout se inseguro)
#   trust-topology-check.sh --ensure-log       # julga e, se ausente ou vazio, cria o destino com cabeçalho, 0600
#
# DESTINO DO LOG (2026-10-22): A2A_TRUST_LOG=<arquivo absoluto> grava o log FORA do repo. Sem ela, o log segue
# em <repo>/docs/evolution/trust-log.md (o comportamento de sempre). Medido em 2026-10-22: o onion-bridge roda
# o gate dentro do CLONE SERVIDO do core, e a trilha de auditoria caía num arquivo RASTREADO desse clone, que
# cada update-bridge guardava num stash (7 stashes, 16 eventos que nunca chegaram ao repo). O destino é julgado
# FAIL-CLOSED: caminho relativo, não normalizado ou com caractere de controle; diretório ausente, symlink em
# qualquer componente, dono diferente de quem roda, diretório gravável por grupo/outros, ancestral de outro dono
# (que não o root) ou gravável por outros sem sticky; arquivo com escrita de grupo ou qualquer bit de outros,
# não gravável ou com mais de um link → recusa (exit 2 no relay; rc 1 no --check-log-dest), sem gravar no lugar errado em silêncio.
# A2A_TRUST_LOG vazia vale como ausente (o idioma ${X:-} dos outros env do transporte).
#
# Exit:
#   0 = autorizado
#   1 = bloqueado (mensagem explicativa em stderr + log)
#   2 = erro de configuração (members.yaml ausente, campo faltando, etc.)
#
# --dry-run: imprime o veredito SEM gravar em trust-log.md — para dogfood/CI/
#            exploração. Sem a flag, toda invocação é logada (invariante RFC-0003
#            "toda tentativa auditável"); com ela, o log de produção não mistura
#            ruído de teste com sinal real (achado #10 da auditoria 2026-07-01).
set -euo pipefail

# --- Argumentos ---
FROM_ID=""
TO_ID=""
ACTION=""
DRY_RUN=0
LOG_MODE=""
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)    FROM_ID="$2";  shift 2 ;;
    --to)      TO_ID="$2";    shift 2 ;;
    --action)  ACTION="$2";   shift 2 ;;
    --repo)    REPO="$2";     shift 2 ;;
    --dry-run) DRY_RUN=1;     shift ;;
    --check-log-dest) LOG_MODE=check;  shift ;;
    --ensure-log)     LOG_MODE=ensure; shift ;;
    *)
      echo "ERROR: argumento desconhecido: $1" >&2
      echo "Uso: $0 --from <id> --to <id> --action relay|advise|correct [--repo <path>] [--dry-run]" >&2
      exit 2
      ;;
  esac
done

# --- Destino do log: julgamento fail-closed de A2A_TRUST_LOG (ver cabeçalho) ---
TRUST_LOG_DEST="${A2A_TRUST_LOG:-}"
_mode_uid() {  # <path> → "<modo octal> <uid> <nlink>" (GNU stat; o -f é o do BSD/macOS)
  stat -c '%a %u %h' -- "$1" 2>/dev/null || stat -f '%Lp %u %l' -- "$1" 2>/dev/null
}
# imprime o motivo e devolve 1 quando o destino é inseguro; 0 quando serve. Ordem: forma do texto → o diretório
# (literal, físico, do dono, fechado) → os ancestrais (do dono ou do root, sem escrita alheia salvo sticky) → o
# arquivo, se existir (regular, do dono, sem bit de outros, gravável, um link só). Refutador de 2026-10-22: o
# symlink num componente do MEIO e o ancestral 777 passavam (o -L só olhava as duas pontas).
trust_log_dest_problem() {
  local p="$1" d a m u n me
  case "$p" in /*) ;; *) echo "relative"; return 1 ;; esac
  case "$p" in *[[:cntrl:]]*) echo "control-char"; return 1 ;; esac
  case "$p/" in */../*|*/./*|*//*) echo "not-normalized"; return 1 ;; esac
  d="$(dirname "$p")"
  if [ -L "$p" ]; then echo "symlink"; return 1; fi
  if [ -L "$d" ]; then echo "dir-symlink"; return 1; fi
  if [ ! -d "$d" ]; then echo "dir-missing"; return 1; fi
  if [ "$(cd -P -- "$d" 2>/dev/null && pwd -P)" != "$d" ]; then echo "dir-path-has-symlink"; return 1; fi
  me="$(id -u)"
  read -r m u n <<<"$(_mode_uid "$d")" || true
  case "${m:-}" in ''|*[!0-7]*) echo "dir-unstattable"; return 1 ;; esac
  if [ "${u:-}" != "$me" ]; then echo "dir-not-owned"; return 1; fi
  if (( (8#$m & 8#022) != 0 )); then echo "dir-writable-by-others"; return 1; fi
  a="$d"
  while [ "$a" != "/" ]; do
    a="$(dirname "$a")"
    read -r m u n <<<"$(_mode_uid "$a")" || true
    case "${m:-}" in ''|*[!0-7]*) echo "ancestor-unstattable"; return 1 ;; esac
    if [ "${u:-}" != "$me" ] && [ "${u:-}" != "0" ]; then echo "ancestor-not-owned"; return 1; fi
    if (( (8#$m & 8#022) != 0 && (8#$m & 8#1000) == 0 )); then echo "ancestor-writable-by-others"; return 1; fi
  done
  if [ -e "$p" ]; then
    if [ ! -f "$p" ]; then echo "not-regular"; return 1; fi
    read -r m u n <<<"$(_mode_uid "$p")" || true
    case "${m:-}" in ''|*[!0-7]*) echo "unstattable"; return 1 ;; esac
    if [ "${u:-}" != "$me" ]; then echo "not-owned"; return 1; fi
    if (( (8#$m & 8#027) != 0 )); then echo "file-mode-unsafe"; return 1; fi
    if [ "${n:-}" != "1" ]; then echo "hardlinked"; return 1; fi
    if [ ! -w "$p" ]; then echo "not-writable"; return 1; fi
  fi
  return 0
}
write_log_header() {  # <arquivo> — o cabeçalho tem UM dono (este script); o a2a-verify pede pelo --ensure-log
  cat > "$1" <<EOF
# Log de Tentativas de Relay — Onion Trust Topology
# Gerado por trust-topology-check.sh (RFC-0003)
# Toda tentativa é registrada — autorizada ou bloqueada.

| Timestamp | FROM | TO | ACTION | STATUS | Razão |
|---|---|---|---|---|---|
EOF
}
if [ -n "$LOG_MODE" ]; then
  [ -n "$TRUST_LOG_DEST" ] || { echo "unset"; exit 1; }
  why="$(trust_log_dest_problem "$TRUST_LOG_DEST")" || { echo "$why"; exit 1; }
  if [ "$LOG_MODE" = "ensure" ] && [ ! -s "$TRUST_LOG_DEST" ]; then
    ( umask 077; write_log_header "$TRUST_LOG_DEST" ) || { echo "create-failed"; exit 1; }
  fi
  echo "ok"; exit 0
fi
if [ -n "$TRUST_LOG_DEST" ]; then
  if ! why="$(trust_log_dest_problem "$TRUST_LOG_DEST")"; then
    echo "ERROR: A2A_TRUST_LOG inseguro (${why}): ${TRUST_LOG_DEST} — nada gravado" >&2
    exit 2
  fi
fi

# --- Validação de argumentos obrigatórios ---
if [ -z "$FROM_ID" ] || [ -z "$TO_ID" ] || [ -z "$ACTION" ]; then
  echo "ERROR: --from, --to e --action são obrigatórios." >&2
  exit 2
fi

case "$ACTION" in
  relay|advise|correct) ;;
  *)
    echo "ERROR: --action deve ser relay, advise ou correct (recebeu: '$ACTION')." >&2
    exit 2
    ;;
esac

# --- Configuração de paths ---
MEMBERS="$REPO/docs/evolution/federation/members.yaml"
TRUST_LOG="${TRUST_LOG_DEST:-$REPO/docs/evolution/trust-log.md}"

if [ ! -f "$MEMBERS" ]; then
  echo "ERROR: members.yaml não encontrado em $MEMBERS" >&2
  echo "Solução: inicializar docs/evolution/federation/members.yaml com o registro de membros." >&2
  exit 2
fi

TODAY="$(date +%F)"
TIMESTAMP="$(date '+%F %H:%M')"

# --- Funções auxiliares ---

# Obter role de um membro
get_role() {
  local ID="$1"
  awk -v id="$ID" '
    /^  - id:/ { found = ($NF == id) }
    found && /^    role:/ { print $2; exit }
  ' "$MEMBERS"
}

# Obter kind de um membro. A AUTORIDADE DE FONTE se reconhece pela NATUREZA (kind: source), nunca só pelo
# papel: desde a matriz das portas (2026-10-09) a porta onion-core publica `role: source` com `kind: door`,
# e o refutador de 2026-10-10 mostrou um adotante disfarçado de porta source AUTORIZADO a `correct` qualquer
# membro quando a decisão lia só o role.
get_kind() {
  local ID="$1"
  awk -v id="$ID" '
    /^  - id:/ { found = ($NF == id) }
    found && /^    kind:/ { print $2; exit }
  ' "$MEMBERS"
}

# Obter parent de um membro (o hub que o T2 adota). Mesmo leitor do role e do kind; comentário inline cai.
get_parent() {
  local ID="$1"
  awk -v id="$ID" '
    /^  - id:/ { found = ($NF == id) }
    found && /^    parent:/ { v = $0; sub(/#.*$/, "", v); sub(/^    parent:[[:space:]]*/, "", v); gsub(/[[:space:]"\047]/, "", v); print v; exit }
  ' "$MEMBERS"
}

# Verificar se ID está em uma lista YAML (campo: [a, b, c])
# Indentação LIVRE (os campos de trust vivem a 6 espaços, aninhados sob `trust:`)
# e comentário inline removido ANTES da comparação — sem isso o match é sempre-falso
# (bug FED-2-0 da auditoria 2026-07-01: topologia granular inteira inoperante).
id_in_list() {
  local ID="$1"
  local MEMBER_ID="$2"
  local FIELD="$3"
  # Extrai o bloco do membro e verifica o campo
  awk -v id="$MEMBER_ID" -v field="$FIELD" -v search="$ID" '
    /^  - id:/ { found = ($NF == id); next }
    found && $0 ~ ("^[ ]+" field ":") {
      line = $0
      # Remove comentário inline PRIMEIRO (senão vira lixo colado ao último elemento)
      sub(/#.*$/, "", line)
      # Remove espaços e colchetes; verifica se search está como elemento
      gsub(/[[:space:]]/, "", line)
      gsub(/^[^:]+:/, "", line)
      gsub(/[\[\]]/, "", line)
      n = split(line, arr, ",")
      for (i = 1; i <= n; i++) {
        if (arr[i] == search) { print "yes"; exit }
      }
      exit
    }
  ' "$MEMBERS"
}

# Obter role de um membro com verificação de existência
get_member_role() {
  local ID="$1"
  local ROLE
  ROLE="$(get_role "$ID")"
  if [ -z "$ROLE" ]; then
    echo "ERROR: membro '$ID' não encontrado em members.yaml." >&2
    exit 2
  fi
  echo "$ROLE"
}

# --- Log de tentativa (auditável — todo relay logado; --dry-run não grava) ---
log_attempt() {
  local STATUS="$1"
  local REASON="$2"

  if [ "$DRY_RUN" = "1" ]; then
    echo "   (dry-run: veredito ${STATUS} NÃO gravado em trust-log.md)" >&2
    return 0
  fi

  if [ -n "$TRUST_LOG_DEST" ]; then
    # destino explícito: o diretório já foi julgado (existe, é do dono, não é gravável por outros); nunca
    # mkdir -p aqui, e o arquivo nasce 0600
    [ -s "$TRUST_LOG" ] || ( umask 077; write_log_header "$TRUST_LOG" )
  else
    mkdir -p "$(dirname "$TRUST_LOG")"
    [ -f "$TRUST_LOG" ] || write_log_header "$TRUST_LOG"
  fi

  # falha ao gravar é erro de CONFIGURAÇÃO (exit 2), nunca o 1 de "bloqueado" que o set -e daria a um relay
  # AUTORIZADO (refutador de 2026-10-22: arquivo 0400 aceito pelo juiz saía rc 1)
  if ! echo "| ${TIMESTAMP} | ${FROM_ID} | ${TO_ID} | ${ACTION} | ${STATUS} | ${REASON} |" >> "$TRUST_LOG"; then
    echo "ERROR: não gravei a tentativa em ${TRUST_LOG}" >&2
    exit 2
  fi
}

# --- Lógica principal de autorização ---

FROM_ROLE="$(get_member_role "$FROM_ID")"
TO_ROLE="$(get_member_role "$TO_ID")"
FROM_KIND="$(get_kind "$FROM_ID")"
TO_KIND="$(get_kind "$TO_ID")"

# source (core) pode enviar para qualquer membro — autoridade emissora
if [ "$FROM_KIND" = "source" ]; then
  log_attempt "AUTORIZADO" "core (source) tem autoridade emissora universal"
  echo "✅ AUTORIZADO: $FROM_ID ($FROM_ROLE) → $TO_ID ($TO_ID) [$ACTION]"
  echo "   Razão: core (source) tem autoridade emissora — sem restrição de saída."
  exit 0
fi

# Qualquer membro pode enviar para o core via relay/advise
if [ "$TO_KIND" = "source" ] && [ "$ACTION" != "correct" ]; then
  log_attempt "AUTORIZADO" "inbox do core é aberto para relay e advise"
  echo "✅ AUTORIZADO: $FROM_ID ($FROM_ROLE) → $TO_ID (core) [$ACTION]"
  echo "   Razão: inbox do core é aberto para relay e advise de qualquer membro."
  exit 0
fi

# correct para o core: verificar can_correct_to
if [ "$TO_KIND" = "source" ] && [ "$ACTION" = "correct" ]; then
  AUTHORIZED="$(id_in_list "onion-evolve" "$FROM_ID" "can_correct_to")"
  if [ "$AUTHORIZED" = "yes" ]; then
    log_attempt "AUTORIZADO" "can_correct_to inclui onion-evolve"
    echo "✅ AUTORIZADO: $FROM_ID → core [correct]"
    exit 0
  else
    REASON="can_correct_to de '$FROM_ID' não inclui 'onion-evolve'. Adicionar se intencional."
    log_attempt "BLOQUEADO" "$REASON"
    echo "🚫 BLOQUEADO: $FROM_ID → $TO_ID [correct]" >&2
    echo "   $REASON" >&2
    echo "   Para propor correção ao core, adicionar 'onion-evolve' em trust.can_correct_to de '$FROM_ID'." >&2
    exit 1
  fi
fi

# hub → seus T2 consumers (downstream): hub tem autoridade sobre seus T2s
if [ "$FROM_ROLE" = "hub" ] && [ "$TO_ROLE" = "consumer" ]; then
  # Verificar que TO está em exposes_downstream de FROM
  IN_DOWNSTREAM="$(id_in_list "$TO_ID" "$FROM_ID" "exposes_downstream")"
  if [ "$IN_DOWNSTREAM" = "yes" ]; then
    log_attempt "AUTORIZADO" "hub→consumer (downstream autorizado)"
    echo "✅ AUTORIZADO: $FROM_ID (hub) → $TO_ID (consumer) [$ACTION]"
    echo "   Razão: $TO_ID está em exposes_downstream de $FROM_ID."
    exit 0
  else
    REASON="$TO_ID não está em exposes_downstream de $FROM_ID. Registrar o T2 antes de fazer relay."
    log_attempt "BLOQUEADO" "$REASON"
    echo "🚫 BLOQUEADO: $FROM_ID → $TO_ID [$ACTION]" >&2
    echo "   $REASON" >&2
    exit 1
  fi
fi

# consumer → SEU parent hub (feedback upward). Até a F3 do configurador A2A (2026-10-15) a regra dizia "seu
# parent" e checava só os papéis: qualquer consumer falava com QUALQUER hub. Com o hub virando receptor vivo
# (/a2a/<hub> no bridge do core), isso deixava o filho de um hub escrever na fila de outro. Agora o parent
# do consumer tem de ser o hub de destino; consumer de outro hub fala com ele pelo core, não de lado.
if [ "$FROM_ROLE" = "consumer" ] && [ "$TO_ROLE" = "hub" ] && [ "$ACTION" != "correct" ]; then
  FROM_PARENT="$(get_parent "$FROM_ID")"
  if [ "$FROM_PARENT" != "$TO_ID" ]; then
    REASON="$FROM_ID (consumer) tem parent '${FROM_PARENT:-ausente}', não '$TO_ID': consumer só fala com o PRÓPRIO hub."
    log_attempt "BLOQUEADO" "$REASON"
    echo "🚫 BLOQUEADO: $FROM_ID → $TO_ID [$ACTION]" >&2
    echo "   $REASON" >&2
    exit 1
  fi
  log_attempt "AUTORIZADO" "consumer→parent hub (feedback upward)"
  echo "✅ AUTORIZADO: $FROM_ID (consumer) → $TO_ID (hub) [$ACTION]"
  echo "   Razão: consumer sempre pode enviar feedback ao seu parent hub."
  exit 0
fi

# hub → hub (peer-to-peer): verificar AMBOS (from.can_advise_to + to.can_receive_from)
if [ "$FROM_ROLE" = "hub" ] && [ "$TO_ROLE" = "hub" ] && [ "$ACTION" != "correct" ]; then
  CAN_ADVISE="$(id_in_list "$TO_ID" "$FROM_ID" "can_advise_to")"
  CAN_RECEIVE="$(id_in_list "$FROM_ID" "$TO_ID" "can_receive_from")"

  if [ "$CAN_ADVISE" = "yes" ] && [ "$CAN_RECEIVE" = "yes" ]; then
    log_attempt "AUTORIZADO" "peer trust bidirecional verificado"
    echo "✅ AUTORIZADO: $FROM_ID (hub) → $TO_ID (hub) [$ACTION]"
    echo "   Razão: $FROM_ID está em can_advise_to e $FROM_ID está em can_receive_from do destinatário."
    exit 0
  else
    MISSING=""
    [ "$CAN_ADVISE" != "yes" ] && MISSING="$FROM_ID.trust.can_advise_to não inclui '$TO_ID'"
    [ "$CAN_RECEIVE" != "yes" ] && MISSING="${MISSING:+$MISSING; }$TO_ID.trust.can_receive_from não inclui '$FROM_ID'"
    REASON="Trust bidirecional incompleto: $MISSING"
    log_attempt "BLOQUEADO" "$REASON"
    echo "🚫 BLOQUEADO: $FROM_ID → $TO_ID [$ACTION]" >&2
    echo "   $REASON" >&2
    echo "   Para habilitar: adicionar '$TO_ID' em can_advise_to de '$FROM_ID'" >&2
    echo "   E adicionar '$FROM_ID' em can_receive_from de '$TO_ID'." >&2
    exit 1
  fi
fi

# hub → hub correct: sempre intermediado pelo core (bloqueado aqui, requer core como broker)
if [ "$FROM_ROLE" = "hub" ] && [ "$TO_ROLE" = "hub" ] && [ "$ACTION" = "correct" ]; then
  REASON="Correção entre peers T1 exige intermediação do core. Enviar via core (relay → core → co-evolve → decide)."
  log_attempt "BLOQUEADO" "$REASON"
  echo "🚫 BLOQUEADO: $FROM_ID → $TO_ID [correct]" >&2
  echo "   $REASON" >&2
  exit 1
fi

# standalone → qualquer não-core: bloqueado
if [ "$FROM_ROLE" = "standalone" ] && [ "$TO_KIND" != "source" ]; then
  REASON="standalone não tem canal lateral. Comunicação só via core."
  log_attempt "BLOQUEADO" "$REASON"
  echo "🚫 BLOQUEADO: $FROM_ID (standalone) → $TO_ID [$ACTION]" >&2
  echo "   $REASON" >&2
  exit 1
fi

# Qualquer outro caso não coberto: bloquear com diagnóstico
REASON="Combinação FROM=$FROM_ROLE TO=$TO_ROLE ACTION=$ACTION não tem regra explícita — bloqueado por segurança."
log_attempt "BLOQUEADO" "$REASON"
echo "🚫 BLOQUEADO: $FROM_ID → $TO_ID [$ACTION]" >&2
echo "   $REASON" >&2
echo "   Se esta combinação deve ser autorizada, adicionar regra explícita em trust-topology-check.sh." >&2
exit 1
