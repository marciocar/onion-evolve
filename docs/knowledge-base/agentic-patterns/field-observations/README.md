# 🔭 Field Observations — Observações Brutas do Campo

## O que é este trilho

Captura rápida e honesta do que **surpreendeu**, **emergiu** ou **não funcionou** ao operar
IA de perto. Sem polimento — o objetivo é não perder o insight enquanto ele é fresco.

Cada arquivo é uma observação datada, ligada ao contexto em que emergiu. Não precisa
ser conclusivo: pode ser uma pergunta, um padrão suspeito, uma anomalia.

---

## Como usar

**Capturar:** qualquer observação relevante sobre comportamento de harness ou transformer
que surpreenda ou revele algo não-óbvio. Arquivo `AAAA-MM-DD-<assunto>.md`.

**Assess:** periodicamente, revisar e marcar o frontmatter:
- `status: raw` — captura inicial (default)
- `status: assessed` — avaliado, mas não promovido
- `status: promoted` — promovido para `harness/` ou `ai-strategies/`

**Curar:** a cada ciclo de evolução do core, limpar `assessed` antigos e promover `promoted`.
Arquivos com `promoted` podem ser arquivados (mover para `_processed/`).

---

## Índice

| Data | Assunto | Status |
|------|---------|--------|
| 2026-06-30 | [Harness Paths — como o Claude Code armazena state](2026-06-30-harness-paths.md) | `promoted` |
| 2026-07-01 | [Verificação superficial travestida de profunda — 2 casos reais](2026-07-01-shallow-verification-masquerading-as-deep.md) | `raw` |
