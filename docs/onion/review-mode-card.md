# Cartão: o revisor de IA do CI (ligar, desligar, crédito, conferir)

Decisão do maestro de 2026-11-13, `D_REVIEW_AUTO_WITH_FALLBACK_1113`, no grafo
`docs/onion/graph/review-gate-saldo-2026-09.kg.yaml`. O revisor é o workflow
`.github/workflows/onion-review.yml`. A regra de quando ele roda mora em `ops/review/review-mode-decide.sh`,
e a lista de guardas mora em `ops/review/guard-paths.sh`.

## Os modos (variável de repositório `ONION_REVIEW_MODE`)

| Valor | O que faz |
|---|---|
| `auto` | revisa **só** o PR que toca guarda. A lista sai de `bash ops/review/guard-paths.sh --print-patterns`: os scripts de ato, delega e **fecho** (o que os atos executam) e os wrappers de deploy do `ops/moat-targets.tsv` (o da árvore somado ao de `origin/main`), mais as cercas fixas: hooks, `settings.json`, `members.yaml`, workflows, `.githooks/`, `ops/review/`, `.claude/validation/` inteiro, `ops/sudoers/`, o próprio tsv, a lista antiga (`ops/update-*`, `ops/deploy-*`, `ops/mcp-*`, `merge-serial.sh`, `apply-ruleset-main.sh`, `pr-merge-verified.sh`), `pr-finalize.sh`, `materialize-door.sh` e o `post-review-comment.sh`. Rename conta pelo nome antigo e pelo novo, e arquivo removido também conta. |
| `on` | revisa todo PR. |
| `off` ou vazio | não revisa: **fallback**. |

A label `review:ia` força a revisão em qualquer modo.

## O que conta como revisão num PR de guarda

Só o verde com a **marca positiva** `onion-review-revisado: … o head <sha>`. Quem a emite é o juiz lido da
**base**, quando o revisor rodou e o gate de achados aprovou aquele head. Qualquer outro verde é fallback:

- a marca de desligado;
- um verde sem marca nenhuma (por exemplo, um PR que mudou o gate);
- nenhum veredito no head.

A marca positiva **não vale** quando o PR muda a maquinaria do revisor: `.github/workflows/`, `ops/review/`,
`review-verdict.sh` e `post-review-comment.sh`. O workflow de um `pull_request` é o do head, e por isso um PR
que o edita consegue forjar qualquer anotação.

## O fallback (sem crédito, sem chave, `off`, ou a action auto-pulada)

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

## Limites declarados (2ª passada do refutador do #1652)

- **`elenxo_isolado: true` é auto-atestado.** O script exige que a declaração exista, não prova que o
  refutador foi outro agente.
- **Bootstraps latentes.** O job do modo usa o juiz, o helper e o tsv do PR quando a base não tem o arquivo.
  O job do veredito usa o juiz do PR quando o da base não emite a marca positiva. Hoje isso só acontece no
  PR que introduz cada capacidade, mas a porta volta a abrir sempre que uma capacidade nova nascer do mesmo
  jeito. Um PR que entre por ela toca `ops/review/` ou `.github/workflows/`, então a marca não vale para ele
  e ele cai no resíduo.
- **Com o #1647 em vigor, a sessão nem mergeia PR de guarda:** o merge dele é do maestro (`--maestro`). A
  exigência do resíduo cobre o caminho que sobra até lá e é o que o maestro confere antes do merge.
- **A frase de crédito só vale no evento `result`.** O resto do arquivo de evidência (o diff, as saídas
  das ferramentas) é ignorado de propósito: um PR não tira o próprio vermelho escrevendo a frase.
