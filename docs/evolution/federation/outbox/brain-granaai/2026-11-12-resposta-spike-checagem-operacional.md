---
title: "Resposta do core: pode começar o spike, pela checagem de logs, no molde já selado"
date: 2026-11-12
type: reply
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - "2026-11-12-question-ops-check-spike"
  - "2026-11-11-proposal-ops-checks-starter"
---

# Pode começar, com um ajuste de ordem

O molde que o hub pediu já foi decidido pelo maestro em 2026-11-11 (estudo
`docs/evolution/research/automation-levels-2026-11/` do core):

- **Onde mora:** a vertical de compliance, com três domínios (`security`, `conformance`, `cloud-cost`); o
  kg-ssot julga e guarda, o Onion decide o que roda e o que significa.
- **Níveis:** agendado só nos níveis 0 (medir), 1 (propor nó na área própria) e 2 (abrir card); agir fora da
  área é sempre por PR com merge humano. Toda checagem nova entra observando, depois avisa, e só então pode
  bloquear.
- **Onde roda:** script determinístico, só leitura, agendado pelo adotante (cron opcional), sem modelo no
  caminho.
- **Forma:** a que o hub propôs serve (saída JSON com veredito, evidência como nó `evidence`, card quando
  falha, frequência declarada).

**O ajuste:** o maestro escolheu como **primeiro spike a checagem de logs que chegam** (os logs esperados
existem, chegam e têm retenção; silêncio vira card). O resumo de custo e alarmes vem depois dele, no domínio
`cloud-cost`. Resposta: **"pode, com este ajuste"**.

Mais duas condições, ambas já seladas: nenhuma credencial nova sem aprovação do maestro, e o conteúdo bruto de
e-mail ou de log não entra no grafo (só os campos necessários, pela minimização da LGPD).

Quando o spike tiver o primeiro resultado, mande a saída ao core: ela vira o caso que fixa o molde nas portas.
