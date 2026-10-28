---
branch: chore/core-maint-1027
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: 738fa522ab8487ab0529496574c2086fce28e4cd8fa7623f5f2aa6d8c5215c82
reviewed_code_sha256: e63c9a5cace3f84587a517c382fde427226de83370e443399d10a77f6ad794e9
findings_total: 5
findings_real: 5
tokens: 115997
duration_min: 6
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: "agentes novos só-leitura (branch-code-reviewer), duas passadas adversariais curtas: o PR inteiro em 2026-10-27 e os commits depois do rebase em 2026-10-28"
nota: >-
  PR de manutenção do core, rebaseado sobre d5c58ae6a: prosa de contagem, lista de skills do CLAUDE.md, README do
  marketplace, pin da claude-code-action v1.0.264 (SAC-261), relógio injetado na bancada a2a-verify, REGRA 92
  pulando a linhagem histórica, caso (r4) do _dparen_end (não reproduz), a bancada pulando no adotante os 8 casos
  sem objeto lá (medidos num clone do sge), a pergunta do meta.x_* velho e as 4 pendências do core fechadas no
  grafo de coordenação.
---

# Passada adversarial: `chore/core-maint-1027`

## O que muda

- O carimbo do sge (`95365699a0e3`) saiu desta branch no rebase: o #1418 já o tinha levado à main (19b242a2e).
- `docs/onion/getting-started.md`, `docs/technical-context/02-ai-context/codebase-guide.md`: as contagens voltam ao
  que o `inventory.sh --env` mede (118 comandos, 14 skills, 114 KBs).
- `CLAUDE.md`: a lista de skills do "Inventário atual" nomeia as 14.
- `.claude/utils/marketplace/marketplace-readme.sh`: o README gerado para de recomendar o `onion-work-tools`, que foi absorvido;
  caso (f) novo em `marketplace_readmes`, com mutante.
- `.github/workflows/onion-review.yml`: `claude-code-action` em `d70510b1` (v1.0.264).
- `.claude/validation/lint-selftest.sh`, família `a2a_verify`: stub de `date +%s` com o NOW da fixture.
- `.claude/validation/door-role-parity-check.sh`: adotante com `superseded_by` sai da comparação, contado e declarado;
  casos (g7), (g7b) e (g7-MUT).
- `.github/workflows/onion-review.yml`: o comentário do pin nomeia a razão da 2.1.312 (rodada 20, SAC-261).
- `.claude/validation/lint-selftest.sh`, família `kg_read_leg`: caso (r4) com a forma `((a)+(b)) <<E` do relato do sge.
- `.claude/validation/lint-selftest.sh`: com `role: adopted`, ⊘ nomeado para r16-table-total, lint-hard-file (c) sem
  `ops/pr-finalize.sh`, as fixtures r53 bad-brace-dead e bad-scalar-dead, e a r89 sem `docs/onion/radar-baselines.yaml`.
- `.claude/validation/lint-selftest.sh`, família `a2a_verify`: o python3 dos PATHs enxutos entra por invólucro, não por
  symlink (o symlink de um venv perde o venv e o PyYAML; medido no pré-voo deste PR, 10 ✗ → 133/133).
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `Q_META_VELHO_EM_GRAFO_SELADO_1028`, gatilho no 2º caso.
- `docs/onion/graph/coordenacao-sessoes-2026-10.kg.yaml`: quatro pendências do core fechadas com a medida.

## Achados do revisor

| # | Severidade | Achado | Destino |
|---|---|---|---|
| 1 | menor | (passada 1) o `codebase-guide.md` seguia dizendo 11 skills (seção 4, lista sem `onion-design-context`, `onion-publish`, `onion-research`) e 90 KBs (árvore e seção 9), contra 14 e 114 do inventário | curado no commit `33c65f7d9`, que também tira a frase falsa de que o header do `@onion` cita os totais |
| 2 | média | (passada 2) o pulo da r89 olhava só a falta da baseline e valia também no core: um rename dela viraria ⊘ em vez de ✗ | o pulo exige `role: adopted` |
| 3 | média | (passada 2) idem no lint-hard-file (c) com o `ops/pr-finalize.sh` | o pulo exige `role: adopted`; no core a falta cai no else e reprova |
| 4 | baixa | (passada 2) o nó do resíduo com til fechava `done` com a premissa refutada | `status: refuted` |
| 5 | baixa | (passada 2) os três nós medidos seguiam `evidence_class: testimony`, e o comentário da r53 dizia "antes do HARD" num if/else exclusivo | testimony retirado; o comentário diz "em vez do HARD" |

Sem achado nos outros quatro focos: o stub de `date` (o sh, a passagem dos outros formatos ao date real, o caso
expired, o remetente do spike), o 5º campo com `IFS=$'\x1f'` e o pulo do superseded_by, o awk/tr do caso (f)
(também com `LC_ALL=C`) e o pin nos dois `uses:` (tag anotada `8c3fd987` → `d70510b1`, conferida pela API).

## Limites declarados

- O PR que edita o workflow de revisão pode pular o próprio review; a prova da v1.0.264 vem no PR seguinte.
- O README publicado no `onion-plugins` só muda na próxima publicação da porta, que é do maestro.
- Os casos que o sge viu falhando foram medidos num clone descartável do sge no pin 1d04d4e24cec (8 ✗; o 9º do relato
  não apareceu). Com a bancada curada: 72 ✓ e 0 ✗ lá; no core, lint_hard_file, r16_table_total e fixtures deram 130 ✓,
  0 ✗, 0 ⊘ (antes do ajuste da passada 2, que só estreita os pulos).
- O `_dparen_end` não reproduz: em `((a)+(b)) <<E` o bash também lê subshell, e o `<<E` abre corpo nas duas leituras.
- A cura do venv nos casos do relógio entrou depois da 2ª passada e não foi revista por agente novo; a prova é a
  família `a2a_verify` no ambiente do runner (133/133) contra os 10 ✗ do pré-voo anterior.
