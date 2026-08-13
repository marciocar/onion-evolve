---
branch: docs/kg-parecer-diff-invertido
pr: 591
date: 2026-08-13
reviewed_diff_sha256: 0de7a3b781dae94183ccd87ce17aee83c2b65f086aab6c2c3fa244c53f8ec0c2
findings_total: 8
findings_real: 7
findings_fixed: 7
tokens: 70289
duration_min: 7
verdict: CORRIGIDO
reviewer: code-reviewer (opus, adversarial — 5º Elenxo da linha de mecanismos)
---

# Passada adversarial — `docs/kg-parecer-diff-invertido`

## O 5º Elenxo derrubou a tese do próprio nó — a lei da linha, contra o autor

O diff era 1 nó + 1 aresta registrando "o parecer do CI revisou um diff INVERTIDO". O revisor
recebeu instrução de refutar cada fato contra o vivo — e derrubou **o fato central**, o único que
eu não tinha conferido por comando.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| 1 | **ALTA** | "em CI não existe diff não-commitado" é FALSO — a edição de 18:54 do **mesmo pin** (soterrada pelo upsert, só visível via `userContentEdits`) diz: *"Ignorei a modificação não-commitada... presente no working tree do checkout... ela reverte exatamente a cura"* | corrigido — nó reescrito |
| 2 | **ALTA** | a tese "diff invertido head→base" é subdeterminada: árvore-revertida e diff-invertido produzem saída **byte-idêntica**; as 2 evidências discriminantes apontam árvore suja; confidence 0.9 insustentável | corrigido — fato vs hipótese separados, confidence 0.8 na hipótese-líder |
| 3 | MÉDIA-ALTA | "1ª ocorrência" é falso — foram **2 runs** (31732737397 e 31735494448); o gatilho que o nó estacionava **já está satisfeito** | corrigido — ação devida declarada no nó |
| 4 | MÉDIA | citação seletiva: usei o parecer de 183a0d3 como calibração e omiti que **ele contém** o dado que derruba a tese | corrigido — nomeado no nó como worst-truth-is-uncertain |
| 5 | MÉDIA | a guarda-por-grep proposta acusaria parecer **correto** (elipses nas citações quebram `grep -F`) | corrigido — proposta retirada |
| 6 | MÉDIA | `grep` BRE sobre trecho com `${}` falha **silencioso** (rc=1 = "ausente") — classe `guarda-por-lista-falha-pelo-vocabulario` | corrigido — proposta retirada |
| 7 | BAIXA-MÉDIA | número de linha citado é offset de hunk — idêntico nos dois sentidos; âncora `arquivo:linha` é cega para inversão | corrigido — proposta retirada |
| 8 | (não-evidenciado) | falso-negativo em refactor-que-move (removido existe na origem E adicionado no destino) | registrado no nó como raciocínio, sem prova |

**O nó resistiu a 7 tentativas de refutação** (catraca em main 2×, linha 1049 nos três SHAs,
verbatim do parecer, run↔head↔janela do upsert, gramática/radar, diffstat +58/+9, o parecer
anterior cobrando a fixture §11).

## O que o nó afirma agora (pós-correção)

**Fato verificado:** nos 2 runs a árvore do runner continha modificação não-commitada revertendo a
cura à base. **Hipótese-líder (0.8, não provada):** o próprio revisor suja a árvore — o prompt não
entrega o diff e o revisor improvisa com Bash (`git checkout base -- arquivo` sem restaurar);
mesma assinatura em 2 runs independentes. **Ação devida (gatilho satisfeito):** (a) o prompt
entrega o comando canônico do diff e proíbe modificar a árvore; (b) o verdict ganha guarda
dirty-tree (`git status --porcelain` após a revisão). **Achado-bônus de mecanismo:** o pin
upsertado apaga os pareceres anteriores da vista — a evidência que derrubou a tese estava
inacessível a olho nu.

## Teto declarado

A hipótese-líder não foi provada (exigiria reproduzir o run com trace das tool-calls do revisor);
o nó a declara como hipótese, não fato. E não houve 6º Elenxo sobre a reescrita: re-validação por
radar (`--integrity` e `--schema` exit 0) + os 7 fatos periféricos já confirmados pelo 5º.
