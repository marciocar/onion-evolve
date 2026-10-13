---
title: 'Resíduo — o modo porta vem de kind: door, e o carimbo standalone do adotante volta a passar'
date: 2026-10-13
branch: fix/standalone-stamp-cut-vs-door
reviewed_diff_sha256: 6294a66e397fb28cd4aaf5191b83070fba5f330fee6aeab41a09cca98bb62986
reviewed_code_sha256: 6b11d9cd8daf7e37a597c8eacc88a02360c3bd5aab52bcd18286d6b31684869c
findings_total: 4
findings_real: 4
findings_fixed: 3
tokens: 0
duration_min: 90
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Passada adversarial do próprio autor, com medição, sem revisor independente (declarado). A cura
  separa as duas perguntas que o `role:` do carimbo respondia: o CORTE continua no `role:` e o MODO
  PORTA passa ao `kind: door`. Achados da passada: (1) REAL e CURADO — escrever `kind: door` num
  adotante fazia registro e carimbo contarem histórias diferentes sem nenhum gate avisar; a REGRA 92
  ganhou [adotante/CARIMBO-DE-PORTA] (no lint isso não foge de guarda: liga MAIS guardas). (2) REAL e
  CURADO — porta standalone ou source que perdesse o `kind: door` passaria a ser julgada como adotado
  (ou como o core) em silêncio; a REGRA 92 ganhou [porta/SEM-KIND-DOOR], medido sem achado no vivo
  (onion-standalone, onion-core e onion-mini carimbam o campo; onion-plugins não tem árvore .claude/).
  (3) REAL e CURADO — o caso (g) do registry-pins herdava o mundo do caso novo (f2) e caiu; o (f2)
  devolve o estado. (4) REAL e NÃO CURADO, declarado — os predicados de `kind: door` do lint não
  aceitam aspas (`kind: "door"` não liga o modo porta), como os três que já existiam; o materializador
  escreve sem aspas e a REGRA 92 aceita as aspas no ramo do adotante. Conferido e sem achado: o corte
  de um hub não muda (pv-d e o manifesto não foram tocados); o `--update` num carimbo standalone sem
  kind segue cortando a adoção (role_cut u6); os predicados de evidência core-privada que já
  isentavam `standalone` (escada, resíduo de revisão, hook do PR) seguem certos para os dois.
---

# Resíduo — `fix/standalone-stamp-cut-vs-door`

Defeito medido em 2026-10-13 na adoção greenfield do bomtexto (pin bd769f168411, papel standalone):
o `/meta:adopt --role standalone` grava `role: standalone` de propósito (o corte), e o core reprovava
esse carimbo — `ops/registry-pins.sh` deu DIVERGE de papel e a REGRA 92 (Papel da porta no registro
concorda com o CARIMBO dela) só aceitava `standalone` com `adopted`.

Reprodução da regra antiga: o clone do sge com só o carimbo trocado de `adopted` para `standalone` foi
de 0 a 16 HARD no lint vendorizado dele. Com a cura aplicada ao mesmo lint: 0 HARD e o mesmo conjunto
de 16 SOFT do carimbo `adopted` (diff vazio). A porta onion-standalone (`role: standalone` +
`kind: door`) dá saída idêntica antes e depois: 0 HARD, 10 SOFT.

Bancada (LC_ALL=C): role_vocabulary 12/12, door_role_parity 22/22, registry_pins 9/9, role_cut e
write_stamp 52/52. Sete mutantes por `ops/mutate-and-restore.sh`, todos reprovam o caso nomeado: sem o
ramo standalone (pv-b, pv-g, pv-e2e-a), ignorando o kind (pv-a), mapa sem standalone→standalone (g3),
sem CARIMBO-DE-PORTA (g3b), sem SEM-KIND-DOOR (d2), registry-pins sem standalone→standalone (f2) e sem
standalone→adopted (f2).

Teto: o julgamento do adotante só vale onde o clone está nesta máquina; no CI a REGRA 92 declara NÃO
MEDIDO. Os itens da mesma família declarados em Q_CARIMBO_DO_ADOTADO_STANDALONE (projeção do wizard,
skill onion-wizard, links de co-evolve e co-relay) não foram tocados.

Re-revisão depois do rebase: o adotante da adoção greenfield entrou no members.yaml pela main, e a
REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) acusou o nome dele em três comentários
que viajam. Os comentários foram generalizados (só texto; nenhuma lógica mudou) e a bancada das
famílias alcançadas foi re-rodada.
