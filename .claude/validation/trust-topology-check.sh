#!/usr/bin/env bash
# trust-topology-check.sh — Valida topologia de confiança antes de qualquer relay entre instâncias Onion.
# Economy of Motors: Shell = determinístico; nunca falha silenciosamente (sem || true).
# RFC-0003 §2.5 + invariante: toda tentativa logada (autorizada ou não).
#
# Uso:
#   trust-topology-check.sh --from <id> --to <id> --action relay|advise|correct [--repo <path>] [--dry-run]
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
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)    FROM_ID="$2";  shift 2 ;;
    --to)      TO_ID="$2";    shift 2 ;;
    --action)  ACTION="$2";   shift 2 ;;
    --repo)    REPO="$2";     shift 2 ;;
    --dry-run) DRY_RUN=1;     shift ;;
    *)
      echo "ERROR: argumento desconhecido: $1" >&2
      echo "Uso: $0 --from <id> --to <id> --action relay|advise|correct [--repo <path>] [--dry-run]" >&2
      exit 2
      ;;
  esac
done

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
TRUST_LOG="$REPO/docs/evolution/trust-log.md"

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

  mkdir -p "$(dirname "$TRUST_LOG")"

  if [ ! -f "$TRUST_LOG" ]; then
    cat > "$TRUST_LOG" <<EOF
# Log de Tentativas de Relay — Onion Trust Topology
# Gerado por trust-topology-check.sh (RFC-0003)
# Toda tentativa é registrada — autorizada ou bloqueada.

| Timestamp | FROM | TO | ACTION | STATUS | Razão |
|---|---|---|---|---|---|
EOF
  fi

  echo "| ${TIMESTAMP} | ${FROM_ID} | ${TO_ID} | ${ACTION} | ${STATUS} | ${REASON} |" >> "$TRUST_LOG"
}

# --- Lógica principal de autorização ---

FROM_ROLE="$(get_member_role "$FROM_ID")"
TO_ROLE="$(get_member_role "$TO_ID")"

# source (core) pode enviar para qualquer membro — autoridade emissora
if [ "$FROM_ROLE" = "source" ]; then
  log_attempt "AUTORIZADO" "core (source) tem autoridade emissora universal"
  echo "✅ AUTORIZADO: $FROM_ID ($FROM_ROLE) → $TO_ID ($TO_ID) [$ACTION]"
  echo "   Razão: core (source) tem autoridade emissora — sem restrição de saída."
  exit 0
fi

# Qualquer membro pode enviar para o core via relay/advise
if [ "$TO_ROLE" = "source" ] && [ "$ACTION" != "correct" ]; then
  log_attempt "AUTORIZADO" "inbox do core é aberto para relay e advise"
  echo "✅ AUTORIZADO: $FROM_ID ($FROM_ROLE) → $TO_ID (core) [$ACTION]"
  echo "   Razão: inbox do core é aberto para relay e advise de qualquer membro."
  exit 0
fi

# correct para o core: verificar can_correct_to
if [ "$TO_ROLE" = "source" ] && [ "$ACTION" = "correct" ]; then
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

# consumer → seu parent hub (feedback upward): sempre autorizado
if [ "$FROM_ROLE" = "consumer" ] && [ "$TO_ROLE" = "hub" ] && [ "$ACTION" != "correct" ]; then
  # Verificar que FROM tem TO como referência em can_receive_from (o inverso: que hub está em can_receive_from do consumer)
  # Simplificação: T2 pode sempre enviar para seu parent T1 via relay/advise
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
if [ "$FROM_ROLE" = "standalone" ] && [ "$TO_ROLE" != "source" ]; then
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
