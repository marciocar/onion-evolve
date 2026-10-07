---
title: 'Resíduo — pesquisa do canal vivo entre sessões em máquinas e contas diferentes'
date: 2026-10-07
branch: docs/research-live-channel
reviewed_diff_sha256: 348853f9b2a10bbacad68dacd9c9d6ff2e391b0d3869905c74eacc98ad37586d
reviewed_code_sha256: 4553ac77746e01d54df895cc3f392cc5b864dd2382c3f8b8756016b3450b0619
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 1335388
duration_min: 10
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Pedido do maestro: transformar em grafo a pesquisa sobre comunicação direta entre sessões Claude
  Code de máquinas diferentes, restrita a membros autorizados (granaai usa Slack, gmill usa Teams).
  Rodado o /onion-research no modo primárias (run wf_da77c143-24c, 18 agentes, 1,34M tokens), com
  as 8 fontes nomeadas pela rodada prévia de agente único: leitura com citação verbatim, ancoragem
  por verificador separado e Elenxo. Grafo novo: 42 evidências confirmed (34 ancoradas e as objeções
  sobreviventes), 1 pergunta-raiz open e 1 claim open com as restrições de desenho da classe 'live'.
  Nada selado, nenhum nó decision: a decisão do canal vivo é do maestro. 11 claims rejeitadas na
  ancoragem (todas exageradas) estão contadas em E_LACUNAS_CANAL_VIVO_PRIMARIAS_1007. Achado na
  revisão do que ficou em aberto, pedida pelo maestro: o Elenxo NÃO foi truncado (julgou as 38
  objeções); o workflow cortava o JSON dele em 7.000 chars antes do escritor. As 13 sobreviventes além
  do corte foram recuperadas do journal do run e viraram nós E_ELENXO_* com CONSTRAINS (44 → 57 nós);
  a cura do corte vai no PR fix/research-elenxo-not-truncated. Radar --integrity --schema exit 0. Nenhum .kg.yaml
  existente editado, logo REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) sem objeto.
  Pre-commit pulado por ordem do maestro; validação = radar + pr-finalize (0 HARD) + CI.
---

# Resíduo — `docs/research-live-channel`

Pesquisa nova; nenhum código muda.
