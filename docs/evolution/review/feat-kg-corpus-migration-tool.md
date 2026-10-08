---
title: 'Resíduo — a ferramenta de migração do corpus ao contrato v3 nasce e passa na onda piloto'
date: 2026-10-08
branch: feat/kg-corpus-migration-tool
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-73 parte 1, conduzido pelo /meta:drive (quebra do @story-points-framework-specialist: ferramenta
  idempotente com --check, 5 SP, e onda piloto, 3 SP). (1) vendor/kg-ssot em contract-v3.0.2
  (408fefa6a12f, 182 arquivos; mesmo contrato, muda guia e docstring), check íntegro. (2)
  .claude/utils/kg/kg-migrate-v3.py: determinística, idempotente, edição por linha (o radar é awk), nunca
  grava YAML inválido; cita datas (baseline, review_after, verified_at, valid_from); deriva provenance SÓ
  de fonte que o nó já traz (trace, ou URL ou caminho citado no verified_against), com o verified_against
  como locator e um method que declara a derivação sem reverificação; nó sem fonte derivável não recebe
  nada e sai como SEM FONTE RECUPERÁVEL; label acima de 280 fica intacto e só é reportado; --check não
  escreve e sai 1 com mudança pendente. (3) Onda piloto em guard-pre-push-2026-10 (8 nós): sem provenance
  5→0, datas sem aspas 2→0, labels longos 8→8 (reportados); 2ª aplicação no-op; radar exit 0,
  kg-contract-check rc 0; gate do contrato desceu (provenance 141→139, data sem aspas 137→135) e a base
  foi travada com --update. Ensaio sem escrita no corpus inteiro: 144 grafos, 129 com mudança, 3.460
  datas, 2.539 provenance deriváveis, 1.255 nós confirmed ou PROD sem fonte recuperável, 2.310 labels
  longos. Bancada: família kg_migrate_v3, 8 casos; 5 mutantes reprovam (M1 datas desligadas → (a); M2
  fonte inventada → (c); M3 label cortado → (d); M4 --check que escreve → (e); M5 provenance repetida →
  (f)). Achados no caminho: (a) a bancada abortava sob set -e quando a saída tinha data sem aspas (o
  json.dumps não serializa date) — curado com default=str e || true nos passos que não decidem; (b) a 1ª
  versão do M3 não mordia porque o limiar de linha (300) era maior que a linha da fixture (297) — defeito
  do mutante, não da cura; refeito com limiar 200, reprova. Fixture inline na família (como a do
  kg_contract_check), não no manifest.tsv: o manifesto é de sondas de lint, e esta é de ferramenta.
  Passada adversarial própria, mandato de achar proveniência inventada ou significado mudado: (i) a fonte
  derivada do trace é o artefato de que o nó fala, não necessariamente o que foi lido para medir — o
  method declara "derivado, não reverificado", e esse é o teto; (ii) um caminho citado de passagem no
  verified_against ("não é ops/x.sh") viraria fonte — teto declarado, as ondas devem revisar o relatório;
  (iii) linhas dentro de escalar em bloco (narrative: >-) com cara de chave de data ou de campo seriam
  editadas — não há caso medido no corpus; teto declarado. REGRA 87 (PR que EDITA um .kg.yaml enxergou os
  confirmed dele) — confirmed vistos: E_GATE_ACEITA_FORMA_QUE_O_CONTRATO_REPROVA,
  D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO, E_CONTRATOS_V2_V3_PEDEM_MIGRACAO, E_GATE_DO_CONTRATO_NO_CI,
  E_GERADORES_ESCREVEM_O_CONTRATO_V3, E_CHECKPOINT_DO_DRIVE_FORA_DO_CONTRATO,
  E_FERRAMENTA_DE_MIGRACAO_E_ONDA_PILOTO; E_TRES_PRS_AO_CI_COM_LINT_VERMELHO,
  E_O_DOGFOOD_ACHOU_DOIS_DEFEITOS_NO_PROPRIO_MOTOR, C_TETO_O_QUE_O_PRE_PUSH_NAO_PEGA,
  E_ELENXO_REPROVOU_O_MOTOR_QUE_LAVAVA_RESIDUO, E_ELENXO_2_REABRIU_B1_PELA_FORMA_DO_HASH. Sem Elenxo
  separado, declarado. Pre-commit pulado por ordem do maestro; validação = família + mutantes +
  pr-finalize + CI.
---

# Resíduo — `feat/kg-corpus-migration-tool`
