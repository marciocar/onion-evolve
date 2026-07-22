---
date: 2026-07-22
instance: onion-evolve
type: learning
classification: collective
tags: [adopter, lint, guard, verification, oracle, federation, dogfood]
affects: [engineering, meta, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Toda guarda nova que possa viajar (está em .claude/validation/ e entra no manifesto de vendor) deve ser rodada UMA VEZ dentro de um clone de adotante antes de ser considerada verde — nunca só no core. O core é o pior oráculo para o que viaja, porque é o único repo onde as dependências da própria guarda existem. Checklist mínimo: a guarda depende de algum arquivo que SÓ o core tem (members.yaml, docs/INDEX.md, um baseline)? Se sim, ela precisa de um caminho de degradação gracioso para o adotante — e esse caminho precisa de fixture própria."
review_after: 2026-10-20
conflict_class: static
significance: "Rodar o lint no core não é rodar o lint — o core é estruturalmente o único repo onde as dependências da guarda existem, então é onde ela mente com mais confiança sobre estar verde."
---

## Signal
**O core é o pior lugar para testar o que viaja.** Uma guarda pode estar VERDE no core e HARD em todo
adotante — porque o core é o único repo onde as dependências da própria guarda existem (`members.yaml`,
`docs/INDEX.md`, um baseline). "Rodar o lint no core" dá uma falsa prova de saúde: o teste roda no único
ambiente onde não pode falhar.

## Evidence
- **Dois bugs achados no MESMO update de campo (gustavo-pulga, 2026-07-21), nenhum por leitura — só
  aparecendo ao rodar o lint DENTRO do repo do adotante:**
  - A **Segurança de Projeção (REGRA 30)**, escrita horas antes, exigia `members.yaml` (P0 → HARD na
    ausência). Mas **só o core tem `members.yaml`**. Resultado: qualquer adotante que atualizasse levava HARD
    e tinha o pre-commit travado. No core, verde; no adotante, morto.
  - `docs/knowledge-base/index.md` é **vendorizado** (viaja) e linkava `../INDEX.md` e `../onion/index.md` —
    nenhum dos dois no manifesto de vendor. No core os alvos existem e o link resolve; no adotante ficam
    pendurados. **O lint do core nunca veria**, porque lá o alvo existe.
- **Isto é a `admission-rule-blindspot` recorrendo em ALTA FREQUÊNCIA, agora medida e não teorizada.** No
  mesmo dia, três vezes: a lição "o baseline explodiria o gate do adotante" (manhã) não alcançou o P0 da
  REGRA 30 (tarde, outro arquivo); a lição "fonte ausente nunca vira verde" (P0 da REGRA 30) não alcançou a
  paridade do `kg-view` (fail-open de novo). Cláusula local não alcança o próximo mecanismo — e o "próximo"
  chega em horas, não em meses.
- **O antídoto é ambiental, não de esforço:** o gate mecânico (`.claude/validation/`) viaja com o adotante;
  então a prova de função é rodá-lo num clone de adotante, onde as dependências do core NÃO existem. Foi só aí
  que os dois bugs se revelaram — depois de eu ter LIDO os dois arquivos várias vezes.

## Next crumb
Ver `next_recommended`. Regra curta: **guarda que viaja prova-se num adotante, não no core.** Pareia com
[[capability-never-met-reality]] (forma × função) — o core é o fixture perfeito, e por isso o pior oráculo.
Ver também [[admission-rule-blindspot]], de que este é o corolário empírico: o ponto cego recorre entre
arquivos dentro de um único dia.
