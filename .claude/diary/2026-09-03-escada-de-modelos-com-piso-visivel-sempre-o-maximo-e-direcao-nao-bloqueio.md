---
date: 2026-09-03
instance: onion-evolve
type: decision
classification: public
tags: [modelos, lineup, fallback, guarda, doutrina, tiering]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "medir em sessão NOVA: /warm-up sem model: roda no modelo da sessão; e o que a plataforma faz quando a cota do Fable fecha (lacuna 6 do E3)"
review_after: 2026-12-02
conflict_class: static
kg: docs/evolution/research/radar-E3-2026-09-03/radar-E3-2026-09-03.kg.yaml
---

## Signal
O maestro trouxe a questão certa antes de podar os `model:` dos comandos: *"o Fable tem acesso limitado mesmo no plano MAX;
tem que haver opção de fallback e mecanismo de reorganização quando modelos novos surgem"*. Decisão selada: **piso Sonnet sim,
opção A** (comandos sem `model:`). A doutrina "sempre o máximo" passa a ser DIREÇÃO com escada, não bloqueio.

## Evidence
- O binário 2.1.259 tem fallback nativo (`fallbackModel` em lista, `--fallback-model`, dispara em sobrecarga 529) — mas não por
  COTA de plano. A escada da casa (`session_models` + `session_floor`) é a SSOT; `fallbackModel` é projeção dela (REGRA 70),
  para a plataforma nunca cair fora da guarda.
- Guarda PreModelSwitch: piso só por fallback (pelo `/model` = veto nomeando o piso); `ladder=degraded|restored` no log; aviso a
  cada prompt enquanto degradado (hook `session-degraded-notice.sh`). Degradar é permitido; degradar CALADO não.
- 109 comandos perderam `model:` (REGRA 71): em 2.1.259 o frontmatter passou a valer em sessão interativa e 96 `sonnet` viravam
  pedido de downgrade a cada invocação. Tiering fica nos agentes, onde é legítimo.
- Reorganização quando surge modelo novo: REGRA 65 dispara a rodada E6 → `ops/model-lineup-probe.sh` prova o acesso por degrau
  → edita-se UM arquivo → lint projeta → guarda lê.

## Next crumb
Lacuna 6 do E3: o fallback nativo emite PreModelSwitch e com que `source`? A guarda assume `source != picker` = fallback. E o
comportamento na cota fechada é medição humana.
