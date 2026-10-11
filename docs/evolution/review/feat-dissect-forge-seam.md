---
branch: feat/dissect-forge-seam
date: 2026-10-11
reviewed_diff_sha256: 018e6961b11e293f63302d28533169cd98185a5760acef7245e856ada0a0d675
reviewed_code_sha256: 9d234cf74439835003cf6de55525cedd08b81612ea069dfc6d01f7c8f729ea9f
findings_total: 6
findings_real: 6
findings_fixed: 4
tokens: 290000
duration_min: 100
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (sem subagente), default reprovado — gate mecânico: famílias dissect (19 casos), forge, plugin_bundle, materialize_repo e plugin_runtime + 7 mutantes + kg-radar + kg-contract-check
  Depois do PR aberto, o maestro selou D_CONDUCTOR_1011 (absorver o conceito, rejeitar o validador fail-open)
  e o contexto principal aplicou o selo no nó (confirmed, com provenance de testemunho), radar e contrato rc 0.
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
dele mesmo está numa cerca `bash`, que a sessão roda à mão); com a diretiva do leitor de planos (hoje `dissect-plans.sh`) passou a
**1**. É contexto medido de verdade, mas não é o censo da forja. Corolário do mesmo teto que o
dogfood achou no dissect (7/7 contando o motor pela citação): presença e referência, nunca
comportamento. Não converti a cerca do censo em diretiva — mudaria o volume de contexto de toda
invocação da forja, fora do escopo; fica como achado para quem tocar a forja.

## Achado 6 — o censo que VIAJA passou a depender de um que não viaja (REAL, achado pelo CI, curado)

> **Nota de re-revisão (pós-CI):** o carimbo anterior caiu, porque o diff mudou depois dele. Este achado não
> veio da minha passada: veio da faixa 3 do CI, que reprovou 4 casos (plugin-bundle, materialize-repo
> a e c, plugin-runtime). Ao contrário do que eu tinha escrito, a passada própria **não** viu o defeito.

A hipótese inicial era o `forge.md` ter levado ao plugin uma diretiva sem o script dela. Medida no
assembler, estava **invertida**: o forge nem viaja no `onion-meta`. O erro inteiro foi *"dissect-census.sh
precisa de forge-census.sh, que NAO esta no VALIDATION[] deste manifesto"*. O `--plans` foi posto dentro
do `dissect-census.sh`, que viaja, e fez dele invocador do `forge-census.sh`, que não viaja porque mede
o harness do repo. O manifesto já declarava essa fronteira em prosa; eu a cruzei sem ler o manifesto.
**Cura**, no padrão do próprio forge-census: o leitor sai para `dissect-plans.sh` (core e standalone, do
lado do forge), e o censo que viaja volta a não ter a dependência. **Mutante**: o censo voltando a
invocar o forge-census derruba a montagem do plugin (`plugin-bundle: montagem`). Correção de número: a
família `dissect` tem **19** casos, não os 20 que eu tinha escrito.

## O que ficou fora, por desenho

- **Guarda de lint nova:** não. O defeito medido não era "plano sem licença passa" (não havia plano
  nenhum); era ausência de forma e de leitor. O mecanismo é o medidor do próprio dissect, com
  polaridade (`p1` COMPLETO rc 0 × `p2..p5` INCOMPLETO rc 1 × `p6` rc 3) e mutantes.
- **A absorção do Conductor:** próxima onda, gatilho = selo do maestro em `D_CONDUCTOR_1011`.
- **O motor sem níveis:** declarado no `dissect.md` (desenho, não implementação), não implementado.
