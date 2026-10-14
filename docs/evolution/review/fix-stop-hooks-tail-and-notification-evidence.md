---
branch: fix/stop-hooks-tail-and-notification-evidence
pr: pendente
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: pendente
elenxo: nao
reviewer: pendente
nota: "resíduo aberto pela forja da SAC-137; a passada adversarial ainda NÃO rodou — os zeros são placeholder, não medição. Carimbar o hash e o veredito depois da passada."
---

# Passada adversarial — `fix/stop-hooks-tail-and-notification-evidence` (PENDENTE)

Forja única da guarda `background-state-needs-evidence.sh` + leitura da cauda nos dois hooks Stop
(SAC-137, nó `Q_HOOKS_STOP_LEEM_SO_A_CAUDA_DO_TRANSCRIPT` da rodada r11 do radar E3).

O que a passada deve atacar:

1. **Equivalência da cauda**: `lib/transcript-tail.py` tem de devolver exatamente as linhas que a
   leitura inteira devolvia (`rows[start:]`), nos três caminhos (tail, bof, full). Medido nesta forja:
   41 prefixos do transcript real × 2 critérios = 82 comparações iguais, 0 divergentes.
2. **Fail-safe do teto**: estourar `ONION_STOP_HOOK_TAIL_MAX_BYTES` sem achar o início do turno tem
   de cair na leitura inteira, nunca em silêncio (casos m2 e f, mutante M2).
3. **Eventos do harness**: `BG_LAUNCH`/`TASK_DONE` só de rows que o harness escreve; o mesmo literal
   citado em `tool_result` não conta (caso q, mutante M8).
4. **Polaridade preservada**: a frase de espera sem lançamento continua vetada (caso o, mutante M5).
