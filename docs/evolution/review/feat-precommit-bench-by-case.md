---
title: 'Resíduo — o pre-commit escolhe a bancada por caso, e o refutador pegou a cobertura escrita à mão'
date: 2026-10-11
branch: feat/precommit-bench-by-case
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_fixed: 5
tokens: 179065
duration_min: 17
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Passada adversarial com mandato de achar FALSO NEGATIVO (a seleção nova rodando menos do que devia),
  default reprovado. Reprovou com um falso negativo real, provado por mutação. Os cinco achados foram
  curados, cada um com caso de bancada e mutante que o mata.
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

## Limite declarado

O fecho sobre-seleciona: ele segue nomes de script citados até em comentário. Por isso, num commit do
domínio, as 13 famílias saídas do núcleo quase sempre voltam. Elas só saem de vez nos commits fora do
domínio, como doc e skill não empacotada. É o preço de não estreitar.
