---
branch: fix/research-write-vocab-lint
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: 875d51e3ddf0b5182ba8d783835255b7db57728b5ac4a4410ddbdd78f768062e
reviewed_code_sha256: 67326700dfb99f8cc3b27283f5aefc2401f79bd69b6888e472b5d3c0fea4ba8e
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "autor (bancada e mutantes); passada adversarial PENDENTE, refutador independente a cargo do team-lead"
nota: "Passada adversarial pendente: o refutador independente fica a cargo do team-lead e ainda não rodou. NO_FINDINGS e os zeros dizem só que a passada do autor (bancada, mutantes, prova contra a origin/main) não achou defeito; não são o veredito de um revisor separado. tokens e duration_min 0 = não medidos. findings_blocking ausente = não triado."
---

# Passada adversarial: `fix/research-write-vocab-lint`

## O que muda

O verificador separado do write(KG) do `/onion-research` roda também o lint de nomes sobre o grafo escrito
(`.claude/validation/kg-vocab-graph.sh`, o `kg_vocab.py lint` do vendor julgando um grafo rastreado ou não), e o
achado volta ao laço de correção contando como tentativa (teto 3). Dano de origem: a rodada `wf_45f0fcd2-079`
saiu verde e o commit do PR #1654 reprovou com 29 códigos OWASP sem termo.

## Achados

Nenhum na passada do autor. A passada adversarial independente está **pendente**, a cargo do team-lead.

## Mutantes

- (ev6) `engineOk` sem a cláusula de nomes: o grafo com sigla sem termo aprova na 1ª tentativa.
- (vg3) `kg-vocab-graph.sh` sem acrescentar o grafo solto ao corpus: rc 0 com sigla sem termo (o furo do
  `--root` que só lê os rastreados).
- Prova contra a base: o caso (ev3) rodado com o workflow da `origin/main` devolve `{"n":1,"ok":true}`, isto é,
  reprova hoje e passa depois. Família `research_workflow`: 56 de 56.

## Limites declarados

- O script troca `kg_query.load` do vendor em memória para acrescentar o grafo solto. Se o vendor mudar essa
  forma, ele sai rc 2 (não julgou), e o motor passa esse caso declarado, como o rc 2 do contrato.
- Sem a base da catraca (adotante), contam todos os achados do arquivo; num grafo apendado com dívida antiga,
  a rodada pode ser cobrada pela dívida herdada.
