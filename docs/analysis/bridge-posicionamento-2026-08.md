---
title: "Bridge — posicionamento e corte DO/DEFER/DROP (proposta ao gate G1)"
date: 2026-08-14
category: analysis
status: selado-g1-2026-08-14
kg: docs/evolution/research/bridge-produto-2026-08/bridge-produto-2026-08.kg.yaml
run_id: wf_f6c09d35-8a7
---

# Posicionamento do Onion Bridge — proposta ao G1

> Projeção do grafo (evidência: 148 findings, 15 lentes; nós `E_*` do KG). O maestro sela.

## A posição proposta

**"O cockpit honesto de um agente que roda de verdade."** Não competir com Open WebUI em
volume de features (149k★, plataforma-tudo), nem com OpenClaw em onipresença (agente no
mensageiro): o Bridge é a superfície onde se **vê** a orquestração real — tool-calls com
resultado, raciocínio, custo por turno com cache-write, comandos e agentes nomeados — com
**KG-SSOT temporal + Elenxo** como diferencial defensável (Zep/Graphiti bi-temporal vence
Mem0 por +30%; Cognee/Supermemory levantaram capital apostando em grafo externo — o mercado
validou a nossa arquitetura). O concorrente mais próximo é o **Mission Control** (6k★ em 6
meses, control-plane sobre Claude Code/Codex): a diferenciação KG+Elenxo precisa ficar
**visível na UI**, não só na doutrina.

## O corte proposto

### DO (agora, nas fases já aprovadas)
1. **F0 inteiro** — apoiado pelo único dado comportamental quantitativo do dossiê: sessões
   sem progresso visível teriam **3× a taxa de abandono** (E_PROGRESSO_VISIVEL_3X_RETENCAO —
   conf 0,5, vendor citando terceiro sem metodologia; a própria lente pede cautela; vale pela
   triangulação com as dores C3, não como fato duro). PR-03 (tool-results + reasoning) é a cura.
2. **Aprovação GRANULAR de ferramenta** (novo, sobe de prioridade): o backlash do Auto Mode
   (14/08, fresco) provou que aprovação binária tudo-ou-nada quebra confiança. Canal de
   permissão no backend (canUseTool → SSE → decisão no chip) + allowlist por ferramenta.
   Entra como **PR-03b** na F0/F2 — e é pré-requisito honesto para um dia sair de
   `bypassPermissions`.
3. **Multi-conversa server-side (F2)** — table-stake unânime nos players
   (E_MULTICONVERSA_TABLE_STAKE). [Retificado no 10º Elenxo: a issue #8928 citada como dor
   viva foi fechada em 2025-01-31 — o DO se sustenta pela unanimidade, não pela dor.]
4. **Quota nativa por usuário/org (F4)** — REBAIXADA a table-stake
   (E_QUOTA_GAP_FECHADO_ABRIL_2026): o Open WebUI fechou as issues de cota como completed
   entre 2024 e abr/2026 — o "gap de 3 anos" venceu. Continua DO (produto multi-seat exige e
   o meter já grava), mas NÃO se vende como gap do concorrente.
5. **Auth como P0 testável** — OIDC quebrou 3× em releases do Open WebUI; nosso `oidc.ts`
   é ativo maduro: ganha teste de regressão na bancada do PR-06b.
6. **Licença honesta como posicionamento** — compromisso público simples desde o dia 1
   (o "open-washing" do Open WebUI após 6 trocas de licença é a lacuna de confiança mais
   barata de capturar). Uma seção no README do bridge.
7. **Dark mode, anexos PDF/text, shiki, i18n pt-BR** (F3 como planejado).

### DEFER (registrado com gatilho, não agora)
1. **Generative UI further-than-inline** — tensão não resolvida (desejada em pesquisa
   >70% vs precedente Office rejeitado). Fica: blocos inline mínimos (assistant-ui nativo)
   na F3; UI que se remonta por sessão NÃO. Gatilho: padrão amadurecer nos players.
2. **Canal mensageiro (tese OpenClaw)** — complementar, não substituto: a casa já tem
   pesquisa WhatsApp/a2a. Gatilho: pós-G5, como canal de divulgação adicional.
3. **Notebook fonte-fundamentado (NotebookLM-like)** — é a direção do Company Brain (F6),
   não do chat. Entra no programa Brain.
4. **Realtime multi-user (presença/co-edição)** — eixo do Company Brain; o dossiê nem o
   cobriu (teto declarado). Programa Brain.
5. **Pricing/packaging** — piso de mercado $20/seat + BYOK mapeado (E_PRICING_PISO_20_SEAT); a decisão
   é do fio D5-pricing (gated, maestro).

### DROP (não fazer, com a evidência do porquê)
1. **Competir em RAG-plataforma** (embeddings de 60k arquivos) — os memory-leaks do Open
   WebUI mostram o beco; nossa aposta é grafo estruturado, não blob semântico.
2. **Voz full-duplex/realtime** — sem sinal de dor no nosso ICP; Web Speech atual basta.
3. **Sync em background no PWA iOS (Personal Brain no bolso via PWA)** — **impossível por
   arquitetura** (teto duro: cache ~50MB, eviction 7 dias, zero Background Sync). O Brain
   mobile futuro exige wrapper nativo — decisão do programa Brain, não deste.
4. **Ressuscitar convites/token compartilhado** — P11 é definitivo; identidade é a porta.

## Tetos do dossiê (o que esta proposta NÃO sabe)
Latência dos concorrentes não medida · postura de compliance deles não auditada · Reddit
triangulado por fontes secundárias (crawler bloqueado) · colaboração realtime não coberta ·
Android sub-coberto · custo operacional de KG multi-tenant citado e não quantificado.
Nós `E_TETOS_DA_PESQUISA` no KG.
