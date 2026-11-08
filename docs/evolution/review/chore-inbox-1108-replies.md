---
branch: chore/inbox-1108-replies
pr: 1544
date: 2026-11-08
reviewed_diff_sha256: cfad08c1e5448285be1c2daed585af4206ca796f22f7f491e853dfd08ae99a34
reviewed_code_sha256: 19f8e716843c423596623d7b32eadce6c24b3b62ad4b9c087440189dc258586d
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 15
findings_fixed: 4
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes)"
nota: "tokens = 0: não medido. Passada de uma lente só sobre respostas de federação, nós de grafo e movimentação de inbox; os testes que valem são o radar, o contrato, a REGRA 113 e a varredura de vazamento."
---

# Passada adversarial: `chore/inbox-1108-replies`

## O que muda

- Commita as 3 respostas ao hub que estavam sem commit no outbox, o repasse da resposta da curadoria sobre a
  promoção do rascunho por PR e o anúncio à curadoria com as respostas da onda 2 (os dois entregues pelo carteiro).
- Grafo novo `doorbell-hardening-2026-11` com as 4 lacunas da campainha (owner core, x_due 11/11), ligado ao
  `comms-stable-2026-11` por `external_edges`.
- `Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11` ganha owner e x_due (13/11); `Q_ADOPTER_VETOES_RESIDUE_1108` entra no
  grafo dos vetos do adotante (teto 16 → 17, com a justificativa no comentário).
- Espelhos no Linear SAC-350 a SAC-354, carimbados nos nós como `x_linear_issue`.
- Sinais atendidos vão para `_processed/`.

## Achados

1. DUPLICATA EVITADA: a `Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11` já existia no grafo da pesquisa de 02/11. Criar
   outro nó com o mesmo id em outro grafo faria dois donos para a mesma pergunta; o nó existente ganhou owner e prazo.
2. CAMINHO DE MÁQUINA (REGRA 99): o `verified_against` da evidência citava o arquivo de estado da campainha pela
   home. O contrato reprovou (rc 1); reescrito como ⟨descrição⟩, rc 0.
3. NOME COMERCIAL: o sinal do hub de 07/11 nomeava o workspace pelo nome comercial do cliente. Trocado por
   «workspace do hub» antes do commit; o id de membro registrado segue.
4. REGRA 113: os 3 sinais da curadoria mantidos na íntegra foram relidos e marcados `true`; os dois do sandbox e o
   dos vetos entram em forma-resumo com nome novo (a lista de classes do resíduo não aparece), e os originais saíram
   sem commit.

## O que fica de fora, por decisão

- `2026-11-07-reply-hub-chat-persona-promotion.md` (curadoria, `reviewed_for_public: false`): repassado ao hub, mas
  não estava na lista de movimentação do brief; segue sem commit no inbox.
- `2026-11-08-signal-campainha-gaps.md` entra no 1º nível do inbox (aberto): o grafo novo o cita por `trace`, e o
  pedido 1 do hub (em que branch a correção está) ainda não tem resposta.

## Verificação

- `kg-radar.sh` rc 0 e `kg-contract-check.sh` rc 0 nos três grafos tocados.
- `door-leak-scan.sh --families sub,word,home`: só o id do membro registrado e ids de repos da família, o mesmo
  padrão dos arquivos já mergeados nas mesmas pastas.

## Mutantes

- Nenhum: não há código. O contrato reprovando o caminho de máquina (achado 2) foi o modo de falha exercitado.
