---
title: "Revisão — pesquisa 'N grafos peer, 1 visão' (decision) + resposta ao sinal do Onion pessoal entregue no inbound (I3)"
date: 2026-09-04
branch: research/kg-multi-graph-view-2026-09
reviewer: "condutor com run EXECUTADO: wf_bb97173d-425 (104 workers, 10 confirmadas/15 refutadas, radar exit 0); SYNTHESIS como projeção do veredito do Elenxo; anúncio no outbox/marcio-pessoal e cópia untracked no inbound do adotante; sinal movido para _processed com triagem"
reviewed_diff_sha256: f9b6ecaab4c35d1c4e8ca4382b5ab1a76c922a5757a0e770ceb4d63dd8825380
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 6800000
duration_min: 70
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados
1. **A resposta "óbvia" caiu por propriedade load-bearing** — `--corpus` no radar destruiria o awk-sem-filesystem que sustenta o `env -i`; o Elenxo achou isso no código, não nas fontes. O agregado é consumidor-irmão (padrão do backlog).
2. **Defeito vivo no core nomeado pela pesquisa** — o backlog ordena grupos de grafos por atenção crua (grau bruto); comparabilidade entre grafos exige normalização provada. Vira fio (C1) antes de qualquer agregado ranqueado.
3. **Resposta entregue com atenção e sem commit alheio** — cópia untracked no `inbound/` do adotante; a REGRA 28 (Anúncio em staging para membro SEM canal de recepção) barrou o outbox — adotante de MÉTODO não tem canal por desenho — e a resposta ficou como projeção `RESPOSTA-marcio-pessoal-2026-09-04.md` na pasta da pesquisa; o commit é da sessão dele. O dado bruto do adotante não foi lido.

## Fora de escopo
- Selo de `D_KG_MULTI_GRAPH_VIEW_0904` (maestro); os 4 fios do core (raiz do backlog, xref+resolver, normalização, console gated) nascem no grafo, não aqui.
