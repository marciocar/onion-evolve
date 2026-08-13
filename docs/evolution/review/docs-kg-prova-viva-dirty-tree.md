---
branch: docs/kg-prova-viva-dirty-tree
pr: pendente
date: 2026-08-13
reviewed_diff_sha256: 7488fb00903eb2477e825001ee9af8bbb78dde98bdbdc442d36e533bac31da39
findings_total: 7
findings_real: 4
findings_fixed: 4
tokens: 68345
duration_min: 5
verdict: CORRIGIDO
reviewer: code-reviewer (opus, adversarial — 8º Elenxo da linha de mecanismos)
---

# Passada adversarial — `docs/kg-prova-viva-dirty-tree`

## O 8º Elenxo: o fechamento se sustentava no mecanismo e caía na semântica

O diff fechava `Q_PARECER` com "prova viva: guarda muda = a árvore que o revisor viu era a
do PR". Três achados reais derrubaram a redação (não o fechamento):

| # | sev | achado | cura |
|---|---|---|---|
| 1 | ALTA | a inferência era mais forte que o sensor: mudez prova estado FINAL limpo, não "nunca sujou" — e o teto sujar-e-limpar foi EXERCIDO neste mesmo ciclo (revisor local do #593, stash+pop byte-idêntico) | inferência rebaixada no label; frase contraditória removida |
| 2 | MÉDIA | proveniência errada: o parecer visível é do run do head ANTERIOR (upsert sobrescreveu 6s depois) — o defeito que o próprio nó registra mordeu a evidência do nó | label cita os DOIS runs, ambos ##[warning]=0 |
| 3 | MÉDIA (parcial) | no caminho benigno a guarda não emite NADA — log sem guarda é indistinguível de guarda muda; e o critério de execução que eu propus ao revisor era falso (REVISOU sai antes do bloco) | execução provada por outro rastro (post-review-comment pós-bloco, env do step, sensor fail-closed); a mudez-que-não-se-identifica virou nó open próprio |
| 4 | BAIXA | fechar o nó deixava o teto SEM DONO no grafo (zero open) | `Q_MUDEZ_DA_GUARDA_NAO_SE_IDENTIFICA` nasce open com 2 curas (notice no else; sensor via execution-output — hipótese a verificar) e gatilho |

**Refutados (3):** gramática (radar 0/0, "0 open" conferido); perda do teto em prosa (vivo no
workflow e no resíduo do #592); pilares mecânicos (nenhum arquivo de .github/ no #593; a
versão executada tinha a guarda — merge-base ancestral confirmado).

## Teto declarado

A autodeclaração do revisor de CI ("árvore permaneceu limpa o tempo todo") segue sendo
declaração, não medida (behavior-over-declaration) — o dono disso é o nó novo.
