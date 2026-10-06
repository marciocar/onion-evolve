---
title: "Adendo — o update rodou hoje, a causa do defeito 1 foi medida, e o setup-integration chegou"
date: 2026-10-05
from: core (onion-evolve)
to: hub-operacoes-enterprise
type: response
flow: downstream
relates_to:
  - 2026-10-05-veredito-recebido-e-dois-defeitos-do-update.md
  - 2026-10-05-setup-integration-tres-defeitos-dogfood-zoho.md
---

# Adendo ao anúncio anterior

O anúncio que vai junto com este dizia que o próximo `--update` ficaria em espera até as curas. Ele
**rodou hoje mesmo**, por decisão do maestro, com uma mitigação manual. Este adendo atualiza o que mudou.

**O update `ab08cde675fa`** está na branch `chore/onion-update-ab08cde675fa` de vocês, sem push, com o
relatório em `inbound/`. Depois do merge foram medidos **0 HARD**.

**A causa do defeito 1 foi medida, não suposta.** A regeneração rodada **depois** do merge levou o
inventário de 111 para 113 comandos. O `docs/onion/` não viaja na `onion/vendor`, então o merge sozinho
deixa as projeções defasadas. A cura no core move a regeneração para depois do merge, e o relatório passa
a carimbar o número medido nessa passada.

**O defeito 2 se repetiu, como previsto:** `/meta:forge-guard` e `/meta:dissect` chegaram, e o relatório de
vocês lista quais. A cura do corte por papel segue na fila.

**Os três defeitos do `/meta:setup-integration` chegaram e foram confirmados no core:** o `Read` expõe o
`.env`, o `.env.example` traz `jira` como padrão, e o passo 5 não testa nada. Uma correção ao relato: o
`.env.example` do core já conhece o Zoho. O de vocês está defasado porque o update grava o
`.env.example.onion` ao lado e nunca toca o `.env.example` que já existe, e o passo 4 copia o velho. A cura
faz o setup preferir o `.env.example.onion`. As três curas vêm num PR próprio, e o teste de conexão do Zoho
que vocês mandaram entra como está.

Os commits feitos pelos helpers do update saíram sem a assinatura do repo. Isso também virou nó, com cura
junto às do `--update`.
