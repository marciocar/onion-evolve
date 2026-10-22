---
branch: feat/workspace-adopt-sync
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 509d904533befd5f8dbbdf7407f2578d85636e7f8ed23dcfde36e997d585a039
reviewed_code_sha256: 5eabca7fad3689c7c9e5441b616cb2027ff1df9fa4eefde6aef6e7b22956a92e
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 60
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `feat/workspace-adopt-sync`

## O que muda

- `ops/workspace-adopt-sync.sh` (core-only, novo): `stage` copia um workspace do /chat para um staging da sessão
  (menos os `.env`, com manifesto do vivo), `apply` devolve o staging ao vivo depois de conferir o manifesto, com
  backup timestampado, rollback impresso e os `.env` protegidos do `--delete`, e `verify` confere o motor KG e o
  `/meta:decide` no vivo e roda o radar de um grafo dele. `--selftest` (13 casos) e `--selftest-mutants` (7 guardas).
- `ops/moat-targets.tsv`: `/var/lib/onion-bridge/workspaces` ganha o wrapper.
- `.claude/validation/lint-selftest.sh`: família `workspace_adopt_sync`.
- Grafo: o selo `D_UI_PILOT_WORKSPACE_ATUALIZA_POR_STAGING_E_WRAPPER_1022`.

## Achados

1. **Grave, achado na 1ª corrida da bancada:** num contexto testado (`( cmd_stage … ) || rc=$?`) o bash desliga o
   errexit, o `die` do `check_target` saía só do `$( )`, o `ws` ficava vazio e o `rsync` partia de `/`. A bancada
   copiou a raiz para o sandbox (só leitura, como o próprio usuário, sem sudo) até ser morta; nada fora do `/tmp`
   foi escrito. Curado em três camadas: `|| exit 2` explícito em cada `check_target`, `shopt -s inherit_errexit`, e
   o trilho `need_path` (sem marca de mutante) antes de todo rsync/tar. Caso novo: a recusa num contexto testado não
   cria staging.
2. O teste de symlink rodava sem sudo: num diretório que o operador não atravessa, `[ -L ]` dá falso e o symlink
   passaria em produção. Agora `sudo_do test -L`.
3. O `realpath` do PREFIX também precisava de sudo (medido: "Permission denied" no 1º stage real).
4. A família extraía "( pass)" (o 1º " pass" da saída era de um rótulo); agora casa `selftest: N pass`.

## Mutantes

- `--selftest-mutants`: symlink, prefixo, marcador de stage, staging alheio, manifesto, symlink de fuga e `.env` no
  staging — 7 de 7 mortos.
- O gate MOAT, sondado com o JSON do hook: `bash ops/workspace-adopt-sync.sh apply …` rc 0 (wrapper rastreado);
  `sudo rsync … /var/lib/onion-bridge/workspaces/<id>/` rc 2, nomeando o wrapper.

## Limites declarados

- O `apply` real é a 1ª execução em produção; o backup e o rollback impresso são a rede.
- A propagação do `|| exit 2` não tem mutante: derrubá-la faria o mutante copiar `/` de novo. O trilho `need_path` e
  o caso "recusa num contexto testado" cobrem a classe.
