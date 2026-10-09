---
title: 'Resíduo — F1.5 das portas: o registro diz a verdade medida, e um carimbo era de outra adoção'
date: 2026-10-09
branch: chore/registry-honest-f15
reviewer: "revisor adversarial (Elenxo, subagente general-purpose, só leitura) sobre 1813fcb6; curas no commit seguinte com bancada registry_pins 7/7 e door_role_parity verdes, um mutante por caso"
reviewed_diff_sha256: 41fee3e2cac9a9b2eb745a4ba4e6135d87a37d38963d0ae7c0b604881360e3c1
reviewed_code_sha256: 9754d040f36db9739f15677908dffde71e684c0a4d8ac4dbb3522b297025582e
findings_total: 6
findings_real: 6
findings_fixed: 4
tokens: 136000
duration_min: 10
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  F1.5 do plano das portas (SAC-90). Dois achados médios curados no PR (carimbo de outra adoção no
  granaai; remoto que falha com clone parado virando ok). Dois menores curados (conferência do carimbo
  dentro do bloco do membro; teto da REGRA 92 para plugins declarado). Projeções regeneradas pelo
  pr-finalize. Fica declarado e não curado: classDef de mini/plugins no graph.sh (cosmético) e a
  bancada não exercitar branch com barra nem --only.
---

# O registro passou a dizer a verdade medida, e a passada derrubou um carimbo

## O que o PR entrega

- `members-validate.sh` aceita `role: mini|plugins` só com `kind: door`, e a única porta que pode
  declarar `onion_version: n/a` é a `mini`, até a F5.
- REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) reconhece a porta de marketplace
  (proveniência) e a porta mini ainda sem carimbo (declarada não-medida).
- `onion-plugins` registrado; `onion-mini` vira `role: mini`, `kind: door`; `onion-core` segue `hub`.
- `ops/registry-pins.sh --check|--seal`, com passada real nos 27 membros.
- O histórico dos comentários do registro migrou para o grafo `door-role-parity-2026-09`.

## Achados da passada adversarial

1. **Médio, curado.** O `granaai` foi carimbado com o carimbo do `brain-granaai`: os dois apontam o
   mesmo remoto, e a `develop` dele traz `role: hub`, adotado em 2026-10-01. O pin voltou a
   `6cc162f32d1c`; o script compara o papel do carimbo com o tier do registro pelo mapa da REGRA 92 e
   recusa (caso f). A decisão sobre os dois membros ficou em `Q_GRANAAI_E_BRAIN_NO_MESMO_REMOTO`.
2. **Médio, curado.** Membro com remoto cujo remoto falha caía no clone sem fetch, e clone parado
   batendo com registro parado saía `ok`, rc 0. Agora sai ILEGÍVEL, rc 3 (caso g).
3. **Menor, curado pelo fechamento.** Projeções desatualizadas no commit revisado; o
   `ops/pr-finalize.sh` as regenera.
4. **Menor, declarado.** O ramo `plugins` da REGRA 92 mede a presença da proveniência, não o `ref`; o
   pin é da REGRA 85 e da F3. Teto escrito no script.
5. **Menor, curado.** A conferência do `--seal` grepava o arquivo inteiro; agora lê o pin dentro do
   bloco do membro e exige exatamente uma linha mudada.
6. **Menor, declarado.** A bancada não exercita branch com barra, a resolução (2)/(3) nem `--only`; o
   `graph.sh` não tem classDef para `mini`/`plugins`.
