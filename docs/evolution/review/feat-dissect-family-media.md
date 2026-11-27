---
branch: feat/dissect-family-media
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_blocking: 1
tokens: 146705
duration_min: 12
findings_fixed: 5
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "subagente general-purpose isolado (não-fork), mandato REFUTAR, sem o raciocínio de quem escreveu"
nota: "O refutador reprovou por 1 bloqueante (o ponteiro da prova N2 citava o id do repo privado da curadoria: REGRA 106 HARD, medido no door-leak-scan e no lint) e 4 menores. Os 5 foram curados no mesmo commit, e a bancada subiu de 148 para 154 casos. tokens = só o refutador."
---

# Passada adversarial: `feat/dissect-family-media`

## O que muda

- Família `midia` no registro do `/meta:dissect`, com `n2_proof` (evidência, selo, mecanismo, limites) e a pergunta
  aberta `Q_MEDIA_N2_LOCAL_RUN` como `CONSTRAINS`.
- Item 12 do checador (`--registry`): família forjada depois do v1 sem a prova N2 reprova. O lint roda o item sobre o
  registro real na família `run_dissect_object_selftests`.
- Doutrina §6: linha da tabela, 7º predicado, a regra da prova N2 e o N2 da mídia declarado como lido, não verificado.

## Achados

1. BLOQUEANTE: `n2_proof.source` e `decision` começavam com o id do repo privado da curadoria, e o registro viaja às
   portas públicas (REGRA 106 HARD). Curado: os ponteiros usam o apelido do papel, `curadoria:`, e a doutrina diz
   por quê. `door-leak-scan.sh` sobre o registro: rc 0. O histórico foi refeito antes do push, então o id não sobe.
2. Menor: a isenção v1 olhava só o id; renomear uma família v1 criava família nova isenta. Curado: `FAMILIES_V1` é
   mapa id → pref. Caso novo na bancada.
3. Menor: `mechanism` numa lista ou número e `limits` com lixo passavam. Curado: texto não vazio e lista de textos.
   Dois casos novos.
4. Menor: a doutrina prometia "ponteiro para o selo" e o código só via a forma. Curado: `decision` num nó `D_`/`Q_`
   e distinta de `source`; doutrina e docstring dizem que o checador não resolve o ponteiro noutro repo. Dois casos.
5. Menor: a família cortou `perseguir` e `projeto-novo` da decisão sem dizer, não criou a pergunta aberta sobre o N2
   e não limita o estudo enquanto o cálculo local não roda. Curado: o corte está em `limits`, a pergunta é o nó
   `Q_MEDIA_N2_LOCAL_RUN` (CONSTRAINS a família), e a doutrina declara o N2 lido, não verificado.

## Mutantes

- Cada código do item 12 tem caso que o acusa e mutante calado que o deixa passar (bancada: 154 casos + 5 de rc 3).
- "Família nova sem a prova N2" (tirar a prova) reprova; com o código calado, rc 0.
- Família aposentada (`superseded`) sem prova N2 passa: o mutante sobrevivente que o refutador apontou ganhou caso.

## Limites declarados

- O checador não cobra ainda o alfa de Krippendorff num estudo de mídia; é a pergunta `Q_MEDIA_N2_LOCAL_RUN`.
- A partição em 5 tipos de mídia não vem da fonte (limite da evidência).
