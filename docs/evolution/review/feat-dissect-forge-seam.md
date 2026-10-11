---
branch: feat/dissect-forge-seam
date: 2026-10-11
reviewed_diff_sha256: 38aeeeaa8bd6990c807a9c688e7b5338b2e288464415c25aa1a194118ef5fcfe
reviewed_code_sha256: 5a6d4b5775850b38d775582c9b050b0ea9656ef1aa236fb554c113ff07950982
findings_total: 5
findings_real: 5
findings_fixed: 3
tokens: 230000
duration_min: 75
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (sem subagente), default reprovado — gate mecânico: família run_dissect_selftests (20 casos) + 6 mutantes + kg-radar + kg-contract-check
---

# A costura dissect→forge sob o refutador: cerimônia sem consumidor, ou plano que se preenche sem medir?

Default reprovado. Duas perguntas do maestro guiaram a passada, e cada uma rendeu achado.

## Achado 1 — o 1º plano pede uma peça que a forja declara não emitir (REAL, curado na prosa)

O plano do Conductor pede as peças **4 e 7** do `onion-research`. O `/meta:forge` diz, com todas as
letras, que **não emite a peça 4**. Se a costura parasse aí, seria cerimônia: o plano entraria no
forge e o forge não teria o que fazer com ele. O leitor mede `4:existe · 7:existe` — logo é
**mudança**, não emissão, e a forja v1 **não tem passo de mudar**. Cura: o `forge.md` diz isso, e
diz o caminho (fluxo normal `/engineer:*` com o plano como especificação; a forja cobra dogfood e
paridade com mutante). Não inventei um passo de mudança que não existe.

## Achado 2 — hex solto no nome do repo contava como pin (REAL, curado com caso e mutante)

A 1ª versão aceitava qualquer sequência de 7 hex na URL: `example.org/deadbeefcafe-tool/blob/main`
passava como "origem com pin" apontando `main`, um alvo que anda. Cura: pin só na posição de pin
(`/blob/` `/tree/` `/commit/` `/tag/` `@` `ref=`). Caso `(p3b)`; o mutante com o regex velho morre.

## Achado 3 — o censo lia data só sem aspas (REAL, curado com caso e mutante)

Achado pelo dogfood, não pela passada, mas registrado aqui porque é defeito do código tocado: a
gramática exige data entre aspas desde o contrato v3, e o `dissect-census.sh` só lia a forma nua. A
dissecação nova saiu `NAO-DECLARADO` com `review_after` presente. O caso `(x)` existente usava data
entre aspas e não pegou, porque só olha nível e veredito. Caso `(q)`; mutante morre.

## Achado 4 — o plano pode ser preenchido sem medir? Metade sim (REAL, DECLARADO, não curado)

As **peças** não: o plano nem tem campo para "existe", o leitor mede no `forge-census` (caso `(p1)`
com mutante). **Origem e licença**, sim: o leitor confere a FORMA (URL com pin, cara de SPDX), não
a VERDADE — uma sessão pode digitar `MIT` sem ter lido nada. O teto está declarado no script, na
doutrina (§4b) e no `forge.md`. A mitigação que existe é de processo, não de máquina: no Conductor
a licença do plano tem lastro num nó N0 `confirmed` com proveniência da API do GitHub. Amarrar
mecanicamente o plano ao nó N0 ficou de fora por não haver defeito medido (nenhum plano falso
existiu ainda) — gatilho: o 1º plano cuja licença divergir da fonte.

## Achado 5 — o forge passou a "ter a peça 3" por causa desta mudança (REAL, DECLARADO)

O `forge-census` conta a peça 3 pela diretiva `!` de medição. O `forge.md` tinha **0** (o censo
dele mesmo está numa cerca `bash`, que a sessão roda à mão); com a diretiva do `--plans` passou a
**1**. É contexto medido de verdade, mas não é o censo da forja. Corolário do mesmo teto que o
dogfood achou no dissect (7/7 contando o motor pela citação): presença e referência, nunca
comportamento. Não converti a cerca do censo em diretiva — mudaria o volume de contexto de toda
invocação da forja, fora do escopo; fica como achado para quem tocar a forja.

## O que ficou fora, por desenho

- **Guarda de lint nova:** não. O defeito medido não era "plano sem licença passa" (não havia plano
  nenhum); era ausência de forma e de leitor. O mecanismo é o medidor do próprio dissect, com
  polaridade (`p1` COMPLETO rc 0 × `p2..p5` INCOMPLETO rc 1 × `p6` rc 3) e mutantes.
- **A absorção do Conductor:** próxima onda, gatilho = selo do maestro em `D_CONDUCTOR_1011`.
- **O motor sem níveis:** declarado no `dissect.md` (desenho, não implementação), não implementado.
