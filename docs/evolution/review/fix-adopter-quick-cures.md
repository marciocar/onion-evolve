---
title: 'Resíduo — curas rápidas dos adotantes recentes: HARD re-medido no --update, assinatura no merge da vendor, âncora da tarefa nos workflows e o aviso do aparte'
date: 2026-10-07
branch: fix/adopter-quick-cures
reviewed_diff_sha256: 21455cbcaab51fd5660ee00128d0ad1700d46434161457eb37d360f3fae76e3f
reviewed_code_sha256: 9061738b71087231de16aab0a893a0c97ab6f142e795aa47a05af6c9217ae92f
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 50
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Fechamento das adoções a pedido do maestro (2026-10-07: "corrigir os problemas que aconteceram com os
  últimos adotantes, do gmill em diante"). Um levantamento conferido contra o código vivo achou 26
  defeitos nesses adotantes. Este PR cura os quatro abertos e baratos:
  (1) o --update declarava "0 HARD" sem re-medir e chegou com 1 HARD num hub; agora remeasure-hard.sh
  roda o lint do alvo depois do merge, com rc=3 (NÃO MEDIDO) quando o lint quebra, em vez de "0", e o
  adopt.md manda citar o número medido (bancada remeasure_hard (a)-(d), mutante (c) morde);
  (2) o commit de MERGE do vendor-branch.sh saía sem a assinatura do adotante; agora leva o
  attribution.commit do alvo (bancada vendor_branch (b2), que precisou forçar um merge não-fast-forward:
  a 1ª versão passava com a cura revertida porque o HEAD era o commit da vendor, já assinado);
  (3) e (4) são o sinal de severidade alta do onion-kg-ssot: um aparte no meio do turno virou, pelo
  harness, o "pedido do usuário" de um Workflow inteiro (4,59M tokens, nenhum grafo). O hook do aparte
  agora avisa para disparar o Workflow só no próximo turno (aside_router_hook (w), mutante morde). E os
  três workflows do core (onion-research, evolve, census) passam a ancorar a tarefa num invólucro ag(),
  com o teto DECLARADO de que o efeito contra o bloco repassado não foi medido (a medição do adotante foi
  num resume, que não repassa nada). A bancada research_workflow (k)(l2) aceita o invólucro. Fora daqui,
  nomeados: o corte de ferramentas só do core para hub e adopted (é o corte da meta-fábrica, decisão
  separada), a convergência docs-only, e a trava de merge no adotante, que por desenho não tem o caminho
  verificado (depois do merge o PostToolUse já avisa MERGE-SEM-REVISOR). REGRA 87 (PR que EDITA um
  .kg.yaml enxergou os confirmed dele): confirmed vistos em gmill-update-547-2026-10:
  E_GMILL_VEREDITO_DOS_TRES_FALSOS_POSITIVOS, E_UPDATE_547_CARIMBOU_0_HARD_E_CHEGOU_COM_1,
  E_REGEN_POS_MERGE_MUDOU_O_INVENTARIO. Sem Elenxo, declarado: curas pequenas, cada uma com mutante.
---

# Resíduo — `fix/adopter-quick-cures`

Teto: a âncora nos workflows é instrução ao agente e pode perder para o bloco do harness; o aviso do
aparte é a parte que não depende de o agente obedecer.
