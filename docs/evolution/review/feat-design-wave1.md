---
branch: feat/design-wave1
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
tokens: 146249
duration_min: 10
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: code-reviewer (agente novo com brief, sem a conclusão do autor)
nota: "Um refutador rodou a guarda e o motor contra fixtures mutados no scratchpad (casos honestos e ruins), conferiu a fórmula WCAG com valores de referência, o radar e o contrato no grafo gerado, e a bancada das duas famílias. Achou 12 defeitos, nenhum bloqueante, 4 importantes. Os 4 importantes e 5 menores foram curados no 3º commit, com 4 casos novos de bancada; os 3 menores restantes viraram tetos declarados no grafo da guarda. Os tokens e a duração são do refutador."
---

# Passada adversarial: `feat/design-wave1`

## O que muda

- `/design:setup` com o motor `.claude/utils/design-setup/` (dry-run padrão, nunca sobrescreve, idempotente, contraste do CTA calculado, termina no gate de tokens).
- A skill `onion-design-context` e `design` no `resolve-context-dir.sh`.
- `docs/design-context` no `/meta:context-freshness` e no `context-freshness-metric.sh`.
- O grafo piloto `docs/design-context/design-context.kg.yaml` (11 nós) e os grafos mínimos de alvo do business-context e do technical-context.
- A guarda REGRA 111 (Grafo do design-context: locator de token e ligação do brief), SOFT no 1º ciclo, com as famílias `design_setup` e `design_context`.

## Achados

| # | Achado | Sev. | Destino |
|---|---|---|---|
| 1 | Falso positivo: a external_edge com a ponta externa no `from` (válida no contrato) era acusada como brief sem ligação | importante | curado: as duas direções contam; caso (n) |
| 2 | Falso verde: com a pasta de design declarada, o gate de tokens lê só `docs/design-context`, sai 0 sem medir, e o setup dizia verde | importante | curado: o setup sai 2 ("gravado, não verificado"); caso (h) do setup |
| 3 | Tokens parciais (só foundations) faziam o setup criar a outra metade com aliases órfãos (11 HARD no gate) | importante | curado: plano `FALTA` e rc 3, nada gravado; caso (g) do setup |
| 4 | Falso negativo: locator fora da forma `#/…` numa fonte de tokens (pontuado, sem `#`, extensão `.tokens`, espaço final) passava calado | importante | curado: achado `LOCATOR-FORMA` nas fontes `*.tokens.json`/`*.tokens`, com `strip()`; caso (o) |
| 5 | A question de falta segue valendo depois que o alvo passa a existir | menor | teto declarado (`C_CEILING_MISSING_NEVER_EXPIRES`) |
| 6 | Grupo DTCG com `$root` saía como grupo; a ponta `.kg.json#` não contava | menor | curado: `$root` aceito e `\.kg\.(yaml\|json)#` |
| 7 | A marca re-derivada apontava o tom escurecido, e a reexecução dava um AVISO espúrio; o setup.md prometia "só MANTER e NADA" | menor | curado: com a ação em `*-strong` e acento presente, a marca é o acento; a frase do setup.md descreve o plano real |
| 8 | `--add-frontmatter` num brief com BOM criava um 2º bloco de frontmatter | menor | curado: leitura com `utf-8-sig` |
| 9 | `allowed-tools` sem o `kg-contract-check.sh`; dependência da `onion-product-context` não declarada no manifesto | menor | curado: ferramenta acrescentada; dependência no `LOADS`, com a degradação |
| 10 | O brief do core e o `--add-frontmatter` sem `date:`, e o brief contava como sem carimbo no frescor | menor | curado: `date:` nos dois |
| 11 | O `--only` da REGRA 111 só casa caminhos com `design-context` no nome | menor | teto declarado (`C_CEILING_ONLY_DEFAULT_PATHS`) |
| 12 | O setup procura o grafo-alvo só no nível de cima da pasta; `open(..., "x")` que falha no meio dava traceback | menor | o traceback foi curado (rc 2 nomeando o arquivo); a busca rasa virou teto declarado (`C_CEILING_SETUP_TOP_LEVEL_TARGETS`) |

## Mutantes

Na família `design_context` (13 casos): sem a exigência de `$value`/`$root` o grupo passa; sem a regra do brief a ligação ausente cala; sem o ramo do token ausente o token sumido cala. Cada sed tem a guarda `! cmp -s`, então o mutante precisa casar para o caso passar. Na família `design_setup` (8 casos): sem o escurecimento do CTA, o gate reprova e o setup sai 1. Na `context_freshness_metric`: a lista padrão sem o design cala. As duas famílias novas deram 21 de 21 depois das curas.

## Limites declarados

- O 3º commit, com as curas, não voltou ao refutador; as curas foram conferidas pela bancada (4 casos novos).
- O checador de projeção do kg-ssot (o `.md` com `projection_of` cita só ids que existem) não existe e não foi implementado: dependência declarada (`Q_PROJECTION_CHECK_DEPENDENCY`).
- A checagem do locator pode migrar para o `kg_trace` do kg-ssot (`Q_LOCATOR_CHECK_HOME`); a guarda ficou isolada para isso.
- O número da REGRA 111 estava livre na origin/main no momento da revisão; outros PRs abertos não foram conferidos.
