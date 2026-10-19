---
branch: docs/seal-stt-loopback-diarization
pr: pendente
date: 2026-10-19
reviewed_diff_sha256: 864d407f609e7d5ae1299fc667ce8e389e68a11ca8c1cacee67ec73f02dce11a
reviewed_code_sha256: c71528d9dab7f1292e68e66e2d1d926cf0be304809fb02c9451504ccb3de8dc4
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão sobre os dois nós e a linha do TETO; sem subagentes
nota: ""
---

# Passada adversarial: `docs/seal-stt-loopback-diarization`

## O que muda

Dois selos do `/meta:decide` de 2026-10-19 no grafo `meeting-capture-2026-10`, pelo selador:
`D_MC_STT_SOBE_EM_LOOPBACK_1019` (o serviço sobe em loopback primeiro, e o Caddy espera o cliente) e
`D_MC_DIARIZACAO_NO_SERVICO_PROXIMO_1019` (a diarização no serviço é o próximo passo). O TETO vai de 11 para 13.

## Achados

1. **REAL, curado antes do commit:** a 1ª escrita do selo do loopback listou «Instalar só loopback» entre as
   DESCARTADAS. O maestro respondeu livre, delegando a escolha («as opções que façam a progressão gradual e
   segura»), e a sessão a lê como esse mesmo degrau. Descartá-lo afirmava o contrário do que vai ser executado.
   Desfeito com `git checkout` e re-selado com `--other`, a interpretação escrita na escolhida e só as duas
   alternativas de fato descartadas.
2. **REAL, curado:** o gatilho de crescimento do TETO não previa este caso (previa o ao vivo re-medido ou o grafo
   de consolidação). Em vez de forçar o encaixe, o `meta:` declara o gatilho como não previsto e diz o porquê.

## Mutantes

Nenhum: não há código. O gate é o próprio selador (radar `--integrity --schema` e contrato em rc 0, com
desfazer automático).

## Limites declarados

- A resposta livre do loopback é INTERPRETAÇÃO da sessão. Fica escrita como tal no nó, para o maestro
  corrigir se não for isso.
- A subida do SDK do bridge e a arrumação (worktrees, diário, MEMORY.md) não viram nó: a primeira deriva da
  ordem permanente de base atual, e a segunda é manutenção. A pergunta nova do maestro (backlog × Linear ×
  plan.md × KG-SSOT) vira grafo próprio quando a proposta for medida.
