---
title: "Resíduo da passada adversarial — a poda que apagava fora do alvo"
date: 2026-09-06
branch: fix/materialize-poda-orfaos
reviewed_diff_sha256: 548011eac7a18b9e9a44b73b3457dc808028d3cb0d7ca6745acefd8860b2dcef
findings_total: 9
findings_real: 8
tokens: 132893
duration_min: 26
verdict: REPROVADO-E-CURADO
kg: docs/onion/graph/onion-plugin-publication-2026-08.kg.yaml
---

# Resíduo da REGRA 56 — REPROVADO, e o achado é dano FORA do diretório alvo

O alvo real desta função é um **repo público**, e o passo seguinte a este PR é rodá-la lá e dar push.
Pedi ao revisor que atacasse com esse peso. Ele achou o que eu não tinha visto.

## 🔴 O achado que bloqueava

`rm -rf "${dir}/"` — com a **barra final que o glob `*/` sempre produz** — **atravessa symlink** e
apaga o conteúdo do **alvo do link**, fora do TARGET. Verifiquei isolado antes de aceitar:

```
$ ln -s "$T/real" "$T/plugins/link"
$ rm -rf "$T/plugins/link/"; echo "rc=$?"
rc=0
depois: 0 arquivo(s) em real/ · link ainda existe? SIM
```

Três agravantes: o `rm` retorna **0**, o relatório declara `⊘ podado`, e o **link sobrevive** para a
rodada seguinte repetir o dano. Cura em duas camadas — symlink nunca é podado (só reportado) e o `rm`
usa `${_d%/}`.

## As outras quatro

- **O marcador estava invertido.** Eu testava `plugin.json`, que é marcador de *ser plugin*, não de
  *ter sido gerado aqui*. Um plugin que o dono do marketplace publique à mão seria **apagado** — perda
  de dado no repo dele. O marcador certo já existia e não era usado: `provenance.json`, escrito pelo
  assemble.
- **Poda e catálogo enumeravam diferente.** A poda por glob é cega a dot-dir; o gerador usa `find`.
  Um órfão **oculto** sobrevivia à poda **e entrava no catálogo** — o próprio sintoma que a poda existe
  para matar, ainda vivo.
- **A poda não era transacional.** Rodava antes da guarda de moat: um `exit 3` deixava o alvo **pior**
  que antes — catálogo apontando para diretório já apagado, irreversível. Agora roda depois.
- **A mensagem de commit dizia um número só.** Agora diz `N do core · M no catálogo` quando divergem.

## A bancada estava fraca — e a lição é específica

Dos 8 mutantes do revisor, **quatro sobreviveram** ao meu caso `(c)`. O pior deles: eu assertava
`catálogo == construídos`, **dois números que zeram juntos** — a poda apagando *tudo* satisfazia a
asserção, e quem matava o mutante era outro caso, por acidente. A âncora agora é o **nº de
manifestos**.

O caso reescrito cobre: órfão normal · órfão **oculto** · órfão com nome **prefixo** de um produzido
(pega match-por-substring) · plugin sem `provenance` que tem de **ficar** · symlink com segredo fora
do alvo que tem de **sobreviver** · e as três linhas de relatório (poda silenciosa era mutante vivo).

O caso `(d)` existe porque o guarda `[ -L ]` torna a segunda camada **inalcançável**: o mutante que
devolve a barra final sobrevive ao `(c)`, medido. Ele mede o comportamento do `rm` num sandbox — para
a razão do `%/` ficar provada e não virar folclore — e confere a forma no helper. É a **única**
asserção estrutural da família, declarada como tal em vez de disfarçada de comportamental.

## Placar

| | antes | depois |
|---|---|---|
| mutantes sobreviventes | 4 de 8 | **0 de 5 testados** |
| casos da família | 3 | **4** (o (c) muito mais denso) |
| bancada total | 1097 | **1098** |

## O que resistiu (não refutado)

Nomes com espaço, acento, iniciando com `-`, com glob (`*`, `?`, `[a-z]`) — podados corretamente, sem
expansão nem execução. Colisão prefixo/sufixo real. Arquivo solto, `.git` dentro de `plugins/`,
diretório vazio, arquivos fora de `plugins/`: intocados. TARGET novo/vazio: ok.

## ANOTAR (não curado, declarado)

Não há guarda `TARGET != SRC` (pré-existente). Hoje inócuo — o core rastreia exatamente os 5
produzidos — mas se um manifesto for removido **e** o TARGET apontar para o próprio core, a poda
apagaria plugin rastreado e vivo. Fica nomeado aqui em vez de silenciado.
