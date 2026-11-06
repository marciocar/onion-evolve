---
branch: docs/persona-runtime-research
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão principal do core no fechamento; o Elenxo (o método de refutar antes de selar) rodou dentro do workflow wf_ad5d1e07-29a
nota: "tokens 0 = o custo da passada de fechamento não foi medido; o custo do run está no frontmatter da SYNTHESIS. Diff de pesquisa: grafo, síntese e retorno do workflow, sem código."
---

# Passada adversarial: `docs/persona-runtime-research`

## O que muda

- **Grafo `persona-runtime-2026-11`:** 90 nós escritos pelo `/onion-research` em modo decision, com radar exit 0 e contrato conforme. Inclui o nó `D_PERSONA_RUNTIME_2026_11`, aberto para o maestro selar.
- **`SYNTHESIS.md`:** projeção do grafo, com o contrato de custo.
- **Retorno do workflow:** versionado em `data/`.
- **`docs/backlog.md`:** regenerado.

## Achados

1. **Real, curado:** o retorno do workflow levava o caminho absoluto da máquina no campo `kgPath` (o repo é público). O prefixo foi removido do JSON versionado.
2. **Real, curado:** o grafo nasceu com `trace:` em todos os nós, e a síntese não era citada por nenhum, o que a deixaria invisível à REGRA 29. O `trace:` da pergunta, que era prosa, passou a apontar para a `SYNTHESIS.md`, sem duplicar a chave.
3. **Descartado, mas medido:** a condição 4 do Elenxo diz que o bwrap falha nesta VPS. Medi no fechamento e é verdade: `apparmor_restrict_unprivileged_userns = 1` e `bwrap` sai com `Permission denied` no uid map. Ficou registrado na síntese, com o efeito sobre o sandbox da curadoria.

## Mutantes

Nenhum: o diff não tem código.

## Limites declarados

- A recomendação é de um agente só, sem votação. O maestro sela.
- 40 claims ficaram fora da verificação por orçamento, e 42 foram cortadas antes.
- O fechamento não reabriu as fontes primárias; quem as leu e votou foi o próprio workflow.
