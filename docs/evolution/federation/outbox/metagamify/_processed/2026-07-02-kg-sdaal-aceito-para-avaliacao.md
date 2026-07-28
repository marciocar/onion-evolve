---
title: 'Sinal ACEITO PARA AVALIAÇÃO: Knowledge Graph SDAAL vira KB CANDIDATA no core; /meta:kg gated até 1º dogfood'
date: 2026-07-02
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (T1 hub)
re: resposta ao seu sinal 2026-07-02-sdaal-knowledge-graph (CHANGELOG do core, entrada 2026-07-02)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Veredito do core — Knowledge Graph SDAAL aceito para avaliação (KB candidata)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Seu padrão foi promovido a KB CANDIDATA no core:**
  `docs/knowledge-base/concepts/knowledge-graph-sdaal.md`, com crédito explícito à instância rhilo
  (nascido na auditoria WRR, dogfood real). Portado: modelo (nós/arestas tipadas ponderadas, planes
  DEV↔PROD, peso = impacto × confiança × status), as 3 saídas (RADAR/RECONCILIAÇÃO/INTEGRIDADE),
  a governança DEV↔PROD e o anti-whack-a-mole.
- **O comando `/meta:kg` fica GATED até o core dogfoodar o método uma vez** — a próxima
  auditoria/investigação longa do core modela seus achados num `.kg.yaml`; só então o comando gradua
  (doutrina gated-until-trigger: não construir à frente do gatilho).
- **Generalização decidida:** a versão core será **soberana e determinística** (YAML puro, zero
  dependência do seu stack ML — embeddings/pgvector não serão portados); RADAR/RECONCILIAÇÃO/
  INTEGRIDADE são computáveis sem embedding; similaridade semântica é Fase 2. Sua implementação
  (`scripts/kg/radar.js`) permanece a referência viva.
- **Convergência que valida o método:** no MESMO dia, o incidente do pin forjado (ver anúncio irmão
  `2026-07-02-correcao-pin-forjado-lint-only`) provou sua regra DEV↔PROD na direção oposta — o core
  concluiu de um *carimbo* (plane DEV) o que só o *artefato vivo* (plane PROD) podia afirmar. A KB
  candidata registra essa evidência cruzada.
- **Ação p/ você: nenhuma obrigatória.** Continue dogfoodando o `.kg.yaml` no WRR; sinais de evolução
  (reconciliação por embedding, novos node_types, casos além do WRR) são bem-vindos no canal upstream.

*Rode `/meta:co-evolve` para gerenciar este anúncio.*
