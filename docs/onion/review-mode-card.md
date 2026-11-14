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

A marca só sai com a contagem de achados **exatamente 0**. Com `-1` ou vazio ("não pude contar", inclusive
a árvore suja), o check segue verde, mas sem a marca.

A marca positiva **não vale** quando o PR muda a maquinaria do revisor. São duas partes:

- **os scripts do veredito:** `.github/workflows/`, `ops/review/`, `review-verdict.sh` e `post-review-comment.sh`;
- **o que o CLI do revisor carrega do head:** `.claude/hooks/`, `.claude/settings*.json`, `CLAUDE.md` e
  `CLAUDE.local.md` em qualquer diretório,
  `.claude/agents/`, `.claude/skills/`, `.claude/rules/`, `.claude/commands/`, `.claude/output-styles/` e
  `.mcp.json`;
- **o que os hooks executam:** `.claude/validation/` e `.claude/utils/` inteiros. O `settings.json` roda
  scripts de lá no SessionStart, e os hooks carregam os utils. Código assim pode reescrever o
  `claude-execution-output.json` no `RUNNER_TEMP`, fora da árvore, e forjar 0 achados.

O workflow de um `pull_request` é o do head, e um hook do PR roda dentro do job. Por isso esse PR consegue
forjar qualquer anotação. A medição cobre **todos** os arquivos do PR, inclusive o nome antigo de um rename.

A marca também só vale pela **origem**: tem de vir de uma check-run do app `github-actions` cuja run seja
do `.github/workflows/onion-review.yml`. Uma check-run de mesmo nome criada por outro workflow, ou por outro
app com `checks:write`, é descartada.

**Dispensar** o veredito vermelho (`--dispensa onion-review-verdict`) num PR de guarda também exige o resíduo
independente: a dispensa não substitui a revisão.

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

Aprovado pelo refutador independente na 5ª passada dele (head fa6570082). Os limites abaixo são os que ficam.

- **O `details_url` da check-run não é autenticado.** A origem da marca lê o run id do `details_url`, e quem
  cria a check-run escreve esse campo. Forjá-lo exige um workflow do repo com `checks: write`, e hoje nenhum
  tem. Endurecimento futuro: conferir que o `head_sha` da run é o `GATE_SHA` e que o `check_suite_id` da
  check-run é o da run.
- **Espaço de largura zero e U+0085 no nome** não são caracteres de controle ASCII e passam pela checagem.
  Eles casam pelo **prefixo**: `.github/workflows/x<ZWSP>.yml` continua começando por `.github/workflows/` e
  conta como guarda. O efeito é a favor da guarda.

- **`elenxo_isolado: true` é auto-atestado.** O script exige que a declaração exista, não prova que o
  refutador foi outro agente.
- **Bootstraps latentes.** O job do modo usa o juiz, o helper e o tsv do PR quando a base não tem o arquivo.
  O job do veredito usa o juiz do PR quando o da base não emite a marca positiva. Hoje isso só acontece no
  PR que introduz cada capacidade, mas a porta volta a abrir sempre que uma capacidade nova nascer do mesmo
  jeito. Um PR que entre por ela toca `ops/review/` ou `.github/workflows/`, então a marca não vale para ele
  e ele cai no resíduo.
- **Com o #1647 em vigor, a sessão nem mergeia PR de guarda:** o merge dele é do maestro (`--maestro`). A
  exigência do resíduo cobre o caminho que sobra até lá e é o que o maestro confere antes do merge.
- **O bootstrap depende de um literal.** O job do veredito decide se usa o juiz da base procurando o texto
  `--achados <n>` nele, e o job do modo procura `--guard-helper`. Uma capacidade nova que não mude esse
  literal faz a base velha rodar sem ela. Uma que o mude faz o PR que a introduz rodar o juiz do próprio PR,
  mas esse PR toca `ops/review/` e cai no resíduo.
- **Nome de arquivo com caractere de controle** (TAB, quebra de linha, `\x00`-`\x1f`, `\x7f`) derruba a medição
  em rc 2, na API, no JSON e no diff do git (lido com `-z`). O parser de linha nunca adivinha onde o nome acaba.
- **A lista de arquivos do PR vem da API, que trunca em 3000 sem erro.** O helper confere a contagem lida com
  o `changed_files` do PR e falha fechado (rc 2, o merge recusa) se divergir ou passar de 3000. PR maior que
  isso não se mede pela API: é do maestro.
- **Injeção de prompt pelo próprio diff.** O revisor lê o diff, e um PR pode trazer instrução nele. Nenhuma
  lista de caminhos fecha isso. Como o revisor tem `Bash`, a injeção que pega vira **forja determinística**
  pelo `RUNNER_TEMP`: um comando reescreve a evidência ou a saída. A marca positiva é, portanto, evidência
  de que o revisor de IA rodou e não achou nada, não uma fronteira de segurança. Num PR de guarda, a defesa
  que não depende do revisor é o resíduo independente, junto com o merge do maestro (#1647).
- **A evidência é escrita no runner em que o revisor tem `Bash`.** Um revisor manipulado por injeção pode
  escrever no `RUNNER_TEMP`, e o conteúdo do head (`CLAUDE.md`, `.claude/agents/`) é uma via de injeção.
  O efeito fica limitado, pelas três razões abaixo:
  - a falta de crédito só conta com `is_error: true` no **último** evento `result`;
  - um retry que deu certo não conta como falta de crédito;
  - o PR que muda essas vias não ganha marca.
- **O fecho de 2º nível** (o que os scripts do fecho executam, como o `materialize-marketplace-repo`, o
  `vendor-manifest.sh`, o `selftest-families.py` e o `load-lease.sh`) é curado no #1647, no mesmo tsv. O
  helper lê as linhas `fecho` de lá e não duplica a lista.
- **A frase de crédito só vale no evento `result`.** O resto do arquivo de evidência (o diff, as saídas
  das ferramentas) é ignorado de propósito: um PR não tira o próprio vermelho escrevendo a frase.
