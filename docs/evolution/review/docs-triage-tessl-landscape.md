---
title: 'Resíduo — a Tessl re-medida: piso não é total, e ausência não é retirada'
date: 2026-10-14
branch: docs/triage-tessl-landscape
reviewed_diff_sha256: d3b88418c551f60f2ec01def8d00ef968178bbbba072e66069ddcb2066ffc30a
reviewed_code_sha256: 19a3340dac283b044ead8e163efe2bce463e7ceeaa8ea25b2a36035398de0bda
tokens: 150000
duration_min: 10
findings_total: 4
findings_real: 4
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Passada adversarial curta, feita pelo próprio autor da triagem e não por um refutador
  independente. Ela olhou duas perguntas: o piso de 1.274 está escrito como piso, e o pivô da Tessl
  está afirmado com citação da doc pública? Saíram 4 achados reais; 3 foram curados no diff e 1 fica
  declarado. O campo tokens é o total da sessão do agente que triou (contador de contexto), não só da passada.
---

# A Tessl re-medida: o que o sinal sustenta e o que não sustenta

A triagem corrige a linha da Tessl no panorama competitivo e refuta o nó
`B5_17_tessl_unico_as_source`. Na passada adversarial, a pergunta foi se o diff afirma mais do que o
sinal do adotante mede.

## Achados

| # | achado | cura |
|---|---|---|
| 1 | **Piso escrito como queda do número.** A 1ª redação dizia que o "10k+" tinha *caído*. O que foi medido é outra coisa: hoje nenhuma página o declara, e o sitemap mostra um **piso** de 1.274. O número de 2025 contava specs de bibliotecas OSS, que é objeto diferente das skills de hoje. Um piso de skills não refuta uma contagem de specs. | O texto agora diz "não se confirma hoje" no panorama, no SYNTHESIS e no label do nó. O panorama diz explicitamente que a medição não refuta o número de 2025. |
| 2 | **O pivô não está afirmado pela doc pública.** O sinal diz que a Tessl "tirou o spec-as-source da doc pública", mas a prova é uma **ausência** no `llms.txt`. A citação afirmativa que existe é um post do **blog** da Tessl (2026-01-29) e um slogan citado por dois terceiros. Os dois nós vêm de 1 agente, sem votação, e o Framework segue em closed beta. | No panorama, no SYNTHESIS e no nó, o pivô aparece como **indício, não fato selado**, com a fonte de cada parte. |
| 3 | **A refutação é do Verify do adotante, não do core.** O core não leu o arXiv 2606.27045 nem re-mediu o sitemap. | A confiança do nó novo ficou em 0,65. O `TETO` do nó declara que o core leu o grafo do adotante como DADO, sem re-medir. |
| 4 | **A question nasce invisível ao backlog.** O grafo `federation-research-2026-06-reconciled` tem `kg-backlog-archive: on`, então `Q_VEREDITO_TRAJETORIA_PERDEU_PREMISSA_TESSL` não aparece em `/meta:backlog`; só o `radar --open-tsv` a mostra. | **Não curado, declarado.** A tarefa pedia o nó neste grafo, ao lado da decisão. Movê-lo para um grafo vivo é escolha de quem conduz o B5_17. |

## O que foi conferido contra o grafo do adotante

Leitura do commit 7625595 do adotante. O nó `E_CORE_10K_SPECS_UNCONFIRMED` diz literalmente "o piso
medido é de 1.274 skills indexadas no sitemap, e o total do registry fica NÃO VERIFICADO". O resumo de
lacunas da linha de base registra a refutação da unicidade pelo Verify (arXiv 2606.27045, tier 6) e diz
que o Elenxo a manteve, porque o spec-as-source do registry é plugin de terceiro. As citações do sinal
batem com o grafo do adotante.

## Gates rodados (LC_ALL=C, só as famílias afetadas)

- `kg-radar.sh <grafo> --integrity --schema`: exit 0 (884 nós, 1090 arestas).
- `kg-contract-check.sh <grafo>`: rc 0, conforme e sem piorar o SHOULD herdado.

## Teto

O total do registry da Tessl e a origem do "10k" antigo continuam **NÃO VERIFICADOS**. O veredito
`B5_17_veredito_trajetoria_campo` não foi tocado: a question que diz que ele perdeu uma premissa está
aberta. O veredito PARQUEAR do estudo C é do adotante e o core não o selou.
