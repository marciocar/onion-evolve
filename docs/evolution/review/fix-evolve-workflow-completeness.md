---
branch: fix/evolve-workflow-completeness
date: 2026-10-12
reviewed_diff_sha256: 9d8a178344ed1e161ab81d9d42bcd8cf7a0fdb1ba14f33f32fb2380bde1370fd
reviewed_code_sha256: 322a4142d4e60a1e50ece376fb82f8e76c929fdc697ce31f5f83f41c4df6c5c8
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

**3ª leva (CI do #1062, shard 4):** o caso (h) do silent-measurer usava o README de `commands/meta` como vítima, e o README deixou de ser candidato pela cura MAQ-3. O caso foi corrigido, não a cura: a vítima sai agora do `--tsv` do próprio censo. O mutante que apaga o rótulo DESCARTADOS reprova o (h) (vítima `cc-update.md`). Revisado nesta passada própria.
