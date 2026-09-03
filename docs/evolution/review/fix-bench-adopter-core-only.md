---
title: "Revisão — a bancada vendorizada passa no adotante: core-only por dado (⊘ visível) e 3 abortos de robustez"
date: 2026-09-03
branch: fix/bench-adopter-core-only
reviewer: "condutor com dogfood EXECUTADO na cópia de um adotante greenfield (Sacola, .claude/ atual, role: adopted): mapa família-a-família (2 versões) + 4 runs completos até 789 ✓ / 0 ✗ / 66 ⊘ rc=0; no core: família core_only_role 3/3 + gate completo"
reviewed_diff_sha256: 36858e06c3ab33e6d24e20f5d93d1786fb0077c17ec67ddb16c831bfd86875ef
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 150000
duration_min: 90
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

`Q_SELFTEST_VENDORIZADO_INSATISFAZIVEL_NO_ADOTANTE`, cura (a) (selo do maestro). Medido, não suposto: cópia da Sacola com o
`.claude/` atual e `role: adopted`, família a família em série (mapa v2: 118 passam, 12 reprovam, 3 abortam), depois 4 runs
completos com `--jobs 4` até **789 ✓ / 0 ✗ / 66 ⊘, rc=0, 136 s**. Os 66 ⊘: 15 famílias core-only (1 ⊘ cada) + 44 fixtures
r16/r22 + 7 skips pré-existentes de tooling.

## Achados

1. **A pergunta era maior que fixtures**: além de r16/r22, 12 famílias testam SSOT/maquinaria que só o core tem (radar-baselines,
   members.yaml, radar-sources, marketplace, moat, outbox, bundling, registro de regras) e 3 (`resolve_target`, `kg_coverage`,
   `backlog_projection`) abortavam por robustez (pipeline vazio sob pipefail; `docs/analysis/` e `docs/backlog.md` ausentes) e,
   curadas, reprovam por semântica do core. Lista **por dado** em `SELFTEST_CORE_ONLY_FAMILIES` (15) — re-medir ao criar família.
2. **O skip é visível e único**: ⊘ nomeando o motivo, registrado pelo worker que reivindicou a família (a 1ª versão registrava
   3× e deixava "NUNCA reivindicada" no pai — pego no dogfood v3).
3. **O mapa v1 (pin velho) mentia por mistura de causas**: metade das reprovações eram helpers novos ausentes no pin, não
   core-only. Só o mapa v2 (`.claude/` atual) separa as duas — é o que um `--update` entrega.
4. **STRICT no adotante**: com `ONION_SELFTEST_STRICT=1` os ⊘ reprovam — correto no CI do core; um adotante que copie o workflow
   STRICT verá vermelho até decidir (fixtures próprias ou STRICT=0). Declarado, não escondido; o nó fica com esse gatilho.
