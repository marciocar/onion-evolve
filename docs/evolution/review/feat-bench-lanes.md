---
title: "Revisão — bancada em faixas: fila dinâmica, mapa derivado + failsafe, famílias afetadas no pre-commit (D_BANCADA_FAIXAS_E_MAPA, opção A)"
date: 2026-09-03
branch: feat/bench-lanes
reviewer: "condutor com dogfood EXECUTADO (4 runs paralelos completos + 2 subconjuntos + baseline serial + teste de carga do lint); Elenxo adversarial em Sonnet (Opus devolveu 529 três vezes): 6 objeções, 1 SOBREVIVEU (achado 8) e foi curada antes do commit"
reviewed_diff_sha256: b914746d29948db6d4bc8ff2d3f15e0fb6b3f933e1a3fbdba647b04ac40728f6
findings_total: 11
findings_real: 11
verdict: APROVADO
tokens: 900000
duration_min: 240
---

# Resíduo — REGRA 56

Selo do maestro ("vamos atacar D_BANCADA_FAIXAS_E_MAPA: opção A"). `lint-selftest.sh` ganha `--list`, `--map`, `--families`,
`--affected`/`--affected-staged`, `--jobs N|auto`, `--timing`, `--dry-run`; hook pre-commit roda só as famílias afetadas em
paralelo; CI roda tudo em paralelo. **Medido**: serial 1037 s → fila dinâmica 472–519 s (8 vCPU); CI serial 1218 s.

## Achados (todos pelo dogfood; nenhum previsto no desenho)

1. **Família fantasma** `vendor_pin`: a única invocação estava DENTRO do corpo da função desde 2026-07-21 — nunca rodou; ao
   rodar, `git archive HEAD | true` em repo sem commit matava a suíte sob pipefail. Curada; guarda nova definidas==invocadas.
2. **`trap … RETURN` vaza para o wrapper** (27 famílias): sob `set -u`, `tmp` fora de escopo abortou a baseline. `trap - RETURN`.
3. **Round-robin estático rendeu só 1,3×** (795 s no pior worker; LPT reconstruído 394 s) → fila dinâmica por `mkdir` atômico, 472 s.
4. **`lint | grep -q 'OK ✓'` sob pipefail** (SIGPIPE) — única ocorrência do idioma com o lint; só falhava em paralelo (2/2 runs).
5. **Vacuidade**: 0 famílias rodando saía `OK ✓`. Guarda: 0 guardas exercidas = FALHOU; worker sem trailer e família reivindicada-sem-done = FALHA (provado: worker 4 morto no run #3 NÃO virou verde).
6. **Bancada aninhada herdava env de worker** (matou o worker 4 no run #3): a bancada desfaz `ONION_SELFTEST_*` após consumir.
7. **A própria guarda `shell-pipefail` pegou uma linha minha** (`sort | head`) no run #3 → `sed -n`.
8. **Sem causa**: `kg-backlog (e)` falhou 1/4 em paralelo (HARD 9→9); lint provado determinístico sob carga (7 cópias) e sem `timeout`
   no caminho → `Q_KG_BACKLOG_E_INTERMITENTE_EM_PARALELO`, e a falha agora lista as HARD só-do-mutante. O `provenance.json` que mudava após cada run
   completo: o Elenxo achou o gravador que eu não achei — `kg_status_factor` (h) montava no `plugins/onion-work-tools/` REAL
   (dest default do assembler, com `rm -rf`) e corria com `plugins_sync` sob `--jobs`. Curado: dest em mktemp + snapshot da árvore.
9. **CI (2 cores) matou o worker 0 com exit 2** e a guarda nova segurou o vermelho: no caso (m) meu `grep | head -4` deu EPIPE ao
   grep sob pipefail — localmente passava por timing (8 cores, buffer único). Curado com `sed -n` (drena). A guarda
   `shell-pipefail` cobre `sort|head`, não `grep|head`: candidata a ampliar (17 ocorrências no arquivo, nota).
10. **`kg-reverify-schema: selftest` reprovou o 2º gate** (classe já em memória: reprova no gate, passa isolado — 3ª vez). O helper
   passou 24/24 sob 8× concorrência: a causa é AMBIENTAL (env/cwd herdado no worker; a fila muda a ordem), não CPU. A mensagem
   descartava a saída; agora mostra as últimas 4 linhas — a próxima ocorrência se explica. Gate refeito.

Declarado: tier do Elenxo abaixo do padrão (Sonnet) por indisponibilidade do Opus; `pre-gate.sh` segue no scratch (o pre-commit
agora cobre a faixa afetada).
