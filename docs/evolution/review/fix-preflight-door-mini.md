---
branch: fix/preflight-door-mini
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 0755ce72d1c155f209edcc85eae545ecc6d8836540dcfbe5573258f729449b1d
reviewed_code_sha256: 8a338f993c0338f88b0514fd28b6b45453f08429091255c02974d4f4eb06dbd1
findings_total: 7
findings_real: 7
findings_blocking: 2
tokens: 0
duration_min: 45
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: autor (passada própria; o brief proibiu subagentes)
nota: "tokens não medidos (0). Passada adversarial feita pelo autor, sem revisor independente: o brief da sessão principal proibiu lançar subagentes."
---

# Passada adversarial: `fix/preflight-door-mini`

## O que muda

- `ops/testing/preflight-families.sh` soma `door_mini` quando o diff (índice contra o merge-base) toca a
  superfície do mini: a allowlist do papel `mini` (relativa a `.claude/`), as fontes dos overlays e os
  insumos da verificação (roles.yaml, resolvedor, door-mini-check, vendor-manifest, materializador). A
  allowlist e os overlays saem do roles.yaml do ÍNDICE pelo `resolve-role-bundle.sh`; roles.yaml que não
  resolve faz a família entrar. A saída deixou de repetir família.
- `run_door_mini_selftests` mede o índice quando ele difere do HEAD (commit sintético do índice, worktree
  descartável). No CI o índice é o HEAD e nada muda.
- Bancada `preflight_families` ganhou (c) seleciona, (d) não seleciona, (e) falha para o lado de medir e
  (f-MUT).

## Achados

1. **BLOQUEAVA, curado.** A 1ª versão testava a família na bancada stageada com `git show | grep -q`, a
   classe EPIPE sob pipefail: o `grep -q` fecha cedo, o `git show` morre de SIGPIPE e o `if` dava falso.
   Medido: a seleção nunca disparava. Trocado por `git grep -q --cached`.
2. **BLOQUEAVA, curado.** Selecionar a família não bastava: o materializador e o checador leem o HEAD, e o
   pré-voo do `pr-finalize` roda antes do commit de conteúdo. Medido com o ponteiro morto só stageado: a
   door_mini saía 13/13 verde sobre o HEAD velho. Curado medindo o índice.
3. **Limite.** Arquivo NOVO fora do mini cujo nome um arquivo do mini já cita (comando ou agente novo no
   core) passa a contar como ponteiro e não seleciona a família. Raro, e cobri-lo selecionaria a door_mini
   em quase todo PR que cria arquivo.
4. **Limite.** Remover ou renomear um arquivo de fora do mini que o mini cita (linha do `known_absent`)
   também não seleciona. O CI segue juiz.
5. **Limite.** Os cinco insumos da verificação são uma lista escrita no helper. A superfície que viaja é
   derivada; a lista é a da maquinaria da própria família.
6. **Limite.** A cura do índice não tem caso de bancada: exigiria stagear no repo real. A prova é a medição
   de dogfood (antes 13/13 verde com o defeito stageado; depois ✗ door-mini (a) com o mesmo defeito; e
   verde com mudança inocente stageada).
7. **Limite.** Se a família morrer no meio (timeout), a worktree do índice fica registrada até o
   próximo `git worktree prune`; o diretório é temporário.

## Mutantes

- `(f-MUT)`: o helper sem o bloco da porta mini não escolhe `door_mini` para o arquivo da allowlist do
  fixture. Morto pela bancada.
- A allowlist do fixture tem `commands/so-no-fixture.md`, que não existe no roles.yaml real: selecioná-lo
  mata o mutante "lista à mão no helper".
- Cura do índice: o `origin/main` é o mutante (mede o HEAD). Morto pela medição manual do achado 6.

## Limites declarados

Os achados 3 a 7 acima.
