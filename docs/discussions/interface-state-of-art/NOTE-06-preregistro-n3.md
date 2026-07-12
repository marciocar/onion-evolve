---
title: "Nota 06 — Pré-registro do dogfood N≥3 (o critério declarado ANTES de minerar)"
category: discussion-preregistration
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
responde: SEED next_action (o portão N≥3) — a trava anti-HARKing que a NOTE-02 disse faltar
metodo: pré-registro (declarar critério e análise antes dos dados; anti-multiple-comparisons)
---

# 🧵 Nota 06 — Pré-registro do dogfood N≥3

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> **Pré-registro:** os critérios abaixo estão FIXADOS **antes** de rodar as sessões. Qualquer critério mudado depois
> dos dados é **exploratório, não confirmatório** — e deve ser marcado como tal. É o antídoto ao "minerar até algo
> parecer significativo" (NOTE-02: a máquina de falso-padrão — múltiplas comparações, Texas sharpshooter).

## 1. A distinção que o pré-registro fixa (o achado do refutador)

O `next_action` do SEED conflava duas coisas. Elas são **legs diferentes** e se provam diferente:

| Leg | Pergunta | Método | O que N≥3 faz |
|---|---|---|---|
| **Leg-1 — observar** | o *loop* é observável? (o diferenciador NS1) | detectar **recorrência** de atrito em N sessões | **é isto** que N≥3 prova |
| **Leg-2 — validar** | os 3 invariantes são **corretos**? | **intervir** (redesenhar um gate *com* o invariante) e **re-medir** | N≥3 **não** prova; é estudo à parte |

**Consequência de honestidade:** mesmo um N≥3 bem-sucedido **não promove os invariantes** — só prova que o loop
observa. Os `R_*` seguem candidatos até a leg-2. Confundir isso seria dizer "medi" o que só "vi".

## 2. Leg-1 — pré-registro da recorrência

**Sinais declarados** (só estes entram na detecção — nada de pescar no telemetry inteiro):
- `tool_decision` **reject-rate** (aceite/rejeição de Edit/Write = retrabalho direto);
- `claude_code.tool.blocked_on_user` (tempo esperando gate) — **interativo-only** (NOTE-05 achado A: em headless flatlina);
- **repeated-span / loops** (repetição de padrão de passos = "travei aqui").

**Critério de recorrência (limiar, fixado):** um *span-pattern de atrito* conta como **candidato** se aparecer em
**≥3 sessões interativas INDEPENDENTES** (tarefas distintas, não a mesma repetida), cada aparição acima do baseline
da própria sessão (reject-rate > 0 no span, ou `blocked_on_user` no topo do quartil da sessão).

**Descoberta ≠ confirmação (anti-HARKing):** as **3 sessões que geram** o candidato **não** o confirmam. Exige-se
**≥1 sessão held-out** onde o mesmo span-pattern reaparece **sem** ter sido usada pra formulá-lo. Logo: **N≥3 vira
N≥4** (3 descobrem + ≥1 confirma).

**Análise declarada (a ordem, fixada):** (passo-0) **filtro de prefixo** `claude_code.*` / `gen_ai.*` — o substrato é
ruidoso (NOTE-05 achado B) → sem filtro não há análise; (passo-1) baseline por-sessão; (passo-2) detecção de
recorrência **só** sobre os 3 sinais declarados; (passo-3) held-out.

## 3. Leg-2 — pré-registro da validação de cada invariante (intervir + re-medir)

Cada invariante exige uma **intervenção com baseline**, não observação. Declarado antes:

- **`R_GATE_CAMADAS`** (gate em camadas por risco): desenhar um gate auto/soft/hard por risco → **confirma** se
  `blocked_on_user` cai vs um baseline de gate-plano **E** nenhum veto é perdido; **refuta** se não muda ou o veto degrada.
- **`R_EXIBIR_SKIP_GATEAR_VETO`** (+ o recorte do refutador): testar o modo-de-falha — quando o *display que alimenta
  um gate* (evidence-pack) degrada, ele **skipa** (ruim) ou **veta**? **Confirma** o recorte "input-de-gate degrada veto"
  se o gate segura mesmo com o display quebrado.
- **`R_FORMATIVO`** — o refutador achou auto-contradição (o loop **precisa** de tendência no tempo). Teste da
  **resolução**: uma tendência *formativa* (`blocked_on_user` ao longo do tempo) ajuda **sem** induzir gaming
  performático? **É o mais fraco** — difícil medir gaming com N=1; marcado **deferido**.

**Nota:** leg-2 é um estudo **maior** que N≥3 — precisa das intervenções + baselines. N≥3 (leg-1) é **pré-requisito**
(você precisa dos sinais-baseline antes de intervir).

## 4. O refutador obrigatório

Qualquer candidato que passe o critério → um agente com mandato único de **quebrá-lo**: explicação alternativa,
artefato de múltiplas-comparações, ou "é o atrito do Marcio, não um padrão". Só sobrevive o que resiste.

## 5. Limites honestos (declarados, não descobertos depois)

- **Intra-órbita:** 3 sessões *do Marcio* têm independência **fraca** (atritos correlacionados). N≥4-Marcio prova
  "o padrão de atrito do Marcio", **não** um padrão geral. É o mesmo limite da veredito F3. Um cold-adopter seria a
  independência real (gated).
- **N pequeno → overfitting:** o held-out mitiga, não elimina. Preferir confirmar **menos** candidatos com mais rigor.
- **Leg-2 é outro estudo:** não prometê-lo dentro do N≥3.

## 6. O harness (engatilhado, pra rodar quando o maestro tiver sessões interativas)

Reusa a NOTE-05: `otlp_sink.py` (~50 linhas, sem deps, escuta `127.0.0.1:4318`) + `CLAUDE_CODE_ENABLE_TELEMETRY=1`
+ `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1`. **Interativo** (não `-p` headless — senão `blocked_on_user` flatlina).
Conteúdo **OFF** (`OTEL_LOG_USER_PROMPTS` não setado — intake=estrutura). Filtro de prefixo é passo-0.

## 7. O que "promover os invariantes" exige (o gate honesto)

Leg-1 (N≥4, recorrência confirmada + refutada) prova **o loop observa** → move o diferenciador NS1 de design pra
medido. Os **invariantes** só promovem depois da **leg-2** (intervenção + re-medida). Até lá, `R_*` seguem
candidatos — e isso está **certo**.
