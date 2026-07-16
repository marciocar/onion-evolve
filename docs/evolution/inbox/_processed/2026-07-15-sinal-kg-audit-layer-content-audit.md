---
type: co-evolution-signal
direction: upstream   # sinal → core
from: observação de campo do Core sobre o grafo do adotante gustavo-pulga/Tornak (docs/tornak/graph/tornak.kg.yaml, Lote 10)
to: Onion core / Mestre
date: 2026-07-15
subject: A camada `audit` do KG SDAAL generaliza para auditar CONTEÚDO/documentação — não só código/sistema
status: proposta-para-avaliação
maturity: evidência de campo espontânea (adotante), verificada pelo radar soberano do core no re-dogfood KG SDAAL 2026-07-15
---

# Sinal ao Mestre — a camada `audit` do KG SDAAL vale para além de código

> Canal upstream (sinal→core). **Proveniência honesta:** este sinal **não** foi escrito por uma
> sessão do adotante — foi **observado pelo Core** durante o re-dogfood geral do KG SDAAL
> (2026-07-15), rodando o `kg-radar.sh` do core sobre o grafo **real e commitado** do
> gustavo-pulga/Tornak. O adotante não pediu nada; o padrão **apareceu no uso** e o core o
> reconheceu. Registro para triagem via `/meta:co-evolve`.

## O que apareceu no campo

A KB canônica [`knowledge-graph-sdaal.md`](../../../knowledge-base/concepts/knowledge-graph-sdaal.md)
apresenta a camada `audit` (grafo epistêmico: `claim/evidence/decision/question`) como método
para **investigações/auditorias de código e sistema** (nasceu da auditoria WRR de produção,
sinal [`2026-07-02-sinal-sdaal-knowledge-graph`](2026-07-02-sinal-sdaal-knowledge-graph.md)).

No campo, o gustavo usou **exatamente a mesma gramática** para **auditar dois decks de
treinamento** (documentação/conteúdo, não código) — e ela segurou **sem nenhuma adaptação**.

## Evidência (Lote 10 do `tornak.kg.yaml`, commit `origin/onion/adopt@4113a55`)

- **Gramática canônica aplicada a conteúdo:** `E_SLIDE_AUDIT` (evidência = varredura dos 2 decks)
  `→SUPPORTS→` 7 `claims` de achados (contradições/gaps/terminologia) `→TRACES_TO→` os artefatos-deck;
  `D_FIX_SCOPE` (decisão) `→DEPENDS_ON→` os claims; **4 `V2 →SUPERSEDES→ V1`** (deck iterado, V1 vira `superseded`).
- **O grafo registrou o próprio erro em vez de sobrescrevê-lo** (doutrina `declarado ≠ verificado`):
  `C_TARDE_NUM_15` (confidence **0.4**) foi **`REFUTED`** por `C_TARDE_NUM_21` (confidence **1.0**),
  backed por `E_MAESTRO_CORRECAO_NUM` (correção humana). O erro da IA ficou no grafo, refutado e
  rastreável — não apagado.
- **Verificação do core:** `kg-radar.sh` (radar+reconcile+integrity+domain+triples) processou o grafo
  (**107 nós / 172 arestas**) **limpo** — 0 contradição estrutural, reconciliou os `SUPERSEDES`/`REFUTES`,
  único warning = `ST_CONTRATO` estado-absorvente (terminal legítimo, na camada `domain`, fora do Lote 10).

## Por que pertence ao core

1. **O método é mais geral do que a KB declara.** A camada `audit` do KG SDAAL não é sobre código —
   é sobre **qualquer investigação com achados que se contradizem e se corrigem**. Auditar decks,
   currículo, contratos, specs — a mesma máquina.
2. **É dogfood de campo do mecanismo de auto-correção.** O caso da numeração 15→21 é a prova viva de
   que o `REFUTES` + confidence-gradient + evidência-humana funcionam para **reconciliar verdade×verdade**
   fora do laboratório — exatamente a dor original do sinal de 2026-07-02.
3. **Custo de adoção baixo:** a KB já existe; falta **documentar o caso content-audit** como aplicação
   de 1ª classe (um exemplo + uma frase no escopo da camada `audit`).

## Pedido

Avaliar **documentar na KB [`knowledge-graph-sdaal.md`](../../../knowledge-base/concepts/knowledge-graph-sdaal.md)
que a camada `audit` se aplica a auditoria de CONTEÚDO/documentação** (não só código/sistema), citando o
Lote 10 do Tornak como instância de campo. Se aprovado, considerar um exemplo mínimo content-audit ao lado
do `example-domain.kg.yaml`.

> **Migalha ligada:** diário `[[2026-07-15-kg-audit-layer-generalizes-to-content]]` (migalha `conditional`
> cujo `valid_when` é justamente "a KB ainda NÃO documenta o uso content-audit" — quando este sinal for
> executado, a migalha se aposenta). Irmão: `[[2026-07-15-kg-sdaal-crosses-federation]]`.

*Rode `/meta:co-evolve` para gerenciar este sinal.*
