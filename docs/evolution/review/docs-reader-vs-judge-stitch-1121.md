---
branch: docs/reader-vs-judge-stitch-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: d728a537898c4b784e02b528077918cd7e2fd915c7bf62f495f4743aa38a97d7
reviewed_code_sha256: 6e705ad69ad480f27fb2ee1996f3f663fdd1904c184562b1e0a2595775472c98
findings_total: 8
findings_real: 7
findings_blocking: 1
tokens: 102701
duration_min: 2
findings_fixed: 5
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "revisor isolado (agente general-purpose novo, só leitura, sem o raciocínio de quem escreveu), sobre o diff stageado inteiro e o sinal de origem lido inteiro"
nota: "1 bloqueante curado (a frase da calibração na SYNTHESIS dizia mais do que o grafo sustenta). Radar exit 0 nos dois grafos depois das curas."
---

# Passada adversarial: `docs/reader-vs-judge-stitch-1121`

## O que muda

A doutrina de avaliação do core ganha a distinção «leitor de gabarito ≠ juiz de modelo», nos rótulos de
`C_LLM_JUDGE_VETOED_SINGLE_ANNOTATOR` e `C_STAGE0_GATE_BEFORE_ANY_MODEL` e na `SYNTHESIS.md` (com a tabela
dos três papéis). O selo `D_READER_VS_JUDGE_STITCH_1121` entra no grafo de selos, com autoria do core e
revisão do maestro pendente. O sinal da curadoria vai para `_processed/` com `reviewed_for_public: true`.

## Achados

| # | achado | real? | bloqueia? | destino |
|---|---|---|---|---|
| 1 | `SYNTHESIS.md`: «é aí que mora a calibração que o veto protege» contradiz `E_YAN_LLM_EVALUATOR_CALIBRATION` (a calibração exige dois anotadores humanos; rótulo errado em que os leitores concordam nunca chega ao humano) | sim | **sim** | curado: «mitiga, mas não substitui, a calibração humano-humano», na SYNTHESIS, nos dois nós e no selo |
| 2 | a costura perdeu a condição do sinal («quando não há anotador humano qualificado») e o ≥50 amostras no caminho por leitores | sim | não | curado nos dois nós, na SYNTHESIS e no selo |
| 3 | «cumpre a porta 0» é largo: o leitor cumpre a **inspeção**, uma das condições | sim | não | curado: «cumpre a inspeção da porta 0» em todos os lugares |
| 4 | célula da tabela dizia «à mão» e logo depois «LLMs cumprem» | sim | não | curado: «inspecionado: à mão, ou … por regra mais leitores de gabarito» |
| 5 | o `purpose` do grafo de selos fala de selo do maestro colhido do grafo de coordenação; este nó nasce aqui | sim | não | LIMITE |
| 6 | a aresta TRACES_TO para `D_DECISION_RATCHET_SYNTHESIS_SEALED_1120` sem a ressalva de contexto que o irmão tem | sim | não | curado: a narrativa diz que a aresta é contexto, não autoridade |
| 7 | `locality: "pessoa"` com fonte que é a sessão do core | não | não | mantido: o método é testemunho de quem decidiu (a sessão do core), mesma forma do selo de 2026-11-21 do descartado como nó |
| 8 | a cópia não versionada do sinal segue em `docs/evolution/inbox/` no checkout principal | sim | não | LIMITE (fora do PR; sai do inbox depois do merge) |

## Mutantes

Não se aplica: PR só de documentação e grafo, sem código executável.

## Limites declarados

- Achado 5: o grafo de selos já recebe selos que nascem nele (precedente `D_PLAIN_LANGUAGE_STITCH_1121`);
  emendar o `purpose` é mudança à parte, não deste PR.
- Achado 8: a limpeza do inbox do checkout principal é da sessão do core depois do merge.
