---
branch: docs/kg-sdk-bridge-prod-evidence
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 3
tokens: 90553
duration_min: 12
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose opus, mandato de refutar, 1 passada
nota: "PR de registro de grafo; sem código nem caso de bancada, logo sem mutante"
---

# Passada adversarial: `docs/kg-sdk-bridge-prod-evidence`

## O que muda

No grafo `radar-E3-2026-10-16-r12`, o nó novo `E_SDK_0_3_301_EM_PRODUCAO_1016` (plane PROD, confirmed,
verified_at 2026-10-16) registra a prova em produção da SAC-156: o deploy de onion-bridge 0d1bc843 e core
99a821cb saiu com rc 0, e o chat-runner verify independente deu n_fail=0, com o CLI do SDK em 2.1.301,
acima do piso 2.1.64. A `Q_SUBIR_O_SDK_DO_BRIDGE_COM_PISO_DE_VERSAO` passa a `done`. A decisão do maestro
é o merge do onion-bridge#77, que ele fez, e o grafo não pede selo à parte. A
`E_BRIDGE_E_RUNNER_RODAM_O_CLI_2_1_232` fica `superseded`, reconciliada com a aresta SUPERSEDES. O nó novo
herda as sustentações: a aresta externa para `E_CVE39861_FIXED_IN_2_1_64` e o SUPPORTS para
`Q_CENSO_MEDE_O_CLI_DO_SDK_DO_BRIDGE`. O grafo vai a 14 nós, dentro do teto de 25.

## Achados

1. **MÉDIO, real, curado.** O critério do Q dizia "piso que barre regressão". Medido em `ops/update-bridge.sh`: o
   deploy só AVISA quando o verify reprova; quem barra é o install do runner. A lacuna ficou registrada no
   E_ e no Q. O handshake está coberto pelo n_fail=0 do verify, e isso foi declarado como derivado, sem a
   linha literal.
2. **MÉDIO, real, curado.** Pôr a E_BRIDGE em superseded cortava duas sustentações: a aresta externa para o
   CVE e o suporte à Q_CENSO, que segue aberta. Curado com as duas arestas a partir do E_ novo e com a
   re-medição: `cc-delta-census.sh` segue com 0 menções a SDK.
3. **BAIXO, real, curado.** O label "roda" sugeria um turno de ponta a ponta. Trocado por "serve".
4. **BAIXO, não procede.** A cerca de rede, o auth enforce e o degrau 1 constam da evidência que a sessão
   principal mediu. O refutador não tinha essa lista completa.

## Mutantes

Não se aplica: o PR não traz caso de bancada nem código. O radar (`--integrity --schema`) e o
`kg-contract-check.sh` saíram com rc 0 depois das curas.

## Limites declarados

- Não foi medido nenhum turno com a API real no CLI novo.
- O conteúdo do onion-bridge (o selftest do contrato e o package.json em 0d1bc843) foi medido pela sessão
  principal, e esta sessão não o releu.
- Decisão tomada sem o maestro: fechar o Q por evidência medida, lendo o merge do #77 como a decisão dele.
