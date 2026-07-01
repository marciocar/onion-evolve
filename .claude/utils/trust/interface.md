# Trust SDAAL — Interface
# Contrato que todos os adapters de trust devem implementar.
# Espelho de .claude/utils/task-manager/interface.md em estrutura.
# RFC-0003 §2.5

## ITrustManager

Interface pública da abstração de confiança Onion. Consumidores chamam esta interface
sem precisar saber o tier da instância local ou dos peers.

```
ITrustManager:

  # Verifica se a instância FROM pode executar ACTION em relação à instância TO.
  # Lê members.yaml para resolver as políticas de ambos.
  # Retorna RelayResult — nunca lança exceção silenciosa.
  can_relay(from_id: str, to_id: str, action: RelayAction) → RelayResult

  # Retorna a lista de ClassificationLevel que esta instância pode ver de FROM.
  # Depende do tier local e do trust_topology de FROM.
  visible_classifications(from_id: str) → [ClassificationLevel]

  # Resolve o caminho local de um peer via members.yaml[id].local_path.
  # Retorna PeerResolution — never-null (usa found:false + error se ausente).
  resolve_peer_path(peer_id: str) → PeerResolution

  # Valida a topologia completa de um membro antes de qualquer operação.
  # Checa: local_path presente, trust: bem-formado, parent existe no members.yaml.
  # Usado por trust-topology-check.sh antes de relay.
  validate_trust_policy(member_id: str) → ValidationResult
```

## Princípios de implementação

1. **Nunca falha silenciosamente** — toda verificação retorna resultado explícito com `reason`.
2. **Sem `|| true`** — qualquer script que chame esta abstração não mascara erros.
3. **Lê membros fresh** — relê `members.yaml` a cada call (não cache em memória).
4. **Log toda tentativa** — autorizada ou não. Auditabilidade é invariante.
5. **Menor privilégio** — default é bloqueado; autorização é explícita, nunca inferida.

## Mapa de adaptadores

| Tier | Adapter | Regra-chave |
|---|---|---|
| `source` | `adapters/source.md` | Lê tudo; escreve só em si; sem parent |
| `hub` | `adapters/hub.md` | Peers autorizados + expõe downstream |
| `standalone` | `adapters/standalone.md` | Só public do core |
| `consumer` | `adapters/consumer.md` | Só o que parent T1 publica |

## Consumidores desta interface

- `.claude/validation/trust-topology-check.sh` — gate determinístico (Shell)
- `.claude/commands/meta/co-relay.md` (extensão Fase 3) — antes de `--to peer:<id>`
- `.claude/commands/meta/diary.md` — `export-sharable` verifica classification antes de empacotar
