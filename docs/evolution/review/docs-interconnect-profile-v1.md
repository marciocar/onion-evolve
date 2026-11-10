---
branch: docs/interconnect-profile-v1
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: dcca36db4271a2f817c1c57c0015d114e1603ebfceeeb8f956d98098168e4ce5
reviewed_code_sha256: 25e0622621cdce62b10629708ab8957e627cb92e44d9323409c0c55c85e4a35f
findings_total: 7
findings_real: 6
findings_blocking: 0
tokens: 0
duration_min: 20
findings_fixed: 5
verdict: FIXED
elenxo: false
reviewer: passada própria sobre o próprio artefato (sem subagente); gate mecânico pelo kg-radar, kg-contract-check, kg-decide-seal, door-leak-scan e private-name-check
nota: "tokens 0 = não medido (sessão sem contador); o conteúdo do perfil já passou pela refutação da curadoria antes deste PR"
---

# Passada adversarial: `docs/interconnect-profile-v1`

## O que muda

Registra o perfil de interconexão v1 (Parte A) selado pelo maestro em 2026-11-10: `PROFILE.md` (versão pública
do rascunho refutado pela curadoria), o grafo `interconnect-profile-2026-11.kg.yaml` (tese, A1 a A5, a pergunta
aberta da Parte B com dono curadoria e aresta externa para `D_MESSAGING_DEVICE_FLOW_LOGTO_JA_1106`), os quatro selos
pelo `kg-decide-seal.sh`, a `SYNTHESIS.md` como projeção e o `docs/backlog.md` regenerado.

## Achados

1. **Vazamento de postura do host (REAL, curado).** O rascunho citava o servidor pelo apelido da máquina e a
   permissão de arquivo da fila (`0700`). Trocados por "servidor" e "estado restrito ao dono". A REGRA 106
   (Superfície que viaja passa pela varredura de vazamento da publicação) não alcança `docs/evolution/` (fora das
   raízes que viajam); rodei o `door-leak-scan.sh` (famílias sub, word e home) e o `private-name-check.sh` direto
   na pasta: 0 achados.
2. **Contagem de rodadas divergente (REAL, curado).** A tarefa diz 6 rodadas; o rascunho diz 5 (bloqueios 7, 5, 3,
   4, 5) e aponta arquivos `profile-review*.md` que não estão na pasta de origem. O `PROFILE.md` não afirma número
   de rodadas nem aponta arquivos ausentes: lista os bloqueios medidos e diz que o histórico fica fora do repo.
3. **Proposta lida como selada (REAL, curado).** A seção "Decisões para o maestro" era pergunta aberta; ganhou o
   bloco com o selo de 2026-11-10 e os ids das quatro decisões, para não ser lida como pendente.
4. **Citações `a2a-verify.sh:N` não re-medidas por inteiro (REAL, LIMITE).** Conferi `:80`, `:120-122`, `:354`,
   `:393-396` e `:460-466` contra a `origin/main` de hoje; as demais (`:76`, `:115,119`, `:289,512`, `:468`) vêm
   da refutação da curadoria e não foram re-medidas aqui.
5. **Label do 1º selo acima do teto (NÃO é achado do artefato).** O selador recusou 293 caracteres (teto 280),
   sem escrever nada; reescrevi o label mantendo os quatro compromissos.

6. **PROFILE.md sem nó que o cite pelo caminho (REAL, curado).** A REGRA 29 (Gate de PROVENIÊNCIA INVERTIDO, com
   catraca) barrou o 1º commit: os `trace:` diziam só "PROFILE.md". O `trace:` da tese passou a citar o caminho
   inteiro; radar e contrato seguiram verdes e o lint completo deu 0 HARD.

7. **Códigos de seção sem termo (REAL, curado).** O contrato KG-SSOT do `pr-finalize` reprovou `A3`, `A4` e
   `A5` nos labels (`vocab.code-unresolved`). Cada nó de seção ganhou o próprio `x_term` (notation `A1` a `A5`,
   scheme `interconnect-profile`), sem nó novo; o lint de nomes deu 0 código novo sem termo.

## Mutantes

Nenhum: o PR não toca guarda nem script.

## Limites declarados

- As seções A1 a A5 estão `done` em DEV como conteúdo do perfil selado, não como comportamento medido: a execução
  da Parte A é que mede o código.
- A aresta para `D_MESSAGING_DEVICE_FLOW_LOGTO_JA_1106` é `TRACES_TO` com a revisão dita na narrative da pergunta;
  a gramática não tem aresta própria de "revisa".
