---
title: 'Resíduo — a REGRA 92 lê o carimbo do adotante na branch de integração'
date: 2026-10-19
branch: fix/r92-adopter-stamp-from-integration
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 0
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Cura selada pelo maestro no /meta:decide (Q_GRANAAI_CLONE_SEM_CARIMBO, "Guarda lê a integração"). Medido em
  2026-10-19: o adotante granaai está vivo e adotado, com o carimbo na develop igual ao registro, mas o clone
  local está parado numa branch de trabalho sem .claude/ rastreado, e a REGRA 92 acusava CARIMBO-AUSENTE num
  membro em dia. A guarda agora lê a árvore de trabalho primeiro e, sem ela, o carimbo da branch de integração
  (resolve-integration-branch.sh, local e depois origin/). Sem carimbo nas duas, segue CARIMBO-AUSENTE.
  Bancada: (g6) clone em branch de trabalho com o carimbo só na integração cala; (g6b) clone git sem carimbo em
  lugar nenhum segue nomeado. Mutante: com a leitura da integração desligada, (g6) reprova (medido, 1 falha).
  Dogfood: a guarda contra o core real deixou de acusar o granaai (rc 0). Passada adversarial própria, sem
  refutador separado (elenxo: nao): o achado que fica é um TETO declarado, não curado — a branch de
  integração LOCAL pode estar defasada (o clone do granaai não busca desde 09-11), e a guarda lê o carimbo
  dela antes do origin/. Papel de adotante muda raramente e o fetch é da equipe dona do clone, que este core
  não toca (I3); por isso não se busca nada aqui.
---
