# Protocolo de teste — plugins Onion no goalflow-suite (2026-07-08)

**Objetivo:** validar empiricamente que os 6 plugins verticais entregam a **Camada 1 (capacidade)**
e provar a fronteira com a **Camada 2 (docs, via `/meta:adopt`)**. Rodar na sessão do Claude Code
**dentro de `~/goalflow-suite`** (não no core).

**Contexto:** goalflow-suite tem os 6 plugins habilitados mas **não é adotado** (sem `.onion-version`).
Logo: comandos autocontidos devem **funcionar**; comandos que consomem docs L2 devem **degradar com
aviso** (pedir o que falta ou apontar pra adopt) — nunca crashar.

---

## Camada A — Resolução (todos os 6 aparecem?)

- [ ] `/help` lista comandos de `onion-engineering`, `onion-product`, `onion-testing`, `onion-docs`,
      `onion-design`, `onion-compliance`.
- [ ] `/plugin list` mostra os 6 `✔ enabled` (já confirmado).

**Esperado:** ✅ todos resolvem. (Se algum sumir → drift de instalação.)

---

## Camada B — Execução autocontida (DEVE funcionar só com plugin)

| # | Comando | O que prova | Esperado |
|---|---------|-------------|----------|
| B1 | `/onion-engineering:help` | ajuda GitFlow pura | imprime, sem erro |
| B2 | `/onion-docs:help` | ajuda docs pura | imprime, sem erro |
| B3 | `/onion-docs:build-index` | escaneia o FS real do goalflow | gera/atualiza índice a partir do que existe |
| B4 | comando de **unit test** de `onion-testing` | detecta framework + gera teste | detecta stack do goalflow e propõe teste |
| B5 | `/onion-engineering:fast-commit` (numa branch de teste) | fluxo git local | stage + commit |

**Esperado:** ✅ funcionam. Isto é a prova de que a **capacidade** viajou no plugin.

---

## Camada C — Fronteira L2 (DEVE degradar com aviso, provando o moat)

| # | Comando | Dep L2 ausente | Esperado (bom) |
|---|---------|----------------|----------------|
| C1 | `/onion-design:identity` | `docs/business-context/` (brief) | pede o brief OU aponta `/meta:adopt`; **não** crasha |
| C2 | `/onion-docs:build-tech-docs` | `docs/meta-specs/` (L0) | avisa que falta a constituição / degrada |
| C3 | `/onion-product:task` | `TASK_MANAGER_PROVIDER` no `.env` | fallback gracioso: decompõe local (provider `none`) |
| C4 | `/catch-up` | é comando-**root**, não empacotado | **não existe** — confirma o gap (só via adopt/onion-core) |

**Esperado:** ⚠️ degradam **educadamente**. Se algum **crashar** (stack trace, erro cru) →
é bug de robustez do comando, anotar como sinal.

---

## Veredito a registrar

- **Camada 1 (plugin) sozinha basta para:** _(preencher — quais B passaram)_
- **Precisa de `/meta:adopt` para:** _(preencher — quais C pediram L2)_
- **Bugs de degradação (crash em vez de aviso):** _(preencher — vira sinal de co-evolução)_
- **Decisão informada:** goalflow fica **plugin-only** (trabalho L1) ou roda **`/meta:adopt`**
  (framework completo L2+3)?

> Isto é o dogfood do moat: se a fronteira L1/L2 se sustenta na prática, a doutrina
> "plugin = capacidade; adopt = docs+governança" está validada em campo.
