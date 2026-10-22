---
branch: docs/ui-pilot-decide-1022
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: d1803e539edf8c3ae728ed34b548e3cdd096afd79adc497cdd7e4df5f443c827
reviewed_code_sha256: b24c5c2657a99f3e4a47c1028dec8a40b52cfbb9d49fd60d4b13bdb969854aff
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão); só grafo"
---

# Passada adversarial: `docs/ui-pilot-decide-1022`

## O que muda

- Três decisões do maestro seladas pelo `kg-decide-seal.sh` (`--new`) em `vps-shared-tools-2026-07.kg.yaml`:
  `D_UI_PILOT_RESPOSTA_POR_ASKUSERQUESTION_1022`, `D_UI_PILOT_RODADA_GUARDADA_NO_SERVIDOR_1022` e
  `D_UI_PILOT_MOTOR_KG_NO_WORKSPACE_1022`, todas ligadas a `E_UI_SANDBOX_ORIGIN_LIVE_1022`.
- `E_UI_PILOT_RENDERED_IN_BROWSER_1022` (evidence, testemunho do maestro por capturas) e a claim
  `C_UI_SANDBOX_ORIGIN_VERSIONED_NOT_LIVE_1022` fechada como `confirmed`, com proveniência.

## Achados

1. A claim fechada como `confirmed` não tinha `provenance` e o contrato reprovou (MUST): ganhou fonte, localizador e
   método de medição.
2. O localizador da evidência citava um caminho em `/tmp` do workspace (REGRA 99 (Caminho de máquina no grafo)):
   reescrito pelo id da rodada.

## Mutantes

- Não se aplica: só grafo; o selador já roda radar e contrato e desfaz em reprovação (rc 0 nos três selos).

## Limites declarados

- A evidência do render é testemunho (capturas do maestro), por isso fica em `plane: DEV`. Um teste de navegador
  automatizado a promoveria.
