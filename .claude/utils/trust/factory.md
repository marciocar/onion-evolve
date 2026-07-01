# Trust SDAAL — Factory
# Resolve qual adapter de trust usar para a instância local.
# Espelho de .claude/utils/task-manager/factory.md em estrutura.
# RFC-0003 §2.5

## Responsabilidade

A factory lê o tier da instância atual (via `detector.md`) e retorna o adapter correto.
O consumidor (`trust-topology-check.sh`, `/meta:co-relay`, `/meta:diary`) nunca precisa
saber qual adapter está em uso — só chama a interface.

## Lógica de resolução

```bash
# Uso: resolve_trust_adapter [<repo-root>]
# Saída (stdout): path do adapter a usar
# Exit: 0 (resolvido) | 1 (tier desconhecido)

resolve_trust_adapter() {
  local REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local TRUST_DIR="$REPO/.claude/utils/trust"

  local TIER
  TIER="$(detect_tier "$REPO")" || return 1

  case "$TIER" in
    source)     echo "$TRUST_DIR/adapters/source.md" ;;
    hub)        echo "$TRUST_DIR/adapters/hub.md" ;;
    standalone) echo "$TRUST_DIR/adapters/standalone.md" ;;
    consumer)   echo "$TRUST_DIR/adapters/consumer.md" ;;
    *)
      echo "ERROR: tier desconhecido '$TIER' — adicionar adapter ou corrigir members.yaml" >&2
      return 1
      ;;
  esac
}
```

## Mapa de adapters

| Tier detectado | Adapter | Regra principal |
|---|---|---|
| `source` | `adapters/source.md` | Lê tudo; escreve só em si; sem parent |
| `hub` | `adapters/hub.md` | Trust bidirecional com peers autorizados |
| `standalone` | `adapters/standalone.md` | Só public do core; sem peers |
| `consumer` | `adapters/consumer.md` | Só o que parent T1 publica |

## Integração com trust-topology-check.sh

O script determinístico chama a factory antes de verificar qualquer ação:

```bash
# Em trust-topology-check.sh:
ADAPTER="$(resolve_trust_adapter "$REPO")"
# Depois aplica as regras do adapter para decidir authorized=true|false
```

## Divergência intencional vs task-manager factory

O task-manager factory resolve via variável de ambiente (`TASK_MANAGER_PROVIDER`).
A trust factory resolve via `members.yaml` (source of truth centralizada e auditável).
Razão: o trust topology é declarativo e versionado — não deve ser configurável por `.env`.
