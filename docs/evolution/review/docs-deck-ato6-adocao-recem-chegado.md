---
title: 'Resíduo — o deck prometia 4 slides novos e a projeção publicada disse 2'
date: 2026-10-01
branch: docs/deck-ato6-adocao-recem-chegado
reviewed_diff_sha256: 52a791ff6df14c36e82c241efe694eb1ac457fcd4d7fa36285cfaaeb948e656d
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 180000
duration_min: 25
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Três achados, todos meus e todos de medição, numa mudança de um arquivo só. O central é que eu
  escrevi a spec ANTES de ler o artefato publicado: prometi 4 slides novos e 79 no total, e a leitura
  mostrou que 2 já existiam — são 2 novos + 1 completado, Ato 6 = 7, total 77. Sem Elenxo porque é
  mudança de documento de estrutura com verificação direta contra a projeção publicada; o erro foi
  achado pela leitura do vivo, que é a medição que importava aqui.

# Escrevi a spec antes de ler o que já estava publicado

## 1. A spec prometeu 4 slides novos; a projeção publicada tinha 2 deles

Redigi a estrutura do Ato 6 de memória e declarei **4 slides novos, 79 no total**. Ao ler o Artifact
publicado, `ciclo-adocao` e `tipos-adocao` **já existiam** — a conta real é **2 novos + 1
completado**, Ato 6 com 7 slides, **77 no total**. A spec corrigida declara o próprio erro em vez de
apagá-lo, e a tabela agora soma 77 com a frase citando 77.

É a classe `behavior-over-declaration` aplicada a mim: o que o deck **é** vive na projeção publicada,
não na minha lembrança do que eu teria posto nele.

## 2. O deck nomeava o sintoma e não dava a cura

O slide "Por onde começar" fechava perguntando *"alguma guarda já te barrou? Se ainda não, a
maquinaria está no disco mas não no caminho"* — sintoma correto, cura ausente. O motivo é um comando
por clone, porque `core.hooksPath` é **config local** e o git nunca a transporta: nem no push, nem no
clone. O slide `onion-no-clone` fecha esse laço.

## 3. O que fica versionado só existia na maquinaria, não no material que ensina

A pegadinha mais cara da adoção — repo que ignora `.claude/` **inteiro** faz o commit de adoção
stajar **zero** arquivos, e quem clona recebe **nada**: sem carimbo, sem gate, sem comandos — vivia
só dentro do `/meta:adopt`. Medida num adotante legacy em 2026-07-24. Agora está no slide
`o-que-fica-no-repo`, com os números medidos num adotante real hoje (615 arquivos em `.claude/`, 156
em `docs/`) e o carimbo `.onion-version` nas 9 linhas literais.

## Medições que entraram no deck, nenhuma de memória

- `chore/onion-update-<pin>`: **4 delas** num adotante real em 2026-10-01 — a terceira branch, que o
  slide `branches-onion` omitia.
- `onion/vendor` existe de fato (`vendor-branch.sh`, e o adotante tem a branch).
- A pegadinha do husky é real: `hooksPath` apontando para `.githooks` com `.husky/pre-commit`
  presente faz o hook do husky parar de rodar em silêncio.
