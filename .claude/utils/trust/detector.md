# Trust SDAAL — Detector
# Detecta tier da instância local e resolve caminhos de peers.
# Espelho de .claude/utils/task-manager/detector.md em estrutura.
# RFC-0003 §2.5

## detect_tier()

Determina o TrustTier da instância atual lendo `docs/evolution/federation/members.yaml`.

```bash
# Uso: detect_tier <repo-root>
# Saída: source | hub | standalone | consumer
# Exit: 0 (sucesso) | 1 (não encontrado em members.yaml)

detect_tier() {
  local REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local MEMBERS="$REPO/docs/evolution/federation/members.yaml"
  local SELF_ID

  # Detectar ID desta instância via .onion-version ou basename do repo
  SELF_ID="$(awk '/^instance:/{print $2; exit}' "$REPO/.claude/.onion-version" 2>/dev/null \
    || basename "$REPO")"

  if [ ! -f "$MEMBERS" ]; then
    echo "ERROR: members.yaml não encontrado em $MEMBERS" >&2
    return 1
  fi

  # Extrair role do membro com este ID (parser ingênuo; YAML simples sem indentação mista)
  awk -v id="$SELF_ID" '
    /^  - id:/ { found = ($NF == id) }
    found && /^    role:/ { print $2; exit }
  ' "$MEMBERS"
}
```

## resolve_peer_path()

Resolve o `local_path` de um peer pelo ID em `members.yaml`.
Campo obrigatório para relay peer — ausente = erro claro.

```bash
# Uso: resolve_peer_path <peer-id> [<repo-root>]
# Saída (stdout): caminho absoluto do peer
# Exit: 0 (encontrado) | 1 (não encontrado ou local_path ausente)

resolve_peer_path() {
  local PEER_ID="$1"
  local REPO="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local MEMBERS="$REPO/docs/evolution/federation/members.yaml"

  if [ ! -f "$MEMBERS" ]; then
    echo "ERROR: members.yaml não encontrado" >&2
    return 1
  fi

  local PATH_VAL
  PATH_VAL="$(awk -v id="$PEER_ID" '
    /^  - id:/ { found = ($NF == id) }
    found && /^    local_path:/ { gsub(/^[[:space:]]*local_path:[[:space:]]*"?/, ""); gsub(/"[[:space:]]*$/, ""); print; exit }
  ' "$MEMBERS")"

  if [ -z "$PATH_VAL" ]; then
    echo "ERROR: local_path ausente para peer '$PEER_ID' em members.yaml — relay impossível." >&2
    echo "Solução: adicionar 'local_path: \"/caminho/absoluto\"' à entrada de '$PEER_ID'." >&2
    return 1
  fi

  echo "$PATH_VAL"
}
```

## validate_trust_policy()

Valida que um membro em members.yaml está bem-formado antes de qualquer relay.

```bash
# Uso: validate_trust_policy <member-id> [<repo-root>]
# Saída: mensagens de erro (stderr) se inválido
# Exit: 0 (válido) | 1 (inválido)

validate_trust_policy() {
  local MEMBER_ID="$1"
  local REPO="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local MEMBERS="$REPO/docs/evolution/federation/members.yaml"
  local ERRORS=0

  # 1. Membro existe?
  if ! awk -v id="$MEMBER_ID" '/^  - id:/ && ($NF == id) {found=1} END {exit !found}' "$MEMBERS" 2>/dev/null; then
    echo "ERROR: membro '$MEMBER_ID' não encontrado em members.yaml" >&2
    return 1
  fi

  # 2. local_path presente? (obrigatório para relay)
  local PATH_VAL
  PATH_VAL="$(resolve_peer_path "$MEMBER_ID" "$REPO" 2>/dev/null || echo "")"
  if [ -z "$PATH_VAL" ]; then
    echo "WARN: local_path ausente para '$MEMBER_ID' — relay peer impossível" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Se tem parent, parent existe?
  local PARENT_ID
  PARENT_ID="$(awk -v id="$MEMBER_ID" '
    /^  - id:/ { found = ($NF == id) }
    found && /^    parent:/ { print $2; exit }
  ' "$MEMBERS")"
  if [ -n "$PARENT_ID" ]; then
    if ! awk -v id="$PARENT_ID" '/^  - id:/ && ($NF == id) {found=1} END {exit !found}' "$MEMBERS" 2>/dev/null; then
      echo "ERROR: parent '$PARENT_ID' de '$MEMBER_ID' não existe em members.yaml" >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  return $ERRORS
}
```

## Precedência de detecção de ID

1. Campo `instance:` em `.claude/.onion-version` (mais confiável — stamp canônico)
2. `basename` do diretório do repo (fallback)

O campo `instance:` deve ser adicionado ao `.onion-version` durante `/meta:adopt` —
próxima evolução do stamp (não bloqueante para o detector: o basename resolve).
