---
title: "Radar E3 — delta Claude Code 2.1.257 → 2.1.259 (rodada 2, 2026-09-03)"
category: research
date: 2026-09-03
status: selado-baseline-atualizada
method: "1 download do CHANGELOG oficial (fonte primária; entradas 2.1.258 e 2.1.259 verbatim em data/) → 11 achados rascunhados no contexto principal com medições locais → 1 juiz adversarial opus/high (mandato REFUTAR, abriu a fonte e re-executou os greps) → emendas aplicadas no grafo, rascunho preservado"
run_id: "teammate juiz-e3-0903 (agent juiz-e3-0903@session-a026e12c)"
tokens: 2600000
agents: 1
duration_min: 35
kg: docs/evolution/research/radar-E3-2026-09-03/radar-E3-2026-09-03.kg.yaml
verified_at: 2026-09-03
---

# Radar E3 — rodada 2: 2.1.257 → 2.1.259

**Gatilho:** REGRA 65 (Radar de mundo com baseline DATADA por eixo) SOFT — `cc_version` da baseline 2.1.257 ≠ processo 2.1.259.
**Fonte primária:** `data/changelog-2.1.258-259.md` (l.N cita esse arquivo). 2.1.258 = 2 itens (macOS 12, sessões remotas);
2.1.259 = 37 itens.

## Placar do juiz

| aprovados | emendados | reprovados | omissões |
|---|---|---|---|
| 1 (F10) | 8 (F1, F2, F3, F4, F6, F7, F9, F11) | 2 (F5, F8) | 8 |

**Defeito de classe da rodada (meu, não do mérito):** 6 de 11 achados com citação errada — 5 números de linha por contagem
visual e 1 leitura de `allow` como `deny` no `settings.json`. E duas medições locais superestimadas: meu `grep -rlE '^model:'`
contava exemplos YAML no corpo dos arquivos (111 comandos/1 skill/163 total) — o frontmatter real dá **109 comandos (96 sonnet,
10 opus, 3 haiku), 0 skills, 51 agentes**. Cura mecânica adotada daqui em diante: toda citação de linha nasce de `grep -n`
sobre o arquivo em `data/`, nunca de contagem; contagem de frontmatter só entre os dois `---`.

## O achado que muda estratégia

**F1 (l.17):** 2.1.259 corrige "frontmatter `model:` em custom commands e skills era ignorado em sessões interativas". Os 96
comandos do core com `model: sonnet` passam a pedir troca de modelo ao serem invocados; a guarda PreModelSwitch (lineup
`claude-fable-5-1`/`claude-opus-5`) veta nos dois ramos — a plataforma resolve o apelido (evento medido em 09-02:
`requested=sonnet`, `to=claude-sonnet-5`, `decision=block`). **O que acontece ao comando depois do veto não foi medido**
(lacuna 2): é a pergunta que decide se os 96 `sonnet` são incômodo ou quebra. Decisão proposta:
`D_COMANDOS_SEM_MODEL_OU_NO_LINEUP` — (A) remover `model:` dos comandos, tiering fica nos agentes (recomendada);
(B) alinhar ao lineup; (C) ampliar o lineup (abandona a doutrina).

## Os demais (resumo; detalhe nos nós)

- **F3** `--permission-prompts none`: sob `bypassPermissions` não muda nada; vale para adotante headless sem bypass.
- **F5** (reprovado e substituído): o core **não tem deny rule**; a linha 12 do `settings.json` é um **allow** de `Bash(grep * .env)`.
- **F6** `plugin validate --json`: o passo manual `--strict` do `onion-publish` vira consumível por gate.
- **F9** worktrees/workflows: resume sem agentes duplicados é correção de **custo** (um resume do `/onion-research` dobraria ~1,3M).
- **F10** GitLab na plataforma: o adapter `gitlab` do forge SDAAL sobe na fila quando um adotante pedir.
- **Omissões do juiz** (8): Stop em sessão remota (l.26), URL de marketplace (l.28), MCP "conectado sem tools" (l.22),
  `--resume` com anexo vazio (l.16), identidade de repo (l.24), `/workflows` JSON (l.33), sessões agendadas (l.39 + 2.1.258 l.44),
  `CLAUDE_CODE_MAX_CONTEXT_TOKENS` (l.13, o core não usa).

## Lacunas declaradas (medição humana, sessão NOVA em 2.1.259)

1. `/warm-up` emite PreModelSwitch? com qual `source:`? (ler a 2ª linha de `.claude/sessions/model-switch.jsonl`).
2. O comando roda, erra ou aborta após o veto?
3. Mesmo probe para `model: haiku` (`meta/backlog`, `meta/co-evolve`, `meta/inventory`); `model: opus` deve liberar.
4. `--permission-prompts none` × `bypassPermissions`: qual vence.
5. Versão do processo das sessões vivas da VPS.

## Selagem

Baseline E3: `last_run: 2026-09-03`, `cc_version: "2.1.259"`, `kg:` deste grafo (mesmo commit). Rascunho pré-juiz em
`data/f1-findings-pre-juiz.md`; changelog verbatim em `data/changelog-2.1.258-259.md`.
