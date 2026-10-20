---
title: 'Resíduo — o co-relay entrega ao dono de um vendor, provado pelo carimbo'
date: 2026-10-20
branch: feat/co-relay-vendor-upstream
reviewed_diff_sha256: 3353f918f3f1102f765e60157cca5f62a89a24f730e32089c4c82d0087e5a864
reviewed_code_sha256: 2e4a83ac77d0108e34f2e42a7b92fdc05807768beba6f4d27817fd4e1eed8405
findings_total: 13
findings_real: 7
findings_fixed: 6
tokens: 97302
duration_min: 9
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Executa D_CANAL_UPSTREAM_POR_VENDOR (maestro, 2026-10-20). O desenho pedido comparava a URL do remote do
  alvo com a source do carimbo, e a medição o derrubou: o carimbo vendor/kg-ssot/.kg-ssot-version não grava
  URL, e a release vem do espelho público, cujo commit (172c62a) o repo do dono não tem (tag 2a69199, origin
  diferente). A prova virou de conteúdo: a árvore de refs/tags/<tag> do destino reproduz os sha256 de todos os
  arquivos do carimbo (444 de 444 no caso real). Passada adversarial por subagente refutador: 13 achados, 7
  reais. Curados com caso e mutante: (1) dono provado sem caixa e sem carimbo do Onion caía como "o core" e
  ganhava docs/evolution/ (V6, V-M5); (2) o rodapé gravava a URL crua do origin, com token (V7, V-M6);
  (3) tag nova do vendor mudava o rodapé e fazia voltar sinal já triado (V8, V-M7: o dedup compara o corpo);
  (4) --target igual ao próprio repo reescrevia a fonte (V9); (5) o mutante V-M4 não removia o rodapé
  inteiro e mordia por grafia, agora apaga o bloco entre marcadores e o caso exige carimbo e tag no rodapé;
  (6) sem python3 a recusa não dizia a causa. O (7), mensagens que diziam "core" com destino de vendor, foi
  curado no texto. Não curado e declarado: qualquer repo git sem carimbo segue tratado como o core (defeito
  anterior a esta branch, medido no dogfood contra um clone defasado do espelho; nó
  Q_CO_RELAY_SEM_CARIMBO_E_O_CORE). Não-defeitos: carimbo forjado pelo próprio remetente (fora do modelo:
  ele teria o cp), injeção no cat-file --batch (falha fechada, medida), papéis, set -u/trap, V-M1..M3,
  REGRA 90 (Prosa de comando conhece os papéis que o script aceita) verde. Família corelay 35/0. Sem Elenxo,
  declarado: exceção estreita de um carteiro com bancada e mutantes, sem guarda nova de lint.
---

# Resíduo — `feat/co-relay-vendor-upstream`

Teto: a prova identifica o dono pelo conteúdo da release, então um fork ou espelho do produto que tenha a tag
e caixa também recebe. É o comportamento querido (o mesmo produto), e o rodapé declara o carimbo e a tag
para a sessão de lá conferir.


## Re-revisão depois do rebase (2026-10-20, sessão principal)

O PR foi rebaseado sobre a `main`, que tinha recebido o #1236 (o selo `D_CANAL_UPSTREAM_POR_VENDOR`), o #1237 e o
#1235. O hash de código mudou porque a base trouxe esse código. O diff deste PR não mudou de natureza. Conferido no
grafo `field-hub-update-2026-10-19`: a decisão do #1236 e o nó de evidência deste PR convivem sem conflito, e o radar
`--integrity --schema` sai 0. Entra a aresta que o agente deixou pendente:
`E_CANAL_UPSTREAM_VENDOR_NO_CO_RELAY` SUPPORTS `D_CANAL_UPSTREAM_POR_VENDOR`, ligando a execução à decisão do maestro.
