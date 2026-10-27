---
branch: docs/doctrine-no-external-service
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: 41f22edbb29ad5d29e64d66d2609526b38ac2774503f492996d35db0b1136935
reviewed_code_sha256: e1277ec1a7dbe17122163c5ea0ad5e63ffdda05f494d244e2380458df4f8db12
findings_total: 9
findings_real: 4
tokens: 125988
duration_min: 5
findings_fixed: 8
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador novo (general-purpose), com o diff e o pedido, sem a conclusão; mediu com grep, gh e o radar
nota: "4 reais e 5 menores, todos curados menos um menor (o README de meta cita Gamma só numa lista de integrações). O real que mais pesou: o texto dizia que o orquestrador GERA pelo caminho local, e o grafo executável segue só-Gamma; virou PARE e devolva o caminho."
---

# Passada adversarial: `docs/doctrine-no-external-service`

## O que muda

A doutrina "sem dependência de serviço externo" (decisão do maestro de 2026-10-27, nó
`D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027`, ligado a `C_POSTURA_ACOPLAMENTO`), a KB
`docs/knowledge-base/concepts/no-external-service-dependency.md`, uma linha no CLAUDE.md e a
reclassificação do Gamma como ponte opcional.

## Achados e curas

1. **Real. "PR 137 em revisão" era falso.** O refutador mediu com `gh pr view 137`: o PR da curadoria
   foi mergeado em 2026-10-27 às 14:03 UTC. Eu reconferi e deu o mesmo. Cura: o texto agora diz
   "mergeado em 2026-10-27; receita provada lá, sem gerador no core", nos 5 arquivos e no nó.
2. **Real. O caminho local estava só declarado.** O aviso dizia que a FASE 5 do orquestrador gerava
   pelo caminho local. Mas a FASE 5 só chama o Gamma, a FASE 6 exige `generationId`, e o agente não tem a
   ferramenta Skill. Cura: sem chave, o orquestrador e o comando **param e devolvem** o caminho local. A
   KB diz que fazer o ramo de geração local é trabalho à parte.
3. **Real. A tabela Antes/Depois afirmava o que o diff não fazia.** Ela dizia "o caminho local vem
   primeiro". Cura: a tabela foi reescrita para o que mudou de fato, e as linhas 41 do comando e 46 do
   orquestrador foram ajustadas.
4. **Real. Faltavam duas candidatas.** O `/engineer:start` repete a frase "Context7 e Perplexity". O
   `/design:identity` reusa o Gamma e o MCP Canva. Cura: as duas foram para a tabela e para o nó, e o
   identity ganhou a nota do `/design:deck`.
5. **Menor. A justificativa do light-arch estava imprecisa.** O passo de pesquisa nomeia WebSearch.
   Cura: a frase foi precisada.
6. **Menor. A Anthropic aparecia com duas leituras.** Cura: uma frase no critério põe o Claude Code e o
   modelo como **substrato**, fora do teste. O onion-review continua candidato porque não nomeia o par
   local, `/git:code-review`.
7. **Menor. O Perplexity do research-agent é só prosa.** Não há ferramenta MCP no frontmatter. Cura:
   anotado na tabela.
8. **Menor. Outros consumidores do Gamma não tinham a nota.** Cura: a nota foi posta no
   storytelling-business-specialist e no setup-integration, e o `/design/deck` entrou nos
   `related_commands` do presentation. **Não curado:** o README de meta, que só lista "Gamma" entre as
   integrações.
9. **Menor. O `/design:deck` não equivale ao Gamma em tudo.** Ele faz deck de treino e onboarding, não
   pitch. Cura: isso ficou dito na KB e no orquestrador.

## Gate

O `kg-radar.sh --integrity --schema` sai com exit 0 no grafo de identidade, e o `kg-contract-check.sh`
dá rc 0. O lint completo rodou uma vez, antes das curas: os HARD eram as REGRAS 109 e 110, que são
efeito direto da KB nova e da linha no CLAUDE.md. Os dois foram curados: o índice foi recontado, e o
teto subiu com um `raise:` que cita o nó. Depois das curas, o `--only` nos artefatos tocados dá 0 HARD.
