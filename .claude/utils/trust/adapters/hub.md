# Trust SDAAL — Adapter: hub (TIER 1)
# Regras de confiança para centrais (hubs com sub-adotados).
# RFC-0003 §2.1 + §2.5

## Identidade

```
role: hub
tier: 1
parent: source (onion-evolve)
```

Um hub adotou o core e tem seus próprios adotados (T2). É simultaneamente:
- **Consumidor** em relação ao core (T0)
- **Emissor** em relação a seus adotados (T2)

## Regras de relay — O que um hub pode ENVIAR

### Para o core (T0)

| Ação | Autorizado? | Condição |
|---|---|---|
| `relay` (sinal/diário) | Sim | Sempre — hub está em members.yaml com parent=source |
| `advise` | Sim — se estiver em `can_advise_to: [onion-evolve]` | Requer concessão explícita |
| `correct` | Sim — se estiver em `can_correct_to: [onion-evolve]` | Requer concessão explícita |

### Para peers T1 (outros hubs)

| Ação | Autorizado? | Condição |
|---|---|---|
| `relay` | Sim — se peer está em `can_receive_from` do destinatário | Verifica trust do peer, não só o próprio |
| `advise` | Sim — se hub está em `can_advise_to` do próprio | E peer em `can_receive_from` |
| `correct` | Bloqueado por padrão | Exige `can_correct_to` preenchido + intermediação do core |

### Para seus adotados T2 (downstream)

| Ação | Autorizado? | Condição |
|---|---|---|
| `relay` | Sim — se T2 está em `exposes_downstream` | Hub é emissor natural para seus T2s |
| `advise` | Sim | |
| `correct` | Sim — hub tem autoridade sobre seus T2s | |

## Regras de relay — O que um hub pode RECEBER

### Do core (T0)

Sempre autorizado. O core pode enviar para qualquer membro.

### De peers T1

| Condição | Resultado |
|---|---|
| Peer está em `trust.can_receive_from` deste hub | Autorizado |
| Peer NÃO está em `can_receive_from` | Bloqueado — log de tentativa + exit 1 |

### De seus T2 (adotados)

Sempre autorizado — T2 pode enviar feedback ao seu parent T1.

## Classificações visíveis

O que um hub pode ler de outros membros:

| Origem | Classificações acessíveis |
|---|---|
| Core (T0) | `public`, `collective` (sem acesso a `protected` do core) |
| Peers T1 autorizados | `public`, `peer` (se em `diary_readable_by` do peer) |
| Seus T2 | `public`, `protected` (hub é parent, equivale ao T0 para seus T2s) |
| T3 standalones | `public` apenas |

## O que um hub NUNCA expõe para seus adotados T2

- Diário `private` e `protected`
- Sessões de desenvolvimento (`.claude/sessions/`)
- Sinais recebidos do core ainda não processados (inbox em triagem)
- Dados de negócio dos próprios projetos do hub
- `members.yaml` completo — T2 vê apenas sua própria entrada + entrada do parent

## O que um hub pode expor para seus T2

- Comandos customizados do hub (via escopo limitado do `/meta:adopt`)
- Entradas de diário com `classification: downstream`
- `personality.md` com classification `public`
- KBs construídas pelo hub para distribuir downward

## Invariants do adapter hub

1. Trust bidirecional com peers é sempre explícita — sem inferência
2. Relay para peer: verificar AMBOS (self.can_advise_to + peer.can_receive_from)
3. Correção para peer: bloquear por default; intermediação do core como trust broker
4. Downstream (T2): hub tem autoridade, mas T2 mantém soberania local (private inviolável)
5. I3 respeitado: hub escreve só em si; relay = cópia sem commit no destinatário
