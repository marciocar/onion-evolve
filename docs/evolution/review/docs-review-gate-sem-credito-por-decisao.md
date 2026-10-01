---
branch: docs/review-gate-sem-credito-por-decisao
reviewed_diff_sha256: c798795357d47198b16a04b2a653c0695d98ce174cf2211795d738b46ef2e84a
elenxo: nao
verdict: SEM_ACHADOS
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 3
nota: "Sem passada adversarial: a mudanca e UM no de decisao que registra uma ordem do maestro, mais a reprojecao do backlog. Nao ha codigo nem guarda nova a refutar. O proprio PR mergeia por dispensa — que e exatamente o estado que o no declara."
---

# Resíduo — a decisão de não repor crédito vira nó, não lembrança

Perguntei **como** travar o revisor externo e o maestro dissolveu a pergunta: *"só saber que neste
momento nao vamos colocar credito ele não vai funcionar no CI"*. Nenhuma mudança de workflow foi pedida
nem feita.

## Por que isto precisava de um nó

O nó que já existia (`Q_REVISOR_SEM_SALDO_DERRUBA_TODO_PR`) dizia que o gatilho era *"o maestro repor o
saldo"* — e isso lê como **evento aguardado**. Não é: é **decisão tomada**. A diferença muda o
comportamento de uma sessão futura, que senão trataria o vermelho como acidente a investigar.

`D_SEM_CREDITO_POR_ORA` fixa as quatro consequências:

1. `verdict` vermelho com `REVISOU=false` é **estado conhecido** — não diagnosticar de novo;
2. merge por **dispensa nomeada**, sem perguntar a cada PR;
3. **não propor religar** nem mexer no `onion-review.yml`;
4. o check **continua vermelho de propósito** — ausência de revisão tem de ficar visível, nunca virar
   verde silencioso (a classe `gate cego`, que o `ops/review-gate-health.sh` já mediu em 2 PRs).

## O que NÃO foi feito, e é deliberado

As três opções que eu havia enquadrado (chave declarada, tirar o gatilho, deixar vermelho) ficaram de
fora. A terceira é o que já acontece; as duas primeiras seriam **mecanismo novo para um estado
temporário** — catedral pelo portão errado. Se o estado durar, o gatilho é ele dizer.

## Gate

`lint-artifacts.sh` → 0 HARD · radar do grafo `exit 0` · backlog reprojetado.
Este PR mergeia por dispensa, pela causa que ele mesmo declara.
