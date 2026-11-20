---
branch: feat/aside-task-dogfood-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: 4416b0b2b2c0ebfd2de56f721db346f2f34ccf2d2736e0fdc656dca70b356b6b
reviewed_code_sha256: fc28176e5fd1cb516a0aa667b69b4a5829d2de551625b816bfb62b7e86b9b52e
findings_total: 12
findings_real: 11
findings_blocking: 0
tokens: 71467
duration_min: 4
findings_fixed: 9
verdict: FIXED
elenxo: false
elenxo_isolado: true
reviewer: "subagente code-reviewer isolado, sem a conclusão do autor, com mandato de refutar e rodar comandos; leu só o diff e o repo"
nota: "tokens = os do subagente revisor. elenxo: false porque não é o Elenxo de workflow; elenxo_isolado: true porque o revisor não escreveu o diff e não recebeu a conclusão. 0 bloqueantes, 6 ressalvas, 6 nits; 9 curados, 2 aceitos com motivo (M7 fraco e rótulo sem namespace do plugin, padrão das rotas existentes) e 1 não real para a guarda (trap no Ctrl-C)."
---

# Passada adversarial: `feat/aside-task-dogfood-1120`

## O que muda

- Motor `.claude/validation/aside-router.sh`: categoria `tarefa:` (aliases `faça:`/`faca:`), mapa `TASK_MAP`
  intenção → peça, rota que só cita a peça cujo arquivo existe, modo `task-map [--check]`.
- Bancada: família `aside_router_task` no `lint-selftest.sh`, 9 fixtures novas em `fixtures/aside/`.
- KB `maestro-aside.md` e `warm-up.md` citam o marcador. O hook não mudou.

## Achados e destino

1. RESSALVA — `CDPATH` fazia o `cd` imprimir o destino e o `MACHINERY_ROOT` ganhava duas linhas (`task-map --check`
   rc 1 a partir da raiz). Curado: `CDPATH= cd -- … >/dev/null`. Medido: `CDPATH=.:/tmp … task-map --check` rc 0.
2. RESSALVA — aliases sem fixture deixavam mutantes vivos (`task:` removido, `faça:` minúsculo em C, `[[:space:]]*`
   antes do `:`). Curado: `pos-faca-minuscula.txt`, `pos-tarefa-espaco.txt`; os dois mutantes rodados de novo morrem.
3. RESSALVA — a doutrina da rota (custo, opt-in do Workflow) não tinha guarda. Curado: contrato (f) e M8 com três
   cláusulas, cada uma apagada morre.
4. RESSALVA — a rota mandava executar sem ressalvar o irreversível. Curado: o texto passa o `$GATE` para merge,
   push na main e apagar; coberto pelo (f)/M8.
5. RESSALVA — `Task:` em texto colado em inglês daria falso-positivo. Curado: `task:` saiu; `neg-tarefa-task-ingles.txt`.
6. RESSALVA — porta standalone: o (b) e a cópia reprovariam onde uma peça não viaja (`forge-guard` é core-only).
   Curado: o (b) é `record_skip` fora de `role: source`; a cópia põe stub na peça ausente. Medido com
   `SELFTEST_ROLE=standalone`: (b) ⊘, resto verde. A materialização da porta não foi rodada.
7. NIT — tamanho (1061 bytes): aceito; 1011 após as curas. 8. NIT — frase duplicada no fallback: curada.
9. NIT — resumo do (a) afirmava UTF-8 sem medir: curado, cita os locales que rodaram.
10. NIT — regex da (c) sem dígito/`_`: curada. 11. NIT — M7 fraco: aceito, o hook não mudou.
12. NIT — sem `trap` no Ctrl-C: não real para o gate (os `return` limpam).

## Bancada

Família isolada (harness com `record_*`, a partir de `/`): 16 PASS, 0 FAIL — contratos (a)–(f) e mutantes M1–M8.
