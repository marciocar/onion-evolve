---
title: "Onion Evolution Backlog — 2026-10-04"
date: 2026-10-04
kg: docs/evolution/research/evolve-round-2026-10/evolve-round-2026-10.kg.yaml
run_id: wf_9cba4ab5-0ac
tokens: 2122103
agents: 31
duration_min: 9
---

# Onion Evolution Backlog — 2026-10-04

> **Projeção do grafo** [`evolve-round-2026-10.kg.yaml`](../evolution/research/evolve-round-2026-10/evolve-round-2026-10.kg.yaml).
> Divergiu, o grafo ganha. Primeira rodada desde 2026-07-30 (66 dias) e a primeira com a superfície
> re-forjada (6/7) e o gatilho da REGRA 97 (A auto-auditoria do framework tem GATILHO).

## 0. Sumário

◆ Dimensões: 7 de varredura (D1 D2 D3 D6 D7 D8 + MAQ) + D9 e D10 no contexto principal
◆ Padrão: pipeline (varredura → verificação adversarial por dimensão, sem barreira)
◆ Workers: 31 · 0 erros · tier: D1/D3/D7/D8 haiku/low · D2/D6 sonnet/medium · MAQ e juízes opus/high
◆ Custo: 2.122.103 tokens de subagente · ~9,4 min · Run ID `wf_9cba4ab5-0ac`

**46 achados devolvidos → 24 julgados → 14 refutados ou vetados → 32 sobreviventes**
(4 blocker · 6 recommended · 22 opportunistic).

**Cortes declarados, nunca silenciosos:** D2 11→8 · D3 23→8 · D7 49→8 · MAQ 16→8. O que ficou fora
não foi julgado, e isso fica dito aqui.

**Não rodado nesta rodada:** D4 (KBs vencidas) e D5 (conformidade de metaspec). A composição da
superfície (`runCommand()`) nunca existiu, e invocá-los de dentro do evolve seria orquestração
aninhada. Ficam como lacuna, **nunca como zero**.

## 1. Backlog priorizado

| # | Sev | Dim | Achado | Esforço | Atuador |
|---|-----|-----|--------|---------|---------|
| 1 | 🔴 | MAQ | `/meta:create-skill` **executa `git diff` a cada invocação**: dois exemplos de documentação são lidos como diretiva viva (l.86, l.219). Viaja para adotante | S | escapar os exemplos |
| 2 | 🔴 | MAQ | **O raio-X publica 2 alvos falsos**: o hook de carga não dispara para skills, e a census as conta como "nunca casou" | S | census: skill = `NAO-MEDIVEL` |
| 3 | 🔴 | MAQ | O checkpoint do `/meta:drive` vive em `STATE.md` **gitignorado**, e o P0.5 é **só prosa** — nenhum script o lê | M | checkpoint para o grafo + `CHECKPOINT-PENDENTE` |
| 4 | 🔴 | D7 | Link morto em `client-material-doctrine.md:114` (3 níveis onde são 4) | S | corrigir o caminho |
| 5 | 🟡 | MAQ | `FindingSchema` do evolve **não é JSON Schema**, e o `allowed-tools` não lista `Workflow`/`Agent` | M | peça 4: `.claude/workflows/evolve.js` |
| 6 | 🟡 | MAQ | Quatro símbolos fantasmas no Passo 3 (`runCommand` ×3 e `sweepSessionMemory`) | S | D4/D5/D9/D10 como passos do contexto principal |
| 7 | 🟡 | MAQ | O extrator da REGRA 59 lê **mensagem de `violation`** como invocação de produção | S | descartar linhas de mensagem no `_pairs` |
| 8 | 🟡 | D1 | `/meta:adopt` com **799 linhas** (teto 800) e `/meta:kg` com 519 | L/M | fatiar |
| 9 | 🟡 | D2 | Quatro artefatos de validação contra metaspec; só um declara a distinção | S | declarar escopo ou marcar alias |
| 10 | 🟢 | MAQ | As lentes casam o **artefato** que o comando produz, não a **invocação** dele | S | census separa `NUNCA` de `RECÉM-NASCIDA` |

## 2. Achados no contexto principal

- **D9 não é no-op no core.** A superfície afirma *"no framework = no-op (contextos são templates)"*.
  Medido: `business-context` tem 15 arquivos e `technical-context` tem 9, populados. A premissa é
  falsa; o D9 deveria rodar aqui.
- **D10: o índice da memória passava do limite de carga** (29.034 bytes contra 24,4KB) e o harness
  cortava o fim a cada sessão. **Curado na hora**: 78 ganchos encurtados, 23.501 bytes, zero
  ponteiros quebrados. O teste de validade por entrada não foi feito.
- **D6: nenhum vazamento de provider medido.** Positivo — e ausência de defeito só vale quando medida.

## 3. Alerta sistêmico

**Texto que cita um comando é lido por um mecanismo como a própria invocação.** Seis sítios, cinco
mecanismos (lint, harness, extrator da REGRA 59, resolvedor de baseline, regex do binário): três
curados hoje por instância, **três vivos**. A cura de classe proposta é uma guarda com um simulador
das regex do próprio harness rodando sobre commands, skills e plugins.

## 4. Invariantes respeitadas

- Nenhuma proposta funde fases de `engineer/*` ou `product/*` (verificado pelos juízes:
  `vetoed_phase_merge` falso em todos os veredictos).
- A rodada não mutou `.claude/`. A única escrita fora de `docs/` foi a memória de sessão (exceção do D10).

## 5. Próximos passos

Em ordem de dano e custo: (1) escapar os exemplos do create-skill · (2) o link morto · (3) a census
e o raio-X para skills · (4) o checkpoint do drive no grafo · (5) a peça 4 do evolve · (6) a guarda
de classe para documentação lida como invocação · (7) a premissa do D9 · (8) D4/D5 numa próxima
rodada, no contexto principal.
