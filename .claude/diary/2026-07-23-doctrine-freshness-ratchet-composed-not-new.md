---
date: 2026-07-23
instance: onion-evolve
type: innovation
classification: collective
tags: [doctrine-freshness, gate, ratchet, temporal, provenance, composition, dogfood]
affects: [meta, engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Ao adicionar uma KB world-facing nova (versão/lineup/teto sensível ao tempo), acrescentar o path a DEFAULT_WORLD_FACING em doctrine-freshness.sh + verified_at/source no frontmatter no mesmo commit — nunca deixar acumular passivo fora do baseline. Adotantes que rodarem --update HERDAM o gate; sem baseline emitido do filesystem deles, ele nasce reprovando o passivo alheio (mesmo risco documentado na REGRA 29 — semear baseline é passo obrigatório do anúncio, não opcional)."
review_after: 2026-10-21
conflict_class: conditional
valid_when: "o gate continua checando só presença+idade de verified_at (nunca tentando confirmar a verdade da afirmação contra a rede em CI)"
significance: "Quase nada aqui é novo — a REGRA 42 é composição de três peças que a casa já tinha (STALE do radar, catraca da 29, clock-untrusted do a2a-verify) — e é exatamente essa economia que a torna barata de manter e fácil de confiar."
---

## Signal
**REGRA 42 é o irmão temporal da REGRA 29** — 29 fecha "conhecimento nasce FORA do grafo" (eixo espacial);
42 fecha "doutrina world-facing que EXPIROU EM SILÊNCIO" (eixo temporal). Ambas são `declarado != verificado`
— uma contra o grafo, outra contra o relógio. E ambas usam a MESMA catraca: baseline que só encolhe,
passivo tolerado vira SOFT, novidade sem tag vira HARD.

## Evidence
- **Mecanismo:** `.claude/validation/doctrine-freshness.sh`, commit `44d7e05` (2026-07-23). Doutrina em
  `docs/knowledge-base/concepts/onion-guardrails.md` seção 8 (a 29 está na seção 7).
- **O limite declarado explicitamente:** o gate NÃO pergunta "esta afirmação ainda é verdade?" — isso
  seria NO-OP num runner de CI sem rede. Ele verifica que toda afirmação sensível-ao-tempo carrega
  `verified_at` + `source` no frontmatter e não passou do TTL (90 dias default), FORÇANDO re-verificação
  periódica. Quem re-verifica de fato é `/meta:kb-freshness` / a sessão — nunca o gate. CI-safe e
  determinístico por construção.
- **Composição, não invenção — três peças reusadas:**
  1. `verified_at` STALE-OLD do kg-radar, generalizado de NÓ de grafo para AFIRMAÇÃO de doutrina em prosa.
  2. A catraca da REGRA 29 (granaai, seção 7): passivo → baseline tolerado (SOFT); novo sem tag → HARD;
     baseline só encolhe.
  3. O guarda `clock-untrusted` do `a2a-verify.sh`: "recente" só vale com relógio provado (NTP) — sem
     prova, a checagem de idade degrada para SOFT em vez de fingir frescor.
- **Dois níveis, honestos sobre qual é mecânico:** Nível A (HARD) — lista world-facing enumerada e
  auditável (4 KBs iniciais: agent-orchestration, context-window-optimization, ai-agent-design-patterns,
  claude-code-commands-best-practices-2026). Nível B (SOFT-only) — rede lexical por token-gatilho, honesta
  sobre ser frágil (pega o que a lista dura ainda não enumerou, sem reprovar).
- **Quatro pressupostos enumerados e testados** (regra de admissão da casa): a lista world-facing, o TTL,
  o relógio, o baseline — cada um coberto por caso no `lint-selftest.sh`.

## Next crumb
Ver `next_recommended`. A REGRA 42 nasceu e no MESMO DIA passou pelo primeiro uso real — ver
[[runflow-doctrine-freshness-proves-value-day-one]]. Origem do achado que pariu o gate:
[[doctrine-fades-declared-not-verified]].
