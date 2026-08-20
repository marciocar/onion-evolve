---
kg: docs/evolution/research/librechat-kg-runtime-2026-08/librechat-kg-runtime-2026-08.kg.yaml
run_id: "inline-2026-08-20 (sem fan-out — a evidência veio do campo, não de exploração)"
tokens: 0
agents: 0
duration_min: 20
---

# F4b — KG-SSOT first/map/runtime dentro do LibreChat

> Fonte é o grafo ao lado (radar exit 0). Aberta pelo gatilho REAL: o 1º agente com MCP
> (assistente-pdi/PoC) **alucinou** `skills/kg-ssot/SKILL.md` e concluiu que a capacidade não
> existia — o maestro nomeou a tese: *"não adianta levar o assistente sem levar o KG-SSOT-first
> e o runtime SDAAL"*.

## O que o campo provou

1. **Sem a perna KG, o agente não degrada gracioso — nega a capacidade.** Ele inventa um
   caminho, o caminho falha, e a conclusão vira "isso não existe". A doutrina tem de viajar
   **com** o agente.
2. **O padrão já existe do lado do servidor**: o MCP da PoC ingere texto→grafo→radar (rc=0) e
   navega o caso pelo grafo. O que faltava era o **lado do agente** saber disso.

## O desenho (as 3 pernas)

- **read(KG)** = tools do MCP do domínio (navegar/radar/consultar) + **instructions com a
  disciplina read-first** (consultar antes de afirmar estado; citar nó; nunca inventar caminho)
  + **skill always-apply via skillSync** como transporte da doutrina (o repo já é fonte viva).
- **map** = pipeline de ingestão DO SERVIDOR (como `ingerir_documento_colado`) — nunca o agente
  montando grafo à mão no chat.
- **write(KG)** = **proposta, nunca escrita direta cross-repo (I3)**: ou a tool de write vive no
  servidor que É dono do repo (caso PoC), ou a proposta entra em fila que o dono sela (o padrão
  da federação com outro transporte). O "memory" nativo do LibreChat **não** é destino de
  conhecimento — fonte paralela é o anti-padrão.

## Próximo concreto (gated, gatilho = ordem do maestro)

**MCP `onion-kg` read-only** (F6.3): kg_radar/kb_search/diary/inventory em streamable-http, no
padrão do assistente-pdi — dá aos agentes do core a perna que a PoC já tem. O precedente de
rede/allowlist já foi pago (mcpSettings + regra ufw cirúrgica).
