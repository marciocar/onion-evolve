---
branch: fix/rename-alvo-pendente
date: 2026-08-09
reviewed_diff_sha256: ec20886bef6d20602f02e6f6104ac827af573b85228e1c79416398b32594be4f
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-O-ACHADO-VEIO-DA-PASSADA-DO-PR-569-E-ESTA-E-A-PARTE-QUE-SOBREVIVEU
reviewer: sem passada adversarial própria — o achado é do Elenxo do #569 (wf_da308fb9-98b)
---

# A única dívida em pt-BR que VIAJAVA para os adotantes

Medido ao construir a REGRA 60: dos **7** identificadores pt-BR residuais do core, **exatamente um**
viaja na superfície vendorizada — `alvoPendente`, em `kg-radar.sh`, presente em **2 manifestos**.

## Por que isso importa mais que o resto

O baseline de uma regra é para **dívida que fica em casa**. Dívida que **viaja** é outra coisa: o
adotante que vendoriza `kg-radar.sh` herda o identificador **sem herdar o baseline** — e nasceria com
HARD sobre dívida que não é dele.

Medido, antes e depois:

```
antes:  adotante com kg-radar vendorizado, sem baseline  →  rc=1  (1 HARD)
depois:                       mesmo cenário              →  rc=0
```

É a lição que o próprio docstring da REGRA 60 cita e que esta casa já pagou uma vez:
**«o CORE É O PIOR ORÁCULO DO QUE VIAJA»** — o `kg-trace-resolve` varreu todos os grafos e acusou
**11 falsos no 1º adotante**.

A regra que fica: **baseline tolera o que fica; o que viaja se conserta.**

## O rename mexeu em âncora de mutation test

`alvoPendente` aparece em 4 sítios do `lint-selftest.sh`, e o próprio arquivo avisa em letra grande:
*"os dois `sed` casam a ASSINATURA das funções; se ela mudar…"*. É a armadilha da **âncora morta**
que já matou três guardas nesta casa.

Renomeado nos 7 sítios de uma vez, e a bancada confirma que as âncoras seguem mordendo: **765 passam,
0 falham**, com o bloco de mutação do `kg-radar` intacto.

## O que este PR NÃO traz

**A REGRA 60 não está aqui.** Ela vive no PR #569, que passou por passada adversarial e voltou com
`FICA-COM-RESSALVA` — defeito local em três lugares, não no motor (o juiz mediu **324 scripts de
terceiros, 810 extrações, zero falsos**).

Este PR extrai a parte que **não depende** daquela discussão: o rename é correto com ou sem a regra,
porque a dívida viajava desde antes dela existir.

## Verificação

- bancada **765 passam / 0 falham / 0 pulam**, **artefato ESTÁVEL** · lint **0 HARD** + 4 SOFT
- `git grep alvoPendente` → **zero** · radar do grafo verde (18 nós, 18 arestas)
- adotante com `kg-radar.sh` vendorizado e sem baseline → **rc=0** (era 1)
