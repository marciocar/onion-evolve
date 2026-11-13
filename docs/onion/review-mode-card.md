# Cartão: o revisor de IA do CI (ligar, desligar, crédito, conferir)

Decisão do maestro de 2026-11-13, `D_REVIEW_AUTO_WITH_FALLBACK_1113`, no grafo
`docs/onion/graph/review-gate-saldo-2026-09.kg.yaml`. O revisor é o workflow
`.github/workflows/onion-review.yml`. A regra de quando ele roda mora em `ops/review/review-mode-decide.sh`,
e a lista de guardas mora em `ops/review/guard-paths.sh`.

## Os modos (variável de repositório `ONION_REVIEW_MODE`)

| Valor | O que faz |
|---|---|
| `auto` | revisa **só** o PR que toca guarda. A lista sai de `bash ops/review/guard-paths.sh --print-patterns`: os scripts de ato, delega e wrapper do `ops/moat-targets.tsv`, mais as cercas fixas (hooks, `settings.json`, `members.yaml`, workflows, `ops/review/`, `act-signature-check.sh`, `ops/sudoers/` e o próprio tsv). Rename conta pelo nome antigo e pelo novo, e arquivo removido também conta. |
| `on` | revisa todo PR. |
| `off` ou vazio | não revisa: **fallback**. |

A label `review:ia` força a revisão em qualquer modo.

## O fallback (sem crédito, sem chave, ou `off`)

O veredito `onion-review-verdict` **não fica vermelho** por isso. Ele sai verde com a anotação
`onion-review-desligado: não revisado pelo CI: <motivo>`, e o motivo aparece no sumário do check e num
comentário no PR (um só, editado a cada push).

No merge, o `ops/pr-merge-verified.sh` lê essa marca. Se o PR toca guarda, ele exige o resíduo da REGRA 56
(PR aberto carrega RESÍDUO da passada adversarial) em `docs/evolution/review/<branch com / trocado por ->.md`,
com:

- `elenxo: true`;
- `elenxo_isolado: true`, ou seja, um refutador independente, não o próprio autor;
- `verdict` igual a `APPROVED`, `FIXED`, `REJECTED_AND_FIXED` ou `NO_FINDINGS`;
- `reviewed_diff_sha256` carimbado pelo `ops/pr-finalize.sh`.

Sem esse resíduo, o merge da sessão recusa. O PR que não toca guarda não tem exigência extra.

## Ligar

O maestro roda pelo `!` no prompt:

```bash
! gh variable set ONION_REVIEW_MODE --body auto
```

## Desligar (volta ao fallback)

```bash
! gh variable set ONION_REVIEW_MODE --body off
```

## Pôr crédito, com teto mensal

O crédito é posto no Console da Anthropic, na organização dona da chave do secret `ANTHROPIC_API_KEY`
do repositório:

1. Em **Settings → Billing**, compre o crédito.
2. Em **Settings → Limits**, defina o teto de gasto mensal (*spend limit*) da organização ou do workspace
   da chave. O teto é do maestro, e a sessão nunca o altera.
3. Ligue o modo `auto`, como na seção "Ligar".

Se o saldo acabar, o revisor volta sozinho ao fallback, sem vermelho. A falta de crédito se reconhece pelo
pré-voo (HTTP 400 com "credit balance") ou pela evidência do run (artefato `review-evidence`).

## Conferir

```bash
gh variable get ONION_REVIEW_MODE                          # o modo vigente (vazio = off)
bash ops/review/guard-paths.sh --pr <N> --repo marciocar/onion-evolve   # o PR toca guarda? (exit 0 = sim)
gh pr checks <N>                                           # o onion-review-verdict do PR
```

No sumário do job `onion-review-mode` aparecem as linhas `run`, `mode`, `reason`, `guard` e `guard_paths`.
No `onion-review-verdict`, a linha `⊘ Não revisado pelo CI: …` indica fallback. Sem ela, o PR foi revisado.
