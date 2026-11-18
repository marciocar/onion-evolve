---
branch: fix/dissect-synthesis-ratchet-1118
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 6
findings_blocking: 1
tokens: 0
duration_min: 35
findings_fixed: 4
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Duas passadas por agentes revisores separados (code-reviewer), só leitura, mandato de refutar. 1ª passada (commit 7fd5ce4a4, ~15 min): REJECTED — mudança real num estudo vinda de ramo bifurcado antes da régua escapava (S5, S1), caso de edição não commitada sem mutante, clone raso mudo. Curados no 6538b8703. 2ª passada (6538b8703, ~20 min): APPROVED com duas declarações e uma lacuna leve de bancada; as declarações foram escritas na docstring pela sessão do core."
nota: "tokens 0 = não medido (o harness não devolveu o custo dos revisores); duration_min soma as duas passadas, pelo relógio declarado por elas."
---

# Passada adversarial: `fix/dissect-synthesis-ratchet-1118`

## O que muda

O item 11 do checador de dissecação (a síntese do estudo cita o grafo; síntese ausente) nasceu em 12/11 sem corte de
tolerância. Num adotante cuja CI reconfere todos os estudos quando o vendor muda (o PR #339 da curadoria), 17 estudos
antigos passaram a reprovar e travaram a atualização do core. A cura estende o padrão que o item 9 já tinha
(`IDEAS_SINCE`): o achado do item 11 vira aviso só para estudo com Etapa 0 anterior a 2026-11-13 que não foi tocado
desde a chegada da régua. «Não tocado» exige três provas: árvore limpa, nenhum commit descendente da chegada mudou a
pasta, e o último commit que mudou a pasta em toda a história é anterior à chegada. História rasa e régua fora da
história cobram, e dizem por quê.

## As passadas

- **1ª (REJECTED):** S5 (ramo lateral pré-régua muda um estudo legado, merge depois) e S1 (estudo novo com data da
  Etapa 0 forjada, criado num ramo pré-régua) saíam como aviso; a guarda de edição não commitada não tinha mutante;
  clone raso falhava fechado em silêncio. Curado no 6538b8703 com a prova do relógio, dois casos e três mutantes.
- **2ª (APPROVED):** S5 e S1 reprovam; a forma do #339 dá aviso; clone raso diz «história rasa, catraca não
  avaliada»; família `dissect_object` 144 de 144.

## Achados e destino

- **(médio, bloqueava, curado):** a brecha do ramo bifurcado (S5, S1).
- **(baixo, curado):** caso e mutante da edição não commitada.
- **(baixo, curado):** mensagem da história rasa.
- **(médio, declarado na docstring):** a prova do relógio confia na data de commit; um estudo novo com
  `GIT_COMMITTER_DATE` antedatado num ramo pré-régua escapa por desenho. A régua é conformidade, não fronteira.
- **(baixo, declarado na docstring):** mudança feita e datada antes da régua, mergeada depois, recebe aviso de
  propósito (o mesmo caso do #339).
- **(baixo, declarado):** a bancada não tem caso de clone raso; a mensagem foi medida à mão pelos dois revisores.
