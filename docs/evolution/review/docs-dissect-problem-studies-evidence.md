---
branch: docs/dissect-problem-studies-evidence
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 068fabcfa70deab98d5295dfb7d41b354e828ed996d21ce4741c250d9541022f
reviewed_code_sha256: 5007b838eed5b0b21a8e36b92c5c3c90fef7926e85db4b07f7e39c4cb2b95877
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 20
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "agente de execução da sessão do core (passada própria; o brief proibiu criar agentes, então não houve refutador independente)"
nota: "tokens 0 = não medido. Evidência trazida da branch local feat/problem-formula por git checkout de diretório, sem rebase dos 39 commits"
---

# Passada adversarial: a evidência dos estudos problem-formula e problem-route chega ao main

## O que muda

- `docs/evolution/dissect/problem-formula-2026-11/` e `docs/evolution/dissect/problem-route-2026-11/`,
  inteiros (104 arquivos: grafos, Etapa 0 e emendas, fichas, gabaritos, scripts e o `run/`), trazidos da
  branch local `feat/problem-formula` com `git checkout <branch> -- <dir>`. Os vereditos já estavam no
  main (parquear e rejeitar, DIARIO.md:159 de session-orchestration-2026-11); o PR leva a evidência.
- As duas citações do main que apontavam o `CERCA.md` "da branch" passam a apontar o caminho real:
  `.claude/validation/act-signature-check.sh:16` e o nó de `deploy-acts-2026-11.kg.yaml:33`.
- O `docs/backlog.md` da branch NÃO veio: as projeções foram regeneradas pelo `ops/pr-finalize.sh`.

## Os achados e o destino de cada um

| # | achado | destino |
|---|---|---|
| 1 | `problem-route-2026-11/hook_exec.py:20` fixava um caminho de máquina sob a home de uma conta real no `PATH` do hook (o core é PÚBLICO; a `door-leak-scan.sh`, família home, reprovava com rc 1) | **neutralizado**: o prefixo passou a `os.path.expanduser('~/.venvs/onion-core/bin')`, mesmo efeito na máquina de origem; a varredura saiu rc 0. O arquivo não está no `MANIFEST.sha256` do estudo, então o manifesto segue válido (`sha256sum -c` sem falha) |
| 2 | os dois grafos entravam com dívida SHOULD do contrato (o `kg-contract-check.sh` cobra grafo novo limpo): 12 `provenance.method` fora da forma `<classe>: <detalhe>` e 18 labels acima de 280 caracteres | **curado por forma, sem mudar o que o nó afirma**: a classe foi explicitada (`leitura:`, `medição:`, `derivado:`) mantendo o detalhe original; cada label longo foi cortado no último limite de frase antes de 280, e o resto foi para o início do `narrative` do mesmo nó. Os dois grafos saem conformes e com `kg-radar.sh --integrity --schema` rc 0 |
| 3 | duas citações do main apontavam para um arquivo que só existia numa branch local | curado (acima) |

## Varredura de vazamento (REGRA 36, REGRA 106, REGRA 119)

- `door-leak-scan.sh` (famílias sub, word e home) sobre os dois diretórios: 1 achado (o item 1), curado; depois rc 0.
- `private-name-check.sh` (REGRA 119 (O diff não acrescenta nome de repo ou de clone de adotante não federado)), modo MÁQUINA: 0 achados.
- Busca à mão por IPv4 e hostnames: nenhum IP; os domínios são fontes públicas citadas (github.com,
  anthropic.com, pagerduty.com e afins) e o exemplo genérico `empresa.com`. Nenhum arquivo excluído.
- A REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) e a REGRA 106 (Superfície que viaja
  passa pela varredura de vazamento da publicação) rodam no lint do commit dentro do `pr-finalize`.

## O que a passada NÃO cobriu (declarado)

- Não houve refutador independente: o brief proibiu criar agentes. É passada própria.
- O conteúdo dos estudos não foi re-julgado: os vereditos são do maestro e já estão no main; aqui só se
  conferiu forma, contrato e vazamento.
- Os scripts dos estudos (`cases.py`, `gate.py`, `hook_exec.py`…) não foram re-executados; só o `hook_exec.py` mudou, e a mudança foi conferida por parse.
