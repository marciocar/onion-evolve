---
date: 2026-09-03
instance: onion-evolve
type: learning
classification: public
tags: [bancada, selftest, faixas, paralelismo, dogfood, fail-open, elenxo]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Q_KG_BACKLOG_E_INTERMITENTE_EM_PARALELO: na próxima ocorrência o caso (e) já imprime as HARD só-do-mutante; abrir causa a partir daí"
review_after: 2026-12-02
conflict_class: static
---

## Signal
A bancada ganhou faixas (D_BANCADA_FAIXAS_E_MAPA, selo do maestro): `--jobs auto` com fila dinâmica de famílias, mapa
família→arquivo DERIVADO do corpo das famílias, failsafe explícito, shard do manifest de fixtures. Medido: 1037 s
serial → 800 s round-robin → **472 s** fila dinâmica (8 vCPU), 980 casos. O ganho técnico foi o menor achado: ligar
`--list` expôs uma **família fantasma**, e o paralelismo expôs três defeitos latentes do próprio harness.

## Evidence
- **Família fantasma** (`vendor_pin`): a única invocação estava DENTRO do corpo da própria função desde 2026-07-21
  (44 dias). Nunca rodou; ao rodar pela 1ª vez, matava a suíte (`git archive HEAD | true` em repo sem commit, sob
  pipefail). Guarda nova: definidas == invocadas (caso (b) de `selftest_lanes`).
- **Trap RETURN vaza para o wrapper**: 27 famílias instalam `trap 'rm -rf "${tmp}"' RETURN`; com `_family` como
  chamador, o trap disparava no retorno do wrapper com `tmp` fora de escopo (`set -u` → abort). Cura: `trap - RETURN`
  após a família.
- **`lint | grep -q 'OK ✓'` sob pipefail**: `grep -q` fecha o pipe no 1º match, o lint leva SIGPIPE e o `if` vê
  falha — só aparecia com 8 workers (2 de 2 runs). Era o ÚNICO uso do idioma com o lint; curado por captura em variável.
- **Vacuidade**: `--families inexistente` (ou pai cujos workers todos morreram) saía `OK ✓` com 0 casos. Guarda:
  0 guardas exercidas = FALHOU. Worker sem trailer de soma e família reivindicada-sem-done também são FALHA.
- **Round-robin estático perdeu 2×**: LPT reconstruído dava 394 s vs 795 s medidos; a fila por `mkdir` atômico
  entrega o balanceamento sem tabela de tempos que drifta.
- **O lint é determinístico sob carga** (7 cópias, 6 concorrentes: 8 HARD idênticos) — a classe "HARD fantasma sob
  carga" NÃO se reproduziu; `kg-backlog (e)` falhou 1 vez em 4 runs paralelos sem causa achada → nó de pergunta.
- **O Elenxo achou o que 4 runs não mostraram**: `kg_status_factor` (h) montava o plugin no `plugins/onion-work-tools/` REAL
  (dest default do assembler, `rm -rf` incluso) — era o churn do `provenance.json` após cada bancada e, sob `--jobs`, uma
  corrida com `plugins_sync`. Passou 4 runs paralelos por sorte de agenda; um refutador lendo o código pegou em 1 passada.
- **Bancada espelha o runner, 5ª vez**: o stub do harness isolado da família nova precisou de `.claude/`+`docs/`+
  `CLAUDE.md`+`inventory.sh` porque o top-level da bancada os lê antes de qualquer família.

## Next crumb
Selo do maestro no fechamento do nó; a intermitência de `kg-backlog (e)` tem gatilho nomeado (a próxima falha se
explica sozinha). O pre-commit agora roda só as famílias afetadas: um commit que toca 1 helper leva segundos.
