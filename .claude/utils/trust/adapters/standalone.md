# Trust SDAAL — Adapter: standalone (TIER 3)
# Regras de confiança para instâncias standalone.
# RFC-0003 §2.1 + §2.5

## Identidade

```
role: standalone
tier: 3
parent: source (onion-evolve)
sem sub-adotados
```

Um standalone adota o core diretamente mas não tem (e não terá) sub-adotados.
É a instância mais simples — relação direta com o core, sem responsabilidades downward.

## Regras de relay — O que um standalone pode ENVIAR

### Para o core (T0)

| Ação | Autorizado? | Condição |
|---|---|---|
| `relay` (sinal/diário) | Sim | Sempre — qualquer membro pode enviar para o core |
| `advise` | Sim — se em `can_advise_to: [onion-evolve]` | Requer concessão explícita |
| `correct` | Sim — se em `can_correct_to: [onion-evolve]` | Requer concessão explícita |

### Para hubs T1

| Ação | Autorizado? | Condição |
|---|---|---|
| `relay` | Bloqueado por padrão | T3 não tem acesso lateral a T1 sem concessão |
| `advise` | Bloqueado por padrão | |
| `correct` | Bloqueado | Sempre — T3 não corrige T1 |

### Para outros standalones T3

Bloqueado sempre. T3 não tem visibilidade de outros T3.
Não sabem da existência dos outros (members.yaml não é exposto para T3).

## Regras de relay — O que um standalone pode RECEBER

### Do core (T0)

Autorizado. O core pode enviar para qualquer membro.

### De hubs T1

Bloqueado por padrão — T3 não está no fluxo downstream de nenhum T1 (a menos que T1 declare
explicitamente este T3 em `exposes_downstream` — o que é raro e exige justificativa).

### De outros standalones T3

Bloqueado sempre. T3s são isolados entre si.

## Classificações visíveis

O que um standalone pode ler:

| Origem | Classificações acessíveis |
|---|---|
| Core (T0) | `public`, `collective` apenas |
| Hubs T1 | `public` apenas (se hub publicar explicitamente para T3) |
| Outros T3 | Nenhuma — isolamento total |

## O que um standalone NUNCA vê

- Diários de outros standalones (qualquer classificação)
- Internos de centrais (protected, peer, downstream)
- `members.yaml` completo — vê apenas sua própria entrada + entrada do core
- Sessões de qualquer outra instância

## Relação com o core

O standalone tem a relação mais simples e direta:
1. Adota o core via `/meta:adopt`
2. Recebe updates via changelog co-evolução
3. Envia sinais/diários de volta ao core (inbox aberto)
4. Não gerencia peers, não tem trust topology complexa

## Configuração mínima de trust

```yaml
trust:
  can_receive_from: [onion-evolve]       # só o core
  can_advise_to: [onion-evolve]          # pode aconselhar o core
  can_correct_to: []                     # por padrão, não corrige
  diary_readable_by: [onion-evolve]      # core pode ler PROTECTED
  diary_classifications_shared: [public, collective]
  exposes_downstream: []                 # T3 não tem downstream
```

## Invariants do adapter standalone

1. Sem relay lateral (peer-to-peer) — toda comunicação passa pelo core
2. Sem sub-adotados — a instância decidiu não ser hub
3. Visibilidade mínima — só public do core; protegida de ver internos de outros
4. Soberania local preservada — private inviolável mesmo para o core
5. I3 respeitado: escreve só em si
