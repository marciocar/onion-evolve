---
title: 'Resíduo — a 1ª rodada interativa real não produziu dado, e isso era indistinguível de "sem atrito"'
date: 2026-09-21
branch: fix/leg1-flush-and-empty-read
reviewed_diff_sha256: fadb22d69f61b85298cc1c22ca5b645840d1734da69ee5f4748a46be86108320
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Os dois achados vieram do USO, não de refutador: o maestro rodou as sessões, a captura veio vazia,
  e o analisador reportou "nenhum atrito" sobre zero sessões. Sem passada adversarial dedicada — o
  que havia a verificar (o binário ainda emite os sinais?) foi MEDIDO e está declarado abaixo.
---

# A medição que inverteu o diagnóstico

O maestro rodou a 1ª rodada interativa. A captura trouxe **apenas** `claude_code.session.count` —
zero traces, zero `blocked_on_user`, zero `tool_decision`.

Minha suspeita inicial era que a superfície tivesse morrido: o pré-registro é de julho, e sinal de
telemetria envelhece. **Medido no binário 2.1.278 com `strings`, a suspeita caiu:**

| item | ocorrências no binário |
|---|---:|
| `TracerProvider` · `startSpan` · `BatchSpanProcessor` | 12 · 5 · 3 |
| `blocked_on_user` · `tool_decision` | 3 · 5 |

A maquinaria está viva. E o contraste fecha a causa: **no mesmo dia, mesmo sink, 5 sessões headless
minhas trouxeram os três sinais**, nos arquivos que o analisador espera —

| arquivo | `blocked_on_user` | `tool_decision` |
|---|---:|---:|
| `logs.ndjson` | 0 | 5 |
| `traces.ndjson` | 5 | 0 |

A diferença não é o binário nem o analisador: é o **encerramento**. Processo headless *termina* e o
SDK descarrega o buffer; sessão interativa *fechada* pode morrer antes do flush periódico — que
estava em 3000/5000 ms.

# Achado 1 — a janela de flush

`5000/3000 ms → 1000/500 ms` no wrapper. **Não elimina** a perda: fechar o terminal manda `SIGKILL` e
o buffer morre de qualquer jeito. Por isso o README passou a pedir `/exit` explicitamente — e o limite
fica declarado em vez de virar surpresa na próxima captura vazia.

# Achado 2 — e este é o grave

Com **0 sessões**, o analisador imprimia *"nenhum span-pattern de atrito em ≥3 sessões"* e saía `rc=0`.

**Uma captura perdida ficava indistinguível de "o loop não tem atrito"** — e o segundo é exatamente a
conclusão que este estudo existe para testar. O dado que não chegou teria virado resultado negativo,
e um resultado negativo aqui é uma afirmação forte sobre o diferenciador NS1.

É a mesma classe que curei hoje no `ops/review-gate-health.sh` (varredura vazia devolvendo veredito),
sobrevivendo num script de julho que ninguém tinha rodado. Agora: `rc=2`, dizendo o que se esperava
encontrar, em qual arquivo, e qual a causa provável.

**Provado nas duas pontas:** captura vazia → `rc=2` com diagnóstico; captura com 5 sessões → `rc=0` e
as 5 sessões listadas. Guarda que só sabe reprovar é tão inútil quanto a que só sabe passar.

# Declarado

- O **Leg-1 segue sem dado**. `Q_PATTERN_UNPROVEN` continua aberto no grafo do estudo, e continua
  exigindo ≥4 sessões **interativas** — estas curas removem um obstáculo, não produzem a evidência.
- **Falta um dado que só o maestro tem:** como as sessões foram encerradas. Se foi fechando o
  terminal, o flush explica tudo; se foi `/exit` e ainda assim nada chegou, há segunda causa e a
  medição recomeça.
