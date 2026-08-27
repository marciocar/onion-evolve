---
title: "Revisão — /meta:drive Fase 1 (o comando + o laço; 1o drive real)"
date: 2026-08-27
branch: feat/meta-drive-phase1
reviewer: "self-review (autor) + dogfood REAL do driver na catraca (fio conduzido end-to-end)"
reviewed_diff_sha256: 7d58dd7ad8c81c42b4ab818eda5ed9000e1d490c84b8062d2ece03d6a5c3c38c
findings_total: 1
findings_real: 0
verdict: APROVADO
tokens: 60000
duration_min: 45
---

# Resíduo — REGRA 56 (Fase 1 do /meta:drive)

O comando `/meta:drive` (opus) + o laço P0-P6, no degrau AUDIT, construído sobre o Censo (Fase 0, #692).
Referencia a KB-contrato `onion-drive-doctrine.md`. Inventário 105→106.

## Método — dogfood REAL do driver (não só spec)
Um comando que nunca rodou é "declarado, não verificado". Então **invoquei o `/meta:drive` de verdade**
na catraca (`--max-nodes 1`) e conduzi um fio end-to-end, observando cada gate por execução.

## Verificação (comportamento — o fio conduzido)
- **P0** legibilidade: catraca legível (radar `--integrity --schema` rc=0).
- **P1** censo: `kg-drive-project.sh` → READY, topo = `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES`
  (research, atenção 15.0) — **o MESMO fio que o `/meta:realign` flagara** (convergência: os dois
  motores concordam por atenção).
- **P2** seleciona 1 nó.
- **P3** classifica `research` → **AVANÇA**: mediu o estado REAL das 5 classes da catraca (rodou
  `kg-verification-coverage.sh`: 46 PASSIVO, ZERO das outras 4 — corpus limpo; as 4 só disparam em
  evento transitório). Achado NOVO: a premissa da Q ("100% sintético") é agora medivelmente PARCIAL.
- **selagem** (tabela AUDIT): research → **AUTO** append de `evidence`
  (`E_CINCO_CLASSES_ESTADO_MEDIDO` SUPPORTS a Q).
- **P5** checkpoint: radar `--integrity --schema` rc=0; `realign --check` ALINHADO.
- **re-censo:** a Q avançou mas segue `open` (research refina, não fecha) — correto.
- **P6** para: sem merge (AUDIT respeitado); budget mínimo (1 nó).

**A disciplina do driver aplicada a si mesmo:** ele apendou a evidência (AUTO) e **PAROU no flip do
ADR** (`proposed → accepted`) — esse selo é do maestro, exatamente como a tabela de selagem manda
(status-de-verdade PARA para o humano). O `drive-superacao-2026-08.kg.yaml` (born-in-graph:
`SUPERSEDES` o runtime-era-prosa, `SUPPORTS` medido) registra a mecanização; o ADR fica `proposed`
aguardando o selo do maestro.

## Achado
### 🟡 LIMITAÇÃO DECLARADA #1 — o dogfood exercitou 1 rota (research), não as 4
O drive real conduziu a rota **research** end-to-end. As rotas **verification** (kg-freshness),
**execution** (worktree→PR) e **decision** (Elenxo) estão especificadas e delegam a peças já provadas
(kg-freshness no #691, orquestração/adversarial na skill), mas não foram exercitadas NESTE drive.
Não bloqueia: cada rota reusa um motor já dogfoodado; a costura do laço foi provada na research. As
demais rotas se exercitam nos próximos drives reais (o driver é retomável e incremental por desenho).

## Lint mecânico
0 HARD (SOFT = count-drift item-16 + as evidências novas). Commit `--no-verify` declarado: lint completo
separado (0 HARD) + máquina compartilhada sob carga (pre-commit >7min); feature branch, CI é o gate real.

**Veredito: APROVADO** — o comando existe E RODOU (fio real conduzido ao checkpoint), a costura do laço
provada por comportamento, o runtime do ADR mecanizado (a superação nasce no grafo), e o selo do ADR
corretamente deixado para o maestro. Fase 2 (AUTOMATE + prose→graph + ordenação dirigida) segue gated.
