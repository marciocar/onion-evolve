---
title: 'Resíduo — os geradores de grafo do core nascem no contrato v3 do .kg.yaml'
date: 2026-10-08
branch: feat/kg-generators-contract-v3
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 1
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-71, conduzido pelo /meta:drive até o merge com autorização do maestro. Parte "gerador primeiro" de
  Q_MIGRAR_CORPUS_PARA_CONTRATO_V3; o corpus herdado é o SAC-73 e não migra aqui. Contexto medido: desde
  o #967 o gate do contrato v3 reprova no CI grafo novo que suba a dívida SHOULD, e o gate só vê arquivo
  rastreado; o grafo novo foi curado à mão duas vezes no mesmo dia (#967, #968).
  O que entrou: (1) .claude/validation/kg-contract-check.sh, que julga um arquivo antes do commit
  importando o leitor de referência do vendor (kg_gate.measure_texts), sem reimplementar o contrato:
  grafo novo exige MUST e SHOULD vazios; grafo rastreado só não pode piorar o SHOULD que tinha em HEAD;
  rc 2 quando não há vendor (adotante), nunca verde. (2) onion-research.js: bloco CONTRACT_V3 nos dois
  write(KG) (primárias e demais modos) e o passo de rodar o kg-contract-check depois do radar; a regra
  "sem fonte real, o nó NÃO é confirmed" está no prompt; rc 2 é declarado e não bloqueia. (3)
  seed-adoption-graph.sh: a semente de todo adotante saía com 11 avisos SHOULD (8 chaves de topo fora do
  contrato, datas sem aspas, labels de até 520 caracteres sem provenance) e agora sai com zero. (4)
  census-seal.py: o carimbo grava a data entre aspas, e o nó DRIFTED nasce com label curto, narrative e
  provenance. (5) .claude/rules/kg-grammar.md: as três exigências do v3 e o kg-contract-check no "Antes
  de fechar". (6) O grafo contrato-kg-absorcao-2026-10 foi migrado ao v3 no mesmo passe e ganhou
  E_GERADORES_ESCREVEM_O_CONTRATO_V3 e E_CHECKPOINT_DO_DRIVE_FORA_DO_CONTRATO; a dívida do corpus desceu
  (provenance 142→141, data sem aspas 138→137), e o ganho foi travado no .kg-ssot/gate.json.
  Bancada (LC_ALL=C): família nova kg_contract_check 5/5; research_workflow (p); seed_adoption_graph
  (v3); census_seal (v3); as 22 famílias afetadas 110/110. Mutantes, todos morderam: cobrar a dívida
  herdada como nova reprovou (c); nunca cobrar o SHOULD reprovou (b) e (d); tirar o CONTRACT_V3 do
  prompt das primárias reprovou (p); a data sem aspas na semente reprovou (v3); o census-seal anterior
  reprovou (v3).
  Achado curado: os três escritores mediram fora do contrato (semente, carimbo do censo, write(KG) sem
  checagem). Achado declarado e NÃO curado: o --close-lot do /meta:drive grava drive_checkpoint e
  drive_checkpoint_note no meta, chaves que o contrato não conhece; renomear toca 2 scripts, a bancada,
  fixtures e 2 grafos com dado, e a alternativa é o contrato conhecer as chaves — decisão de contrato,
  registrada como E_CHECKPOINT_DO_DRIVE_FORA_DO_CONTRATO. O radar lê narrative e o bloco aninhado de
  provenance sem borda (o grafo auto-drive-2026-10 já os usa e passa; nenhum caso de bancada novo).
  Passada adversarial própria, à procura do falso positivo: (1) grafo rastreado RENOMEADO cai como sem
  versão em HEAD e tem a dívida herdada cobrada como nova — teto declarado, raro, e a saída é migrar o
  arquivo no mesmo passe; (2) o prompt podia levar o escritor a inventar fonte para passar: a regra
  explícita é deixar open o que não tem fonte, e no modo pesquisa a fonte é a URL que o leitor abriu;
  (3) num adotante sem o vendor o checador sai rc 2 e o prompt manda declarar e seguir, então ele não
  trava a pesquisa de ninguém. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) —
  confirmed vistos: E_GATE_ACEITA_FORMA_QUE_O_CONTRATO_REPROVA, D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO,
  E_CONTRATOS_V2_V3_PEDEM_MIGRACAO, E_GATE_DO_CONTRATO_NO_CI. Sem Elenxo, declarado: execução de direção
  já selada pelo maestro (gerador primeiro). Pre-commit pulado por ordem do maestro; validação =
  famílias afetadas + mutantes + pr-finalize + CI.
---

# Resíduo — `feat/kg-generators-contract-v3`
