---
title: "Radar E3 — delta Claude Code 2.1.259 → 2.1.260 (rodada 3, 2026-09-04)"
category: research
date: 2026-09-04
status: selado-baseline-atualizada
method: "1 download do CHANGELOG oficial (entrada 2.1.260 verbatim em data/, l.N por grep -n) → 13 achados rascunhados no contexto principal com medições locais → 1 juiz adversarial opus/high (mandato REFUTAR, re-executou as medições) → emendas aplicadas no grafo, rascunho preservado"
run_id: "teammate juiz-e3-0904 (agent juiz-e3-0904@session-04d86786)"
tokens: 1400000
agents: 1
duration_min: 25
kg: docs/evolution/research/radar-E3-2026-09-04/radar-E3-2026-09-04.kg.yaml
verified_at: 2026-09-04
---

# Radar E3 — rodada 3: 2.1.259 → 2.1.260

**Gatilho:** REGRA 65 (Radar de mundo com baseline DATADA por eixo) — processo 2.1.260 vs rodada 2.1.259. **Fonte:** `data/changelog-2.1.260.md`
(66 itens). **Placar do juiz:** 3 aprovados (F4, F5, F11) · 9 emendados · 1 reprovado (F8) · 8 omissões — **0 erros de citação**
(a cura de ontem, `l.N` só por `grep -n`, funcionou na primeira rodada seguinte).

## O que muda para o Onion

- **Ação local (F12, l.39/l.40):** o `parseRepoIdentity` do forge SDAAL do core descarta subgrupos aninhados do GitLab (owner = último
  segmento) — o mesmo defeito que a plataforma corrigiu. Fio `I_FORGE_PARSE_GITLAB_SUBGRUPOS` em `fios-abertos`.
- **Superação parcial (F1, l.42):** a plataforma reverteu a cobertura de deny rules `Read()` em args do Bash; cai a metade "opção a
  adotar" do E_F5 da rodada 2, fica viva a metade do allow `Bash(grep * .env)`. As 4 camadas de settings do core são allow-only.
- **Escada de modelos (F2, F3):** troca de modelo deixa de ficar bloqueada por falha de carga de hook de PLUGIN (vale para o Onion
  instalado como plugin, não para o core) e o picker mostra o Fable — o caso mensurável novo é `ladder=restored` por pick.
- **Custo do "sempre o máximo" (F5, F6):** cache do Fable após tool results e ao mudar `/effort`; auto-compact antes do 1M.
- **Orquestração (F7):** erros de teto de retry do Workflow passam a dizer qual validação falhou (nenhum schema da casa é insatisfazível).
- **Notas de plataforma (F8/F9/F10/F13):** subagentes/background, `/reload-plugins` (dispensar reinício NÃO foi medido), `!` fora
  do sandbox (o core não tem sandbox: no-op hoje).
- **Omissões que importam:** `Skill(name)` deny não cobria `<dir>:name` (l.16; 13 skills expostas aninhadas no plugin); `claudeMd`
  gerenciado sem diálogo de segurança (l.55); organização pode desligar marketplaces de usuário (l.8; toca a Fase 5).

## Lacunas (medição humana / uso real em 2.1.260)
Nenhum comportamento de 2.1.260 foi observado; `ladder=restored` nunca foi observado; `/reload-plugins` com hooks embarcados; cota do Fable.

## Selagem
Baseline E3: `last_run: 2026-09-04`, `cc_version: "2.1.260"`, `kg:` deste grafo (mesmo commit).
