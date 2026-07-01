# Trust SDAAL — Adapter: source (TIER 0)
# Regras de confiança para o core (onion-evolve).
# RFC-0003 §2.1 + §2.5

## Identidade

```
role: source
tier: 0
parent: (nenhum)
```

O core é a autoridade emissora. Não tem parent. Não tem peers com acesso igual.
Todo o know-how do core é protegido por papel — não por concessão em trust_topology.

## Regras de relay

### O que o core pode ENVIAR

| Destino | Ação | Autorizado? | Condição |
|---|---|---|---|
| Qualquer membro | `relay` | Sim | Membro existe em members.yaml |
| Qualquer membro | `advise` | Sim | Membro existe em members.yaml |
| Qualquer membro | `correct` | Sim | (core tem autoridade implícita) |

O core pode iniciar relay para qualquer membro sem verificação adicional de trust_topology —
é a autoridade emissora. O maestro humano decide o conteúdo; o script decide o transporte.

### O que o core pode RECEBER

| Origem | Ação | Autorizado? | Condição |
|---|---|---|---|
| Qualquer membro | `relay` | Sim (inbox) | Qualquer instância pode enviar para inbox do core |
| Qualquer membro | `advise` | Sim | O core sempre escuta |
| Qualquer membro | `correct` | Sim | O core avalia correções sem bloqueio automático |

O core tem inbox aberto — qualquer instância pode enviar sinal. O core tria via `/meta:co-evolve`.

## Classificações visíveis

O core pode ler qualquer classificação de qualquer membro:
```
private    → Não (nem o core lê private de outro — respeito à privacidade local)
protected  → Sim (core está em diary_readable_by de qualquer membro bem configurado)
peer       → Sim (core tem visão global)
downstream → Sim
public     → Sim
collective → Sim (core é o sintetizador)
```

**Exceção importante:** `private` é imutável — nem o core lê entradas private de outros.
A privacidade local é inviolável.

## O que o core NUNCA expõe

- Sessões de desenvolvimento (`.claude/sessions/`) — efêmero e privado
- Diário privado (`.claude/diary/*.md` sem share_with) — soberano
- Análises internas não publicadas (`docs/analysis/` — só após PR merged)
- Inbox de co-evolução de outros repos (chegou via relay, permanece confidencial no core)
- `.env` (regra global, jamais)

## O que o core expõe proativamente

- `docs/knowledge-base/` — public para todos os membros
- Changelog co-evolução (`docs/evolution/CHANGELOG-co-evolve.md`)
- Comandos/agentes/skills via `/meta:adopt`
- `personality.md` (quando criado via `/meta:personality-sync`) — public

## Invariantes do adapter source

1. Sem trust_topology própria — o core lê tudo por papel
2. Inbox sempre aberto — any member → core inbox → core tria
3. Soberania local (`private` inviolável mesmo para o core)
4. Escreve apenas em si mesmo — I3 respeitado
