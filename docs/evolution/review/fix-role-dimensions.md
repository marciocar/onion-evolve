---
title: 'Resíduo — papel no registro e no carimbo são duas dimensões; a REGRA 92 julga o adotante por compatibilidade'
date: 2026-10-07
branch: fix/role-dimensions
reviewed_diff_sha256: 498db9da8c912026aa580998bfe9677fffec63dfe6b43a83edbe1e395b6bce96
reviewed_code_sha256: 1db5e77e83ebeb8cb0e9a4ae8ebbe40ea396bceddeec1485bcab25be657dd8b5
findings_total: 6
findings_real: 6
findings_fixed: 5
tokens: 0
duration_min: 60
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Triagem do sinal do onion-kg-ssot (2026-10-07: registro `standalone` × carimbo `adopted`). O maestro
  escolheu primeiro "vocabulário único", e o Elenxo REPROVOU a escolha com medição em clones: carimbar
  `standalone` num adotante liga o modo porta no lint (sge 0→16 HARD, onion-arthur 0→14 HARD), o corte
  levaria embora o caminho de promoção a hub e a autoria própria de três adotantes, e a doutrina já dizia
  em door-role-parity-check.sh que standalone×adopted em adotante é CORRETO. O Elenxo também corrigiu
  números meus (o corte de `standalone` exclui 92 caminhos, não 103; `adopted`/`hub` excluem 1, não 12).
  O maestro selou o desenho do Elenxo e apertou o mapa do hub (hub→hub, sem `adopted`). Curado neste
  PR: (1) o registro volta a ser só tier: `adopted` sai do enum do members-validate.sh, e a "unificação"
  de 2026-09-24 é revertida e emendada onde estava escrita (validador, members.yaml, co-deliver.md,
  co-deliver.sh como legado); (2) sge `adopted`→`standalone`, porque o parent é o core (T3);
  (3) metagamify `hub`→`standalone` (decisão do maestro: carimbo `adopted`, zero sub-adotados);
  (4) a REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) passa a julgar o adotante por
  um MAPA de pares permitidos (hub→hub; standalone|consumer→adopted), SOFT, com a porta mantendo a
  paridade exata e o adotante sem clone declarado NÃO MEDIDO; (5) fixture nova recusando `adopted` no
  registro. NÃO curado aqui (6): o clone do granaai em /home/marcio/granaai não tem
  .claude/.onion-version. A guarda nova o nomeia como SOFT, e a cura (re-apontar o local_path ou
  re-adotar) é decisão do maestro e ato fora deste repo. Medido no vivo depois da cura: 21 adotantes
  com clone, 20 compatíveis e 1 (granaai) nomeado. Bancada door_role_parity + members_registry +
  fixtures: 126/126. Três mutantes reprovam: o mapa aceitando tudo reprova (g2)(g3); voltar a pular
  adotante reprova (g2)(g3)(g5); `adopted` de volta no enum deixa a fixture nova passar. O corte da
  meta-fábrica para adotante comum fica FORA, como decisão separada a medir por adotante.
---

# Resíduo — `fix/role-dimensions`

Teto: o mapa julga só o adotante cujo clone está nesta máquina; no CI ele declara NÃO MEDIDO. O mapa
é a tradução entre os dois vocabulários e muda só se eles mudarem. O `consumer` (T2, via hub) segue
aceito no registro sem nenhum membro hoje: é o papel que o trust-topology-check.sh lê.
