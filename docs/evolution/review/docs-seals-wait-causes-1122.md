---
branch: docs/seals-wait-causes-1122
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: ee0d47d30d6a8d89c585469fbe1f4335529bea77d7537cc0a35f2f29fc466f1f
reviewed_code_sha256: 5dbe03d2c0d72edc59fbcbf00e22747aeda16c8f4a14f13a2d1b86c7f41bdaad
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: self
nota: "passada da própria sessão sobre 4 linhas de grafo e 3 bullets de doc; tokens não medidos"
---

# Passada adversarial: `docs/seals-wait-causes-1122`

## O que muda

- `x_wait` em 4 nós `open` que o pulso da batuta contava como fila pronta: a finalidade do tratamento no contrato do
  grafo (parada pela palavra do maestro de 17/11, «LGPD rasa por ora») e três perguntas da kg-ssot parqueadas com
  gatilho pela decisão de aresta entre repos e pelos gatilhos de campo do produto.
- Três bullets no preâmbulo do agente de execução, da proposta da curadoria (SAC-422 e SAC-434): o sha do resíduo é
  carimbado, git roda sozinho com o rc lido à parte, e o lint tem teto folgado. O sinal vai para `_processed/`.

## Achados

1. **A 1ª redação das causas citava um gatilho inventado** («a 1ª medida de campo do contrato de aresta»), e não o
   que o nó escreve. Real, corrigido: cada `x_wait` agora repete o gatilho da narrativa do próprio nó (objeção
   perdida entre repos ou adotante externo; régua de cada gatilho de campo).
2. **O `x_wait` só cala o pulso depois que o #1725 entrar.** O `baton-pulse.sh` da `main` ainda não lê o campo. Real,
   não bloqueia: o campo vale como registro da causa desde já, e o efeito no pulso chega com o merge do #1725.
3. **Suspeita: a decisão citada não existe no core.** Medido: `D_CROSS_REPO_CONTRACT_1104` mora no repo da kg-ssot,
   e o texto já diz isso. Não é defeito.

## Mutantes

Não se aplica: o diff não muda guarda nem script.

## Limites declarados

- Achado 2: o pulso só para de contar os 4 nós depois que o #1725 entrar.
- Revisão da própria sessão, sem revisor isolado.
