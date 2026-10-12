---
branch: fix/evolve-workflow-completeness
date: 2026-10-12
reviewed_diff_sha256: 09b375ad502dd805b633a834a1755f553c2b44c8e921e6f92c26d146cc3b0645
reviewed_code_sha256: 8c78dabc2e81f790d64f433db3ce05cbde69a2d10b3ba94ef6b8dbc8a6d2dd0a
findings_total: 10
findings_real: 8
findings_fixed: 7
tokens: 148694
duration_min: 4
verdict: REPROVADO_E_CURADO
reviewer: refutador opus (subagente, default reprovado) sobre o commit da 1ª leva; curas na 2ª leva com caso e mutante
---

# Passada adversarial: o atalho do /meta:evolve e os verdes falsos do raio-X

O refutador recebeu o mandato de achar (A) dimensão que ainda some em silêncio no retorno do
`evolve.js`, (B) verde falso que sobrou no `evolve-census.sh` e (C) caso de bancada que não afirma o
que o nome diz. Reprovou a 1ª leva com quatro achados `recommended` e alguns oportunistas, todos com
sonda executada.

| # | achado | sev | destino |
|---|---|---|---|
| 1 | Census com seção 7 sem alvo ("peças NÃO MEDIDAS") punha a MAQ em `measured` | recommended | **curado**, caso evolve-workflow (m), mutante M14 |
| 2 | `dims` como string ou chave errada (`dmis`) rodava tudo (13 agentes) | recommended | **curado**, caso (m), mutantes M16, M17 |
| 3 | `maqTargets` não-string virava o alvo `[object Object]` | recommended | **curado**, caso (m), mutante M18 |
| 4 | scan sem `findings[]` contava como medido | opportunistic | **curado** (vira dead), caso (m), mutante M15 |
| 5 | medidor com rc 0 e saída vazia imprimia "0 com selftest", "passivo: nenhuma", "0 vencida(s)" | recommended | **curado**, caso evolve-census (n), mutantes M19, M20 |
| 6 | `_guard_links`: padrão vazio casava tudo; `fail "…"` contava como elo | recommended | **curado** (fail-closed + funções de mensagem), caso (m) ampliado, mutantes M21, M22 |
| 6b | o mesmo: linha que mistura código e `echo` sai inteira; heredoc de mensagem conta; só `*-check.sh` | recommended | **teto declarado** no código e no nó `C_GUARD_LINKS_TETO` (pede parser de shell) |
| 7 | "nenhum deles vigiado" impresso sem candidato | opportunistic | **curado** (só com superfícies) |
| C1 | o ramo `cen.rc !== 0` não tinha caso | recommended | **curado**, caso (m), mutante M13 |
| C2 | o (l) do workflow só confere texto | opportunistic | **declarado** no nome do caso ("presença de texto") |

Sem furo, segundo o refutador: casos (c), (h) a (k) do workflow, (k) e (l) do raio-X, e o (j) do
forge, que faz `git add -A` antes de rodar e por isso não é decorativo.

**Bancada:** famílias evolve_workflow, evolve_census, forge e evolve_staleness, 42/42 com `LC_ALL=C`.
**Mutantes:** 23 via `ops/mutate-and-restore.sh`, um por cura, todos reprovando o caso deles.
**Dogfood:** o raio-X rodou no core (seção 7 passou de create-skill/create-vertical, falsos, para
co-deliver/co-evolve/co-relay, reais) e, só leitura, no clone do adotante onion-kg-ssot (plano `n/a no
adotante`; o README segue lá até o update levar o forge-census novo). **Não exercitado no runtime
real:** o `evolve.js` pela ferramenta Workflow — a sessão que fez o PR não tinha a ferramenta; o corpo
roda no stub da bancada, no mesmo embrulho async do runtime.
