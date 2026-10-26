---
branch: docs/triage-curation-duolingo-ai-front
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 6840637a3e78c5cef50e83ee529ed6e2f6de1b5885f1103c6aea448a19634bf8
reviewed_code_sha256: 73addec6377765e8ac4976d7194735d77efe1052c1793eff8fb5a5048a527995
findings_total: 7
findings_real: 3
tokens: 0
duration_min: 12
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: claude-opus-5-5 (passada própria do agente executor, não separado)
nota: "tokens 0 = não medido à parte (passada dentro da sessão do agente executor)"
---

# Passada adversarial: `docs/triage-curation-duolingo-ai-front`

## O que muda

- Dois grafos de triagem do core, na forma dos da Vexa e do anarlog: `duolingo-actor-2026-10` (costurar, revisita
  trimestral) e `ai-front-2026-10` (rodar o piloto 3). Os dois nós de decisão foram criados pelo
  `kg-decide-seal.sh --new`, rc 0 nos dois, com radar, contrato e lint de nomes verdes.
- `onion-slm-2026-10`: a pergunta-raiz é reconciliada por SUPERSEDES com a primária do PoETa v2, aberta na fonte.
- A baseline do eixo de treino e inferência do radar ganha a pauta da 1ª rodada (comentário, sem chave nova).
- O panorama competitivo ganha o Duolingo como ator medido fora da categoria.
- Os dois sinais vão para `docs/evolution/inbox/_processed/`.

## Achados

1. **Real, corrigido.** O sinal dizia "três variantes adaptadas ao português". O PDF (Tabela 1, seção 3.1) mostra
   o modelo base sem adaptação e duas adaptadas (GigaVerbo e Carolina). O nó de evidência diz isso, e o rótulo
   fala só em "três variantes".
2. **Real, corrigido.** As 9 leituras de síntese do grafo de modelos pequenos apontavam só para a pergunta que ficou
   superada, e a pergunta viva nascia sem nenhuma resposta ligada a ela. Ganharam `TRACES_TO` para a pergunta nova,
   e as arestas antigas ficam como registro.
3. **Real, corrigido.** O rótulo da pergunta nova nasceu com 288 caracteres, acima do teto de 280 do contrato.
   Foi encurtado sem perder as duas metades.
4. **Não procede.** O panorama copiaria número errado do sinal? Conferi receita, reservas, margem bruta e EBITDA
   ajustado contra os nós de dinheiro do grafo da curadoria (`f12dd1b`), e todos batem.
5. **Não procede.** A nota na baseline do radar quebraria a REGRA 65 (Radar de mundo com baseline DATADA por eixo)?
   É só comentário YAML, sem chave nova, e o `never_run` continua lá.
6. **Risco aceito, declarado.** O grafo da frente de IA no core marca `x_dissect_verdict: perseguir` com o veredito
   da curadoria ainda `open` lá. O censo do core vai mostrar "perseguir". Isso é coerente com a escolha do maestro
   (rodar o piloto 3 é o caminho de perseguir como estudo), mas o selo do veredito em si continua com a curadoria.
7. **Risco aceito, declarado.** O `review_after` do Duolingo no core (2026-11-15) não repete o da origem
   (2027-01-24), ao contrário dos irmãos. Isso é de propósito: a revisita trimestral escolhida pelo maestro vence
   antes. O motivo está no `meta:`.

## Mutantes

- Fiz a passada com a pergunta "se eu tirar esta linha, algum gate reprova?" sobre as arestas novas. Sem o
  `SUPERSEDES`, o radar deixa as duas perguntas `open` lado a lado, e a reconciliação não aparece. Sem os
  marcadores `x_dissect_*` no nó selado, o `dissect-census.sh` deixa de listar `duolingo-actor` e `ai-front`.
  Conferi o censo depois da edição, e as duas linhas aparecem com veredito.

## Limites declarados

- A passada é minha, do agente executor, sem refutador separado (`elenxo: nao`).
- O gatilho da revisita do Duolingo lê a lista de documentos da SEC e procura um 8-K com o item 2.02. Um 8-K com
  esse item por outro motivo dispararia cedo, e o risco é baixo.
- A ligação entre a lacuna do radar e o eixo de treino e inferência vive em comentário (baseline e `meta:` do grafo
  da frente de IA), sem nó. A decisão do eixo já é nó (`D_RADAR_E7_TREINO_INFERENCIA_ABERTO_1026`), e o achado já é
  nó (`E_OPENAI_SELF_SERVE_FINETUNE_SUNSET_2026`). Um terceiro nó só repetiria os dois.
- O ToolOrchestra ficou sem nó, só como nota no `meta:` do grafo da frente de IA e no PR, como o brief pedia.
