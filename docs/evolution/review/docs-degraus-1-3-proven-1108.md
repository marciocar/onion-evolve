---
branch: docs/degraus-1-3-proven-1108
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: a3ce4373fc6135469259478371c557dcb0915403ca9e31d7bb1f2a1ba1d1ec9d
reviewed_code_sha256: c8a0e25fa409557f4528127f9c2c44cf41ffe355195d5e052db12c9f15985bf8
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: passada própria sobre o próprio diff (sem subagente); gate mecânico kg-radar --integrity --schema e kg-contract-check
nota: "tokens 0 = não medido. Lote de grafo fechado pelos testes ao vivo medidos no mesmo turno."
---

# Passada adversarial: `docs/degraus-1-3-proven-1108`

## O que muda

`Q_CS_DEGRAU1_CAMPAINHA_1109` e `Q_CS_DEGRAU3_SESSAO_COM_SESSAO_1109` passam de `open` para `done`, com
`verified_against` apontando os testes ao vivo (core↔curadoria em 07/11, core↔hub em 08/11). O checkpoint do lote
nomeia os dois flips. Com isso os seis itens do plano estão fechados.

## Achados

1. **Na sessão do core que é de fundo, a campainha não tocou por push (REAL, declarado).** A resposta do hub ficou
   pendente até a sessão consultar `pending_signals`. A causa é que a sessão de fundo do daemon não foi aberta com a
   flag de channels. O critério do degrau 1 ("toca a sessão receptora sem ninguém digitar") foi medido no hub e na
   curadoria, que eram as receptoras dos testes. O limite fica escrito na narrativa do nó.

## Mutantes

Não se aplica: o diff é dado de grafo, sem lógica. O gate é o radar (exit 0) e o contrato (rc 0).

## Limites declarados

- O checkpoint do drive segue pendente para o selo do maestro (`kg-drive-project.sh --seal`).
- Os identificadores em pt-BR da peça (o servidor `campainha`, as variáveis `CAMPAINHA_*` e `fila`) estão em rename
  para o inglês num PR do onion-messaging.
