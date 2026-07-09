# Rascunho — patch de cobertura dos plugins (#1-2) — NÃO APLICADO

**Status:** rascunho. Aplicar só depois do smoke-test no goalflow
(`onion-plugin-smoke-test-goalflow-2026-07.md`). Escopo = os ajustes **inequívocos**;
os transversais ficam para a decisão do `onion-core` (#3).

---

## Achado que redefine o escopo

`onion-validation` tem `paths: [".claude/**"]` e descreve "validar **comandos, agentes e skills**" —
é skill de **autoria de framework** (meta), não de QA de produto. **Não** vai em onion-testing.

Reclassificação das 5 skills:

| Skill | Natureza | Home |
|-------|----------|------|
| `onion-orchestration` | dep funcional de `design:generate` (confirmado em `commands/design/generate.md`) | **onion-design** ✅ (patch abaixo) |
| `onion-validation` | autoria/validação de `.claude/**` (meta) | onion-core/meta (#3) |
| `onion-patterns` | padrões do framework | onion-core (#3) |
| `onion` | orquestrador/navegação | onion-core (#3) |
| `language-standards` | idioma — transversal a tudo que escreve | onion-core (#3) |

→ Das 5, só **1** entra agora. As outras 4 provam que precisamos de um **base plugin** (#3),
não de espalhá-las.

---

## Patch #1 — `runflow-dev` → onion-engineering

O agente `runflow-specialist` já está no plugin; falta só o comando irmão.

**Arquivo:** `.claude/utils/marketplace/verticals/onion-engineering.manifest.sh`

```diff
-COMMANDS=(".claude/commands/engineer" ".claude/commands/git")
+COMMANDS=(".claude/commands/engineer" ".claude/commands/git" ".claude/commands/development/runflow-dev.md")
```

> Nota: `development/` só tem `runflow-dev.md` + `README.md`. Empacotamos o comando, não o README.

---

## Patch #2 — `onion-orchestration` → onion-design

**Arquivo:** `.claude/utils/marketplace/verticals/onion-design.manifest.sh`

```diff
 VALIDATION=(".claude/validation/lint-design-tokens.sh")
+SKILLS=(".claude/skills/onion-orchestration")
```

(o assembler já suporta `SKILLS=` desde a Fase 4 — copia o dir p/ `skills/` + provenance.)

Opcional (Capability Contract, coerência): declarar a skill em `PROVIDES`/`REQUIRES` se
quisermos que o `--closure`/lint a rastreie. Avaliar — pode ficar pro refinamento de doc-deps.

---

## Depois de aplicar (obrigatório — drift-guards)

```bash
# re-montar os 2 plugins afetados
bash .claude/utils/marketplace/assemble-plugin.sh .claude/utils/marketplace/verticals/onion-engineering.manifest.sh
bash .claude/utils/marketplace/assemble-plugin.sh .claude/utils/marketplace/verticals/onion-design.manifest.sh
# gate: R19 plugins-sync + R20 conformance + R22 role-bundle
bash .claude/validation/lint-artifacts.sh
bash .claude/validation/lint-selftest.sh
# inventário (se contagem de comandos empacotados entra em alguma SSOT)
/meta:inventory
```

**Commit sugerido (Conventional):**
`feat(marketplace): runflow-dev no engineering + onion-orchestration no design (cobertura L1)`

---

## Fora deste patch (decisões maiores, não "fáceis")

- **#3 onion-core** — base plugin: root commands (`onion`/`warm-up`/`catch-up`) + as 4 skills
  transversais. Resolve o gap do `/catch-up`. Ver smoke-test C4.
- **#4 onion-meta** — os 30 comandos `meta/` como plugin de papel hub/source. **Tensiona a
  doutrina** (meta = L2/L3 = adopt-only) → RFC, casa com o sinal do inbox.
