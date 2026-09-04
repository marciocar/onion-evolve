---
title: "Revisão — Radar E3 rodada 4 (2.1.260→2.1.261): nada muda a adequação; baseline selada no mesmo commit"
date: 2026-09-04
branch: research/radar-e3-2026-09-04-r4
reviewer: "condutor com run EXECUTADO: wf_3b06e7ee-dcf (103 workers, 7 confirmados / 18 REFUTADOS, radar exit 0); baseline cc_version 2.1.260→2.1.261 no MESMO commit do grafo; duas lacunas declaradas (comportamento não observado; fan-out sem worker de mercado)"
reviewed_diff_sha256: 933ea03f38784720243c3d0907078338c1cf4c042a4d6c51271537b945ebf011
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 5950000
duration_min: 45
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **18 de 25 claims REFUTADAS** — a maior taxa de refutação das quatro rodadas do eixo (rodada 3: 1/13). Quase tudo que parecia achado de changelog não sobreviveu à checagem de fonte primária. O veredito "nada muda a adequação" é, portanto, resultado de refutação, não de ausência de busca.
2. **A afirmação central não foi re-testada** — "o `exit 2` segue barrando sob `bypassPermissions`" é inferida da ausência de menção no delta. Declarado no grafo e na síntese, com a sonda nomeada (sessão nova em 2.1.261 + provocar um dos três vetos). Não rodou porque este processo é 2.1.260.
3. **Achado com consumidor real no core** — `claude -p --resume` com sid malformado agora reinicia limpo, e `worklog-capture-session.sh:36` monta exatamente esse comando a partir de um sid que o fallback sem `jq` pode malformar. Vira fio com gatilho (validar o formato ou rotular a fonte da extração), não conserto cego.
4. **Falha de execução da própria rodada, registrada** — o fan-out não teve worker de mercado, violando o invariante de que capital é eixo de toda pesquisa. Vai como lacuna de execução, com gatilho na próxima rodada (e a E4-capital está perto do teto de 45 dias).

## Fora de escopo
- A sonda de comportamento em 2.1.261 (exige sessão nova).
- `/skill-doctor` vs camada L2 da poda: comparação com gatilho, não decisão agora.
