---
date: 2026-07-18
instance: onion-evolve
type: decision
classification: collective
tags: [autonomy, runtime, graduated-ladder, moat, thread-conduction, superseding, validation-pattern]
affects: [meta, co-evolution, orchestration]
breadcrumb_for: []
share_with: [granaai, metagamify]
next_recommended: "Continuar o backlog do runtime (ingestor ITEM2/S4, G1 do method-adopter); AUTOMATE (auto-merge) segue gated até o enabler git-nativo cabeado."
review_after: 2026-10-15
conflict_class: static
---

## Signal
O core pode **conduzir fios pendentes de forma autônoma** por uma **escada graduada de autonomia**, e a lição
é: **mais autonomia não se concede por decreto — se SUPERA contra o KG**, com o gate humano preservado onde o
**ato-3 (executar)** vive. A escada: **Nível 0** (atos 1-2 + propor + write(KG) + reversível-own-repo-em-worktree,
autônomo) · **AUDIT** (avança a PR verde sozinho; merge no main é humano, em LOTE — o piso) · **AUTOMATE** (auto-merge
own-repo, teto GANHO/GATED por 3 pré-condições) · **MOAT** (entregar-adotante/repo-alheio/vendor-outward/irreversível/W7
= nunca). O maestro encolhe para **aprovar lotes**, não N perguntas — "rever cenários é mais barato que esperar decisão".

## Evidence
- ADR: `docs/analysis/onion-adr-autonomous-thread-runtime-2026-07.md` (proposed→accepted no 1º lote/#426).
- Fundamentado em padrões de 2026 (Audit/Assist/Automate, merge por política DETERMINÍSTICA não juízo-de-IA,
  earned trust — `docs/evolution/research/autonomous-thread-runtime-2026-07/`, write(KG) com `SUPERSEDES`) + as
  doutrinas Onion (3 atos `onion-adr-comms-transport-vs-execution:62-70`; W6/W7 `onion-adr-work-models`; toolbox-lifecycle).
- **Refutado adversarialmente (fable): 10 furos, 4 ALTA eram contradições internas do meu rascunho** — vendor=outward,
  auto-merge-vs-main-only, LLM-na-política-determinística, enabler-git-nativo-ignorado. O padrão de validação
  (`onion-patterns` §validação-de-doutrina) é o motor de qualidade da superação.
- 1ª+2ª passadas: #426-#430 conduzidos autônomo (contrato · reconcile · federation-radar · outbox-hygiene · adopt-S3B).

## Next crumb
Rodar o runtime: **censo** (`gh pr list` + inbox + `git branch/worktree` + memória) → **classificar** cada fio
(Nível0/AUDIT/MOAT + reversível-determinístico?) → **conduzir em worktree própria** (`session-beacon.sh check`
antes de todo switch; nunca a branch checked-out do main) → **1 LOTE** (PRs verdes + vereditos + poda-proposta +
C-gated). **AUTOMATE só destrava** com: enabler git-nativo (`auto/*` + branch protection) + path-allowlist
(`git diff ∩ manifesto-vendor = ∅`; `.claude/**`/`docs/knowledge-base` = AUDIT pra sempre) + política 100%
mecânica (LLM = veto-only). **Guardas de parada:** max-fios/passada · 1-passada/sessão-sem-confirmação · abort-on-anomaly.
