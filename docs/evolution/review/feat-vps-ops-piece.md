---
branch: feat/vps-ops-piece
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: 3cca8c3d1224c9b6f9ba2deb66f00efc2c21f5d808672ca2f1aaa28b396b6aab
reviewed_code_sha256: 45e0e7b614a40cd6efa077d75996f2ba4860231c65c65f10884b7c9600a4e32f
findings_total: 5
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: "1ª passada: o próprio agente de execução (o brief proibiu spawnar agentes); sem refutador separado. Voz única, DECLARADA: a revisão separada fica para o revisor do CI e para o maestro, que faz o merge."
nota: "tokens 0 = não medido. Medido depois da edição: members-validate.sh rc 0 (33 membros) e o pulso real na worktree com onion-vps-ops PIECE_UNOWNED, dono «onion-vps-ops» (members.yaml), sponsor maestro, arranque `cd ~/onion-vps-ops && claude --name onion-vps-ops`."
---

# Passada adversarial: `feat/vps-ops-piece`

## O que muda

O membro `onion-vps-ops` do `members.yaml` ganha `piece: true`, `owner_session: onion-vps-ops` e `sponsor: maestro`,
na mesma forma que o #1645 deu a `onion-kg-ssot`, `onion-curation` e `onion-messaging`. O pulso da batuta passa a
cobrar sessão dona viva para a peça. Nada mais muda: o `kind:` segue `adopter`.

## Achados

| # | achado | real? | destino |
|---|---|---|---|
| 1 | O `onion_version` do registro segue `6760a7bede50`, e o update para `28bb98dd132d` está no PR #5 do onion-vps-ops, não mergeado | sim | Limite: o pin do registro se carimba por `ops/registry-pins.sh --seal` depois do merge daquele PR, nunca antes |
| 2 | O `members.yaml` é guarda: marcar a peça amplia o que a batuta cobra e o que a delegação alcança | sim | Merge do maestro, dito no corpo do PR |
| 3 | A peça precisaria de bloco `a2a:` para o core mandar sinal | não | O pulso não lê `a2a:`; `onion-kg-ssot` e `onion-messaging` são peças sem ele. O core entrega por arquivo no `inbound/` (`/meta:co-deliver`), e a campainha do PR #5 toca nisso |
| 4 | O core é público: o diff poderia expor dado de máquina | não | O diff são três chaves sem caminho, IP nem segredo; o `local_path` já estava lá |
| 5 | O pulso poderia dar a peça como dona por casar com as sessões antigas do repo | não | As duas sessões com rótulo onion-vps-ops estão `UNREACHABLE` (farol órfão), e o casamento ignora `UNREACHABLE`: o pulso mediu `PIECE_UNOWNED` |

## Mutantes

- Nenhum novo: a resolução do dono é coberta pelos casos (ag) a (am) da família `baton_pulse`, do #1645.

## Limites declarados

- Sem fila A2A para esta peça: registrar exige par de chaves, `jwks/<kid>.pem` pinado e conferência de impressão pelo
  maestro fora de banda. Fica como passo à parte, se o maestro quiser sinal assinado em vez de arquivo.
