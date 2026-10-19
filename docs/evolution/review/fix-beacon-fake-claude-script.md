---
title: 'Resíduo — o falso claude da sonda do session-beacon vira script, e a guarda volta a ser exercida no ubuntu 26.04'
date: 2026-10-19
branch: fix/beacon-fake-claude-script
reviewed_diff_sha256: aaa5374d1ad704f24185a54f0d211821a260d7fa26ef692d2e00fa9475bf423e
reviewed_code_sha256: c05614830caf4b09d352341cf0f94d1515b60dfc5d5adff8f7840c54b4a4ba8c
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 30
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Perna "adaptar" de D_RUNNER_FIXADO_2404_1019 (grafo ci-runner-2604-2026-10). No runner ubuntu-26.04 a sonda do
  session-beacon caía em STRICT com "comm não observável após 2s (último comm visto: <vazio>)". Causa medida num
  container ubuntu:26.04 na VPS: o coreutils lá é o uutils, um binário multicall que escolhe a ferramenta pelo
  argv[0]; a bancada copiava o sleep como "claude", e a cópia responde "coreutils: unknown program 'claude'" e sai
  com rc 1 na hora, então o comm nunca é visto. Não é corrida, é estrutural. Cura: o falso claude vira um script
  (#!/bin/sh com laço de sleep 1), cujo comm é o nome do arquivo e que não deixa órfão ao ser morto. Prova: no
  container 26.04, sem root e com curl, as famílias session_beacon e federation_a2a (esta com a cura do #1207)
  dão 145 passaram, 0 pulados, 0 falharam em STRICT; na VPS (24.04) session_beacon em STRICT, 0 pulados. A cura
  revertida reproduz o defeito no 26.04 (a forma antiga foi a que o container rodou primeiro: unknown program).
  Teto: a bancada COMPLETA ainda não rodou no 26.04; é o gatilho de Q_ADAPTAR_GUARDAS_AO_2604_E_VOLTAR_AO_LATEST
  para devolver o runs-on ao ubuntu-latest.
---
