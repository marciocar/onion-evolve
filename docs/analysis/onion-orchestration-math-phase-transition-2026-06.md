---
title: "Matemática de dimensionamento de orquestração — o paper de transição de fase aplicado ao Onion (jun/2026)"
date: 2026-06-21
type: analysis
status: proposed / living
authority: mapeamento + leitura crítica; sem decisão executável (insumo p/ /meta:evolve e p/ a doutrina de orquestração)
research: arXiv:2601.17311 (verificado via web, jun/2026) + arXiv:2604.02460 (suporte empírico)
last-review: 2026-06-21
next-review-trigger: "se quisermos critérios de aceite NUMÉRICOS p/ judge-panel · OU calibrar N_max de panel por modelo · OU nova evidência empírica sobre s>β"
relates:
  - ./onion-orchestration-external-radar-2026-06.md
  - ./onion-orchestration-topology-adr-2026-06-21.md
  - ../knowledge-base/concepts/agent-orchestration.md
---

# Matemática de dimensionamento de orquestração — o paper de transição de fase aplicado ao Onion

> **Natureza:** nota de análise **viva**. Aprofunda o item 🟡 MATH do
> [radar de orquestração](./onion-orchestration-external-radar-2026-06.md). Lê o paper com fundamento, mapeia
> honestamente o que se aplica ao Onion e o que **não** se aplica, e recomenda **sem absoluto**.

## 1. Contexto — o paper foi VERIFICADO

O radar parqueou a matemática como **não verificada**, com um pré-requisito: confirmar o paper antes de
aprofundar. **Cumprido (2026-06-21):**

- **Paper:** *"Phase Transition for Budgeted Multi-Agent Synergy"* — **arXiv:2601.17311** (Bang Liu,
  Université de Montréal & Mila; Linglong Kong, Alberta; Jian Pei, Duke; jan/2026). Fórmulas conferidas
  no HTML (`arxiv.org/html/2601.17311v1`).
- **Suporte empírico irmão:** **arXiv:2604.02460** — "Single-Agent LLMs Outperform Multi-Agent Systems
  on Multi-Hop Reasoning Under Equal Thinking Token Budgets".

A descrição trazida pela conversa externa era **fiel**. O que segue corrige o status "não verificado" e
extrai o que de fato serve ao Onion.

## 2. As fórmulas (fiéis ao paper) — e a ressalva de escopo

> ⚠️ **Escopo do modelo (decisivo):** os teoremas valem para **tarefas binárias (sucesso/falha) com
> agregação por MAIORIA** em árvores b-árias. **Não** é um modelo do fan-out geral. Ler tudo abaixo
> dentro desse escopo.

- **Restrição de fan-in.** Estrela: `N·m ≤ W` (fan-in ≤ `⌊W/m⌋`). Árvore: `b·m ≤ W` *local* por nó
  agregador → `N = b^L` folhas em profundidade `L`. (m = tamanho da mensagem; W = janela.)
- **Transição de fase (Thm 4).** Escalar único
  `α_ρ := γ(m)·[ρ + (1−ρ)·f_b'(0)]`, onde `f_b'(0) = b·C(b−1, (b−1)/2) / 2^{b−1}` (inclinação da
  maioria no sinal fraco), `γ(m) ∈ (0,1]` = fidelidade do canal, `ρ ∈ [0,1)` = correlação de erro
  compartilhado. Recursão `μ_{t+1} = f_{b,ρ}(γ·μ_t)`.
  - `α_ρ ≤ 1` → **colapso**: viés μ→0 (vira acaso).
  - `α_ρ > 1` → **amplifica** a um ponto fixo μ* ∈ (0,1).
- **Sinergia orçada (Thm 5).** Expoente de organização `s := log_b(α_ρ)`. Scale-out (mais agentes em
  árvore) supera o melhor agente único **sse `s > β`** (β = expoente de escala compute→performance do
  agente único). Alocação ótima (Thm 9): se `t > β`, ótimo interior `x* = [β/(t−β)]·c_0` com
  `c_0 = 2m·b/(b−1)`; se `t ≤ β`, **gastar todo o orçamento num agente mais forte**.
- **Mixing depth / saturação (Eq 13).** Existe profundidade útil finita: além dela, mais folhas quase
  não ajudam — o piso é `v* = σ_c²(m) / [(b−1)(1−ρ)]`. Só baixa reduzindo `ρ` ou aumentando `γ`.

## 3. Mapeamento honesto Onion ↔ paper

| Resultado do paper | Aplica ao Onion? | Onde / como |
|---|---|---|
| `α_ρ>1` amplifica vs `α_ρ≤1` colapsa | **SIM — precisamente no judge-panel** | O judge-panel do Onion (N céticos, voto — `onion-orchestration/SKILL.md:43-45`, `agent-orchestration.md:254-274`) **é** uma agregação por maioria binária. O paper o modela diretamente. |
| `s > β` (scale-out vs scale-up) | **SIM — lente do gate "orquestrar ou não"** | Quantifica o gate de acoplamento já existente (`SKILL.md:23-27`). O irmão arXiv:2604.02460 dá suporte empírico ao "quando `s ≤ β`, não orqueste — single-agent vence sob mesmo budget". |
| mixing depth / saturação | **SIM — teto racional ao panel** | "Mais juízes além de um ponto é desperdício, a menos que `ρ↓` ou `γ↑`" → limita o N do judge-panel; casa com o cap de 16 e com "completeness critic" sem inflar custo. |
| estrela satura em `W/m` | **PARCIAL** | **Não morde no orquestrador** (fan-in do Onion é JS a 0 token — ele não lê as N saídas). **Morde no nó sumarizador** quando a síntese é por LLM — é o `b·m ≤ W` do [ADR de topologia](./onion-orchestration-topology-adr-2026-06-21.md). |
| recursão de maioria binária | **NÃO — ao fan-out geral** | O fan-in comum do Onion é **dedupe/rank/merge** (não voto binário) sobre **workers heterogêneos**. Fora do escopo do modelo; não force a matemática aqui. |

## 4. As 3 lentes acionáveis

1. **Diversidade do judge-panel é requisito de CORREÇÃO, não estética.**
   `α_ρ = γ·[ρ + (1−ρ)f_b'(0)]`. Se os juízes são quase idênticos (mesmo modelo + mesmo prompt → `ρ→1`),
   então `α_ρ → γ ≤ 1` ⇒ o painel **não amplifica** — pode votar errado em consenso. O paper dá base
   formal à guidance que o Onion já tem ("perspective-diverse verify", lentes distintas): **baixar ρ**
   (modelos/prompts/lentes diversos) é o que move o painel para o regime amplificador `α_ρ>1`.

2. **`s > β` é a versão quantitativa do gate "orquestrar ou não".**
   A orquestração só compensa o multiplicador de custo quando o expoente de organização supera o de scale-up.
   Em tarefa acoplada (código, raciocínio sequencial) `s` é baixo → `s ≤ β` → **não orqueste**
   (single-agent com bom context-engineering vence). Confirma a postura opt-in do Onion + o irmão 2604.

3. **Mixing depth = teto racional do panel.**
   Aumentar juízes/profundidade tem retorno decrescente até um piso `v*`. Passar disso só ajuda se
   reduzir `ρ` (mais diversidade) ou aumentar `γ` (resumos menos lossy). Ou seja: **diversidade > número**.

## 5. Recomendação (sem absoluto)

- **Adotar QUALITATIVamente já (custo ~zero):** o paper **explica e justifica** duas coisas que o Onion
  já faz por heurística — a diversidade do judge-panel (`α_ρ`) e o gate orquestrar-ou-não (`s>β`).
  **Candidato diferido (não agora):** uma linha na doutrina de orquestração tornando explícito que *"a
  diversidade do panel (ρ baixo) é requisito de correção — painel homogêneo pode colapsar em consenso
  errado (α_ρ≤1)"*. Igual ao padrão do ADR de topologia: registrar a decisão, implementar quando aceito.
- **Manter QUANTITATIVO no radar 🟡:** calibrar `β, γ(m), ρ` empiricamente exige instrumentação que o
  Onion não tem (medir correlação de erro entre juízes, fidelidade por tamanho de resumo). Provavelmente
  **não vale** a complexidade no modelo spec-as-code. *Gatilho:* se quisermos critérios de aceite
  **numéricos** para judge-panel ou calibrar `N_max` de panel por modelo.

## 6. Limites do modelo (o que NÃO cobre)

- Só **tarefa binária + voto por maioria** — não modela dedupe/rank/merge, nem síntese sobre workers
  heterogêneos, nem `pipeline` sem barreira.
- `β, γ, ρ` são **parâmetros empíricos** — o paper dá a forma, não os valores do Onion. Sem medição, as
  fórmulas são **lente qualitativa**, não calculadora.
- Resultados assintóticos (árvores profundas) — o Onion opera em N pequeno (cap 16), onde efeitos de
  borda dominam o assintótico.

## 7. Log / revisibilidade

- **2026-06-21** — Nota criada ao aprofundar o eixo MATH do radar. Paper **verificado**
  (arXiv:2601.17311). Achado central: a teoria modela **precisamente o judge-panel** (binário+maioria),
  não o fan-out geral. 3 lentes extraídas; recomendação adotar-qualitativo / calibrar-quantitativo no
  radar. Para retroagir: editar com data + porquê.

## 8. Fontes

- **Primária (verificada):** *Phase Transition for Budgeted Multi-Agent Synergy*, **arXiv:2601.17311**
  (Liu, Kong, Pei, jan/2026). Fórmulas de `arxiv.org/html/2601.17311v1`.
- **Suporte empírico:** **arXiv:2604.02460** — single-agent vence multi-agent sob budget igual (multi-hop).
- **Canônico interno:** `onion-orchestration/SKILL.md` (judge-panel, gate, caps), `agent-orchestration.md`
  (doutrina), [ADR de topologia](./onion-orchestration-topology-adr-2026-06-21.md), [radar](./onion-orchestration-external-radar-2026-06.md).
