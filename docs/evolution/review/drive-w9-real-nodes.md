---
title: "Revisão — Drive W9: 3 nós reais fechados por mecanismo + radar E3 rodada 1"
date: 2026-09-02
branch: drive/w9-real-nodes
reviewer: "revisão do condutor com medições executadas: write-stamp dogfood em clone real (AVISO 1 referência, inbox excluído) + bancada caso 6 PASS/FAIL sob mutação; bench a2a spawnSync 4820ms vs spawn 1,1ms (t0 antes do yield, artefato de medição corrigido); radar freshness fixture testimony (TESTIMONY/TESTIMONY-UNMARKED/MISPLANED) PASS + census-extract (d) 1 A-MEDIR/1 TESTEMUNHO; E3: juiz opus/high re-mediu no vivo (26 settings rc=1; plugins/ 0 symlinks; setsid só decoy); lint-artifacts rc=0, 0 HARD; radar --integrity --schema exit 0 nos 4 grafos tocados"
reviewed_diff_sha256: c28ddf508bc05305e15b30e856f9e7aef46c40d725ceae9771e739b361f9a61d
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 5400000
duration_min: 95
---

# Resíduo — REGRA 56

Lote W9 do `/meta:drive` (executado por mim, ordem do maestro): Q_PIN_GREP_WORTH_IT
(D_GREP_OLD_PIN no write-stamp), Q_A2A_SPAWNSYNC (PR #66 no bridge, spawn assíncrono com timeout
15s), Q_TESTEMUNHO (`evidence_class: testimony` no radar + censo), radar E3 (2.1.252→2.1.257).

## Achados

1. **Bench mentia por ordem do cronômetro** — a 1ª medição do spawnSync deu 0,6ms porque `t0`
   nascia depois do bloco; movido antes do yield de 200ms: 4820ms vs 1,1ms. Corrigido antes de
   citar o número no PR do bridge.
2. **TESTIMONY-UNMARKED por vocabulário** — o padrão `relato` casava um nó `question` que só
   CITAVA "relato-do-maestro-*" no verified_against (classe guarda-por-lista-falha-pelo-vocabulário);
   restrito ao 1º token. Bancada com o falso-positivo como fixture (T_CITA não flagado).
3. **Medições minhas erradas no E3, pegas pelo juiz** — `find` sobre `.claude/plugins` inexistente
   (fail-open: 0 symlinks de alvo ausente) e "10 adotantes" onde o real são 26 settings varridos.
   Emendadas no grafo, rascunho pré-juiz preservado em `data/`.
4. **Lacunas do juiz truncadas 2× no canal** — itens 3-4 das lacunas são meus, e o grafo/SYNTHESIS
   dizem isso; não atribuir ao juiz o que ele não disse.

## Não mudou
Backlog 70→67 é projeção regenerada (REGRA 62). Plugins re-assemblados por mudança de fonte
(kg-radar/skill/comando) — provenance acompanha o tree_sha. `.claude/session-lifecycle.jsonl`
fora do commit. Merge/deploy do bridge (#65/#66) = ato do maestro (MOAT).
