---
name: backlog
description: "Regenerar docs/backlog.md — a projeção humana do trabalho ABERTO do core, a partir dos nós abertos (status open) da camada canônica (docs/onion/graph) + grafos marcados. Use para ver os fios abertos num lugar só, ordenados por atenção (a régua do radar), agrupados por owner. Projeção pura: item fecha no grafo → some daqui sozinho. A fonte é o grafo; este .md deriva."
model: haiku
category: meta
tags: [backlog, kg, projection, open-threads, self-evolution, ssot]
version: "1.0.0"
updated: "2026-08-22"
allowed-tools: Read Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-check.sh*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh*)
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

## Escopo — a camada canônica inteira (decisão do maestro, 2026-08-23: "nada sem controle")

Entram **todos os grafos de `docs/onion/graph/*.kg.yaml`** (a camada canônica = a fila de decisão/
execução do core) **UNIÃO** os grafos marcados `# kg-backlog-guard: on` em qualquer lugar (ex.: o F4b
em `docs/evolution/research/`). Fica **de fora** só o arquivo de pesquisa/discussão histórica
(`docs/discussions/`, `docs/evolution/*` não-marcado) — ruído epistêmico, visível só via
`kg-radar --open-tsv`. Assim o backlog mostra a fila inteira (o flip de auth, federation, pricing…),
ordenada por atenção — o topo é o que "custa caro estar errado". O marcador `# kg-backlog-guard: on`
segue sendo o opt-in **da guarda REGRA 58** (cap + carimbo), agora desacoplado do escopo da projeção.

**Opt-OUT de arquivo** (decisão do maestro 2026-08-23): um grafo que se declara `# kg-backlog-archive: on`
no `meta:` **sai do backlog** (mas segue no radar `--open-tsv`). Nasceu porque a `federation-research`
de 2026-06 (319 abertos epistêmicos históricos) era 63% do backlog — ruído afundando o sinal da fila de
decisão. Superfície de controle limpa > completude: o backlog é a fila ACIONÁVEL, não o arquivo.

## Procedimento

1. **Regenerar** (default): `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh` — consome
   `kg-radar --open-tsv` de cada grafo marcado (a **atenção já vem calculada**, coluna 8 — a régua do
   radar, não recalculada), agrupa por **`owner:`** (campo do nó; fallback = nome do grafo), ordena por
   atenção desc, **sem corte** (item recém-criado nunca some), e escreve `docs/backlog.md`.
2. **`--check`** (advisory): `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh --check` — compara o
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
- Gerador: `${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh` · Fonte: `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh --open-tsv`
- Guarda do grafo de backlog (cap+carimbo): `${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-check.sh` (REGRA 58)
- Grafo de backlog cross-grafo + contrato de leitura: `docs/onion/graph/fios-abertos.kg.yaml`
- Irmão-molde: `/meta:inventory` (a outra projeção determinística da casa)
