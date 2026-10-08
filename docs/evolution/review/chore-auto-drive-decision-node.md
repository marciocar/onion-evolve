---
title: 'Resíduo — a proposta do auto-drive vira nó de decisão aberto'
date: 2026-10-08
branch: chore/auto-drive-decision-node
reviewed_diff_sha256: 0387e8b48406ab35e5d4ae85d1e4b030631e9422a33fff5d07b9a9e17967a599
reviewed_code_sha256: 0a1a692c453051aa5f8910cffeb52b8f1b832b9b0d1838eccbe8942cdeb3b8bb
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Pedido do maestro (2026-10-08): registrar na fila e no Linear a proposta do auto-drive (o degrau
  AUTOMATE do /meta:drive) e pedir segunda opinião ao adotante que evolui o KG-SSOT. A fila está no teto
  de 30, então a proposta nasceu num grafo próprio, auto-drive-2026-10, com 8 nós: Q_GUARDA_API_DIRETA_DE_PROVEDOR (SAC-75, bloqueado por SAC-65) é o mecanismo da regra do dogfood obrigatório; E_DOGFOOD_POR_COMANDO_REAL (forja + comandos reais por item, decisão do maestro) restringe a decisão; a segunda opinião chegou no mesmo dia e virou 3 evidências com CONSTRAINS sobre a decisão (expansão ainda não confiável, carimbo pelo que foi lido, riscos que faltavam), e a pergunta que a pedia foi fechada como done no próprio rascunho, que nunca esteve na main.
  E_LEVA_CONDUZIDA_ATE_O_MERGE_POR_ORDEM sustenta D_AUTO_DRIVE_DEGRAU_AUTOMATE (open, não selado), que
  depende de Q_SEGUNDA_OPINIAO_KG_SSOT. Projeção no Linear: SAC-74, bloqueado por SAC-66 e SAC-67 e
  relacionado ao SAC-63. Radar --integrity --schema exit 0. Nenhum .kg.yaml existente editado, logo
  REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) sem objeto. Sem Elenxo, declarado: a
  decisão fica aberta e o Elenxo é condição dela. Pre-commit pulado por ordem do maestro; validação =
  pr-finalize + CI. Achado ao rebasear sobre o #967 (gate do contrato v3 no CI): o grafo novo subia três
  dívidas SHOULD (provenance ausente em nó confirmado, data sem aspas, label acima de 280). Curado no
  próprio grafo: datas entre aspas, provenance estruturada nos 5 confirmed, labels longos divididos em
  label curto mais narrative. É o primeiro grafo do core conforme ao contrato v3 no SHOULD; gate rc=0.
---

# Resíduo — `chore/auto-drive-decision-node`
