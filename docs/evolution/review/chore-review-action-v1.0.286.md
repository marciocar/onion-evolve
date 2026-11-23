---
branch: chore/review-action-v1.0.286
pr: 1708
date: 2026-11-20
reviewed_diff_sha256: 56a0f36a4767e8947fd99de668a3e5b1e2144ccf8ffc9ef63b38a702b47ac31f
reviewed_code_sha256: 69a5dd2b881d336d48c6314acc6afaece4e0a2f97243f10f215f5c2bb90b7ae1
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 81907
duration_min: 15
findings_fixed: 1
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "revisão isolada por subagente code-reviewer (sem a conclusão da sessão no brief): conferiu tags, compare d5f7970a...acfe7992, notas v1.0.273..v1.0.286 e o código da action no sha novo contra os inputs e outputs do job"
nota: "a prova de execução do pin e do --permission-mode default fica para o PR SEGUINTE: o PR que edita o workflow faz a action se auto-pular"
---

# Passada adversarial: `chore/review-action-v1.0.286`

## O que muda

O pin da `anthropics/claude-code-action` sobe de v1.0.272 (`d5f7970a`, CLI 2.1.322) para v1.0.286 (`acfe7992`, CLI 2.1.330), nas duas chamadas do `onion-review.yml` (passos `review` e `review2`). São 32 commits. O pedido veio do aviso do `session-currency-check` (SAC-432).

Diferente das subidas anteriores, esta muda comportamento. A v1.0.273 (#2004) abre a sessão em auto mode por padrão. Nesse modo, uma revisão de segurança decide as chamadas que nenhuma regra de allow cobre, o `--allowedTools` deixa de ser lista estrita, um run com `prompt` pode editar a árvore e regras largas são ignoradas. Para manter o contrato medido da allowlist e o mandato de só ler, o `claude_args` dos dois passos ganha `--permission-mode default`. É o opt-out que as notas da release indicam para runs com `prompt`. A action põe o `--permission-mode auto` antes do `claude_args` do usuário, e o último vence (`src/modes/agent/index.ts:147`).

## Achados

1. **Real, não bloqueante, corrigido.** O comentário novo dizia que a #2059 (o `AGENTS.md` vem da base) só vale para autor sem escrita ou fork. Está errado: no sha novo, `run.ts` chama `restoreConfigFromBase` em todo PR, e o `AGENTS.md` entrou em `SENSITIVE_PATHS`. O efeito hoje é nulo, porque o core não tem `AGENTS.md`. Mas um PR que crie esse arquivo o vê sumir da árvore durante a revisão. O comentário foi emendado nos dois blocos.

O revisor também confirmou, com evidência:
- os dois shas batem com as tags;
- a seção `outputs:` do `action.yml` não muda;
- os inputs novos (`allow_fork_prs` e `restrict_untrusted_prs`, ambos com default `"true"`) não são usados aqui;
- a #2003 e a #2098 restauram `GITHUB_ENV`, `GITHUB_PATH`, `GITHUB_OUTPUT` e git config sem afetar os passos seguintes, que só leem os outputs;
- o CLI 2.1.330 aceita `--permission-mode default` (`bogus` é recusado) e abre a sessão com `"permissionMode":"default"`.

## Mutantes

Não se aplica: a mudança é um pin e um argumento de linha de comando.

## Limites declarados

- O `--help` do CLI 2.1.330 não lista `default`. O valor é aceito e é o que as notas e o `docs/usage.md` da action mandam usar, mas pode ser um alias legado de `manual`. Se o alias sumir, o CLI recusa o valor na largada e o review-verdict reporta a morte com o motivo.
- A prova de execução fica para o PR seguinte, pela regra da casa sobre o PR que edita o próprio workflow.
- Não rodamos `actionlint`, porque ele não está instalado. O YAML passa no `yaml.safe_load`.

## Revisão isolada (2026-11-23)

Subagente general-purpose (opus), isolado, mandato REFUTAR, só leitura. Veredito: **APPROVED**, nada bloqueante.

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | v1.0.286 é a release mais nova; tag `cb5e7061` → commit `acfe7992`, o sha pinado nos dois passos | conferido | — | — |
| 2 | `--permission-mode default` vence o `auto` da action (o último vence em `parse-sdk-options.ts`; `--allowedTools` não engole a flag) | conferido | — | — |
| 3 | Só a v1.0.277 (#2059) tem «Breaking» entre v1.0.274 e v1.0.286, já coberta no comentário | conferido | — | — |
| 4 | Resíduo dizia `pr: pendente` | sim | não | Curado: `pr: 1708` |
| 5 | `default` pode virar nome antigo de `manual` num CLI futuro | risco declarado | não | O review-verdict acusa a morte do review; troca quando o CLI recusar |
| 6 | Comentário de 14 linhas repetido nos dois passos | sim | não | Aceito: os passos já são duplicados |

Não verificado pelo revisor: execução da action (ela se auto-pula no PR que edita o workflow), actionlint e lint completo.
