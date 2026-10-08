---
title: 'Resíduo — o contrato v3 do .kg.yaml entra no core por pin, e o gate dele roda no CI ao lado do radar'
date: 2026-10-08
branch: feat/kg-ssot-contract-v3-gate
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 30
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-69, conduzido pelo /meta:drive a partir do sinal 2026-10-08-graduacao-contrato-v3 do adotante
  dedicado ao KG-SSOT (arquivado em inbox/_processed neste PR) e da decisão já selada
  D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO, na opção (a): o gate fica ao lado do radar, sem mudar o radar.
  Feito: vendor/kg-ssot pela tag contract-v3.0.0 (commit 820de3bbb967, 179 arquivos), o check do vendor
  íntegro; .kg-ssot/gate.json gravado pelo kg_gate.py --update com 142 grafos e dívida herdada zero
  (confere com o número do sinal); o passo "Contrato KG-SSOT (vendor íntegro + gate por grafo)" no
  onion-validate.yml, com os paths vendor/kg-ssot/** e .kg-ssot/** no filtro. Medição, nesta worktree:
  kg_gate.py rc=0 (142 de 142 no MUST); mutante, um grafo rastreado sem label, deu PIOROU
  form.required.node.label com rc=1; o vendor não foi editado. Decisão desta passada: o gate entra só no
  CI, não no pre-commit, para não pesar a esteira que acabou de ser curada (SAC-66); fica aberto em
  Q_ABSORVER_VALIDADOR_DO_CONTRATO, junto com os válidos que o radar ainda recusa, o perfil YAML 1.2 na
  REGRA 78 e o caminho (b). Grafo: E_GATE_DO_CONTRATO_NO_CI sustenta a decisão e o compromisso; radar
  --integrity --schema exit 0. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed
  vistos: E_GATE_ACEITA_FORMA_QUE_O_CONTRATO_REPROVA, D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO,
  E_CONTRATOS_V2_V3_PEDEM_MIGRACAO. Passada adversarial própria, à procura do falso positivo e do
  fail-open: (1) um PR que não toca nenhum path do filtro não roda o gate; a cobertura do filtro
  (docs/**, .claude/**, vendor/kg-ssot/**, .kg-ssot/**) inclui todo .kg.yaml do corpus, e o gate só
  mede grafos rastreados, então nada escapa no caminho normal; o teto é o mesmo de todo o lint, por
  filtro de path, e não é novo; (2) o pip install no runner pega as versões fixadas pelo
  requirements.txt do vendor, então o leitor do CI é o mesmo do medido; (3) um vendor alterado reprova
  no check antes do gate. Sem Elenxo, declarado: absorção de artefato já provado no adotante, e a
  decisão foi selada antes. Pre-commit pulado por ordem do maestro; validação = gate local + mutante +
  pr-finalize + CI.
---

# Resíduo — `feat/kg-ssot-contract-v3-gate`
