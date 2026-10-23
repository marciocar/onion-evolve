---
branch: fix/env-guard-data-exec-helper
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: e7493c043a71183a69017350a631271fd1ba6d27bd68a0f733d7d000f6afa284
reviewed_code_sha256: 28a12302831fdb85cc7ffcb291c8e8fe18b59d812a419f8ed88ae4e5de651887
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 60
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria; achado de origem: passada adversarial do adotante onion-curation"
nota: "tokens não medidos (passada na própria sessão)"
---

# Passada adversarial: `fix/env-guard-data-exec-helper`

## O que muda

- `.claude/hooks/pretooluse-env-guard.sh`:
  - A1: `data_used_as_code` passa a barrar os executores de arquivo de programa (`awk`/`gawk`/`mawk`/`nawk`,
    `make`/`gmake`/`bmake`, `sed`/`gsed`, `m4`) que mencionam o arquivo de dados, e a cópia por redirecionamento
    (`>`, `>>`, `>|`, `&>`) ou `tee` para um nome não-dados no segmento que menciona o arquivo. O próprio heredoc
    gravando o arquivo de dados não conta como cópia.
  - A5: o helper `env-check.sh` só é aceito pelo caminho canônico (`<raiz>/.claude/utils/task-manager/env-check.sh`)
    do repo do hook (`ONION_GUARD_ROOT`) ou do topo git do cwd da sessão, por `realpath`; a forma documentada
    `REPO="$(git rev-parse --show-toplevel)"` + `bash "$REPO/…/env-check.sh"` vale só sem `cd`/`pushd` antes da
    atribuição.
- `.claude/validation/lint-selftest.sh` (caso (u) da família `env_exposure`): 7 casos novos e 4 mutantes
  (M21 a M24); o `helper-var` passa a rodar no cwd do repo (fora dele o helper relativo não existe).
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_ENV_GUARD_A1_A5_CURADOS_1023`.

## Achados

1. A 1ª versão da cópia por redirecionamento disparava no próprio `cat > "$REPORT" <<EOF` que grava o heredoc
   de dados (caso `report` do (u) reprovou): o destino que É o arquivo de dados sai da conta.
2. A 1ª versão do A5 barrava a forma documentada no `.claude/commands/meta/recover.md` (`"$REPO/.claude/…"`),
   pega pela varredura do corpus (caso (j)): aceita só com a atribuição ao topo git na mesma linha e sem `cd` antes.
3. O nó de evidência citava um caminho de máquina (REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela
   classe)): reescrito.

## Mutantes

- M21 (executor de arquivo de programa), M22 (cópia por redirecionamento), M23 (helper só pelo nome) e M24 (`cd`
  antes do topo git) revertidos numa cópia do hook invertem os casos deles; a família `env_exposure` fica 17/17.

## Limites declarados

- A cópia por `dd of=` e executores fora da lista (ex.: `ed`, `ex`) seguem
  fora; o caminho em duas chamadas (Write e depois executar) segue como fronteira declarada do hook.
- O helper aceito pelo topo git do cwd confia que o cwd da sessão é o repo de trabalho.
