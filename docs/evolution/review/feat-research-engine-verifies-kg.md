---
branch: feat/research-engine-verifies-kg
date: 2026-10-11
reviewed_diff_sha256: 79658196fa57d0cfb5efdd432ba9bede076f102a8dab99eb6cef3287891dc25d
reviewed_code_sha256: 226e710bf4107ea0d80c7d5d10bb3887ab80c93baf07e195e5f8e6b45df4e4d2
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 40
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutantes executados (sem subagente) — gate mecânico: run_research_workflow_selftests
---

# O motor de pesquisa julgava o número que o escritor declarava

## Achados

1. **O `radarExit` era declaração.** O escritor rodava o radar, contava as próprias tentativas e
   devolvia o número, e o motor confiava nele (nó `E_N3_ONION_CONFIA_NO_RADAR_DECLARADO` do Conductor).
   Agora um agente separado roda `kg-radar` e `kg-contract-check` sem poder editar, e o veredito que
   vale é o dele. O teto vive em `MAX_WRITE_ATTEMPTS` e é contado no JS.
2. **A recomendação do Elenxo era cortada em 1500 caracteres** no prompt do write(KG). Foi assim que o
   degrau 2 do SAC-70 chegou truncado e o escritor o completou de memória (PR #1035). É a mesma classe
   do `.slice(0, 7000)` curado em 2026-10-07. O corte saiu.
3. **A SKILL descrevia o mecanismo velho** ("o agente prova radar exit 0"). Foi reescrita.

## Mutantes (o caso tem de reprovar)

- `if (engineOk(ver)) break` trocado por confiar em `res.radarExit === 0`: (ev1) e (ev2) reprovam.
- `MAX_WRITE_ATTEMPTS = 5`: (ev1) reprova, porque viu 5 tentativas.

## O que esta passada NÃO verificou

- **Um run real do workflow com o verificador.** O custo é de um agente sonnet/low por tentativa, e a
  primeira pesquisa depois do merge é o dogfood.
- **Se o harness re-pede ao modelo quando o schema falha.** Segue como lacuna nomeada no grafo do
  Conductor.
