---
branch: fix/env-guard-heredoc-data-file
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: 111d30b3fe849b78a90f71bc99eb711e597fe0b30527d9712b636d10c1034ef5
reviewed_code_sha256: 7db1899f78ed02a6cb9ec26eb67552b29889a32bbd72bc9bc128972e3e5a3925
findings_total: 5
findings_real: 5
tokens: 0
duration_min: 35
findings_fixed: 5
verdict: CORRIGIDO
elenxo: nao
reviewer: "agente de execução (claude-opus-5-5), passada própria com bateria de escapes executada contra a main e contra a cura"
nota: "tokens não medidos (passada no próprio agente). A bateria tem 26 formas de composto (if/for/while/case, função com a chave na linha seguinte, function, exec, coproc, >&3, dois destinos, pipe com |& e 2>&1, mv/sed -f/source/bash -c do .md) e o replay dos 17 comandos vetados em 2026-10-23 nos transcripts desta máquina."
---

# Passada adversarial: `fix/env-guard-heredoc-data-file`

## O que muda

- `.claude/hooks/pretooluse-env-guard.sh`:
  - `group_outputs` e `attach_groups`: um heredoc sem redirecionamento próprio, dentro de um composto (`{ }`,
    `do … done`, `if … fi`, `case … esac`), grava onde grava o composto mais interno que redireciona a saída.
    Pipe depois do composto, corpo de função, `exec`, `coproc`, `>&N` (N ≥ 3) ou estrutura que não fecha deixam o
    corpo que cita o arquivo de segredos vetado.
  - `GROUP_LEAD`: o `{`, `do`, `then` ou `else` antes do consumidor não é o consumidor.
  - `_resolve_dests`: a variável do destino se resolve pelas atribuições dos trechos anteriores do mesmo comando,
    a não ser que um `for`, `select` ou `read` a troque. `/dev/null` não é destino.
  - `data_used_as_code`: o tee só toma por destino os argumentos antes do 1º operador, e `/dev/null` não é cópia.
  - `find` cujos `-exec`/`-ok` rodam só comando de METADADO passa, pelo mesmo critério do `wc` direto.
- `.claude/validation/lint-selftest.sh` (caso (u) da família `env_exposure`): 13 casos novos e os mutantes M25 a M34.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_ENV_GUARD_HEREDOC_COMPOSTO_CURADO_1023`; o índice de
  leitura do KG foi regenerado (REGRA 84 (Índice de leitura do KG em sincronia com os traces)).

## Achados

1. **Escape da main (cinco formas)**: o heredoc dentro de um composto era tido como saída padrão. Davam rc 0 na main:
   `{ true; cat <<'E' … E; } > run.sh; bash run.sh`, o grupo gravando um `.md` lido por `awk -f`, `f()` com a
   chave na linha seguinte chamada com `> run.sh`, `exec > run.sh` numa linha seguida do heredoc, e `coproc`.
   Curado: os cinco dão rc 2.
2. **Defeito anterior no tee**: o `data_used_as_code` tomava `<<`, o delimitador e o `>` como destinos do tee,
   então `tee r.md <<'E' >/dev/null` virava "cópia para nome não-dados". Curado com o corte no 1º operador.
3. **/dev/null como cópia**: com o achado 2 curado, `>/dev/null` ainda contava como cópia para nome não-dados.
   Curado.
4. **Falso positivo do find** (medido numa sessão do core): `find . -name CLAUDE.md -not -path './node_modules/*'
   -exec wc -c {} \;` era vetado depois de um `cd` numa linha com `(`, porque a pasta fica desconhecida e o glob
   do `-path` fecha como leitura. Curado pelo comando do `-exec`. `-exec cat {}` e a mistura `-exec wc` com
   `-exec cat` seguem rc 2.
5. **Caso de bancada que não exercitava o mutante**: `exec > run.sh; cat <<E` na MESMA linha já era pego pelo
   `written` da linha do operador, então os mutantes M25 e M32 sobreviviam. O caso passou para a forma com quebra
   de linha, que é o escape real da main, e os dois mutantes morrem.

## Mutantes

- Revertidos numa cópia do hook pela própria bancada: M25 (o composto não decide o destino), M26 (a palavra do
  composto é tomada pelo consumidor), M27 (sem as atribuições anteriores), M28 (`for`/`read` não invalidam),
  M29 (`/dev/null` como destino), M30 (pipe depois do composto), M31 (corpo de função), M32 (`exec`) e M33
  (`find` com `-exec` de metadado). Cada um inverte o caso dele.
- M34 aceita qualquer `-exec` e inverte `find-exec` e `find-exec-mix`: é a prova de que o `-exec cat` segue
  barrado pelo critério de metadado.
- Família `env_exposure` 17/17; as 44 famílias afetadas pelo hook (`--affected`) 650/0.

## Limites declarados

- Um composto que o veto não prova (`case` com parêntese de abertura, chaves desbalanceadas) veta o corpo de saída
  padrão que cita o arquivo de segredos, mesmo quando ele só iria para a tela. O erro é para o lado do veto, e a
  saída é a ferramenta Write.
- O destino `$VAR` usa a última atribuição literal do comando. Ramos (`if …; then R=a; else R=b; fi`) não são
  vistos, como já declarado para o glob. A execução do arquivo de dados segue barrada pelo `data_used_as_code`
  em qualquer dos dois nomes.
- `-exec wc`, `-exec sha256sum` e afins sobre o arquivo de segredos passam, como o `wc` direto (critério METADATA
  que já existia).
- Segue fora: o caminho em duas chamadas (grava com Write, executa depois) e o nome montado em runtime.
