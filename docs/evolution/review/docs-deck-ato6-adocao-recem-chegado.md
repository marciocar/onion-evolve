---
title: 'Resíduo — o deck prometia 4 slides novos e a projeção publicada disse 2'
date: 2026-10-01
branch: docs/deck-ato6-adocao-recem-chegado
reviewed_diff_sha256: 5cb65e938c819e2f17b96ad31444dcce98d23252ab3dcf3f54936c9dc5074421
findings_total: 4
findings_real: 4
findings_fixed: 4
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

## 4. O painel de estado CONTA os resíduos — então todo PR que adiciona um deve regenerá-lo

Achado pelo CI, e só reproduzível na árvore de merge do PR: a **REGRA 81 (Painel de estado é GERADO
dos produtores, nunca redigido)** reprovou com o painel **em sync no `main` e em sync num clone raso**
— o que me fez procurar no lugar errado por duas rodadas. A divergência só aparece na árvore
`refs/pull/899/merge`, e é de **duas linhas**:

```
| Resíduos de revisão     | 345 → 346 |
| — legado (texto livre)  |  91 →  92 |
```

O painel é alimentado por `review-ledger.sh --env`, que **conta os resíduos**. Logo existe um
acoplamento que ninguém tinha nomeado: **a REGRA 56 (PR aberto carrega RESÍDUO da passada
adversarial) exige um resíduo, e esse resíduo muda um número que a REGRA 81 cobra.** Todo PR que
adiciona resíduo tem de regenerar o painel no mesmo commit — e o `--only` do lint não dispara essa
guarda (ela é regra de repo), então o pre-commit local nunca a vê num PR de um arquivo.

**Nota colateral, pré-existente e não curada aqui:** meu resíduo entrou como *legado (texto livre)*
embora o `verdict:` esteja no enum, porque o ledger extrai a forma de maneira frouxa e pegou a
primeira palavra da prosa do `nota:` ("**Três** achados…"). A lista de legado tem 68 formas
distintas e a maioria são palavras de prosa (`TRES`, `UMA`, `DUAS`, `SEIS`, `OS`, `FICA`) — é a mesma
evidência que o próprio script cita para ter fechado o vocabulário. Fica **declarado, não curado**:
gatilho é alguém querer usar o ledger para decidir algo, momento em que a extração frouxa deixa de
ser cosmética.
