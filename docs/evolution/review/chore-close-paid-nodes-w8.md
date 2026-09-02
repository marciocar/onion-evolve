---
title: "Revisão — fechamento dos nós-fonte da Onda 8 + aresta do censo pela realidade"
date: 2026-09-02
branch: chore/close-paid-nodes-w8
reviewer: "revisão do condutor com medições executadas (grep no console.sh vivo; lint-artifacts.sh:1687-1698; gh pr view 65 = OPEN; radar --integrity --schema exit 0 em 10 grafos; 0 alvos de SUPERSEDES pendentes, eram 13); bancada census-seal (d) PASS com a regra e FAIL com a regra removida (mutação medida, não suposta); a lista classificada de 2026-09-02 chamou 6 nós de 'já pagos' e a medição derrubou 3 (JWKS = deploy pendente; instrument_metrics e quadro = refinados, não pagos) — corrigido no PR, não no discurso"
reviewed_diff_sha256: 3fe7c396bc3597f7dce9a442d56a4f80d78a3cb5f29ab5cbe24296f25524d057
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 62000
duration_min: 22
---

# Resíduo — REGRA 56

Fechamento dos nós-fonte que o fios-abertos já dava por pagos na Onda 8 (colheita
I_JWKS_ATTEMPTED_AT, I_LINT_VE_WORKFLOWS, I_GTM_JSONL_PERSISTIDO, I_CONSOLE_AUTOOFF,
I_FECHAMENTOS_TRIVIAIS; nó novo E_W8_FECHAMENTO_FONTES).

## Achados

1. **Sobreclaim na listagem** — "6 já pagos" eram 3: JWKS fecha só no deploy (ato do maestro,
   evidência E_W8_JWKS_PR65_ABERTO registra o gatilho disparado); instrument_metrics e quadro de
   citações foram REFINADOS pelo censo, não pagos — seguem open com gatilho re-derivado.
2. **census-seal emitia SUPERSEDES incondicional** — 13 alvos com trabalho pendente em 8 grafos
   ficaram open sob SUPERSEDES (o radar exige flip; flipar apagaria o item do backlog). Regra do
   radar aplicada (CONSTRAINS = refina) e mecanizada: aresta pela realidade, bancada (d).
3. **Radar não exercitado nos grafos-fonte** — o /meta:realign default só olha fios-abertos;
   os 13 pendentes eram invisíveis ali. Registrado no nó; varredura multi-grafo é fio com
   gatilho (próximo censo).

## Não mudou
Backlog 78→70 é projeção regenerada (REGRA 62). `.claude/session-lifecycle.jsonl` fora do commit.
