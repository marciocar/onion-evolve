---
title: 'Resíduo — os fixes confirmados dos sinais do contrato e da suíte de conformidade do .kg.yaml'
date: 2026-10-08
branch: fix/kg-ssot-signals-confirmed
reviewed_diff_sha256: 46a719edb426d31ce5d0a7e6128bc600e04d87d2200a07aed712d04f587ada66
reviewed_code_sha256: ec739df9fb91b241dbc27455848ca4b1af125afb09ea670617f81a9a3ddf9675
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Quatro fixes aprovados pelo maestro ("fixes confirmados agora"), de dois sinais de campo de um
  adotante (contrato v1 item 1; suíte de conformidade itens 2, 3 e 5), cada um medido antes. (1) Chave
  repetida num nó: 5 grafos do core tinham `trace` duas vezes (medido com leitor YAML que acusa chave
  repetida: 5 de 177 arquivos, fixtures inclusas). Corrigido sem perder fonte: em 3 grafos de pesquisa
  o 2º `trace` era o caminho do próprio grafo (tautológico, saiu); no jev a URL do domínio foi para o
  `verified_against` do mesmo nó; no federation-health ficou `members.yaml:36`, que contém o outro.
  Causa: NÃO foi o gerador — os 4 de pesquisa vêm de uma edição de sessão (0f8a2d41, 2026-10-01) que
  acrescentou o `trace` da SYNTHESIS para a REGRA 29 sem ver o `trace` existente; o 5º nasceu em
  1d9fd485 (2026-07-18). Mecanismo: o radar --integrity reprova QUALQUER chave repetida na coluna de
  campos do nó, mesmo com valor igual (a guarda de 2026-08-12 só via 4 campos e valores diferentes); a
  skill de pesquisa passa a dizer onde citar a SYNTHESIS. Passivo depois da cura: 0 no core (140
  grafos, radar exit 0 em todos), 36 fixtures com o mesmo veredito de antes, 35 grafos de 5 adotantes
  ativos com o mesmo veredito de antes; 9 grafos de um clone de projeto abandonado têm `nota` repetida
  e reprovariam num update que não está previsto. (2) REGRAS 78 e 82 passam a usar o predicado único
  de fixture: a 82 tira a fixture da varredura; a 78 a diz como SOFT FIXTURE-INVALIDA em vez de HARD.
  ACHADO 1 da passada: o caso (e) da 78 afirmava de propósito que "fixture inválida CONTA" (a casa já
  pagou por guarda cega ao material de teste); isenção muda contrariaria isso, por isso SOFT nomeado e
  não silêncio, com (e2) provando que o mesmo conteúdo fora de fixtures segue HARD. ACHADO 2: a bancada
  da 82 copiava o helper sem o predicado, e a 1ª rodada abortou; as duas guardas agora falham fechado
  (exit 2) sem o predicado e a bancada copia a dependência. (3) O backlog NÃO inclui grafo não
  rastreado (o CI regenera de clone limpo e a projeção divergiria, REGRA 62): passa a AVISAR no stderr,
  nomeando cada grafo; a skill manda regenerar depois do `git add`. (4) zoho.md: createTask manda
  `owners_and_work` aninhado na criação. Mutantes, todos morderam (LC_ALL=C): checagem genérica
  desligada → (k); restrição de coluna removida → (l) falso positivo; isenção da 82 removida → (b2);
  tag de fixture da 78 removida → (e); aviso do backlog desligado → (c2); zoho.md anterior → (o).
  Tetos: a chave repetida só é vista em NÓS (arestas e meta não); chave com hífen fica fora do
  alfabeto do detector; o aviso do backlog depende de o grafo estar no escopo (canônico ou marcado).
  Pre-commit pulado por ordem do maestro (commits --no-verify como checkpoint); validação = famílias
  tocadas (kg_radar_integrity, kg_yaml_validity, kg_census_parity, backlog_projection, zoho_adapter)
  + mutantes + pr-finalize + CI. Passada adversarial feita pelo próprio fork (ele não abre subagente);
  sem Elenxo, declarado. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele): os 5 grafos
  editados tiveram só a linha duplicada removida (e um `verified_against` estendido); nenhum status,
  label ou aresta mudou, e o radar --integrity --schema sai 0 em todos. Os confirmed de maior
  impacto desses arquivos (E_SEMGREP_FINGERPRINT_INCLUI_NOME_DA_REGRA, E_PRECOMMIT_R_CHECKER_DEPOIS_DE_FIXER,
  E_OBJECAO_8_FINGERPRINT_SEM_REGRA_E_DETECTOR_DE_SOBREPOSICAO) foram lidos: tratam do corpus de regras e
  não respondem nem contrariam o que este PR muda, que é só a forma do mapa do nó.
---

# Resíduo — `fix/kg-ssot-signals-confirmed`

Quatro fixes de sinais de campo, cada um com caso de bancada e mutante.
