---
branch: docs/drive-comms-stable-1107
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: f61b894f880735274e4a8f7be6a7d60eb7951917d012f67d88d09053f2a12b0d
reviewed_code_sha256: 59cbf51f0210eabc7d69425ff29d876a3b595a589992662576d433fa8ab58bce
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: passada própria sobre o próprio diff (sem subagente); gate mecânico kg-radar --integrity --schema e kg-contract-check
nota: "tokens 0 = não medido nesta sessão. Lote de grafo, sem código: a passada é a releitura do diff contra o vivo medido no mesmo turno."
---

# Passada adversarial: `docs/drive-comms-stable-1107`

## O que muda

O lote do `/meta:drive` de 07/11 no plano `comms-stable-2026-11`:
- fecha `Q_CS_PESQUISA_PADROES_MENSAGERIA_1106` (pilha selada no grafo da pesquisa) e
  `Q_CS_ORIENTACAO_COMPLIANCE_1106` (resposta entregue e citada pelo hub);
- apenda evidência em `Q_CS_DEGRAU1_CAMPAINHA_1109` (fila nos dois sentidos, ao vivo),
  `Q_CS_APP_SLACK_E_CHANNELS_1106` (as quatro escolhas do maestro, cujo fecho segue dele) e
  `Q_CS_DEGRAU2_SLACK_RASCUNHO_1109` (mudança de host da persona);
- escreve o checkpoint do lote como pendente no `meta:`.

## Achados

1. **A primeira escrita partiu o `external_edges:` ao meio (REAL, curado).** O script inseria os nós
   antes da primeira ocorrência de `edges:\n`, e essa ocorrência era o fim de `external_edges:`. O radar
   acusou arestas para nós inexistentes e o contrato deu YAML ilegível. A cura usa a âncora de início de
   linha (`^edges:`), e o arquivo foi refeito a partir da `origin/main`.
2. **O grafo declara teto de 16 nós e a primeira versão do lote o furava (REAL, curado).** Eu tinha
   criado 3 nós `E_` novos. A cura levou a evidência para o `verified_against` e a `narrative` dos nós
   que ela sustenta, sem nó novo.
3. **O grafo já passa do teto na `origin/main` (REAL, não curado aqui):** são 17 nós contra o teto de
   16. Vai em Limites.

## Mutantes

Não se aplica: o diff é dado de grafo, sem lógica. O gate é o radar (`--integrity --schema` exit 0) e o
contrato (rc 0), os dois medidos depois da cura.

## Limites declarados

- Teto de 16 nós já furado na base (17). Podar ou subir o teto é decisão do próximo lote, não deste.
- A mudança de host foi relatada pela sessão que a fez (1c3b4688) e não foi re-medida por esta.
- O fecho dos dois `Q_` é flip `open→done` com critério de pronto medido. O checkpoint nomeia os dois, e
  o merge é o selo.

- Acréscimo no mesmo PR: o maestro confirmou os passos 1 a 6 do card do Slack, e `Q_CS_APP_SLACK_E_CHANNELS_1106` fecha com a confirmação dele.
