---
title: 'Resíduo — o pre-commit escolhe a bancada por caso, e o refutador pegou a cobertura escrita à mão'
date: 2026-10-11
branch: feat/precommit-bench-by-case
reviewed_diff_sha256: fc101cebf3cca9c66654a53b2ef9f981b5e64b0936f7976f7351081a33d7ac56
reviewed_code_sha256: 37c4485f66341ac30e3a288ca9a68e718c5ad097cfb1f9a5b418500e32907596
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 179065
duration_min: 17
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Passada adversarial com mandato de achar FALSO NEGATIVO (a seleção nova rodando menos do que devia),
  default reprovado. Reprovou com um falso negativo real, provado por mutação. Os cinco achados foram
  curados, cada um com caso de bancada e mutante que o mata. Depois do rebase sobre a main 9ef87725
  (REGRAS 102 e 103), o contexto principal mediu um 6º falso negativo: a cobertura derivada seguia nome de
  script, não o DADO que a guarda lê (interface.md não selecionava task_manager_capabilities). Curado por
  classe; o resíduo volta a pendente para o hash ser recalculado no diff novo.
---

# Seleção por caso no pre-commit (SAC-72)

## O que mudou

A faixa do pre-commit da bancada (`--affected` / `--affected-staged`) passou a escolher por caso:

- **Bloco.** Um diff em `lint-selftest.sh` roda só as famílias cujo bloco `run_*_selftests` mudou,
  mais as que leem a bancada como dado. Se mudar uma linha de código fora de família, roda tudo, e a
  linha que causou isso é impressa.
- **Núcleo.** Caiu de 14 famílias para 1 (`gitattributes_eol`), e essa uma tem a razão escrita. As
  outras 13 declaram o que cobrem com `# selftest-covers:`. Essa cobertura é fraca de propósito: ela
  seleciona a família, mas não conta para o failsafe.
- **Empacotado.** Um arquivo que algum manifesto de plugin empacota seleciona as famílias de plugin,
  entre elas `plugin_bundle`. Era o achado do PR #1024. O pre-commit também passa a disparar a bancada
  nesse caso; antes, um commit só de skill nem chegava a rodá-la.
- **Checkpoint.** Com `ONION_PRECOMMIT_CHECKPOINT=1`, o pre-commit mostra a seleção e diz em voz alta
  que não validou nada, em vez do `--no-verify`, que pulava tudo calado.

O CI continua rodando a bancada completa.

## Achados do refutador e curas

1. **Falso negativo real.** `materialize_repo` declarava só o script materializador e os manifestos.
   O materializador chama `marketplace-readme.sh`, que, mutado, quebrava a família. A seleção não a
   rodava, porque o arquivo é citado por outra família e por isso o failsafe não disparava.
   **Cura:** a cobertura fraca virou fecho derivado. Ela parte de cada script declarado e inclui o
   diretório dele e todo script que ele cita pelo nome, de forma transitiva. O caso (f) prova a cura.
2. **A mesma classe nas outras famílias.** Anotação escrita à mão é uma lista. **Cura:** o mesmo
   fecho vale para todas. `model_ssot` e `site_derivation` passam a cobrir `.claude/validation/`.
3. **String aberta num bloco e "fechada" por `}` na coluna 0.** Nesse caso, uma linha `#` depois do
   fechamento seria lida como comentário inerte. **Cura:** o estado das aspas atravessa as linhas de
   família e recomeça só no próximo cabeçalho. O caso (c9) prova a cura.
4. **Renome e exclusão.** `--name-only --diff-filter=ACMR` perdia o caminho antigo. **Cura:** a coleta
   usa `--name-status -M --diff-filter=ACMRD`, e o gatilho do pre-commit passa a incluir D. O caso (g)
   prova a cura.
5. **`.gitattributes` não disparava o gatilho.** **Cura:** `gitattributes_eol` declara cobrir esse
   arquivo, e o mapa exato do gatilho o enxerga.

## Mutantes (ops/mutate-and-restore.sh)

Os 8 mutantes reprovam o caso certo da família `selftest_selection`: regra do bloco desligada,
derivação do empacotado desligada, cobertura fraca contada como conhecida, 2ª camada de heredoc
desligada, núcleo sem razão, fecho desligado, renome/exclusão fora do staged e estado de aspas zerado
nas linhas de família.

## 6º achado (contexto principal, depois do rebase sobre 9ef87725)

**O dado lido pela guarda não selecionava a família.** A REGRA 103 lê `interface.md` e
`adapters/*.capabilities.tsv`. Mudar `interface.md` selecionava 30 famílias, e
`task_manager_capabilities` não estava entre elas. **Cura de classe, derivada:** de todo script que a
família cita, ou alcança pelo fecho, cada caminho de dado nomeado no CÓDIGO (`.md/.tsv/.yaml/.json/.txt/.csv`,
inclusive glob) e cada diretório não-raiz do repo viram cobertura fraca. Ficam fora:
- o `lint-artifacts.sh`, que é infraestrutura (mudá-lo já compra tudo) e roda sobre fixture;
- as raízes do domínio (`.claude/validation/` derivado punha 78 famílias num commit de um helper só, e o
  `selftest_lanes` (e) acusou).

O caso (h) e o 9º mutante (derivação de dado desligada) provam a cura. O mutante da cobertura fraca
contada como conhecida tinha deixado de morder, porque a compactação levou a cobertura do template a
`.claude/utils/`, uma raiz que o failsafe já exclui por outra via. O caso (d) ganhou o `.tsv` do adapter,
que só uma cobertura fraca não-raiz alcança, e o mutante voltou a reprovar.

**Custo:** commit de skill empacotada sobe para 73 famílias (~520 s medidos hoje + ~175 s pela série de
09-11, com 17 sem medida). O commit só de doc segue com 1.

## Limite declarado

O fecho sobre-seleciona: ele segue nomes de script citados até em comentário. Por isso, num commit do
domínio, as 13 famílias saídas do núcleo quase sempre voltam. Elas só saem de vez nos commits fora do
domínio, como doc e skill não empacotada. É o preço de não estreitar.

## Passada pós-CI (2026-10-12)

O CI reprovou o caso (d) de `selftest_selection` depois do rebase. A 2ª sonda do (d) usava o
`jira.capabilities.tsv` como exemplo de cobertura **só fraca**, mas o caso (h) deste mesmo PR deu
cobertura FORTE a esse tsv (arquivo de dado lido pelo script da guarda). Os dois casos se contradiziam.
A sonda obsoleta saiu. Lacuna declarada no código: a exclusão da 3ª coluna (fraca por diretório
não-raiz) fica sem exemplo vivo, porque o outro diretório anotado também é forte. A família fica 19/19.
