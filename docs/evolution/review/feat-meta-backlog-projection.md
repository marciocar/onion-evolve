---
title: "Revisão adversarial — /meta:backlog (projeção de backlog) — PR #654"
date: 2026-08-22
branch: feat/meta-backlog-projection
pr: 654
reviewer: "@branch-code-reviewer (passada adversarial, mandato REFUTAR)"
reviewed_diff_sha256: f126a7f73a0a8ed3b9a9df5a54a2ab471775c637079cefe293e5280561396e94
findings_total: 11
findings_real: 2
tokens: 60280
duration_min: 18
verdict: APROVADO
---

# Resíduo de revisão — REGRA 56

Passada adversarial sobre `origin/main...HEAD` (excl. `review/`), mandato refutar, foco no gerador
bash. **11 candidatos investigados, 2 achados reais (LOW) — ambos CORRIGIDOS antes do merge.**

## Verificações que PASSARAM (tentei refutar, não consegui)

| Eixo | Resultado |
|---|---|
| Extração de `owner:` escopada por bloco | ✅ nó sem owner entre dois com owner NÃO vaza o do vizinho |
| Atenção da coluna 8 do `--open-tsv`, sort desc | ✅ 8.10/7.65/6.00/3.20 na ordem certa |
| `done` ausentes (prova do "some sozinho") | ✅ Q_SEALING/Q_ONION_KG (carimbados) não aparecem |
| Idempotência | ✅ 2 runs → diff vazio; run vs committed → idêntico |
| Array vazio sob `set -u`, `mktemp`+trap, label com pipe | ✅ seguro (bash 5.2), limpo, `tr '|' '·'` |
| Guarda REGRA 58 no F4b | ✅ exit 0, 17/25, TETO 25 lido certo, done carimbados |
| Propagação 103→104 | ✅ inventory=104 real, zero straggler, históricos preservados |
| YAML do comando (description com `: ` aspada) | ✅ parseia |

## Achados — ambos CORRIGIDOS (dogfood req 3-4: veredito verificado → fix → re-dogfood)

- **R1 (LOW) — CORRIGIDO.** `kg-backlog-project.sh:54`: `grep -c . || echo 0` sobre input vazio com
  `pipefail` emitia **dois** `0` (grep imprime "0"+exit 1 → `|| echo 0` imprime outro), quebrando a linha
  de sumário com um `\n` — **exatamente no estado-alvo da feature** (backlog zerado → "some sozinho").
  Curado: `grep -c . || true` (0 único, e sem `2>/dev/null` antes de contagem — o anti-padrão que o
  próprio hook da casa acusa). Provado: vazio → "0" único.
- **R2 (LOW) — CORRIGIDO.** `kg-backlog-project.sh:68`: `$(...)` não-quotado no `for` sofria
  glob-expansion; owner com `*`/`?`/`[` (campo livre) expandiria contra o cwd. Curado: `set -f`/`set +f`
  ao redor do loop. Provado: owner `a*b` fica literal.

## Veredito

**APROVADO** — o gerador é sólido no caminho quente (projeta os 4 fios do F4b, ordena, omite done,
idempotente, `--check` correto) e os 2 achados de robustez de borda foram curados e re-testados. Verificado
por comportamento, não declaração.
