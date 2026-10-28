---
branch: chore/core-maint-1027
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: 33fbb6fa4f3eff9a74609fd11e23e77646592bdbf77564bf4803977b03fdbdfe
reviewed_code_sha256: 237b89027a58436f279d4fa229296c525385df55886f38d3f8dfaf0a1ddb7d52
findings_total: 1
findings_real: 1
tokens: 63276
duration_min: 4
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: "agente novo só-leitura (branch-code-reviewer), passada adversarial curta sobre o diff"
nota: >-
  PR de manutenção do core com itens medidos (o carimbo do sge saiu: o #1418 o fez antes): prosa de contagem,
  lista de skills do CLAUDE.md, README do marketplace, pin da claude-code-action v1.0.264, relógio
  injetado na bancada a2a-verify, ressalva do _dparen_end (não reproduz), famílias que o sge viu
  falhando (passam no core) e REGRA 92 pulando a linhagem histórica.
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

## Achados do revisor

| # | Severidade | Achado | Destino |
|---|---|---|---|
| 1 | menor | o `codebase-guide.md` seguia dizendo 11 skills (seção 4, lista sem `onion-design-context`, `onion-publish`, `onion-research`) e 90 KBs (árvore e seção 9), contra 14 e 114 do inventário | curado no commit `33c65f7d9`, que também tira a frase falsa de que o header do `@onion` cita os totais |

Sem achado nos outros quatro focos: o stub de `date` (o sh, a passagem dos outros formatos ao date real, o caso
expired, o remetente do spike), o 5º campo com `IFS=$'\x1f'` e o pulo do superseded_by, o awk/tr do caso (f)
(também com `LC_ALL=C`) e o pin nos dois `uses:` (tag anotada `8c3fd987` → `d70510b1`, conferida pela API).

## Limites declarados

- O PR que edita o workflow de revisão pode pular o próprio review; a prova da v1.0.264 vem no PR seguinte.
- O README publicado no `onion-plugins` só muda na próxima publicação da porta, que é do maestro.
- As famílias que o sge viu falhando passam no core; no adotado não há como medir daqui.
