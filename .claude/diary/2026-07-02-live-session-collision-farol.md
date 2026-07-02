---
date: 2026-07-02
instance: onion-evolve
type: error
classification: public
tags: [work-models, w1, w3, i3-invariant, session-beacon, cross-repo]
affects: [meta, federation, co-evolution]
breadcrumb_for: [meta:adopt, meta:co-deliver, meta:co-relay, meta:co-evolve]
share_with: [collective]
next_recommended: "2026-07-02-forged-pin-false-announcement"
review_after: 2026-09-30
---

## Signal
Na primeira operação W1 real (sessão do core operando o rhilo por path), fiz `git checkout` na
working tree do alvo **com uma sessão W2 viva lá** (auditoria WRR em outra branch). **I3 "um
escritor por repo" inclui sessões vivas, não só commits** — `git status` limpo não prova posse
livre da working tree; a branch corrente é contexto de quem está trabalhando.

## Evidence
- A sessão de auditoria do rhilo se viu em `develop` com 130 arquivos alheios não-commitados
  (meu update em trânsito); protegeu-se sozinha (trabalho salvo em `e6f85a5a`, backup do doc
  untracked) e devolveu a decisão ao maestro — comportamento W6 exemplar do outro lado.
- Nada se perdeu, mas só por disciplina da outra sessão — o risco era real (o ADR work-models
  tinha sido escrito HORAS antes sem prever colisão de working tree).
- Cura de raiz (mesmo dia): **farol de sessão** — `session-beacon.sh` (up/refresh/down/check/sweep,
  git-invisível via `.git/info/exclude`) + hook nos 3 eventos de ciclo de vida + aviso 🕯️ no boot
  quando há outra sessão viva; 7 guardas no lint-selftest (105→112). ADR work-models §7 (adendo).

## Next crumb
Antes de checkout/escrita na working tree de repo alheio: `session-beacon.sh check <repo>` — exit 1
= parar e coordenar com o maestro. Entrega em `inbound/` (untracked) dispensa o check. O farol é
sinal, não trava: stale não bloqueia, o gate é humano. Regra irmã de "pin é hipótese"
(2026-07-02-forged-pin-false-announcement): estado declarado ≠ posse verificada.
