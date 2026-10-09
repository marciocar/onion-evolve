---
title: 'Resíduo — F0 das portas: a matriz registrada, e a superação era parcial em todos os alvos'
date: 2026-10-09
branch: docs/doors-matrix-f0
reviewer: "revisor adversarial (Elenxo, subagente general-purpose, só leitura) sobre e81635cd; curas em 2380241d com radar --integrity --schema exit 0 nos dois grafos e kg-contract-check rc 0 no grafo de lar"
reviewed_diff_sha256: 26e9b9c7df348ffcb6bc30af72cb53b855049ed13afcdc5c31a58a7c932a2a73
reviewed_code_sha256: 9054a48445882335f1022f48e4b075edb7421ff5e3278b04b76091fb6479158e
findings_total: 8
findings_real: 8
findings_fixed: 8
tokens: 140000
duration_min: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  F0 do plano das portas (SAC-88), só registro e doutrina. O revisor reprovou a 1a redação sem
  bloqueador: 6 achados médios e 2 menores, todos curados no próprio PR. O item 3 do briefing (papéis
  mini e plugins no members.yaml) PAROU por medição: o schema recusa os dois valores.
---

# A matriz das portas entrou no grafo, e a 1a redação superava demais

## O que o PR registra

- `D_MATRIZ_DE_PORTAS_2026_10` em `docs/onion/graph/door-role-parity-2026-09.kg.yaml`: a decisão do
  maestro de 2026-10-09 (testemunho, `evidence_class: testimony`).
- `E_ONION_CORE_NASCEU_PUBLICO_2026_09_17`: o fato que o corpus nunca tinha virado nó.
- `E_REGISTRO_RECUSA_PAPEL_MINI_E_PLUGINS` e `Q_REGISTRAR_ONION_PLUGINS_NO_MEMBERS`: a parada do
  item 3, medida (`members-validate.sh` sobre cópia mutada: `role inválido (mini)`, rc 1).
- Logto: `E_LOGTO_CADASTRO_ABERTO_INTENCIONAL_2026_10_09` + `Q_LOGTO_QUANDO_FECHAR_O_CADASTRO`, e a
  linha da doutrina em `docs/onion/identidade-onion-vps.md`.
- CLAUDE.md (regime PORTA com quatro portas), notas na KB `public-door-vs-private-core.md` e no
  `members.yaml` (só comentários).

## Achados da passada adversarial (todos curados)

1. **SUPERSEDES errado no Logto.** O `I_A1` diz onde fica o portão real (403 em `/identification`), e
   isso segue valendo. Virou `CONSTRAINS`.
2. **Testemunho vestido de medição.** O estado do Logto veio da sessão do maestro e não foi remedido.
   Virou `evidence_class: testimony`, `plane: DEV`, sem `source_kind: repo`; a doutrina diz "relato".
3. **Aufhebung incompleta.** Faltavam quatro nós selados: `D_FAMILIA_TEM_DOIS_REGIMES_2026_09`,
   `D_FAMILIA_TEM_TRES_REGIMES_2026_09`, `E_FAMILIA_MULTIIDE_CONGELADA` e
   `D_ONDE_COBRAR_A_DEFASAGEM_DA_PORTA`. Entraram em `x_supersedes_external` e na nota do lote.
4. **Superação total onde ela é parcial.** De `D_CORTE_…` sobrevive "tudo viaja" para o onion-core;
   de `D_VEICULO_…` sobrevive o reenquadramento do `/meta:adopt` com `onion/vendor`. A narrative da
   matriz agora diz o que cai e o que sobrevive em cada alvo.
5. **KB pública contradizia a matriz** ("Nunca: meta-factory" para o standalone; mini que nunca
   vendoriza). Nota de superação parcial na KB e no comentário do standalone no registro.
6. **CLAUDE.md prometia no presente** a publicação sob demanda, que só existe a partir da F3. Corrigido:
   a REGRA 85 e o `onion-door-staleness` seguem cobrando até lá.
7. **Fonte da decisão não verificável** (plano local fora do repo). A fonte principal passou a ser a
   SAC-88, e o nó é declarado testemunho.
8. **onion-plugins na doutrina e fora do registro, sem gatilho.** Nasceu
   `Q_REGISTRAR_ONION_PLUGINS_NO_MEMBERS`, com gatilho na ampliação do schema (F1.5/F2).

## Flips propostos ao maestro (não aplicados)

Nomeados em `meta.x_drive_checkpoint_note` (checkpoint `pending`): `D_CORTE_E_TUDO_INCLUSIVE_META_FABRICA`,
`D_VEICULO_STANDALONE_PUBLICO_MAIS_ADOPT`, `D_ADOPT_REFRAME` (condicional), os três nós de regime de
`onion-identity-2026-07`, `D_ONDE_COBRAR_A_DEFASAGEM_DA_PORTA` (só na F3) e
`Q_LIBERAR_A_META_FABRICA_PARA_O_PLUGIN` (open→done).

## Teto declarado

- `identidade-onion-vps-2026-08.kg.yaml` segue com `kg-contract-check` rc 1 por 17 nós sem
  provenance que já estavam em `origin/main`. Os nós novos não somam nenhum (contado antes e depois):
  a dívida é da onda O3 (SAC-73), que já tem esse grafo no universo.
- O `provenance.json` publicado no `onion-plugins` nomeia `marciocar/onion-evolve` (o core privado)
  num repo público. Não é deste PR; fica para a F3/F4.
