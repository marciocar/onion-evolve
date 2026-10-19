---
title: 'Resíduo — o caso do JSON fundo do convite A2A deixa de depender da versão do Python'
date: 2026-10-19
branch: fix/a2a-deep-json-oracle
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 30
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A bancada completa reprovou no push ao main depois da onda 1 do EPIPE (#1204) e o CI abriu o revert automático
  #1205. Medido: não é a onda 1. A família federation_a2a passou 6/6 local (3 na main, 3 no pai do #1204). O job que
  caiu rodou em ubuntu-26.04; os verdes do mesmo dia, em ubuntu-24.04 (o ubuntu-latest está migrando). O caso monta
  um JSON de 100.000 níveis e só aceitava rc 2 "não medido". Do Python 3.14 em diante o limite do decodificador é a
  pilha real: com 3.14 e pilha de 16 MB ou mais os 100.000 níveis são lidos (rc 0, ok); com 3.12 dá RecursionError
  em qualquer pilha. Reproduzido no leitor direto: 3.12 com 8 MB dá unmeasured, 3.14 com 64 MB dá ok. O invariante
  que o caso declara é "nunca 'o bridge recusa'", então os dois desfechos honestos passam a valer e só a afirmação
  de recusa reprova. Mutante: o leitor mapeando o RecursionError para invalid reprova o caso (medido). Teto: a
  família inteira não rodou no regime 3.14, porque falta PyYAML nesse Python local e não instalei pacote; o leitor
  foi exercido direto. O #1205 fecha sem merge, com a causa nomeada.
---
