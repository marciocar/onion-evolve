---
title: 'Resíduo — o pr-merge-verified ganha --merge-commit, e o update do adotante preserva a ancestralidade com onion/vendor'
date: 2026-10-08
branch: fix/merge-verified-merge-commit
reviewed_diff_sha256: d759a980256b38205ab4c215d6b6801b349d7b47b78816a7822d4637bb41c7d4
reviewed_code_sha256: 1214f7efdfb505d993a0702bfaa58d584af74b961cdbbd003ae14c0d0e1ae26d
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 40
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  SAC-76, conduzido pelo /meta:drive a partir do sinal 2026-10-08-pr-merge-verified-merge-commit do
  adotante dedicado ao KG-SSOT (arquivado em inbox/_processed neste PR). Defeito medido: o
  ops/pr-merge-verified.sh só mergeava com --rebase (fallback --squash). O PR de update de um adotante
  traz um merge real com onion/vendor, e linearizá-lo tira a onion/vendor da ancestralidade da main; no
  adotante, o PR #26 entrou por rebase e o update seguinte conflitou em falso em lint-selftest.sh, e o
  PR #35 teve de ser mergeado à mão para preservar a ancestralidade. Cura em três partes: (1)
  --merge-commit usa gh pr merge --merge, depois dos MESMOS gates (checks, veredito, dispensa nomeada)
  e com a mesma prova pelo estado; sem a flag o comportamento antigo não muda; o fallback para --squash
  só existe no modo antigo. (2) Sem a flag, se os pais dos commits do PR (lidos do forge) mostram commit
  de merge, o script AVISA e nomeia a flag, sem trocar o modo; se a leitura falha, diz que não sabe e
  não avisa nada. (3) --assert-ancestor <ref>, depois do merge provado, confere a ancestralidade contra
  origin/<base> e sai rc=3 nomeando a ref quando ela não vale, ou quando a base não pôde ser lida. O
  /meta:adopt (passo 2 do relatório downstream) passa a instruir o merge commit; o arquivo ficou nas 800
  linhas. Bancada pr_merge_verified, 22 de 22 com LC_ALL=C, casos novos (q) a (v) com as duas
  polaridades. Cinco mutantes, todos reprovaram o caso deles: --merge-commit chamando --rebase reprovou
  (q); o padrão virando --merge reprovou (r); aviso desligado reprovou (s); aviso sempre ligado
  reprovou (t); a ancestralidade sempre aceita reprovou (v). Passada adversarial própria: (a) a flag
  não pula gate nenhum, porque a escolha do modo acontece depois de todos os gates e do registro da
  dispensa, na única linha do gh pr merge; (b) o aviso pode disparar numa stack legítima que recebeu
  main por merge ("update branch"), e por isso é aviso e não veto, e o modo nunca muda sozinho; (c) com
  --merge-commit, um PR com conflito real falha no forge e cai no caminho já existente de rc≠0 com
  prova pelo estado; (d) o --assert-ancestor depende de o checkout local ter a ref pedida (ex.:
  onion/vendor), e sem ela dá rc=3, que é a direção segura. Teto: o aviso olha só os primeiros 100
  commits do PR (per_page=100); e o ops/ não viaja no payload do adopt, então o adotante sem o script
  segue a instrução pelo botão do forge. Sem Elenxo, declarado: cura estreita de script de serviço com
  mutante por cura. Pre-commit pulado por ordem do maestro; validação = família tocada + mutantes +
  pr-finalize + CI.
---

# Resíduo — `fix/merge-verified-merge-commit`
