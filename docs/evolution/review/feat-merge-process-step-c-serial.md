---
title: 'Resíduo — passo C do processo de merge: ops/merge-serial.sh com lock só no rebase+merge, e o auto-rebase deixa rastro no PR'
date: 2026-10-13
branch: feat/merge-process-step-c-serial
reviewed_diff_sha256: 7c8d03febf637ed89841204133e02f41ffc1d3efab0c18e946dab28ffd68d5f0
reviewed_code_sha256: 97357ec670448f9755bf3df947339b989a9acf1aedfa072beed6060196877a26
findings_total: 4
findings_real: 4
findings_fixed: 3
tokens: 0
duration_min: 90
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Passo C da decisão selada D_MERGE_PROCESS_ONION_2026_10 (nó C_OPCAO_C_MERGE_SERIAL_IN_OPS, agora
  done). O helper merge-serial do scratchpad vira ops/merge-serial.sh (core-only), com as objeções
  E_OBJECAO_LOCK_ONLY_ON_REBASE_AND_MERGE, E_OBJECAO_LOCK_SCOPE_SETS_THROUGHPUT,
  E_OBJECAO_FLOCK_MUST_WRAP_API_MERGE, E_OBJECAO_HELPER_LIVES_ONLY_IN_SCRATCHPAD e
  E_OBJECAO_ADOPT_SERIALIZATION_NOT_TOOL atendidas. O lock (flock no git-common-dir, com teto de
  espera) envolve só a chamada ao ops/pr-merge-verified.sh; o CI é esperado fora dele; o fd do lock é
  fechado no filho; o auto-rebase faz o verificado sair rc 4 (--no-wait-after-rebase novo), o lock é
  solto e o PR volta à fila; o limite de rebases vale para a série (ONION_MERGE_REBASE_DONE). O
  verificado comenta no PR cada auto-rebase (head antigo para novo, causa projeção ou fonte, N/MAX);
  comentário que falha vira aviso nomeado. O pr-finalize passou a nomear cada projeção que resolveu,
  e é dali que sai a causa. Família nova merge_serial, 17 casos verdes sob LC_ALL=C, e 17
  mutantes por ops/mutate-and-restore.sh, cada um reprovando o seu caso. Dogfood no forge real só
  pelos caminhos sem efeito (PR já MERGED é pulado nomeando o mergedAt; PR repetido recusado; uso sem
  argumento); merge real é proibido nesta tarefa. Passada adversarial (refutador default reprovado),
  quatro achados reais. (1) A decisão da dispensa fazia leituras do forge DENTRO do lock: um gh
  pendurado seguraria o lock sem teto. Curado: a decisão saiu do lock; se o head mudar até o lock, o
  verificado recusa a dispensa preventiva ou o veredito que passou a falhar, e as duas direções param.
  (2) Só a anotação da PRIMEIRA run do check era lida; com re-run, um "apontou" numa run e um "NÃO
  revisou" noutra davam dispensa automática de achado. Curado (caso d4 com mutante): lê as anotações de todas as runs do
  check no head, e qualquer "apontou" para a série. (3) A variável de ambiente que trocava o arquivo
  do lock tirava uma série da serialização sem ninguém ver. Curado: removida; o lock é fixo no
  git-common-dir. (4) Duas séries ainda podem intercalar merges (o flock não é fila justa), uma
  chamada direta ao verificado não toma o lock, e o helper antigo do scratchpad usa outro arquivo de
  lock. Não curado, declarado como teto no cabeçalho do script e no nó: dentro de uma série a ordem é
  estrita, e entre séries o custo é um rebase a mais, nunca um merge sem os gates. Pre-commit pulado
  (--no-verify, checkpoint declarado); validação = famílias tocadas + mutantes + radar --integrity
  --schema exit 0 + kg-contract-check rc 0 + pr-finalize + CI.
---

# Resíduo — REGRA 56

## Achados da passada adversarial

1. **Leitura do forge dentro do lock** — curado (decisão da dispensa antes do `flock`).
2. **Só a 1ª run do `onion-review-verdict` era lida** — curado (todas as runs do head; qualquer "apontou" para).
3. **Knob de ambiente para o arquivo do lock** — curado (removido).
4. **Intercalação entre séries / chamada direta / helper antigo** — teto declarado, não curado.
