---
branch: chore/kg-ssot-4.46.0-machine-vocab-en
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 1
tokens: 0
duration_min: 25
findings_fixed: 1
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: agente de execução (passada própria, sem revisor isolado: o brief proibia criar agentes)
nota: "tokens 0 = não medido. A passada não teve revisor isolado; os vereditos abaixo vêm de medição com rc, não de leitura."
---

# Passada adversarial: `chore/kg-ssot-4.46.0-machine-vocab-en`

## O que muda

1. O vendor do kg-ssot sobe de 4.45.0 para 4.46.0 (contrato v4.19, só SHOULD) pelo caminho oficial:
   `kg_vendor.py update --tag kg-ssot-v4.46.0`. Vendor íntegro: 731 arquivos, commit `d3b1cc1fe1b1`.
2. A base do gate (`.kg-ssot/gate/`) é regravada com o kit 4.46.0. A regressão entra aceita, com motivo, em
   `.kg-ssot/gate/accepted/9e32e64d130b1993.json`. Quatro grafos que não tinham registro ganham registro.
3. O grafo `docs/onion/graph/testes-evidencia-2026-09.kg.yaml` recebe o selo da decisão do maestro de 2026-11-08
   (valor de campo de máquina em inglês). O nó novo `D_VALOR_DE_MAQUINA_DO_RESIDUO_EM_INGLES` foi gravado pelo
   `kg-decide-seal.sh --new` com uma aresta `SUPERSEDES` para `D_VOCABULARIO_FECHADO_DO_VEREDITO`, e esse nó
   passa a `superseded`.

## Achados

1. **BLOQUEAVA, curado: o aviso do kg-ssot não bate com o gate do core.** O aviso dizia que os dois códigos novos
   "aparecem como dívida antiga na rampa". Medido: o `ops/kg-gate-ci.sh` sai **rc 1**, com
   `✗ WORSE debt.integrity.bare-decision: 0 → 736` e `✗ WORSE debt.integrity.superseded-without-successor: 0 → 63`.
   A base do core é por nó (`granularity: node`) e não tinha esses códigos, então qualquer contagem acima de zero
   piora. Os números batem com os do kg-ssot (736 e 63). Nenhum outro código mudou: os outros SHOULD, os 2 MUST
   herdados, o critério (14, 0 achados) e os nomes (0 novos) ficaram iguais antes e depois. Cura: a dívida entrou
   como linha de base por `--update --accept-regression "<motivo>"`, sem afrouxar a catraca. Depois disso o gate dá
   rc 0.
2. **Limite: o selo não muda o nó superado.** O `kg-decide-seal.sh --new` cria o nó e a aresta, mas deixa
   `D_VOCABULARIO_FECHADO_DO_VEREDITO` em `confirmed`. Passei o status para `superseded` à mão. Depois disso o radar
   (`--integrity --schema`) e o `kg-contract-check` deram rc 0.
3. **Limite: as opções descartadas foram reconstruídas.** O brief trazia a escolha do maestro e não as opções
   descartadas. No selo elas ficaram como «manter o valor de máquina em pt-BR» e «reescrever os resíduos antigos
   para o inglês». A segunda tem lastro no PR #1541 ("os resíduos antigos não foram reescritos"). A primeira é a
   alternativa óbvia. Se o `/meta:decide` ofereceu outras, a narrative do nó pede emenda.

## Mutantes

- Tirar a `narrative` do nó novo, que fica `done` sem nenhum `SUPPORTS` chegando: o gate dá **rc 1** com
  `bare-decision: 736 → 737`. Com o original restaurado, rc 0.
- Trocar a aresta `SUPERSEDES` do selo por `TRACES_TO`, deixando o nó antigo `superseded` sem sucessor: o gate dá
  **rc 1** com `superseded-without-successor: 63 → 64`. Com o original restaurado (`cmp` confere), rc 0.
- A catraca nova barra o crescimento das duas dívidas.

## Limites declarados

- `kg-projection.sh` (REGRA 112: página com projection_of cita ids que existem nos grafos dela) segue julgando a
  `kg-ssot.projection/1`: rc 0 com 1 página, 3 ids e 3 resolvidos, saída idêntica byte a byte antes e depois do
  vendor. A chave aditiva `superseded_cited` não muda o rc.
- As contagens 736 e 63 são o retrato de `origin/main` `3a1051d97` mais este PR. Pagar a dívida é trabalho à parte.
- Achados 2 e 3 (acima).
