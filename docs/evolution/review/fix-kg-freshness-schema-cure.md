---
title: "Revisão — Elenxo sobre a cura: REPROVOU as três, e a cura saiu maior e menor ao mesmo tempo"
date: 2026-08-29
branch: fix/kg-freshness-schema-cure
reviewer: "Elenxo completo (run wf_26433f93-c5d): 3 lentes cegas sonnet/medium + steelman opus/high + refutador opus/high com default REPROVADO; as objeções A2/A3/A4 foram re-medidas pelo autor (tabela-verdade determinística + sandbox) antes de qualquer edição"
reviewed_diff_sha256: e31f30dc3f176d69d2857c597abea498e7e8b7d38e0de386ebf830c93cab5535
findings_total: 8
findings_real: 8
verdict: REPROVADO_E_RETOMADO
tokens: 451837
duration_min: 12
---

# Resíduo — REGRA 56

O maestro pediu *"uma passada com Elenxo ou outra proposta de alinhamento e superação"*. O Elenxo
rodou as 5 etapas sobre as 3 sub-decisões abertas (A=schema · B=juiz fixo · C=censo→amostra) e
**REPROVOU as três** — o fio, nas palavras do refutador: *"a evidência que autoriza a mudança foi
colhida pelo lado que ACEITA, nunca pelo lado que REJEITA"*.

## O que cada etapa entregou

**Lentes cegas (3):** convergiram em A (reestruturar), divergiram em B (a lente de mecanismo
queria juiz fixo; a de economia queria dimensionar; a epistemológica alertou para
institucionalizar LLM-judge).

**Steelman:** achou o que nenhuma lente viu — **B e C são a mesma decisão**. Sem o juiz fixo, o
censo custa 13,0M e **cabe**; com ele, 26,5M e não cabe. "O censo não cabe" era consequência
orçamentária de uma escolha de tiering sobre n=4, nunca discutida como escolha.

**Refutador (A=B=C REPROVADO):** 4 objeções em A, e re-medi cada uma antes de aceitar:

| objeção | re-medição | veredito |
|---|---|---|
| A1: só se mediu ACEITAÇÃO, nunca barragem | tabela-verdade determinística, 15 casos | **PROCEDE** — agora medida |
| A2: `if/then/else` ≠ `allOf` (contra-exemplo) | **0 divergências** na cadeia raiz=coverage; **2** na raiz=verdict — o contra-exemplo era da outra cadeia | **PARCIAL** — salvou o schema do aninhamento errado |
| A3: a cura não existe no repo | verdade — só existia em sessão | **PROCEDE** — curado neste PR |
| A4: "a guarda não precisa mudar" é falso (fixture BOM canoniza `allOf`) | lido na fonte, linhas 145-152 | **PROCEDE** — curado neste PR |

## O que este PR executa (o núcleo que TODAS as partes aprovaram)

1. **Schema curado no repo**: cadeia `if/then/else` com **raiz na cobertura** — a raiz é MEDIDA,
   não estilo (a alternativa natural diverge em 2 casos, um deles o modo-de-falha dominante).
   O histórico e o aviso de não-reordenar estão gravados como comentário no próprio schema.
2. **Catraca `FORMATO-RECUSADO-PELA-API`** na guarda: recusa `allOf/anyOf/oneOf` de topo — a
   forma que viveu 17 dias com OK verde. Provada nos dois lados: schema real `rc=0`, mutante
   `rc=1` com a violação nomeada.
3. **Fixture BOM** da bancada deixa de canonizar o formato morto; o `allOf` virou o **7º caso de
   acusação** (`--selftest` 7/7).

## O que NÃO foi executado, por reprovação do Elenxo (nós preservados)

- **Juiz fixo (B): NÃO.** `C_JUIZ_SEM_PADRAO_OURO` — 4/4 reprovações com mandato de refutar e
  zero contagem independente não distinguem "certo" de "sempre reprova". Promover seria
  CONFIRMED-por-plausibilidade sobre o próprio verificador. Caminho: `D_JUIZ_CALIBRACAO_GATED`
  (padrão-ouro humano barato na próxima passada real; gatilho nomeado).
- **Fechar uma duplicata do censo (C): NÃO AGORA.** `C_JUIZ_E_CENSO_SAO_UMA_DECISAO` — fechar C
  antes de decidir B seria selar a consequência antes da causa.

## Reconciliação (Aufhebung)

`D_CURA_E_RESTRUTURAR_O_SCHEMA` → **superseded** (dizia "nada mais precisa mudar" — falso, A4).
`E_CURA_MEDIDA_NOS_DOIS_LADOS` → **superseded** pela tabela-verdade (media aceitação, não barragem).
As posições ficam no grafo — são elas que explicam o desenho novo.

## Gate mecânico

- `kg-reverify-schema-check.sh` → **rc=0** no real · **--selftest 7/7** · mutante **acusado**
- `kg-radar.sh --integrity --schema` → **exit 0** (28 nós, 30 arestas)
- `docs/backlog.md` sem drift (regenerado, byte-igual)
