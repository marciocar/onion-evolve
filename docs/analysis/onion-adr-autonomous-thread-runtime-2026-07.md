---
title: 'ADR — Runtime de orquestração autônoma de fios: escada graduada de autonomia (Audit→Automate) com moat determinístico'
date: 2026-07-18
type: adr
status: accepted (degrau AUDIT) — o runtime foi MECANIZADO e dogfoodado em 2026-08-27 pelo /meta:drive (Censo `kg-drive-project.sh` #692 + laço `drive.md` #693; superação em `docs/onion/graph/drive-superacao-2026-08.kg.yaml`). Selado pelo maestro. ⚠️ Aceite QUALIFICADO: o dogfood exercitou a rota **research** + o laço P0-P6 completo (fio real conduzido ao checkpoint na catraca), NÃO a rota **execution→PR-verde** — essa e o lote completo se exercitam nos próximos drives reais. AUTOMATE (auto-merge) segue GATED (Fase 2)
decision-scope: co-evolution / autonomy (o core conduz os fios pendentes com autonomia graduada)
supersedes: none
extends:
  - onion-adr-work-models-session-topologies-2026-07.md (W6 responder-gated → escada graduada; usa o enabler git-nativo já armado)
  - onion-adr-comms-transport-vs-execution-2026-06.md (os 3 atos — a regra-núcleo que a escada não viola)
origin-signal: 'pedido do maestro 2026-07-18 ("conduzir ao máximo os fios de forma autônoma; rever cenários é mais barato que esperar minha decisão")'
deciders: maestro
related:
  - docs/evolution/research/autonomous-thread-runtime-2026-07/SYNTHESIS.md (padrões de 2026 — write(KG))
  - docs/onion/graph/autonomous-thread-runtime-2026-07.kg.yaml (o grafo, arestas SUPERSEDES)
  - onion-patterns/SKILL.md §"validação de doutrina" (o método que decidiu este contrato)
  - onion-adr-telescope-session-observation-2026-07.md (precedente "proposed/accepted — GATED até dogfood")
---

# ADR — Runtime de orquestração autônoma de fios

## Contexto

O maestro pediu **conduzir ao máximo os fios pendentes de forma autônoma** — "rever cenários é mais barato que
esperar minha decisão" — decidindo por **superação no KG-SSOT**, testando/adaptando pelas doutrinas do Onion.
Tensão a resolver: a doutrina é **responder-gated** (W6: atos 1-2 automatizam, **executar** gateia;
`onion-adr-comms-transport-vs-execution-2026-06.md:62-70`), e W7-cron foi **rejeitado**. Mais autonomia **não se
concede por decreto — se SUPERA contra o KG**, com o gate humano preservado onde o ato-3 vive.

**Pesquisa de 2026 (write(KG) em `research/autonomous-thread-runtime-2026-07/`):** autonomia é **escada graduada**
(Audit→Assist→Automate; "Automate é estado GANHO"); **merge decidido por política DETERMINÍSTICA, nunca por juízo
de IA**; earned trust. Coincide com os 3 atos + o toolbox-lifecycle (ASSESS→TRIAL→ADOPT) + `declarado≠verificado`.

**Decidido pelo padrão de validação** (`onion-patterns` §validação-de-doutrina): fan-out de lentes + pesquisa web
→ **verificação adversarial** (revisor `fable`, **10 furos reais** — 4 ALTA foram contradições internas) →
correções integradas → este ADR nasce **GATED**. O adversário **ganhou o dinheiro**; o contrato abaixo é o
pós-refutação.

## Decisão — a escada graduada de autonomia

- **Nível 0 — autônomo sempre:** atos 1-2 (transportar/`co-deliver` carteiro, notificar, escanear, gates
  mecânicos) · orquestração `Workflow` **budget-gated** · **propor** ato-3 · `write(KG)` com `SUPERSEDES` · atos
  reversíveis no próprio repo **em worktree própria** (branch, commit, abrir PR, dogfood). **Poda:** só o
  subconjunto **determinístico** `git branch --merged main` ∧ ausente de `git worktree list` ∧ local-only.
- **Nível AUDIT — o piso (batch-confirm), único ATIVO nesta rodada:** o runtime avança um fio a **PR verde**
  sozinho; **o merge no main é 100% humano**, revisado **em LOTE** num checkpoint. Preserva "revisão humana em
  todo merge".
- **Nível AUTOMATE — teto DESENHADO, GATED (não ativo):** auto-merge só destrava por **3 pré-condições duras**:
  1. **Enabler git-nativo** — branches `auto/*` + **branch protection** restringindo quem/o-quê mergeia (o gatilho
     que `work-models:80` já armou: "1ª automação que commite sem humano"). *Cabear, não escrever* (telescópio #10).
  2. **Path-allowlist mecânica** — `git diff --name-only ∩ manifesto-vendor = ∅`. O manifesto `want=` do
     `adopt.md` (`.claude/**`, `docs/knowledge-base`, `docs/meta-specs`, `docs/sdaal`) é **outward-facing**
     (chega nos adotantes via `--update`) → **AUDIT para sempre**. Elegível a AUTOMATE só: `docs/analysis`,
     `docs/evolution`, `docs/discussions`, `docs/onion`.
  3. **Política 100% mecânica** — CI verde + lint 0/0 + `kg-radar` exit 0 + cap de tamanho de diff. **Checks de
     LLM (`onion-review`, verificação adversarial) são VETO-ONLY** (fail bloqueia; pass ≠ base afirmativa —
     `silêncio=veto`). A verificação adversarial de um PR **nunca** é gradada pela instância que o autorou.
  Graduação de uma classe a AUTOMATE = toolbox-lifecycle, decidida pelo padrão de validação (adversário: "auto-merge
  desta classe abre brecha?").
- **Nível MOAT — nunca (a regra que nenhuma superação viola):** entregar/aplicar no adotante · escrever repo alheio
  (I3) · deploy · **merge de path vendorizado/outward/irreversível** · observar sessão viva sem `telescope:allowed`
  · selar doutrina sem dogfood · **agendar por relógio (W7)**. Sempre gate humano.

## O runtime (mecanismo)

Loop **invocado pelo maestro** (não auto-inicia no boot — o lazy-por-sessão sanciona atos 1-2, não começar
rebases sozinho), **budget-capped**, **retomável** (`resumeFromRunId`):
1. **Censo** — `gh pr list` + inbox + `git branch -a`/`worktree` + memória. Molde: `reconcile-inputs.sh`.
2. **Classificar** cada fio (Nível 0 / AUDIT / MOAT + reversível-determinístico?).
3. **Conduzir em worktree própria** (`~/worktrees/onion-evolve/<slug>/`); **`session-beacon.sh check` antes de
   qualquer switch**; nunca operar a branch checked-out do main. Dogfood cada fio.
4. **Checkpoint em LOTE:** PRs verdes + vereditos de triagem + poda-proposta + lista C-gated.

## Guardas de PARADA (invariantes do loop)
- **Max fios por passada** (teto explícito) · **max 1 passada por sessão sem confirmação** — nenhuma passada nova
  enquanto um checkpoint pende (senão o batch-confirm degrada em revisão post-hoc, o anti-padrão vendor rejeitado).
- **Abort-on-anomaly:** colisão de beacon · CI vermelho inesperado · verificação adversarial reprovada → **parar
  e reportar, NUNCA contornar** (retomar a fase quebrada, não racionalizar a jusante).
- **Loop sem budget é proibido** ("sem teto não há loop").

## Invariantes (o que a escada NUNCA faz)
- **Vendor ↛ AUTOMATE** (path-allowlist mecânica) — mudança que chega ao adotante é sempre AUDIT+.
- **Merge por política determinística, nunca por juízo de IA** (LLM = veto-only).
- **Main humano** nesta rodada; AUTOMATE só com o enabler git-nativo cabeado.
- **Worktree própria + beacon-check** (não colidir com a árvore/ sessões vivas — I3).
- **`declarado≠verificado`** · **selar só com dogfood** (este ADR nasce GATED; aceite no checkpoint da Fase 2).

## 1º dogfood (o gate) — REALIZADO 2026-08-27
A **Fase 2** (1ª passada, TRIAL no AUDIT) é o dogfood: conduz os fios reais a PR verde e produz **1 lote**. O
aceite do maestro nesse checkpoint **sela** este ADR (`proposed → accepted`). Sem esse dogfood, o contrato não sela.

**O que de fato aconteceu (behavior-over-declaration):** o runtime virou o comando `/meta:drive` (era prosa
neste ADR). O 1º drive real (`catraca --max-nodes 1`) conduziu um fio **end-to-end** — censo pegou
`Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES` (research, o mesmo que o `/meta:realign` flagara), avançou
(mediu as 5 classes), selou AUTO (append de evidência), checkpoint `kg-radar` rc=0 + `realign --check`
ALINHADO, **sem merge** (AUDIT respeitado). E o driver aplicou a **própria tabela de selagem a si mesmo**:
apendou a evidência e **parou no flip deste status** (`proposed→accepted`), porque status-de-verdade é
selo humano. O maestro selou. **Aceite qualificado:** provou a rota **research** + o laço; a rota
**execution→PR-verde** e o **lote completo** ficam para os próximos drives (achado #1 do resíduo
`feat-meta-drive-phase1.md`). AUTOMATE segue GATED.
