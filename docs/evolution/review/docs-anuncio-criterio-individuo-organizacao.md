---
title: 'Resíduo — o anúncio do critério selado, e o PR que testa a cura do revisor'
date: 2026-09-14
branch: docs/anuncio-criterio-individuo-organizacao
reviewed_diff_sha256: 50160ed6714430cdf4b36a34ca994343182b09751d72822217011db589ceb28b
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR de DOIS arquivos de documentação, sem código executável: o anúncio downstream e o registro de
  que ele foi transportado. O passo 6 do /engineer:pr dispensa a passada adversarial abaixo do corte
  (docs-only pequeno, espera de CI curta) — o custo de montar e ler os refutadores supera o ganho, e
  declarar `elenxo: nao` aqui é o uso correto do campo, não uma omissão. O escrutínio que este PR
  de fato exige foi feito por MEDIÇÃO e está descrito abaixo.
---

# Um anúncio, e o PR que serve de instrumento

## Por que NÃO houve passada adversarial

O passo 6 do `/engineer:pr` (escrito hoje, PR #827) declara o corte: obrigatória quando o PR toca
`.claude/`; dispensada em docs-only pequeno, porque **abaixo de ~10 min de espera o custo de montar
e ler o retorno supera o ganho**. Este PR toca dois arquivos de `docs/evolution/federation/outbox/`
e nenhuma linha executável.

Aplicar a regra é o ponto. Uma regra que se aplica sempre não é um corte — é cerimônia.

## O que foi verificado, por medição

| Verificação | Resultado |
|---|---|
| Transporte chegou íntegro | `cmp` staging × `inbound/` do adotante → **rc=0**, 6267 bytes byte-idênticos |
| Lint completo | **0 HARD** |
| Commits | **sem `--no-verify`**, nos dois |
| Conteúdo do anúncio contra o grafo | as quatro emendas conferidas contra `D_R2_EMENDAS_A_C_SELADAS`; o limite da ANPD contra o nó da rodada 2 |

**O transporte foi conferido pelo que CHEGOU, não pelo que o remetente diz ter enviado.** É a mesma
régua do `comm -13` do `/meta:co-evolve`, e ela existe porque um cruzamento desses achou **7
anúncios entregues no checkout errado** em 2026-07-21 — o core achava que tinha anunciado, o adotante
nunca viu, e nenhum gate disparou.

## O achado que este PR carrega sem ser dele

O anúncio transmite ao adotante uma **refutação que o core fez de si mesmo**: a rodada 3 concluiu que
não há análogo brasileiro do art. 88 do GDPR *porque a lista do art. 611-A da CLT seria fechada*. O
texto oficial diz **"entre outros"** — a lista é exemplificativa e a conclusão cai.

Transmitir isso é o ponto: sem essa linha, o adotante herdaria o erro e desenharia o banco de provas
em cima dele.

## ⚠️ Este PR é um INSTRUMENTO, e é isso que mais importa nele

Ele é o **primeiro depois do merge do #827**, que levou a cura do revisor do CI
(`--allowedTools Read Grep Glob Bash`). Essa cura **não pôde ser validada no PR que a escreveu** —
PR que edita `onion-review.yml` faz a action **se auto-pular**, então ela saiu verde sem ser
exercida.

O `onion-review` aqui é o veredito, e o nó `A_CURAR_O_REVISOR_DO_CI_COM_MECANISMO` fica `open`
até ele falar:

| Se o revisor | Leitura | Ação |
|---|---|---|
| revisar de verdade (turnos, parecer) | a allowlist funcionou | fechar o nó |
| morrer em **t=0, zero turnos** | allowlist estreita demais | **alargar, nunca remover** |
| morrer com **negações** de novo | o alvo estava errado | voltar a medir, pelo `onion-review-diagnose` |

E o PR é pequeno **de propósito** para o sinal vir limpo: sem mudança grande, o que o revisor fizer
(ou não fizer) é sobre ele, não sobre o diff.

## Gate

```
lint (LC_ALL=C, completo) : 0 HARD
transporte                : cmp rc=0 (byte-idêntico no inbound do adotante)
commits                   : 2, sem --no-verify
passada adversarial       : DISPENSADA pelo corte do passo 6 (docs-only), declarada e não omitida
```
