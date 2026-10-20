---
title: 'Resíduo — o --update prova que o gate do alvo BARRA, num sandbox descartável'
date: 2026-10-20
branch: feat/adopt-update-proves-gate-blocks
reviewed_diff_sha256: bbf3976ea14de16a6e649a4ffee339a01efb14423c57c676e70fade4802720ae
reviewed_code_sha256: 925d7c04ee66bd6db7886c6566a156fe39c993e115f1645419b5663405eb9313
findings_total: 7
findings_real: 7
findings_fixed: 7
tokens: 134909
duration_min: 10
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Autorizado pelo maestro via /meta:decide em 2026-10-20. Recorrência medida: em 11 updates seguidos o
  verify-adopter-gate.sh (core-only) só provou que o hook EXECUTA, e o commit-sonda de bloqueio ficava com a sessão
  do adotante. O prove-gate-blocks.sh clona o alvo com --shared para mktemp, sobrepõe o pendente contra o HEAD e os
  hooks do disco, faz um commit de controle e um com uma linha plantada em docs/onion/inventory.md (REGRA 8), exige
  rc diferente de zero com a regra citada e confere que HEAD, branch, status e config do alvo não mudaram. O refutador
  isolado (10 experimentos executados em sandbox próprio) reprovou a 1ª versão com 7 defeitos: um bloqueador, um falso
  PROVADO para hook que barra tudo (o controle barrado era aceito contando linhas VIOLATION, que o lint imprime também
  para SOFT); três reais, todos falsos NÃO PROVADO ou escrita no alvo: o pendente só stageado ficava fora do sandbox
  (ls-files -m compara com o índice), o hook no gitdir comum de uma worktree ia para fora do .git do sandbox e o
  delegador relativo quebrava, e o hook symlink absoluto preservado por cp -a lintava e escrevia no checkout real; três
  menores: o cabeçalho afirmava que o clone --shared não escreve nada no alvo (o git refresca o mtime de objetos),
  sinal deixava a última linha sem veredito, e três decisões sem caso que as medisse. Todos curados: controle barrado
  nunca é PROVADO (as HARD vêm do sumário do lint e só escolhem rc 3 ou 1), diff HEAD no lugar de ls-files -m, hooks do
  gitdir comum para o mesmo caminho no .git do sandbox, cp -aL, cabeçalho corrigido, trap de sinal, e seis casos novos
  com mutante cada (24 casos na família, todos verdes também sob LC_ALL=C). Teto declarado no cabeçalho, não curado:
  hook que faz cd para caminho absoluto fixo do repo real escapa do sandbox, e a foto não vê arquivo ignorado (vê-los
  daria rc 4 falso a cada log de sessão viva). No dogfood, a 1ª foto incluía todas as refs e acusou o repo real do
  adotante de ter mudado: era uma branch commitada pela sessão dele noutra worktree; a foto ficou em HEAD, branch,
  status e config, e o 2º dogfood viu outra ref andar sem acusar falso. Tokens e duração são os do refutador.
  Confirmed do grafo editado, visto: field-hub-update-2026-10-19.kg.yaml: E_UPDATE_PROVA_BLOQUEIO_DO_GATE.
---

# Resíduo da passada adversarial

## Achados

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 1 | bloqueador | hook que barra tudo saía PROVADO: o controle barrado era aceito quando havia linhas `VIOLATION:`, e o lint imprime SOFT com o mesmo prefixo | controle barrado nunca é PROVADO; HARD lidas do sumário `Violações HARD : N` só escolhem rc 3 (o alvo já reprova) ou rc 1 (barra tudo) |
| 2 | real | pendente só stageado ficava fora do sandbox (`ls-files -m` compara working tree com índice) | `diff --name-only HEAD` mais os não-rastreados; apagados por `--diff-filter=D` |
| 3 | real | worktree com hooks no gitdir comum: a cópia ia para fora do `.git` do sandbox e um delegador `../../.githooks` quebrava | hooks sob o gitdir comum vão para o mesmo caminho dentro do `.git` do sandbox |
| 4 | real | hook symlink absoluto, preservado por `cp -a`, voltava ao checkout real, lintava e escrevia lá | `cp -aL`; teto do hook com caminho absoluto fixo declarado no cabeçalho |
| 5 | menor | o cabeçalho afirmava que o clone `--shared` não escreve nada no alvo; o git refresca o mtime de objetos | cabeçalho corrigido |
| 6 | menor | sob SIGTERM a última linha não era o veredito | `trap` de TERM, INT e HUP com veredito NÃO PROVADO |
| 7 | menor | três decisões sem caso que as medisse (cópia de hooks, apagados, ramo do gitdir comum) | casos (i), (j), (k), (l), (m), (n) com mutante cada |

## Verificação

- Bancada `prove_gate_blocks`: 24 de 24, também sob `LC_ALL=C`.
- Dogfood contra um clone local descartável de um adotante de campo: `bloqueio PROVADO (REGRA 8 (Inventário canônico sincronizado com o filesystem), rc 1)` em 172 s; hook trocado por eco, `NÃO PROVADO` rc 1; sem pre-commit, `NÃO PROVADO` rc 3; o repo real do adotante igual antes e depois.
