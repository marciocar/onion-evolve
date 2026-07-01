# Trust SDAAL — Adapter: consumer (TIER 2)
# Regras de confiança para adotados de hub (consumer-de-hub).
# RFC-0003 §2.1 + §2.5

## Identidade

```
role: consumer
tier: 2
parent: <hub-id>   # um hub T1 específico — não o core diretamente
```

Um consumer adotou um hub T1, não o core diretamente. O hub é seu intermediário natural
e filtro de contexto. O consumer não sabe o que há acima do hub — e isso é intencional.

## Regras de relay — O que um consumer pode ENVIAR

### Para seu parent hub T1

| Ação | Autorizado? | Condição |
|---|---|---|
| `relay` (sinal/diário) | Sim | Sempre — T2 envia feedback natural ao seu parent |
| `advise` | Sim | |
| `correct` | Bloqueado por padrão | T2 não corrige T1 sem concessão explícita do hub |

### Para o core (T0)

Bloqueado. Consumer não acessa o core diretamente.
Se precisar enviar algo ao core: passa pelo hub (que decide se encaminha ou não).

### Para outros consumers T2 ou standalones T3

Bloqueado sempre. Consumer não tem visibilidade lateral.

## Regras de relay — O que um consumer pode RECEBER

### De seu parent hub T1

Autorizado — hub decide o que expõe downward (entradas `classification: downstream`).

### Do core (T0)

Não diretamente. O core pode enviar para o hub, que decide se propaga ao T2.
O consumer não tem canal direto com o core.

### De outros consumers T2 ou standalones T3

Bloqueado sempre.

## Classificações visíveis

O que um consumer pode ler:

| Origem | Classificações acessíveis |
|---|---|
| Parent hub T1 | `downstream`, `public` (o que o hub expõe explicitamente) |
| Core (T0) | `public` apenas (filtrado via hub) |
| Outros membros | Nenhuma |

**Nota importante:** um consumer não sabe quais outros membros existem além do seu parent e do core.
O `members.yaml` que o consumer vê contém apenas sua entrada + entrada do seu parent.

## O que um consumer NUNCA vê

- Diário `protected` e `peer` do seu hub
- Sessões do hub
- Internos do core
- Qualquer coisa de outros T1s, T2s ou T3s

## Relação com o hub

O hub age como um filtro e protetor do consumer:
1. O hub decide o que chega ao T2 (política `exposes_downstream`)
2. O hub agrega e adapta o contexto do core antes de repassar
3. O hub é o único ponto de contato upstream do T2

Esta relação espelha o padrão de microserviços com API gateway:
o consumer não sabe o que há atrás do gateway — e é mais seguro assim.

## Configuração mínima de trust

```yaml
trust:
  can_receive_from: [<parent-hub-id>]    # só o parent
  can_advise_to: [<parent-hub-id>]       # pode aconselhar o parent
  can_correct_to: []                     # não corrige por padrão
  diary_readable_by: [<parent-hub-id>]   # parent pode ler PROTECTED
  diary_classifications_shared: [public] # compartilha public com parent
  exposes_downstream: []                 # T2 não tem downstream
```

## Invariants do adapter consumer

1. Canal único: T2 ↔ parent T1 apenas; sem acesso direto ao core
2. Parent T1 é o único ponto de trusted contact
3. Visibilidade mínima — só downstream + public do parent
4. Soberania local preservada — private inviolável mesmo para o parent
5. I3 respeitado: escreve só em si
6. Sem conhecimento da topologia global — o consumer não sabe quem mais existe
