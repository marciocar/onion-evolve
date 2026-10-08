---
title: 'Resíduo — o conflito só de projeção em plugins/ se resolve no rebase do pr-finalize, e o mapa da federação entra na lista do motor'
date: 2026-10-08
branch: fix/generated-projection-merge
reviewed_diff_sha256: 4561cef02b50403ba5452e8365edc1fb8ec22154be8bd8322becbb37fcade091
reviewed_code_sha256: 986053ba6d0d36bbe0f15d981bf7b69d8357081142f6ac8dfeca0f59b385d484
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-67, conduzido pelo /meta:drive no nó Q_MERGE_DRIVER_PARA_PROJECAO_GERADA, com a medição ANTES do
  código, como o especialista de story points recomendou. Medição (sandbox: clone --shared do core em
  730b653d, dois PRs que tocam fontes DIFERENTES e regeneram as projeções como o pr-finalize): o segundo,
  rebaseado sobre o primeiro, conflitou em 4 arquivos, todos projeção gerada e todos FORA da lista do
  motor (plugins/onion e plugins/onion-engineering, provenance.json e README.md), e em 0 de fonte. A
  história confirma as rodadas à mão ("plugins regenerados depois do rebase sobre #959 e #960", "depois
  do rebase sobre a cura do Zoho"). Decisão: nem merge driver (exige git config em cada clone e no CI)
  nem tirar a projeção do PR (afeta a catraca byte-a-byte das REGRAS 62 e 81); o --rebase do
  pr-finalize já resolvia conflito de projeção da lista exata e só não conhecia plugins/. Cura:
  onion-regen-lib.sh ganha ONION_GENERATED_DIRS="plugins/", onion_is_generated e
  docs/onion/federation-map.md na lista; o hash de código exclui plugins/ (derivado das fontes); o
  --rebase classifica pela função e REMONTA plugins/<v> das fontes mescladas no próprio passo, em vez
  de escolher um lado; o _regen regenera o mapa da federação (REGRA 38, cobrado 3 vezes na leva). Achado
  no caminho, pego pela bancada do --check: o _regen devolvia o rc do `[ -f ]` do último item da lista,
  e com federation-map.md no fim um repo sem ele recusava a rodada; agora return 0 explícito. Bancada
  pre_push 48/48 com LC_ALL=C, com os casos SAC-67 (x1) plugin em conflito remontado das fontes
  mescladas e (x2) conflito em FONTE continua recusa, rebase abortado e HEAD intacto. Mutantes, todos
  reprovaram: lib sem plugins/ reprova x1 e x2; resolver o plugin por --theirs sem remontar reprova x1
  (passaria rc=0 com o README VELHO, s2-base — o modo de falha silencioso); tratar todo conflito como
  projeção reprova x2. Passada adversarial própria, à procura do falso negativo, que aqui é o pior
  desfecho (esconder conflito de fonte): (1) só caminho sob plugins/ ou na lista exata vira projeção;
  qualquer outro aborta o rebase; (2) o plugin não é resolvido por lado nenhum, é remontado das fontes
  do passo, então nunca carrega o conteúdo de um lado só; (3) remontagem que falha aborta o rebase; (4)
  excluir plugins/ do hash de código não esconde edição à mão no plugin, porque a REGRA 19 compara o
  plugin com a remontagem das fontes. Tetos: o PR em CONFLICTING continua sem CI até alguém rodar o
  pr-finalize --rebase (falta o disparo, não a resolução); por isso Q_MERGE_DRIVER_PARA_PROJECAO_GERADA
  segue open com esse rótulo. A medição foi de um par de PRs; conflitos de projeção da lista exata
  (backlog.md, testing-*) não apareceram nesse par, e já eram resolvidos antes. REGRA 87 (PR que EDITA
  um .kg.yaml enxergou os confirmed dele): E_CONFLITO_DE_PROJECAO_GERADA ganhou a narrative da medição;
  confirmed vistos no grafo da fila: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO,
  E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO,
  E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE,
  D_PAPEL_DUAS_DIMENSOES, E_PRECOMMIT_SELECAO_GROSSA, E_PR_FINALIZE_ATRITO_MEDIDO,
  E_TM_PERCENTUAL_IGNORA_STORY_POINTS, E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO. Radar --integrity --schema exit 0;
  kg-contract-check rc 0. Sem Elenxo, declarado: cura de motor medida com mutante. Pre-commit pulado
  por ordem do maestro; validação = família tocada + mutantes + pr-finalize + CI.
---

# Resíduo — `fix/generated-projection-merge`
