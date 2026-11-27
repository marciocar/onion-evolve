---
branch: docs/a2a-dev-channel-seals
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: 9c12288951e2f900a177921d0355dd9dfaef9992ab1b89ac7dfbc82c1f0d2721
reviewed_code_sha256: 0ec70a06c591bc5e0944b81729b1a3bd2ebafb5f180d501f18d8587f9f2bf003
findings_total: 3
findings_real: 3
findings_blocking: 3
tokens: 80289
duration_min: 1
findings_fixed: 3
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: "subagente general-purpose isolado (sonnet), só leitura, sem o contexto da conversa, com mandato de refutar"
nota: "PR só de selo: três decisões do maestro coletadas pelo /meta:decide e gravadas pelo kg-decide-seal.sh; o desenho do canal fica aberto à espera da pesquisa da curadoria."
---

# Passada adversarial: `docs/a2a-dev-channel-seals`

## O que muda

Três nós de decisão entram no grafo `a2a-backbone-product-2026-11`, gravados pelo selador:
- `D_DEV_BRAIN_ACCOUNT_THREE_STAGES_1127`: isolamento da brain do hub em três etapas;
- `D_DEV_BRAIN_FIRST_INVITE_1127`: o 1º convite;
- `D_DEV_BRAIN_MVP_SCOPE_1127`: o escopo do MVP.

Eles vêm do Delphi `dev-to-brain-channel-1127` e das respostas do maestro. O teto do meta sobe de 64 para 67, com justificativa (REGRA 58).

## Achados

O revisor isolado reprovou os três labels pela mesma razão: cada um afirmava como decisão do maestro uma inferência do selador.
- No primeiro, o usuário do host, a contenção pela catraca e «a AWS já com conta própria».
- No segundo, transformava em decisão firme o «se você achar melhor» que o maestro delegou, e acrescentava o critério de medir ida e volta.
- No terceiro, acrescentava «uma a uma» e «auditoria» sem citar a opção oferecida.

Cura: cada label agora diz só o que o maestro respondeu e o texto da opção oferecida, e a delegação aparece como delegação. Radar `--integrity --schema` rc 0, contrato rc 0, 67 nós.

## Mutantes

Não se aplica: o PR não muda código nem guarda, só nós de grafo validados pelo radar e pelo contrato.

## Limites declarados

O desenho do canal (a síntese do Delphi, com as duas objeções sobre a volta) não é selado aqui. Ele espera a pesquisa em primárias pedida pelo maestro à curadoria.
