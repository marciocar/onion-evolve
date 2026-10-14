---
branch: fix/stop-hooks-tail-and-notification-evidence
pr: pendente
date: 2026-10-14
reviewed_diff_sha256: 79a42360dc79d0854830294ea6fa321c3f896a10b6c87e717b00170c0ef9e45b
reviewed_code_sha256: 7fee0f8f1b7cf3e9afa40a8af8f0b5c3b62e02dec5dc6f29a28a1e891bcea650
findings_total: 3
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: subagente (9 mutantes, 41 cortes do transcript real) + passada própria da sessão principal: famílias 60/0 re-executadas, hooks re-cronometrados no transcript real, e sonda adversarial comparando o hook antigo e o novo em 3 frases de fechamento
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


## Passada adversarial da sessão principal (2026-10-14)

1. **A cauda dá o mesmo veredito?** Re-executei as famílias (`guard_forge`, `rule_title_in_prose`,
   `shell_pipefail_robustness`, `selftest_lanes`): 60/0. No transcript real, 407 ms e 221 ms contra ~1 s e ~0,55 s
   antes, com a máquina mais carregada que na medição do subagente.
2. **A emenda abre brecha?** Sondei o hook antigo e o novo com o mesmo lançamento de fundo e 3 fechamentos:
   "segue rodando" nu é vetado nos dois (rc 2); "segue rodando; aguardo a notificação" passa só no novo (o
   pedido); "segue rodando e já terminou com sucesso" passa nos DOIS (rc 0). Real e NÃO curado aqui: é lacuna
   de vocabulário anterior a esta mudança (o hook não reconhece afirmação de TÉRMINO sem notificação nem
   observação). Fica declarada, para a próxima forja da guarda.
3. **O fail-safe vira silêncio?** Não: estourado o teto, o lib relê o arquivo inteiro (casos m2 e f, mutante M2).
