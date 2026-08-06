---
branch: fix/review-verdict-caso-benigno
pr: 552
date: 2026-08-06
reviewed_diff_sha256: b0616a628f49edd6c36a72f208c3cae10b6f26bf60fd53957db162e10186f4cd
findings_total: 5
findings_real: 5
findings_fixed: 3
tokens: 76843
duration_min: 6
verdict: CORRIGIDO-E-RE-REVISADO
reviewer: code-reviewer (opus, adversarial)
---

# Passada adversarial — `fix/review-verdict-caso-benigno`

> **Este PR está FORA do escopo da REGRA 56 por desenho** (`_skip PR-edita-o-proprio-revisor`, o caso
> ovo-galinha). O artefato existe assim mesmo: a revisão foi rodada, achou defeito **ALTO**, e os
> campos alimentam a reavaliação em N=10. Registrar quando não é obrigatório é o que distingue o
> mecanismo do teatro.

## Por que a passada aconteceu

A guarda de shell avisou ao abrir o PR. A REGRA 56 não o alcançaria — mas **a substância do aviso
estava certa**, e hoje mesmo custou caro: a revisão ausente no #546 deixou passar 8 defeitos.

## Achados

| sev | achado | status |
|---|---|---|
| **ALTO** | `HAS_ANTHROPIC_KEY != 'true'` → o job **roda**, steps pulam, conclui `success` (não `skipped`) ⇒ `revisou=''`, `benigno=''` ⇒ **exit 1 para sempre**. E o ramo `RESULT == skipped` é **código morto**: só fork o produz, e ali o veredito nem roda | **corrigido** — `sem_chave` exportado do step que já detecta |
| **MÉDIO** | `always()` **não** cancela o job ao cancelar a run — o GitHub re-avalia e `always()` dá `true`. Um `gh run cancel` humano virava "❌ NÃO foi revisado" | **corrigido** — `!cancelled()` |
| **MÉDIO** | o predicado `benigno` é **proxy do diff**, não da causa. Enquanto só suprimia comentário, bastava; agora **anistia o check** ⇒ qualquer PR que edite o revisor ficaria dispensado mesmo se ele morresse por `is-error`/`json-ilegivel` | **corrigido** — exige também a assinatura `sem-arquivo` |
| BAIXO | `git diff` falhando (base force-pushado) degrada em silêncio para "não benigno" | **não corrigido** — declarado |
| BAIXO | a prosa do caso benigno ficou duplicada em dois lugares (o predicado, não) | **não corrigido** — declarado |

## Confirmado correto (não re-suspeitar)

O export do output funciona **ponta a ponta**, com evidência de run real (`31111058204`: `benigno=true`
exportado, veredito verde) · a ordem dos ramos (revisão real ganha de anistia) · `needs.*.outputs.*`
de step pulado = string vazia, e todo ramo compara com `= "true"` (fail-closed) · fork pula os dois
jobs juntos · timeout do job dá `failure`, e o vermelho ali está **certo**.

## O padrão que se repetiu

A cura endereçou o caso benigno **medido** e deixou de fora o **não exercido nesta casa** — porque aqui
a chave sempre existe. Terceira vez no dia: **o repo onde se mede é o pior oráculo do que viaja.**

## Verificação pós-correção

Bloco `run:` extraído do YAML e rodado nos seis estados:

```
revisou de verdade      → 0     job pulado (fork)     → 0
benigno (auto-pulo)     → 0     FALHA REAL orçamento  → 1
SEM CHAVE (era eterno)  → 0     FALHA REAL crash      → 1
```

As duas falhas **reais** seguem reprovando — curar o falso-positivo sem desligar o alarme verdadeiro.
