---
title: 'Resíduo — lote de fim do dia da fila 2026-10-06 + a tabela de tempos entra no mapa da bancada'
date: 2026-10-07
branch: chore/queue-reconcile-and-times-map
reviewed_diff_sha256: 13007a790c2b0705399ffa2ab4a3f7e38608ea8f72f6e0f816570b68d50051a3
reviewed_code_sha256: a9ca43abc2946d0e56905c77293adb520e45af71f546af83d85b5c7bf382a753
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Lote do /meta:drive sobre fila-2026-10-06.kg.yaml, fechado em uma só passada no fim do dia (o hábito
  declarado hoje: nós da fila num PR só, não um por PR). Achado curado: mudar
  ops/testing/selftest-family-times.tsv caía no failsafe "não é citado por nenhuma família" e o
  pre-commit rodava as 219 famílias; agora o caso (g) da família shard_plan cita a tabela, o --map a
  liga a shard_plan, e o caso também cobra que a tabela seja legível, porque o plano IGNORA em
  silêncio linha malformada e uma tabela corrompida devolveria o CI ao round-robin sem ninguém ver. O
  mutante (TAB→espaço numa linha de dados) reprova; a 1ª tentativa de mutante mexeu na linha de
  comentário e passou, e o defeito era do mutante, não da cura. Grafo: dois flips open→done por
  execução mergeada (Q_HOOK_LER_RESIDUO_DA_BRANCH_DO_PR pelo #948, Q_ONION_KG_SSOT_REPO pelo repo
  adotado, registrado e atualizado); quatro nós novos (D_PAPEL_DUAS_DIMENSOES confirmado pelo #949,
  Q_TABELA_DE_TEMPOS_NO_MAPA feito aqui, Q_VETO_PRETOOLUSE_NO_PR_CREATE GATED, Q_GRANAAI_CLONE_SEM_CARIMBO
  aguardando o maestro). Com isso o grafo chega a 30 nós, no TETO declarado. Checkpoint escrito pelo
  --close-lot (drive_checkpoint: pending), radar --integrity --schema exit 0, realign ALINHADO.
  REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos neste grafo:
  E_PRECOMMIT_RECARIMBA_RESIDUO, E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO,
  E_MAPA_SEM_MERGE_ONION_HOOKS, E_ADOPT_SEM_GITIGNORE_DE_SEGREDOS, E_DURABLE_COMMIT_SEM_ASSINATURA,
  E_CI_TEMPLATE_IGNORA_GITHOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO,
  E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE,
  D_PAPEL_DUAS_DIMENSOES. Sem Elenxo, declarado: reconciliação de estado já medido e um caso de bancada
  com mutante.
---

# Resíduo — `chore/queue-reconcile-and-times-map`

Teto: o caso (g) valida a forma da tabela, não a idade dela. Uma tabela legível e velha segue
equilibrando mal, e o refresco é rodar o `collect-family-times.sh` sobre um run recente.
