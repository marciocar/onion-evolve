---
title: "Revisão — escada de modelos com piso visível e comandos sem model: (D_COMANDOS_SEM_MODEL_OU_NO_LINEUP: piso Sonnet + opção A)"
date: 2026-09-03
branch: feat/model-ladder-commands-without-model
reviewer: "condutor com dogfood EXECUTADO: 6 transições da guarda à mão + família model_ladder 7/7 (guarda, aviso, REGRA 70, REGRA 71, sonda com claude falso) + lint real limpo nas duas regras; binário 2.1.259 lido (tier 10) para o fallback nativo"
reviewed_diff_sha256: 33324e0d9c6fa17a6c24339c967f901e9141e7d86e684b61feaf58a36e40d4d6
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 250000
duration_min: 60
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Selo do maestro: **piso Sonnet sim, opção A**. A pergunta dele antes de selar ("Fable tem acesso limitado mesmo no MAX; tem que
haver fallback e reorganização quando surgem modelos") virou mecanismo, não prosa.

## Achados

1. **A plataforma já tem fallback nativo, mas só por sobrecarga** (binário: `fallbackModel` em lista, `--fallback-model`,
   `FallbackTriggeredError reason=overloaded`, headers `x-cc-fallback-*`); não há fallback por COTA. Logo a escada da casa é a
   SSOT (`session_models` + `session_floor`) e `settings.json:fallbackModel` é PROJEÇÃO dela — REGRA 70 (HARD, paridade).
2. **Piso só por fallback, nunca pelo `/model`**: a guarda veta `picker→piso` nomeando o piso e permite `fallback→piso` com
   `ladder=degraded` e aviso; `session-degraded-notice.sh` repete o aviso a cada prompt até `restored`. Degradar é permitido;
   degradar calado não. Testado nas 6 transições (fable↔opus, fable→sonnet por picker/fallback, sonnet→fable, fable→haiku).
3. **109 comandos sem `model:`** (REGRA 71 HARD, template e skill `onion-patterns` atualizados); agentes mantêm o tiering.
   Antes desta mudança, em 2.1.259, 96 comandos viravam pedido de downgrade a cada invocação (radar E3, l.17).
4. **Reorganização é 1 arquivo**: REGRA 65 dispara a rodada E6 → `ops/model-lineup-probe.sh` prova o acesso por degrau
   (ok|denied|timeout, TSV + jsonl, exit 1 se algum nega) → edita-se a escada → lint projeta → guarda lê.
5. **Lacunas declaradas** (nó E_LACUNAS, item 6): o fallback nativo emite PreModelSwitch? com qual `source`? (a guarda assume
   `source != picker` = fallback); e o comportamento quando a cota do Fable fecha no Max — só medição humana em sessão nova.
   Hook novo (`session-degraded-notice`) exige sessão nova para disparar.
6. **O lint contradizia a si mesmo e o gate pegou**: a REGRA 23 (Frontmatter: `model:` em comandos e `category:` em agentes) EXIGIA
   `model:` em comando (auditoria 2026-07-04) — o oposto da 71. Aufhebung: a 23 fica só com a metade de agente (título e `previne:`
   dizem que a metade de comando foi revogada pela 71); as duas fixtures de comando inverteram de papel no manifest. Provado no
   sandbox: comando sem `model:` = 0 citações; comando com `model:` = REGRA 71.
