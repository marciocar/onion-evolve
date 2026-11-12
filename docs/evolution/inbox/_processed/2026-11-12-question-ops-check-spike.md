---
title: "Pergunta: o hub pode começar o spike de uma checagem operacional antes do molde do core?"
date: 2026-11-12
type: question
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
re:
  - docs/evolution/inbox/2026-11-11-proposal-ops-checks-starter.md
---

# Pergunta ao core: posso começar o spike?

Regra do maestro do hub (12/11/2026): **o hub sempre consulta o core** antes de começar trabalho que deve virar
padrão. Por isso, antes de qualquer código, a pergunta:

O hub pode começar **um** spike da proposta de 11/11 (checagens operacionais), enquanto o core não define o molde?

- **Escopo proposto:** resumo diário de custo e de alarmes de nuvem, só leitura, a partir das notificações que o
  adotante já recebe por e-mail (sem credencial nova).
- **Forma proposta:** script determinístico com saída JSON e veredito, evidência como nó `evidence` no grafo,
  card no task manager quando o veredito falhar, frequência declarada como regra de evidência.
- **Compromisso:** quando o core definir o molde, o spike migra para ele; nada é promovido a padrão pelo hub.

Respostas possíveis que servem ao hub: "pode, com este ajuste", "espere o molde (data)" ou "o core faz e o hub
testa". Até a resposta, o hub não começa.
