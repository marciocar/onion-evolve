---
branch: docs/research-maestro-persona
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 7
tokens: 138734
duration_min: 11
findings_fixed: 7
verdict: CORRIGIDO
elenxo: sim
reviewer: agente general-purpose separado, que não escreveu a SYNTHESIS nem as edições do grafo (default REPROVADO)
nota: >-
  Fechamento do run wf_ded7babd-681 do /onion-research em modo decision (7.377.462 tokens, 106 agentes,
  33,6 min, conferidos no diário do workflow). Grafo novo com 74 nós; D_MAESTRO_PERSONA_SOURCE_2026_11
  fica OPEN, e quem sela é o maestro. A passada adversarial foi de um agente separado, que julgou a
  SYNTHESIS contra o grafo e o retorno bruto do run: 12 achados, 7 reais, todos corrigidos, e 5
  falso-positivos que registram o que foi conferido. Tokens e duração são os da passada, não os do run.
  Radar e kg-contract-check com exit 0 depois das correções. Nenhum .kg.yaml existente foi editado,
  logo a REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) fica sem objeto.
---

# Passada adversarial: `docs/research-maestro-persona`

## O que muda

- Grafo novo `docs/evolution/research/maestro-persona-2026-11/maestro-persona-2026-11.kg.yaml` (74 nós, 91 arestas),
  escrito pelo workflow e corrigido no fechamento: id do run conferido, mercado e lacunas com a contagem do retorno,
  re-medida do MEMORY.md e `trace:` do nó `Q_` apontando para a SYNTHESIS.
- `SYNTHESIS.md` como projeção, com o contrato de custo no frontmatter, NÃO-VERIFICADOS e valeu-a-pena.
- `docs/backlog.md` regenerado (13 itens do grafo novo).

## Achados

1. **REAL**: «as 40 objeções chegam ao `D_` por CONSTRAINS» era falso. Só 18 chegam ao `D_`; 10 vão para A, 10 para D e
   3 para B. Corrigido na SYNTHESIS.
2. **REAL**: a nota (a) de `E_LACUNAS_*` ainda dizia que o id do run foi inferido. Corrigida para a conferência no diário.
3. **REAL**: `E_LACUNAS_*` ainda dizia «quem financia o tema não buscado», e a SYNTHESIS atribuía a frase ao
   sintetizador, cujo campo `market` diz só «sem sinal». Corrigidos o nó e a atribuição.
4. **REAL**: «três claims cortadas viraram objeção»; o grafo tem 15 nós `E_OBJECAO_CUT_*`. Corrigido.
5. **REAL**: «todas refutadas por fonte, não por evidência» contrariava o grafo na sexta, que o Elenxo mantém pela
   Tabela 2. Corrigido.
6. **REAL**: o negrito cobria 7 das 8 fontes `E_OBJECAO_SRC_*`; a oitava (tianpan.co) agora é nomeada com o peso baixo.
7. **REAL**: siglas sem glosa na primeira menção (KG-SSOT, A2A, SFT, SLM, IETF, ASR, BLEU/MAUVE, ERRO-A/ERRO-B, AAIF,
   LLM). Glosadas.
8. a 12. **FALSO-POSITIVO**: id e custo do run, números da SYNTHESIS contra o JSON e o grafo, correção do mercado,
   frontmatter e `review_after` (45 dias, cadência de modelos), `D_` aberto, radar 0 e ausência de dado privado:
   todos conferidos e aprovados.

## Mutantes

Não se aplica: nenhum código ou guarda muda.

## Limites declarados

- Ninguém leu as 39 fontes cortadas nem votou as 41 claims cortadas; o fechamento só as nomeia.
- Os valores de rodada (Twin1, Simile, Mem0) vêm de títulos e de claims não votadas; nenhum entrou como fato.
- O retorno bruto do run não foi versionado em `data/`: traz caminhos de máquina e não foi saneado.
