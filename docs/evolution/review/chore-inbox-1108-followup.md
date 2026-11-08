---
branch: chore/inbox-1108-followup
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: cfdb7b54675c61578fcad6d16c5904c1ec90eb5bca5f4c6191ff02f79c166890
reviewed_code_sha256: ce3dfa4452ced7857c64b263b5f4d12734d1b6a284c5af88cf70ff2a42ac8600
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes)"
nota: "tokens = 0: não medido. Dois arquivos de federação; o teste que vale é a REGRA 113 e a releitura como publicado."
---

# Passada adversarial: `chore/inbox-1108-followup`

## O que muda

- `2026-11-07-reply-hub-chat-persona-promotion.md` (curadoria), já repassado ao hub, vai a `_processed/` com
  `reviewed_for_public: true`, depois de relido como publicado: só ids de nó e o fluxo proposto.
- O anúncio `2026-11-08-resposta-branch-das-lacunas.md` ao hub (entregue pelo carteiro) responde o pedido 1 do sinal
  das lacunas da campainha: as curas saem num PR do onion-messaging por cima do PR #7, prazo 11/11.

## Achados

1. PERDIDO NO MERGE: estes dois arquivos eram um commit de follow-up do #1544, mas o #1544 foi mergeado no head
   anterior e a worktree foi removida no meio do push. Voltam aqui, em PR próprio, a partir do commit local.

## O que fica de fora, por decisão

- `2026-11-08-signal-campainha-gaps.md` segue aberto no inbox até as curas saírem.

## Verificação

- REGRA 113 (Sinal relayado a destino público só se commita revisado): o sinal entra com `true`.

## Mutantes

- Nenhum: não há código.
