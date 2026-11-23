---
title: "Proposta — registrar o descartado na gramática de grafos do core"
date: "2026-11-17"
type: proposta
from: onion-curation
reviewed_for_public: true  # revisado pelo core em 2026-11-21: só grafos públicos do core e contagens agregadas
---

# Proposta da curadoria ao core — registrar o descartado na gramática

Saída do pedido do core (2026-11-17): virar as cinco práticas de `recording-discarded-2026-11` em proposta de
texto para a gramática de grafos (`.claude/rules/kg-grammar.md`). **A curadoria propõe; o core decide e escreve
na própria gramática.** O documento completo vive no repo da curadoria; o essencial segue aqui, **auto-contido**:

## A medição (clone --depth 1 da main pública do core, 2026-11-17, 249 grafos)

- **124 grafos** trazem «descartadas» (**482 linhas**): a opção rejeitada de uma decisão selada mora em **texto**.
- Arestas de descarte existem (**REFUTES 144, SUPERSEDES 424**, em 110 grafos), mas quase sempre apontam **nó
  superado entre revisões**, não a opção rejeitada de uma decisão; só **48** grafos têm ambos.
- **Proxy declarado:** NÃO conferi nó a nó se a aresta dos 48 aponta a opção rejeitada; «descartadas» conta só o
  padrão do `/meta:decide`.

## A prática principal (acrescentar à gramática, após "A regra que mais custa esquecer")

> Nota (2026-11-23): o texto abaixo foi superado pela redação da gramática (`.claude/rules/kg-grammar.md`); não copie daqui.

> **E o que foi descartado também é nó.** Quando uma decisão é selada com opções rejeitadas (o campo
> «descartadas:» do `/meta:decide`, ou uma alternativa de desenho considerada e recusada), cada opção rejeitada
> **substantiva** vira um nó (`claim`/`decision`, status `refuted` se derrubada ou `superseded` se trocada) com
> uma aresta **`REFUTES`** (mata) ou **`CONSTRAINS`** (limita) ligando-a à decisão. A objeção que mora só na
> palavra do rótulo não é reconstituível por consulta (some do `kg_query`, do pacote de auditoria, do leitor
> seguinte). **Não** vira nó a rejeição **procedimental** (as variantes do `/meta:decide`: «Confirmo com ajuste»,
> «Não selar», «Ainda não») — só a alternativa de **desenho com conteúdo próprio**.

## Antes/depois reais (grafos do core; nó não inventado)

- `docs/onion/graph/a2a-outbound-2026-11.kg.yaml#D_QUEUE_HARVEST_OPENCLAW_NOW_1110` — «descartadas: «Junto da Fase
  2»», sem nó (só `TRACES_TO`). Depois: um nó `refuted` + `REFUTES`. +1 nó.
- `docs/onion/graph/company-brain-multiaudiencia-2026-10.kg.yaml#Q_MA_WRITE_SURFACE` — quatro alternativas A–D só
  em prosa; só a escolhida (E) é nó. Depois: nós `refuted` para A e C/D + `REFUTES`; B (considerada) `CONSTRAINS`.

## Checker e custo

- **Lint SOFT candidato:** nó `decision`/`question` cuja narrativa casa `descartad|rejeitad` **e** sem aresta
  `REFUTES`/`CONSTRAINS` chegando → aviso "rejeitadas só em texto". **Só humano:** substantivo × procedimental, e o
  tipo de aresta.
- **Custo:** +1 nó por opção substantiva. A maioria das 482 é **procedimental** (não vira nó); só as de desenho
  multi-opção. **Só adiante**, nunca retroativo em massa; TETO ajustado no mesmo PR.

## As outras quatro práticas

2 (substituição datada, sem apagar), 4 (rejeição é status, id não reusado) **já estão** na gramática — reforço de
texto. 3 (opção com porquê-não) é a prática 1 aplicada ao `/meta:decide`. 5 (toda consequência) é guia, não gramática.

## Não-verificados

O 48 é proxy (não nó a nó); «descartadas» é só o padrão do `/meta:decide`; li o core por clone da main (sem fixar
sha); o corte substantivo × procedimental das 482 é inferido de amostra; o ponto de inserção na gramática o core
confere no arquivo vivo.
