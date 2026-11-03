---
branch: docs/a2a-rt-remeasure-1103
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 1
tokens: 96057
duration_min: 1
findings_fixed: 4
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente general-purpose (sonnet), modo REFUTAR, sem o raciocínio da sessão"
nota: "tokens e duração do subagente revisor; a escrita foi da sessão do core."
---

# Passada adversarial: `docs/a2a-rt-remeasure-1103`

## O que muda

O resultado da re-medição da ida e volta A2A de 2026-11-03 no pré-registro (Emenda 2 no §9 e o §10b), o
`--no-chrome` na linha de teste do card e do instalador, e uma evidência no grafo de sinais de campo.

## Achados

1. **Real, exagero no S7.** O veredito dizia «S7 passa com o `--no-chrome`», mas o `EndConversation` do harness
   segue fora da lista exata do S7. Corrigido para «S7 parcial».
2. Nit: o veredito listava o S1 como medido sem o ressalto da Emenda 2. Corrigido: «S1 pela leitura da Emenda 2, a
   confirmar pelo maestro».
3. Nit: o P13 dava DADO pleno, mas o rc 0 do 2º aceite não foi colado. Corrigido no §10b e no nó do grafo.
4. Nit: o id do convite vivo ia ao repo público. Trocado por «convite de teste emitido em 2026-11-02, 7 dias».

## Conferido sem achado

Sem IP, hostname, e-mail, token nem senha nas linhas novas; S8a aberto e S4 parcial; jtis e threads batem entre o
§10b, a Emenda 2 e o nó; `bash -n` do instalador rc 0; radar `--integrity --schema` rc 0.

## Mutantes

Nenhum: não há código novo, só a flag na linha de comando.

## Re-revisão depois do contrato (2026-11-03)

O contrato KG-SSOT barrou cinco códigos sem glosa no nó novo (R3, R5, P12, S4 no label e na narrativa).
A cura trocou cada um pela glosa («rodada 3», «rodada 5», «passo 12», «critério 4 (identidade depois do
reinício)»), sem mudar afirmação nem número. Conferido inline: o diff são 2 linhas do mesmo nó, e o gate
`ops/kg-gate-ci.sh` deu rc 0.
