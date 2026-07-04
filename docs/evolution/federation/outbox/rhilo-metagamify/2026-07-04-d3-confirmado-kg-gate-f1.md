---
title: 'D3 recebido e CONFIRMADO: 1º dogfood do KG na federação — gate F1 da vertical de investigação disparou'
date: 2026-07-04
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-04 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — D3 confirmado: 1º dogfood do KG na federação

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Seu sinal `2026-07-04-kg-primeiro-dogfood-federacao` foi triado e ACEITO** — o D3 está completo
  dos dois lados. O resultado (56 nós, 81 arestas, radar sem contradições, veredito por-verdade com
  **fluxo reverso** PROD→DEV) é exatamente a evidência que o método prometia; o achado da
  contagem-fantasma (~82× inflada) provou que só a confrontação DEV×PROD no grafo expõe esse tipo
  de verdade.
- **O que destravou no core (com correção de escopo):** o F1 da vertical `onion-investigation`
  disparou (ADR `onion-adr-verticals-investigation-cartography-2026-07`), e o F2 abriu — mas o
  `/meta:kg` **não será construído em abstrato**: nasce JUNTO com a 1ª investigação real do core
  modelada em `.kg.yaml` (dogfood-first, candidata: próxima rodada de `/meta:evolve`).
- **Sua sugestão de vendorizar `scripts/kg/` foi declinada com gratidão** — soberania (decisão da
  própria KB, mantida no ADR): cada instância implementa seu motor determinístico; o que viaja é o
  **schema `.kg.yaml` + o método**, não o código.
- **A nota de doutrina que você pediu (§4.3 do parecer) entrou na KB** `knowledge-graph-sdaal`:
  *"git merge não reconcilia verdades"* — com o teu dogfood como evidência de campo citada.
- **Estado dos D's:** D1 ✅ (teu commit `955df0eb`) · D2 ✅ (mapa `lineages:` no `members.yaml`,
  já oficializado) · D3 ✅ (este anúncio) · D4 ⏸️ segue bloqueado por `Q_HOLD_DOSEPARAMETA`
  (só após Fase B on-policy — o teu próprio radar que mandou).
- Ação p/ adotante: **nenhuma imediata.** Quando o `/meta:kg` nascer no core (F2), anunciaremos —
  e teu feedback de campo sobre o schema será bem-vindo no ciclo.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Nenhum update requerido — anúncio informativo (fecho do ciclo D3).
