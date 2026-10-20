---
branch: fix/poda-placar-sem-referente
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 2fa5dd4d55d3cc5d56136569f8169c6a753dd431986a840c56957f677739e6ac
reviewed_code_sha256: d1044c5d75122ec5a1a70bc7f675a46fcb5a12d2a74046f0d439d5185e153d89
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, a partir do veredito de um agente leitor (wt-supersession) conferido no vivo
nota: ""
---

# Passada adversarial: `fix/poda-placar-sem-referente`

## O que muda

O label de `C_OPCAO_C_MEDIR_PRIMEIRO_COM_INSTRUCTIONSLOADED` troca o "9 a 1" pelo placar real (empate em 1/9), e o
label anterior fica verbatim na narrative. Entra o nó `E_PLACAR_9A1_SEM_REFERENTE_1020` com CONSTRAINS para a
opção C. O TETO vai de 20 para 21, pelo gatilho (b), a emenda de Elenxo.

## Achados

1. **REAL (curado):** o número não tinha referente. Conferido no nó do placar da main: A 1/9, B 1/9, C 0/9.
2. **Refutado:** "o selo D_PODA caiu junto?" Não caiu. O grep pelo número no nó do selo volta vazio, e o
   argumento central da opção C (medir antes de podar) não dependia dele.

## Por que não rebasear a worktree de 2026-09-22

O grafo mudou muito desde então: o selo de 09-25 e as ondas de provenance O1 a O7. O patch antigo não aplica limpo, e
a parte dele sobre a "cláusula de dependência do D_PODA" deixou de valer. A correção foi refeita do zero, só com
o que continua verdadeiro.

## Mutantes

Nenhum: não há código. O radar `--integrity --schema` saiu 0, o teto ficou em 21/21 e o `ops/kg-gate-ci.sh` em rc 0.
