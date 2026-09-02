---
title: "Radar E3 — delta Claude Code 2.1.252 → 2.1.257 (rodada 1, 2026-09-02)"
category: research
date: 2026-09-02
status: selado-baseline-atualizada
method: "1 leitura do CHANGELOG oficial (fonte primária, entrada 2.1.257 = l.8-114) → 7 achados rascunhados no contexto principal → 1 juiz adversarial `juiz-e3` (opus/high, mandato REFUTAR, ABRIU as fontes e RE-MEDIU no vivo) → emendas aplicadas no mesmo loop → write(KG)"
run_id: "teammate juiz-e3 (agent-ajuiz-e3-754de9fd73b1ece1)"
tokens: 3708084
agents: 1
duration_min: 9
kg: docs/evolution/research/radar-E3-2026-09-02/radar-E3-2026-09-02.kg.yaml
verified_at: 2026-09-02
---

# Radar E3 — o que 2.1.257 muda na maquinaria do Onion

> **Projeção do grafo.** SSOT: [`radar-E3-2026-09-02.kg.yaml`](./radar-E3-2026-09-02.kg.yaml)
> (radar exit 0; 15 nós, 14 arestas). Fontes: [`data/changelog-2.1.257.md`](./data/changelog-2.1.257.md)
> (entrada oficial, `l.N` abaixo) e [`data/f1-findings-pre-juiz.md`](./data/f1-findings-pre-juiz.md)
> (rascunho **antes** do juiz — preservado para que a emenda seja auditável).

**Gatilho:** REGRA 65 SOFT (`cc_version: 2.1.252` na baseline ≠ `claude --version` = 2.1.257).
**Pergunta** (ordem do maestro, 2026-08-31): não "quebrou algo?", mas *"o que isto muda na
NOSSA estratégia?"*. O CHANGELOG salta de 2.1.252 para 2.1.257 (sem 253–256); 2.1.258 já publicado só com 2 fixes.

## Vereditos (juiz opus/high, mandato REFUTAR)

| # | Achado | Veredito | O que muda no Onion |
|---|---|---|---|
| F1 | Fable 5.1 default (l.10) — **mas** alias `fable` segue em Fable 5 via gateway (l.99) | EMENDADO | snapshot da KB atualizado **com** o gap de runtime nomeado |
| F2 | `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` ignora `model` por spawn/definição (l.13) — 51/60 agentes declaram `model:` | APROVADO | skill passo 8 checa a env antes de declarar tier; nota na KB; lint GATED |
| F3 | `bypassPermissions` em settings de projeto ignorado (l.98) — 26 settings varridos, 0 ocorrências | EMENDADO (números) | nenhum; doutrina do exit 2 segue válida |
| F4 | `blockReadsOutsideWorkingDirectories` (l.16) vs censo/kg-freshness que leem `/home/marcio/*` e `/home/onion` | APROVADO | kg-freshness.md distingue bloqueio de FS (sudo) de bloqueio de HARNESS (sudo não vence) |
| F5 | `permissions.ask` em subshell · deny Read/Edit cobre `< file`/`tac` · plugin não lê via symlink (l.53/61/54) | EMENDADO (medição fail-open: `.claude/plugins` não existe; alvo real `plugins/` = 0 symlinks) | só reforço |
| F6 | `timeout`/`setsid` morrem no stop (l.69) — único setsid é decoy do selftest, morto por `kill` | APROVADO | nenhum |
| F7 | sem sinal sobre hooks/exit 2/memory tool | EMENDADO (non-sequitur "reforçada por F5a" removido) | capacidade que compra o acoplamento intacta |
| F8 | worktree isolado deixou de recusar loops/heredocs/`$(…)` (l.63, l.72) | omissão do juiz | `isolation: worktree` segue declarado-e-não-exercitado (0 usos); gatilho nomeado |
| F9 | worker cortado mid-stream **continua** (l.49); transcript >5 MB retomável (l.62) | omissão do juiz | "resposta incompleta" vira sintoma de CONTEÚDO, não de corte — muda o que UNVERIFIABLE significa |
| F10 | settings de `.claude/` criada pós-startup valem sem restart (l.18) | omissão do juiz | bridge (`workspace.ts:105`) e `/meta:adopt --in-place` tinham bug latente; plataforma fechou |
| F11 | Containment Escape em auto mode (l.12) | nota | converge com `a2a-ssrf-check.sh:69`; sem fricção no gate |

**Medição colateral (comportamento, não catálogo):** o juiz spawnado com `model: opus` executou
`claude-opus-5` (39 turnos) — o gap "alias `opus` resolve para 4.8" da KB está **fechado por medição**.

## Lacunas declaradas (desfecho de 1ª classe)

(1–2 do juiz na 1ª entrega; 3–7 do juiz na 2ª entrega, 01:12Z, após 2 truncamentos — 3–4 coincidem com as que eu já declarara por conta própria.)

1. Preço/cota do Fable 5.1 **nesta conta** — CHANGELOG dá tabela, não cota (régua de 3 degraus exige o maestro). → **FECHADA por testemunho (maestro, 2026-09-02: "confirmado, saiu a versão 5.1 do fable"; `E_FABLE_5_1_CONFIRMADO_NA_CONTA`, `evidence_class: testimony`)** — acesso confirmado; custo segue catálogo.
2. Se o alias `fable` desta sessão (não-gateway) resolve 5 ou 5.1 — lido, não medido em runtime.
3. F9 é leitura do CHANGELOG, não observação — corte de stream não reproduzido (mim + juiz, independentemente).
4. `blockReadsOutsideWorkingDirectories` não exercitado — a opção não está setada; só se confirmou que a leitura cross-repo funciona hoje (mim + juiz).
5. F8 mede declaração, não execução — o gate não rodou dentro de worktree isolado (juiz).
6. Sem WebSearch/WebFetch — nada cruzado com fonte externa (juiz).
7. 2.1.258 fora do escopo — seus 2 fixes não avaliados; entram na próxima rodada do E3 (juiz).

## Edições aplicadas nesta rodada (mesmo commit da baseline)

- `docs/onion/radar-baselines.yaml` — E3: `last_run: 2026-09-02`, `cc_version: "2.1.257"`, `kg:` → este grafo.
- `docs/knowledge-base/concepts/agent-orchestration.md` — snapshot Fable 5.1 + gap `fable`; nota `SUBAGENT_MODEL_FORCE`; gap `opus` fechado por medição.
- `.claude/skills/onion-orchestration/SKILL.md` — passo 8 checa a env force antes de declarar tier.
- `.claude/commands/meta/kg-freshness.md` — bloqueio de FS ≠ bloqueio de HARNESS.

## valeu-a-pena

3,71M tokens (3,26M cache-read) · 1 agente · 9 min → 11 achados verificados, 4 emendas ao meu
rascunho (2 delas medições minhas erradas: alvo inexistente em F5, número inventado em F3) e 4
omissões que eu não veria sozinho. Sem juiz, F3/F5 entrariam com contagem falsa. Comparado à
rodada 0 (6 eixos, 2,87M): o custo por eixo subiu (cache do contexto principal), a taxa de emenda
também — o juiz que **re-mede** custa mais que o juiz que **lê**, e pega mais.
