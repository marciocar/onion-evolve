---
title: 'A classe do backtick registrada, e o passivo da outra porta nomeado'
date: 2026-09-26
branch: chore/backtick-class-and-door-pin
reviewed_diff_sha256: 216f2795a9768d602663e1e924f2da651eca2aff598e2e9501acf1bd6adedf34
elenxo: nao
findings_total: 1
findings_real: 1
verdict: SEM_ACHADOS
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, declarado: o diff registra uma classe JÁ medida três vezes (a evidência é histórica, não uma hipótese a refutar), carimba um campo que o mecanismo escreveu, e anota uma baseline. Nada aqui propõe desenho a ser atacado — o desenho que ele nomeia fica GATED. O único achado é uma observação de padrão, não um defeito.'
---

# Resíduo — a classe do backtick, e o passivo que ninguém escolheu

## O que este diff registra

**`C_BACKTICK_EM_PROSA_DENTRO_DE_CONTEXTO_QUE_INTERPRETA`** — três ocorrências em dois dias, todas com
o artefato **saindo 0**:

| # | onde | o que aconteceu |
|---|---|---|
| 1 | `ops/pr-merge-verified.sh` | dois contra-barras partiram o corpo do registro ao meio; postou `\`, saiu 0, disse "dispensa registrada" |
| 2 | `ops/materialize-door.sh` | crase dentro de heredoc **não-citado** virou substituição de comando; a palavra saiu **vazia** da instrução |
| 3 | `.claude/diary/` | caminho em crase citado **para dizer que não existe** — barrado pela guarda de ponteiro morto, que está certa em não distinguir a intenção |

**O padrão de falha é o pior formato possível:** `rc=0`, arquivo não-vazio, conteúdo mutilado. As três
verificações baratas — `rc`, `[ -s ]`, `bash -n` — passam em todas. Nas três, o que revelou foi **rodar
e olhar a saída**.

**E há um agravante que é desta casa.** A doutrina daqui manda escrever o **porquê dentro do artefato**,
em prosa densa que cita caminhos, campos e comandos em crase. Logo a superfície exposta a esta classe
**cresce com a própria prática que dá qualidade ao resto** — não é um descuido isolado, é um custo
estrutural do estilo, e por isso merece mecanismo em vez de atenção.

**Guarda GATED, com desenho nomeado:** extrair todo heredoc **não-citado** de `ops/**` e
`.claude/**/*.sh` e reprovar crase não-escapada dentro dele; `<<'EOF'` é isento **por construção**, e a
cura no sítio é escolher o heredoc citado ou escapar. A distinção citado-vs-não-citado é mecânica, a
superfície é enumerável, e o gatilho da casa (recorrência medida ≥ 3) **já disparou** — o que falta é a
decisão de construir, que é do maestro.

## O achado: um passivo que ninguém escolheu, subindo três vezes num dia

`onion-standalone` foi de 421 → 422 → **423** em um único dia, sempre pelo mesmo motivo: **cada leva
mergeada afasta uma porta que ninguém re-materializa desde 2026-07-19**. Não é trabalho novo — é a
catraca registrando passivo.

O que importa nomear é que **o número vai crescer para sempre** enquanto não houver decisão entre
**re-materializá-la** ou **declará-la congelada**. Continuar subindo a linha a cada leva é pagar a
esteira em silêncio, e silêncio é o que esta casa combate. A catraca já faz o que pode: não deixa o
passivo desaparecer. A escolha é do maestro, e este resíduo existe para que ela não fique implícita.

## O que o ciclo da porta provou, de graça

O `ops/door-seal-pin.sh` mostrou **os dois lados no mesmo ciclo**: **recusou** antes do commit (árvore
suja — materialização no disco não é publicação) e **carimbou** depois do push conferido no remoto. Na
véspera, a v1 teria carimbado no primeiro momento. `onion-core` está `ok 0/0` — medido pela porta, não
pela memória.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **1500 casos · 0 falhas**
- `door-staleness-check.sh` → **rc=0**, com `onion-core ok 0/0`
- `kg-radar.sh --integrity --schema` → **exit 0**, teto 54→55 com razão escrita
