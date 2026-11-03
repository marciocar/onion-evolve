---
branch: docs/diary-orchestration-1103
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: 533dad64335b1268cb9c160f0d0a6189958cb1c6e179ab8fb53d46b91abc8047
reviewed_code_sha256: 35bee62a9755bb67895db560881be1c4735b1e2060842ef421fc8db3de1e1bb6
findings_total: 12
findings_real: 12
tokens: 143072
duration_min: 4
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente opus separado, mandato REFUTAR; conferiu os números contra o pré-registro, o agregado e os logs do llama-server extraídos da evidência"
nota: "1 achado aceito sem cura (o cabeçalho do index.md do diário muda com o nome da worktree), declarado abaixo."
---

# Passada adversarial: `docs/diary-orchestration-1103`

## O que muda

- O diário da orquestração de sessões de 2026-11-03 (estratégias 1 a 22) e quatro migalhas em `.claude/diary/`.
- O estudo `session-orchestration-2026-11`: um grafo com 11 nós e a SYNTHESIS, com a proposta do mecanismo em
  degraus e o gatilho.
- Correção na SYNTHESIS dos spikes: o parágrafo dos tempos do llama-server passa a citar as quatro células e não
  afirma a hipótese do 1º byte. O apontamento foi do kg-ssot.

## Achados

Foram 12, nenhum alto. O parágrafo corrigido dos spikes conferiu com os logs: prompt de 650 s a 702 s e maior
tempo total de 731,7 s. Radar e contrato rc 0.

1. **Médio (curado).** O nó `E_SO_JANELA_DE_2026_11_03` citava números do fecho apontando para o recorte de 17:40.
   Agora cita as fontes do fecho (Emenda 6 do pré-registro, resíduo do PR #1461) e as estratégias 1 a 22.
2. **Médio (curado).** As sete `C_SO_*` tinham rótulo de regra geral sobre N=1. Os rótulos viraram observação da
   janela, e o meta e a SYNTHESIS declaram que, como regra geral, elas são candidatas, sujeitas ao gatilho.
3. **Médio (curado).** «Papéis emergiram sem desenho prévio» contrariava a autorização do maestro. O papel do core
   agora consta como dado pelo maestro.
4. **Médio (curado).** O vigia aparecia como existente. Agora consta «em PR, #1461, no fecho deste estudo».
5. **Médio (curado).** O gatilho era pouco testável. Agora pede ao menos uma janela com outro tipo de trabalho, os
   três papéis e 5 das 7 regras em cada janela, e declara a refutação.
6. **Médio (curado).** A migalha do stub dizia «7 e 18 minutos»; o certo é de 6 a 19.
7. **Baixo (curado).** A migalha da revisão dizia 5 emendas e 5 passadas; agora diz 6 e 8.
8. **Baixo (curado).** O diário dizia «181 mutantes» sem rastro; agora anota 181 às 17:40 e 218 no fecho.
9. **Baixo (curado).** A estratégia 11 atribuía à Emenda 1 uma redação da Emenda 6.
10. **Baixo (curado).** O nó `C_SO_REGRA_DO_MEDIDOR` não citava a Emenda 5, e o `method` divergia da fonte.
11. **Baixo (curado).** O diário dizia «celular das 13h às 23h» (o certo é até as 22h; a autorização ia até as 23h),
    e o status seguia «vivo».
12. **Baixo (aceito).** O cabeçalho do `.claude/diary/index.md` muda com o nome da worktree (`diary-index.sh`).
    É ruído, não vazamento.

Fora do escopo, também curado: a SYNTHESIS dos spikes dizia «v3, com 5 emendas»; agora diz 6.

## Mutantes

Não se aplica: a branch é só de documentação, sem código nem guarda.

## Limites declarados

- O gatilho do degrau 2 depende de duas janelas futuras; o estudo não constrói nada.
- O churn do `index.md` do diário fica como achado 12, sem cura nesta branch.
