# Spec do motor de reconciliação — derivação Onion (camada 2)

> **Camada 2 — NOSSA derivação.** Cita a camada 1 ([`../theories/`](../theories/)), **nunca a reescreve**.
> PLAUSÍVEL/open. Fonte: [`../../research/SYNTHESIS-P2.md`](../../research/SYNTHESIS-P2.md). Discussão: [`../../02-reconciliacao.md`](../../02-reconciliacao.md).
> Executável: [`../reconciliation-engine.kg.yaml`](../reconciliation-engine.kg.yaml).

## O que o motor faz, peça a peça (IGUAL transfere / DIFERENTE desenha)

| Peça | IGUAL / DIFERENTE | Sustentação (camada 1) |
|---|---|---|
| **Substrato belief-base graduado + bipolar** | IGUAL (compor, não inventar) | AGM/Hansson; Dung; bipolar (Cayrol 2005); QBAF — [formal-reconciliation](../theories/formal-reconciliation.md) |
| **Operador Aufhebung** (formal: supersessão append-mostly · narrativo: redenção) | IGUAL o operador | Hansson kernel; McAdams — [formal-reconciliation](../theories/formal-reconciliation.md), [self-in-time](../theories/self-in-time.md) |
| **Compromisso ≠ fato** (objeto 1ª classe: bindingness + bright-line + sunset) | **DIFERENTE — não-construído** | Parfit, Ainslie, Thaler-Shefrin, Ricoeur (ipse) — [self-in-time](../theories/self-in-time.md) |
| **3ª camada `ipse`** (fio-de-promessa acima de domain/audit) | **DIFERENTE (conf 0.65)** | Ricoeur idem/ipse — [self-in-time](../theories/self-in-time.md) |
| **Discriminador — órgão 1: screen-hard** | IGUAL | unsat-core/MaxSAT; sensibilidade-à-info (SEP) — [discriminator-motor-bug](../theories/discriminator-motor-bug.md) |
| **Discriminador — órgão 2: marca-humana** | **DIFERENTE (nenhum produto tem)** | sacro autorado (Tetlock, Chang) — [discriminator-motor-bug](../theories/discriminator-motor-bug.md) |
| **Discriminador — órgão 3: resíduo pós-hoc** | **DIFERENTE (aprendizado idiográfico)** | resíduo de Williams; Higgins (guarda) — [discriminator-motor-bug](../theories/discriminator-motor-bug.md) |
| **Ordem de entrincheiramento** (quem vence) | IGUAL o conceito / DIFERENTE a ordem (idiográfica) | Gärdenfors-Makinson — [formal-reconciliation](../theories/formal-reconciliation.md) |
| **Anti-auto-engano: DEV datado como check externo** | **DIFERENTE — load-bearing, menos fonteada** | Ulisses/bright-line (Ainslie) + sunset (Parfit/Wrosch) — [self-in-time](../theories/self-in-time.md) |

## Os dois eixos de entrada

1. **metas × ações** (P1): DEV declarado × PROD vivido.
2. **eu-passado × eu-presente** (P2): compromisso × comportamento/preferência atual — **divergência estrutural**
   (desconto hiperbólico), não falha moral.

## A máquina do compromisso (no KG)

`DECLARADO` —(defecção)→ `MANTIDO` (default: o mastro de Ulisses segura) · `DECLARADO`/`MANTIDO` —(sunset
ratificado / marco N=1)→ `LIBERADO` (a válvula de escape auditável). Um **fato** contraditório nunca invalida o
compromisso — só o `ramo-bug` (fato×fato) usa `REFUTES`/supersessão. Ver o contraste no
[grafo](../reconciliation-engine.kg.yaml): `RECONCILIAÇÃO` mostra o REFUTES só no ramo-bug.

## O que fica ABERTO (a agenda)

Qual semântica pinar (grounded × QBAF) · proxy computável de conexão psicológica · `ipse` como schema · onde ser
normativo vs descritivo · cadência por marco N=1 · fronteira inferência-automática × marca-humana · aprender o
conjunto-sacro sem virar viés de confirmação. Detalhe em [`../../02-reconciliacao.md`](../../02-reconciliacao.md) §6.
