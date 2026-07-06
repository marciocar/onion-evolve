---
title: 'ADR — Vertical educacional (ensino & aprendizagem): F0 aberto sobre os confirmados da pesquisa SRL/PLEA'
date: 2026-07-05
type: adr
status: provisório (F0 aberto — camada de conhecimento fundada; construção gated)
decision-scope: meta / verticais / educação
supersedes: none
extends: onion-adr-exchange-unit-2026-06.md, onion-adr-verticals-investigation-cartography-2026-07.md
deciders: maestro + sessão de evolução
context_freshness: 2026-07-05
related:
  - docs/analysis/onion-research-srl-plea-2026-07.md (a evidência que funda a vertical)
  - docs/knowledge-base/education/srl-plea-doctrine.md (Tijolo 1 — entregue neste F0)
  - docs/analysis/onion-research-seed-hegel-dialectics-2026-07.md (pesquisa-irmã, fundação filosófica)
  - docs/analysis/onion-parecer-whatsapp-sender-2026-07.md (§4-C — eixo messenger gated, amarrado à Q3)
---

# ADR — Vertical Educacional (`onion-education`)

> **Status: PROVISÓRIO (F0 ABERTO em 2026-07-05).** O maestro decidiu abrir a vertical de ensino
> & aprendizagem sobre os **achados confirmados** da pesquisa SRL/PLEA (entregue no mesmo dia,
> com verificação adversarial). Este ADR registra a rampa; **só a camada de conhecimento é
> construída agora** — o resto é gated, como manda a doutrina anti-v4.0.

## Contexto

Diferente das verticais anteriores, esta nasce com **três vantagens raras**: (1) fundação
**verificada** — 11 achados da pesquisa SRL/PLEA, com vereditos e fontes primárias; (2) **demanda
real imediata** — os materiais educacionais do maestro (pulse-mais-2026) são campo de dogfood
vivo; (3) **alerta de evidência embutido** — o risco nº 1 do domínio já é conhecido (a "preguiça
metacognitiva": IA genérica melhora a tarefa sem gerar aprendizagem — RCT BJET 2025).

## Decisão — rampa gated

| Fase | O quê | Gatilho | Estado (2026-07-05) |
|---|---|---|---|
| **F0** | Este ADR + camada de conhecimento: categoria `docs/knowledge-base/education/` com a doutrina SRL/PLEA classificada ([srl-plea-doctrine.md](../knowledge-base/education/srl-plea-doctrine.md)) | decisão do maestro | ✅ **aberto/entregue** |
| F1 | **Dogfood de campo**: aplicar a doutrina num artefato educacional real — candidato nº 1: o guia do aluno pulse-mais reescrito pela lente PLEA (estrutura de fases embutida + avaliação forçada) | sessão do maestro no material | ⏳ gated |
| F2 | Agentes/comandos que o F1 revelar necessários (candidatos hipotéticos: `@learning-designer`, `@srl-coach`) — **só se o uso pedir** | fricção real documentada no F1 | ⏳ gated |
| F3 | Manifesto `onion-education.manifest.sh` → plugin no marketplace | ≥2 artefatos maduros (critério que graduou design/compliance) | ⏳ gated |

## Diretrizes vinculantes (derivadas da evidência, não de opinião)

1. **Estrutura de fases SRL embutida** em todo artefato educacional da vertical — o ingrediente
   ativo do andaime (SRLAgent; confiança medium, replicação pendente).
2. **Anti-preguiça-metacognitiva**: artefato educacional NUNCA entrega resposta sem forçar
   avaliação/reflexão do aprendiz (o análogo pedagógico do juiz adversarial) — Fan et al. 2025.
3. **Rótulos honestos**: manter a separação fato-CONFIRMADO vs analogia-PLAUSÍVEL do relatório em
   todo material derivado (o "declarado ≠ verificado" aplicado à pedagogia).
4. **Prompts móveis sem promessa**: a Q3 (mensageria autorregulatória) está ABERTA — nada de
   messenger pedagógico até a rodada dedicada + gatilho do eixo SDAAL (parecer whatsapp §4-C).

## Capability draft (vira `capability.json` só na F3)

```json
{
  "provides": ["srl-plea-doctrine", "educational-artifact-design-guidelines"],
  "requires": ["kb:education/srl-plea-doctrine"],
  "loads": ["when:educational-design -> kb:education/srl-plea-doctrine"],
  "conformance": "bronze-alvo-inicial"
}
```

## O que NÃO fazemos agora

Nenhum agente, comando, template ou plugin — F1 primeiro (dogfood no material real do maestro).
Nenhuma promoção a 4ª dimensão peer — vertical é **capacidade**, não dimensão (critério
dono×ritmo×decisão do `architecture.md §8` não está em jogo).

## Histórico

| Data | Mudança |
|---|---|
| 2026-07-05 | F0 aberto: ADR + KB `education/srl-plea-doctrine` fundada sobre os 11 achados verificados |
