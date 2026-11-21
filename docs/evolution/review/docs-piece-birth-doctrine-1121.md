---
branch: docs/piece-birth-doctrine-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: ed43b76ca09f096ddfd0216b4f361d0f2dfdde22aef1c8295551ac5e2923ffec
reviewed_code_sha256: eac74de0bbe4c018460610d702c6ac61877e97618834501f7498a4047c9ec010
findings_total: 9
findings_real: 9
findings_blocking: 3
tokens: 117079
duration_min: 3
findings_fixed: 8
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "revisor isolado (agente general-purpose novo, só leitura, sem o raciocínio de quem escreveu), sobre o diff stageado inteiro, a proposta de origem lida inteira e os scripts citados conferidos contra o vivo"
nota: "3 bloqueantes curados: contagem do index, o caso privado descrito ao contrário (veio da proposta) e a KB prometendo mais verificação do que o members-validate.sh faz. Radar exit 0, kb-index-check rc 0 e REGRA 100 sem achado na KB depois das curas."
---

# Passada adversarial: `docs/piece-birth-doctrine-1121`

## O que muda

KB nova `docs/knowledge-base/concepts/piece-birth.md` (doutrina de nascimento de peça, card SAC-479), entrada no
índice das KBs, inventário regenerado (118 KBs) e `agents-reference.md` realinhado pelo `--fix` do lint. O selo
`D_PIECE_BIRTH_DOCTRINE_1121` entra no grafo de selos, com autoria do core e revisão do maestro pendente. A proposta
da curadoria vai para `_processed/` com `reviewed_for_public: true`. O `members.yaml` não muda.

## Achados

| # | achado | real? | bloqueia? | destino |
|---|---|---|---|---|
| 1 | o `index.md` seguia com 111 documentos e 57 conceitos em quatro pontos | sim | **sim** | curado: 112 e 58; `kb-index-check.sh` rc 0 |
| 2 | «repo de cliente nunca entra na lista; o caso privado vive fora» inverte `D_PRIVATE_OWNER_SESSIONS_1119`, que **delega** o repo de consultoria do dono do core; quem fica sempre fora é o repo de outro dono | sim | **sim** | curado: os dois casos separados na KB, no resumo, no índice e no selo |
| 3 | o critério 1 sugeria que o `members-validate.sh` confere os campos de peça (não confere), o 3 não tem script e o fecho dizia «sem julgamento» com o critério 4 sendo revisão | sim | **sim** | curado: a coluna diz o que o script confere e o que se confere lendo; o critério 4 é julgamento declarado |
| 4 | critério 4 sem o vocabulário real do `verdict`, sem `findings_blocking: 0` explícito e sem o hash do diff | sim | não | curado |
| 5 | critério 2 sem o estado `PIECE_OWNER_NAME_MISMATCH` | sim | não | curado |
| 6 | o critério 5 acontece depois do nascimento, então não é item da porta | sim | não | curado: vira «condição permanente»; a porta tem 4 critérios |
| 7 | o `(core-only)` no meio da frase atrapalhava a leitura | sim | não | curado: vai ao fim da linha |
| 8 | o `purpose` do grafo de selos fala de selo do maestro colhido; não há nó aberto para a revisão pendente | sim | não | LIMITE |
| 9 | faltava a aresta para `D_SESSIONS_MERGE_OWN_PRS_INCL_GUARD_1118`, origem da parte B | sim | não | curado: TRACES_TO acrescentada |

## Mutantes

Não se aplica: PR só de documentação e grafo, sem código executável.

## Limites declarados

- Achado 8: o grafo de selos já recebe selos que nascem nele (precedente `D_PLAIN_LANGUAGE_STITCH_1121`), e a
  revisão pendente do maestro é declarada no próprio selo, como nos selos do core do mesmo dia. Emendar o
  `purpose` ou abrir um nó de revisão é mudança à parte.
