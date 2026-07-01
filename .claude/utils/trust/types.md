# Trust SDAAL — Types
# Instância do padrão SDAAL: tipos base para topologia de confiança entre instâncias Onion.
# Espelho de .claude/utils/task-manager/types.md em estrutura.
# RFC-0003 §2.5

## TrustTier

Tier hierárquico de cada instância Onion na rede federada.

```
TrustTier:
  source     # TIER 0 — core; autoridade emissora; lê tudo; escreve só em si
  hub        # TIER 1 — central com sub-adotados; parent = source
  consumer   # TIER 2 — adotado de hub; parent = hub; não acessa core diretamente
  standalone # TIER 3 — adota core diretamente, sem sub-adotados
```

Determinado por: campo `role` em `docs/evolution/federation/members.yaml` (lido por `detector.md`).
Nunca auto-declarado pela instância — o core é a fonte de verdade.

## ClassificationLevel

Nível de visibilidade de um artefato (entrada de diário, KB, documento).

```
ClassificationLevel:
  private      # Só a instância dona
  protected    # Instância dona + TIER 0 (core)
  peer         # Instância dona + peers listados em trust.diary_readable_by
  downstream   # Instância dona + seus filhos T2 listados em trust.exposes_downstream
  public       # Qualquer instância federada autorizada
  collective   # Elegível para síntese co-autorada pelo core (subset de public)
```

## RelayAction

Ação sendo solicitada antes de verificar trust.

```
RelayAction:
  relay    # transportar artefato (inbox-to-inbox)
  advise   # enviar conselho/observação não-vinculante
  correct  # propor correção (exige can_correct_to preenchido explicitamente)
```

## TrustPolicy

Política de confiança de uma instância (campo `trust:` em members.yaml).

```yaml
TrustPolicy:
  can_receive_from: [<id>...]         # quem pode me enviar (relay/advise)
  can_advise_to: [<id>...]            # quem posso aconselhar
  can_correct_to: [<id>...]           # quem posso corrigir (vazio = nenhum)
  diary_readable_by: [<id>...]        # quem acessa meu diário PROTECTED
  diary_classifications_shared: [<ClassificationLevel>...]  # o que envio proativamente
  exposes_downstream: [<id>...]       # IDs dos meus sub-adotados T2
```

Campo `can_correct_to: []` é o default seguro — correção exige concessão explícita, nunca inferida.

## RelayResult

Resultado de uma tentativa de relay verificada.

```
RelayResult:
  authorized: bool
  action: RelayAction
  from_id: str
  to_id: str
  reason: str   # mensagem de diagnóstico (presente se authorized=false)
  logged: bool  # toda tentativa é logada (autorizada ou não)
```

## PeerResolution

Resultado da resolução de caminho de um peer.

```
PeerResolution:
  found: bool
  local_path: str | null    # valor de members.yaml[id].local_path; null se ausente
  error: str | null         # diagnóstico se not found
```

## Valores sentinela

- `[]` em qualquer lista trust = nenhuma concessão deste tipo
- `local_path` ausente = relay impossível (erro claro, nunca silêncio)
- `role: source` em `.onion-version` = instância é o core; lê tudo por papel, sem trust_topology
