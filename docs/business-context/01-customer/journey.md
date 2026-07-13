# Jornada do Cliente

**Última Atualização:** 2026-07-13

Ciclo do adotante do Onion — descoberta → adoção → federação → advocacy. Adaptado à natureza do produto (framework instalável, não SaaS). Marcado `[INFERIDO]` onde não há campo ainda.

---

## Descoberta (awareness)

- **Gatilho:** dor de contexto perdido / drift / retrabalho com IA no dev; ou desconforto com "vibe coding" (["vibe coding is dead", 2026](https://byteiota.com/spec-driven-development-kills-vibe-coding-march-2026/)). `[INFERIDO]`
- **Fontes:** hoje boca-a-boca / rede do maestro (treinamentos, consultoria). Sem canal público ativo (`onion-evolve` é privado).
- **Perguntas do prospect:** "isso é mais um repo de comandos?" "o que muda vs Claude Code puro / Spec Kit / Agent OS?"

## Avaliação

- **Critérios:** prova de valor rápida no próprio repo; diferença real vs alternativas; não virar lock-in.
- **Objeções comuns:** "já tenho CLAUDE.md" · "SDD é waterfall de novo?" ([contraponto Fowler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)) · "é só pra Claude Code?".
- **Prova (proof point):** o **"aha" do mini** — apontar no repo do prospect e gerar os 3 contextos, mostrando onde a decisão se perdia + efeito medido (40%↓erro, 55%↑veloc — Anthropic). Ver `strategy.md` §Modelo comercial.

## Adoção (onboarding)

- **Caminho técnico:** `/meta:adopt` (durável ou efêmero, faseado retomável) → `/warm-up` → primeiro workflow (`/engineer:start` ou `/product:collect`).
- **1º marco de sucesso:** primeiro ciclo faseado retomável concluído (plan→pr) OU os 3 contextos vivos no repo.
- **Ponto de confusão comum:** entender as 3 dimensões peer; qual comando/agente usar (mitigado por `/onion`). `[INFERIDO]`

## Crescimento / Federação

- **Expansão:** de 1 repo dogfood → múltiplos repos co-evoluindo via federação (contratos + doc-bridge).
- **Uso avançado:** `/meta:evolve` (auto-auditoria), federação multi-repo, escrever doutrinas próprias.
- **Sinal de cliente saudável:** repo ativo, contexto fresco (`/meta:context-freshness`), participa do fluxo core↔adotante.

## Advocacy / Churn

- **Advocacy:** adotante cujo dogfood de campo acha+corrige bug do core (ex.: gustavo-pulga achou o bug #303) — o maior sinal de valor.
- **Risco de churn:** contexto apodrece (STALE); drift do core sem migração; complexidade sem o "aha". `[INFERIDO]`
- **Retenção:** curadoria SOTA contínua + federação que devolve valor destilado (o flywheel — ver `strategy.md`).

---

_§template: o adotante reescreve os gatilhos/objeções/marcos com a jornada dos seus próprios clientes._
