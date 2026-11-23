---
branch: feat/aside-task-dogfood-1120
pr: 1701
date: 2026-11-20
reviewed_diff_sha256: 3c17cf88ca7bf4cf8fff23fd617e8d2fdde2c3c0e3e9c8b61d7b35d6657e1cc0
reviewed_code_sha256: 4e0614ee41110d318e3ff718d2886f7b91ba74de64042db69b397e8722b4e580
findings_total: 16
findings_real: 15
findings_blocking: 0
tokens: 71467
duration_min: 4
findings_fixed: 11
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "subagente code-reviewer isolado, sem a conclusão do autor, com mandato de refutar e rodar comandos; leu só o diff e o repo"
nota: "tokens = os do subagente revisor. elenxo: true (corrigido em 2026-11-22 pela sessão do core; antes false porque não era o Elenxo de workflow): no esquema do resíduo o campo declara se houve passada adversarial, e houve, por revisor com mandato de refutar; elenxo_isolado: true porque o revisor não escreveu o diff e não recebeu a conclusão. 0 bloqueantes, 6 ressalvas, 6 nits; 9 curados, 2 aceitos com motivo (M7 fraco e rótulo sem namespace do plugin, padrão das rotas existentes) e 1 não real para a guarda (trap no Ctrl-C)."
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

## Revisão isolada (2026-11-23)

Subagente general-purpose (opus), isolado, mandato REFUTAR. Veredito: FIXES_NEEDED, nada bloqueante no core. CI com a família
`aside_router_task` 16/16 conferido nos logs; mutantes M1–M8 matam pelo motivo certo.

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | No plugin o mapa nunca acha `commands/<cat>/<cmd>.md` (comandos soltos como `/<plugin>:<cmd>`), e a rota mandava dizer que faltou peça instalada | sim | não (core) | Curado no mínimo: a rota vazia manda conferir a lista instalada; o KB declara o limite. Resolver pelo `plugin-namespace-check.sh --map` fica para outro PR |
| 2 | `_ART_LOCS="$locs"` e a linha do `miss` dentro do `$(...)` eram código morto com comentário enganoso | sim | não | Curado: apagadas |
| 3 | O teste (c) contra o repo real passa por construção; quem dá dente é o M6 | sim | não | Declarado |
| 4 | `CLAUDE_PROJECT_DIR` no teste (e) é inócuo | sim | não | Declarado: o hook acha o motor pelo `BASH_SOURCE` |
