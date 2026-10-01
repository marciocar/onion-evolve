---
kg: docs/evolution/research/motores-de-regras-deterministicos-2026-10/motores-de-regras-deterministicos-2026-10.kg.yaml
run_id: wf_fcfb94bc-f30
tokens: 9183465
agents: 132
duration_min: 87
review_after: 2027-01-01
---

# Motores determinísticos em 2026 — e por que o gate do Onion NÃO migra

## A resposta primeiro

**Não migrar.** O que transfere é a **capacidade**, não o substrato. O estado da arte confirmado é de
motores de **AUTORIZAÇÃO** — `permit`/`forbid`, decisão pura, ordem-independente **por projeto**. As
guardas do Onion não só decidem: **produzem artefato**, **dependem de ordem**, e precisam do `exit 2`
de hook que nenhum motor entrega.

## O que o campo tem, e vale copiar sem adotar

| capacidade | evidência |
|---|---|
| **análise estática de conflito** | Cedar reduz política a SMT com codificação **sólida, completa e decidível**; prova equivalência e acha o request que um conjunto permite e o outro nega (~75 ms, número de 2024 — pode estar superado) |
| **teste diferencial spec↔implementação** | o Rust do Cedar é diferenciado contra o **modelo em Lean**, imposto pelo CI — **25 bugs** que review e teste unitário não pegaram |
| **verificar o verificador** | **SymCert (FMCAD 2026)** verifica a própria análise, porque erro na camada de verificação corrompe em silêncio |

## Mercado: o dinheiro mudou de lugar

- **Apple fez acquihire** dos fundadores e equipe da **Styra** (mantenedora do OPA); Apache-2.0 e
  governança CNCF **inalteradas**
- **Cedar entrou no CNCF Sandbox** (InfoQ, 01/2026) — hyperscaler doando a linguagem para governança neutra
- **AWS pôs Cedar no caminho crítico de dois produtos de agente**: Policy do Bedrock AgentCore (05/2026)
  e autorização multi-agente com Cedar em Lambda separada (07/2026)
- **entrantes na categoria agente/MCP**: Permit.io MCP Gateway, **Sondera (Cedar em hooks de Claude
  Code, Cursor, Copilot, Gemini CLI)**, ToolHive, ScopeBlind, Vectimus

**A leitura:** o dinheiro visível é de **plataforma** e de **talento**, não venture em motor de regras.
O valor migrou de *vender o motor* para **usar o motor como coleira de agente**.

## NÃO-VERIFICADOS, e esta lacuna importa

**O lado clássico voltou VAZIO**: Drools, Camunda/DMN, OpenL, json-rules-engine, Easy Rules, NRules,
Clara, GoRules BRMS — **nenhuma claim sobreviveu**. Licença, cadência e sinal de vida **não medidos**.
Logo: **não há resposta sobre substituto do ZEN nesta rodada.** O maestro selou "não agora" em
2026-10-01; a lacuna fica com gatilho — reabre se o adotante de gamificação sinalizar dor real.

**Sem sinal de capital** em: rodada/valuation/ARR de qualquer fornecedor de motor; aquisição de empresa
(só o acquihire); relatório de analista de casa sobre motores de decisão.

## valeu-a-pena

9.183.465 tokens ÷ 32 nós = **~287k por nó**. Faixa de varredura, e cara. O que se comprou: a resposta
de NÃO-migrar com razão de categoria, as duas capacidades transferíveis, e o achado de mercado que
originou a rodada do produto bilhetável. O que NÃO se comprou: o lado clássico, que seguiu vazio.
