---
title: "Revisão — .claude/rules entra no manifesto de vendor (a KB vendorizada apontava o vazio em TODO adotante)"
date: 2026-08-31
branch: fix/vendor-claude-rules
reviewer: "achado medido em 2 adotantes no mesmo lote de update (o mesmo link quebrado 2x em cada): a KB onion-kg-ontology-hierarchy.md vendoriza e aponta .claude/rules/kg-grammar.md, que o manifesto não levava"
reviewed_diff_sha256: 71e801cc471b48b84127345d57cb9167ea139a421cfa185f38d93d71a704b8cc
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 0
duration_min: 8
---

# Resíduo — REGRA 56

Dois consertos de mecanismo que o lote de `--update` revelou:

1. **`.claude/rules` entra no manifesto de vendor** (3 sítios: adopt.md ×2 + vendor-branch.sh).
   A KB vendorizada `onion-kg-ontology-hierarchy.md` aponta `.claude/rules/kg-grammar.md` — que
   não viajava. Resultado medido: link quebrado (HARD) em **todo** adotante atualizado (2×2 no
   lote). O `.prettierignore` tpl já cobre (`.claude/` inteiro).
2. **`compose-exposure-baseline.txt` nasce VAZIO no core** — o `--ensure-from` do
   regen-baselines só semeia baselines que o CORE tem; sem o arquivo, adotante pré-catraca ficava
   NO-BASELINE na R64 (medido no granaai: precisou de emissão manual).

## Gate
assemble (R19) · os manifestos mudaram em par (a bancada do vendor-branch cobre o _manifest)
