---
name: backlog
description: "Regenerar docs/backlog.md — a projeção humana do trabalho ABERTO do core, a partir dos nós abertos (status open) dos grafos que optaram-in (`# kg-backlog-guard on`). Use para ver os fios abertos num lugar só, ordenados por atenção (a régua do radar), agrupados por owner. Projeção pura: item fecha no grafo → some daqui sozinho. A fonte é o grafo; este .md deriva."
model: haiku
category: meta
tags: [backlog, kg, projection, open-threads, self-evolution, ssot]
version: "1.0.0"
updated: "2026-08-22"
allowed-tools: Read Bash(bash .claude/validation/kg-backlog-project.sh*) Bash(bash .claude/validation/kg-radar.sh*) Bash(bash .claude/validation/kg-backlog-check.sh*) Bash(bash .claude/validation/lint-artifacts.sh*)
argument-hint: "[--check]  (sem arg = regenera docs/backlog.md · --check = só reporta drift, advisory)"
---

# 🧅 /meta:backlog — a projeção humana do trabalho aberto

O core tem centenas de nós `status: open` espalhados por dezenas de grafos — visíveis só pelo radar
por-grafo. Este comando os **projeta num artefato único legível**, `docs/backlog.md`, para o maestro
ver os fios abertos de uma vez. É o "mecanismo para nada ficar parado" feito superfície: *item nasce
no grafo → aparece no backlog → fecha no grafo → some daqui sozinho* (projeção pura, reescrita).

> **NÃO é fonte.** O grafo é a fonte; `docs/backlog.md` deriva. Nunca edite o `.md` à mão — feche o
> nó no grafo (`status:` ≠ `open`, com carimbo) e regenere. É a doutrina do próprio `fios-abertos.kg.yaml`:
> *"backlog de documento ordena item morto"* — por isso a projeção é pura, não uma lista paralela.

## Escopo — opt-in por marcador (mata o ruído)

Só entram os grafos com **`# kg-backlog-guard: on`** no `meta:` (o mesmo opt-in da guarda REGRA 58).
Grafo de pesquisa/discussão histórica **não** opta-in → seus abertos epistêmicos não viram ruído no
backlog. Para incluir um grafo de trabalho vivo: adicione `# kg-backlog-guard: on` + um `# ═══ TETO: N
NÓS ═══` no `meta:` dele (a guarda passa a cobrar cap + carimbo de `done`). A visão **exaustiva** (todos
os grafos, sem curadoria) continua sendo `bash .claude/validation/kg-radar.sh <grafo> --open-tsv`.

## Procedimento

1. **Regenerar** (default): `bash .claude/validation/kg-backlog-project.sh` — consome
   `kg-radar --open-tsv` de cada grafo marcado (a **atenção já vem calculada**, coluna 8 — a régua do
   radar, não recalculada), agrupa por **`owner:`** (campo do nó; fallback = nome do grafo), ordena por
   atenção desc, **sem corte** (item recém-criado nunca some), e escreve `docs/backlog.md`.
2. **`--check`** (advisory): `bash .claude/validation/kg-backlog-project.sh --check` — compara o
   recomputado vs o commitado e diz se drifou. Não é gate (projeção-sob-demanda, como o oráculo-PoC fez).
3. **Reportar**: os contadores (N abertos · M grafos · K owners) e o path. Se algum grafo marcado
   mudou de cap/estado, lembre que `kg-backlog-check.sh` (REGRA 58) é quem cobra o cap+carimbo.

## Saída
```
🧅 backlog projetado — N abertos em M grafo(s) marcado(s) · K owner(s)
   ◆ docs/backlog.md (ordenado por atenção, sem corte)
   ▶ item fecha no grafo → some na próxima projeção
```

## ⚠️ Notas
- **Melhoria sobre o gerador da PoC** (o adotante-oráculo, que originou este mecanismo): consome
  `--open-tsv` em vez de parser regex frágil; lê `owner:` como campo do nó em vez de derivá-lo do id.
- **Verbo solto em `meta/`**; não funde nem dispara workflows faseados. Espelha `/meta:inventory`
  (gerador determinístico + comando fino).

## 🔗 Referências
- Gerador: `.claude/validation/kg-backlog-project.sh` · Fonte: `.claude/validation/kg-radar.sh --open-tsv`
- Guarda do grafo de backlog (cap+carimbo): `.claude/validation/kg-backlog-check.sh` (REGRA 58)
- Grafo de backlog cross-grafo + contrato de leitura: `docs/onion/graph/fios-abertos.kg.yaml`
- Irmão-molde: `/meta:inventory` (a outra projeção determinística da casa)
