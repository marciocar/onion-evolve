---
title: 'Resíduo — fechar um nó com medição, e a lição que o nó carrega'
date: 2026-09-15
branch: docs/fecha-no-revisor-curado
reviewed_diff_sha256: 4b97b6606c174932057e36607784b64d8e7a0533fa7374ef78db42c3e2571d87
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR de UM arquivo de grafo mais a projeção do backlog. A passada adversarial é dispensada pelo corte
  do passo 6 (docs-only, sem linha executável) — `elenxo: nao` é o uso correto do campo. O escrutínio
  que este PR exige é de OUTRA natureza: ele afirma que uma cura funcionou, e essa afirmação foi
  verificada por execução no caminho real, não por leitura de código.
---

# Fechar um nó é uma afirmação — e ela foi medida

## O que este PR faz

Flipa `A_CURAR_O_REVISOR_DO_CI_COM_MECANISMO` de `open` para `done`, com `verified_at` e
`verified_against` nomeando a execução que o prova.

**Flip de status de verdade é selo do maestro** (tabela de selagem do `/meta:drive`), e ele mandou
fechar. O que eu trago é a medição, não a decisão.

## A afirmação, e como ela foi verificada

| Afirma | Verificado por |
|---|---|
| A cura do revisor funcionou | execução do `onion-review` no PR #828, **caminho real** |
| `permission_denials_count: 0` | `gh run view` no log do run — era **9**, e **14** em 2026-08-07 |
| `is_error: false` | idem — era **true** |
| `num_turns: 8` completos | idem — antes **18** morrendo, ou **1** sem partir |
| `total_cost_usd: 0.37` | idem — trabalho real, não morte em t=0 |
| Não foi auto-pulo nem caso benigno | o PR #828 **não edita** `onion-review.yml` |

Essa última linha é a que sustenta todas as outras. A cura saiu verde no PR que a escreveu **sem ter
sido exercida** — porque PR que edita o workflow faz a action se auto-pular. Por isso o nó nasceu
`open` com o gatilho escrito, e só fecha agora.

## O que o nó guarda, e é mais que o conserto

**O alvo dormia há cinco semanas.** A frase `No buffered inline comments` estava registrada no
próprio workflow desde a 1ª ocorrência, ao lado do `permission_denials_count: 14`. Ela nomeia o
subsistema — comentário **inline de review** — e ninguém a leu como o alvo que era. Lia-se o número; a
frase ficava.

**A defesa existente era prosa.** O prompt dizia *"NÃO tente postar comentário nem aprovar o PR"*, e
ele ignorou nas duas ocorrências. Conselho não é mecanismo.

**E a parte que é sobre mim:** cinco ciclos de CI do PR #827 saíram com o `onion-review-verdict`
vermelho, e eu li como *"o de sempre"*. Alarme que se aprende a ignorar já morreu antes de quebrar — e
o próprio workflow adverte contra isso em letra, algumas linhas acima de onde o defeito morava.

## Por que NÃO houve passada adversarial

Corte do passo 6 do `/engineer:pr`: obrigatória quando o PR toca `.claude/`; dispensada em
docs-only pequeno. Este PR toca **um `.kg.yaml` e uma projeção**. Aplicar o corte é o ponto — regra
que vale sempre não é corte, é cerimônia.

## Gate

```
radar --integrity --schema : exit 0
realign --check            : ALINHADO
lint (LC_ALL=C, completo)  : 0 HARD
o nó SAI do backlog        : 0 ocorrências — prova de fechamento, não declaração
commit                     : SEM --no-verify
selftest                   : não dispara (docs-only, por desenho; rede é o cron 04:17 UTC)
```
