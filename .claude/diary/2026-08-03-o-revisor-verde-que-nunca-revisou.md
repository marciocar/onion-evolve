---
date: 2026-08-03
instance: onion-evolve
type: learning
classification: collective
tags: [behavior-over-declaration, ci, soft-pass, fixture-confirma-premissa, onion-review]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-01
conflict_class: dynamic
valid_when: "o onion-review segue usando claude-code-action com execution_file como único sinal de veredito"
significance: "O onion-review tinha retry E aviso de soft-pass — máquina completa, comentada em 3 blocos — condicionados a um sinal que NUNCA dispara; 11 PRs mergearam num dia sob um revisor que não leu nada, e o CI dizia verde o tempo todo."
---

## Signal

Máquina de resiliência **condicionada ao sinal errado é indistinguível de máquina ausente** — e
custa mais caro, porque o comentário no código promete a proteção que não existe. Ao ler
`is_error`/`outcome`/`status` de um wrapper, confirme **onde o fato mora**: o exit code do
invólucro e o veredito do agente são coisas diferentes. E ao escrever fixture para um formato que
você não leu, você testa a sua premissa, **não a realidade**.

## Evidence

- `onion-review.yml` tinha retry (`review2`) e aviso de soft-pass (annotation + comentário no PR),
  ambos gated em `steps.review.outcome == 'failure'`. **Nenhum dos dois disparou uma única vez.**
- A `claude-code-action` sai com **exit 0 mesmo com `is_error: true`**: o log de uma run que custou
  0 e deu 1 turno registra `outcome=success;conclusion=success`. O fato vive **dentro** do JSON.
- Medido em 4 runs de 2026-08-03 (03:34 · 12:10 · 17:11 · 19:17): forma **idêntica** em todas —
  `is_error: true`, `num_turns: 1`, `total_cost_usd: 0` — e **zero** comentários/reviews em
  qualquer PR. Os **11 PRs** da sessão mergearam sob um revisor que não leu nada.
- A hipótese inicial (`claude_code_oauth_token: ""` → secret ausente) era **plausível e errada**:
  a causa não era auth, era a condição jamais satisfeita. Consertar o token não teria mudado nada,
  porque o retry continuaria sem gatilho.
- **Erro meu no mesmo fio:** escrevi `review-verdict.sh` assumindo que o `execution_file` era
  JSONL, e as fixtures do selftest passaram **7/7**. A fonte da action no pin
  (`base-action/src/execution-file.ts`) diz `JSON.stringify(messages, null, 2)` — é **array**.
  Medido: a expressão antiga sai `jq: error ... Cannot index array with string "type"` no formato
  real → todo PR viraria alarme falso, que é como um alarme morre.

## Next crumb

O `verde` do CI agora **diz qual verde é**: `review-verdict.sh` classifica pelo `is_error` e o job
carimba `GITHUB_STEP_SUMMARY` nos dois desfechos. Re-teste (`dynamic`): abra um PR e confira que o
resumo do job traz ✅ *revisou* ou ⚠️ *não revisou* — **silêncio nos dois é regressão**.

Fica aberta a causa (o item 1): por que a action erra na primeira volta. Mas note a ordem — com o
rastro no lugar, uma reincidência **se anuncia**; sem ele, consertar a causa só devolveria o
silêncio bonito de antes.

E a lição transferível, mais barata que as duas: **fixture derivada de premissa confirma a
premissa**. Quando o formato vem de fora, o selftest só vale depois de ler a fonte — senão ele
mede a minha convicção com rigor de teste.
