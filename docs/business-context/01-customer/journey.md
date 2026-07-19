# Jornada do Cliente

**Última Atualização:** 2026-07-19

Ciclo do adotante do Onion — descoberta → adoção → federação → advocacy. Adaptado à natureza do produto (framework instalável, não SaaS). Marcado `[INFERIDO]` onde não há campo ainda.

---

## Descoberta (awareness)

- **Gatilho:** dor de contexto perdido / drift / retrabalho com IA no dev; ou desconforto com "vibe coding" (["vibe coding is dead", 2026](https://byteiota.com/spec-driven-development-kills-vibe-coding-march-2026/)). `[INFERIDO]`
- **Fontes:** boca-a-boca / rede do maestro (treinamentos, consultoria) + **a porta pública `onion-standalone`** (aberta 2026-07-19 — a instância adotável do framework para Claude Code; o core `onion-evolve` segue privado). O hub `marciocar/onion` aponta o dev solo p/ ela.
- **Perguntas do prospect:** "isso é mais um repo de comandos?" "o que muda vs Claude Code puro / Spec Kit / Agent OS?"

## Avaliação

- **Critérios:** prova de valor rápida no próprio repo; diferença real vs alternativas; não virar lock-in.
- **Objeções comuns:** "já tenho CLAUDE.md" · "SDD é waterfall de novo?" ([contraponto Fowler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)) · "é só pra Claude Code?".
- **Prova (proof point):** o **"aha" do mini** — apontar no repo do prospect e gerar os 3 contextos, mostrando onde a decisão se perdia + efeito medido (40%↓erro, 55%↑veloc — Anthropic). Ver `strategy.md` §Modelo comercial.

## Adoção (onboarding)

- **Caminho técnico:** `/meta:adopt` (durável ou efêmero, faseado retomável) → `/warm-up` → primeiro workflow (`/engineer:start` ou `/product:collect`).
- **1º marco de sucesso:** primeiro ciclo faseado retomável concluído (plan→pr) OU os 3 contextos vivos no repo.
- **Ponto de confusão comum:** entender as 3 dimensões peer; qual comando/agente usar (mitigado por `/onion`). `[INFERIDO]`

## Standalone (o degrau grátis — dev solo) `[reframe 2026-07-19]`

- **O que é:** adotar a porta pública → o framework **completo** rodando no repo do dev solo (as 3 dimensões
  + ferramentas de trabalho + KG soberano), **sem federação**. É o "texto" dado de graça — o hábito que fixa
  (MOAT/advocacy), não uma cobrança.
- **1º marco:** primeiro ciclo faseado retomável concluído (plan→pr) OU os 3 contextos vivos + o 1º `.kg.yaml` próprio.
- **Objetivo de negócio:** **não** é conversão em volume (D5: solo não sustenta volume) — é dogfood de campo,
  advocacy e o funil que alimenta os leads de ORG (P3/P4) que passam por aqui como demo.

## Crescimento / Federação (o upsell — empresa/hub) `[reframe 2026-07-19]`

- **Gatilho de expansão (land-and-expand):** a **chegada do MULTI** — 2º repo local adotado OU 2ª pessoa
  commitando/precisando sincronizar. Não é "usar mais"; é o uso virar **organizacional**.
- **Expansão:** standalone → **hub** (federação: sync multi-repo, bundles por squad, sub-adoção) — a rede que
  nenhum concorrente copia. **Ou** standalone → consumer (re-parenteia a um hub).
- **Uso avançado:** `/meta:evolve` (auto-auditoria — core), federação multi-repo, escrever doutrinas próprias.
- **Sinal de cliente saudável:** repo ativo, contexto fresco (`/meta:context-freshness`), participa do fluxo core↔adotante.

## Advocacy / Churn

- **Advocacy:** adotante cujo dogfood de campo acha+corrige bug do core (ex.: gustavo-pulga achou o bug #303) — o maior sinal de valor.
- **Risco de churn:** contexto apodrece (STALE); drift do core sem migração; complexidade sem o "aha". `[INFERIDO]`
- **Retenção:** curadoria SOTA contínua + federação que devolve valor destilado (o flywheel — ver `strategy.md`).

---

_§template: o adotante reescreve os gatilhos/objeções/marcos com a jornada dos seus próprios clientes._
