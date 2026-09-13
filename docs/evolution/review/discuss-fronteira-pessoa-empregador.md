---
title: 'Resíduo adversarial — eixo pessoa × empregador e a pesquisa indivíduo × organização'
date: 2026-09-13
branch: discuss/fronteira-pessoa-empregador
reviewed_diff_sha256: 58e83980c52077e2581034fe50b53b261dfd5c38d189ed0c713f83f795e42124
findings_total: 19
findings_real: 17
findings_fixed: 16
tokens: 213270
duration_min: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Um refutador com mandato de derrubar e default REPROVADO atacou a síntese, os dois grafos e a mudança no
  workflow. Resultado: 6 ALTA, 8 MÉDIA e 5 BAIXA. A classe dominante é a síntese escrevendo com mais certeza que
  o grafo e o retorno do run. Dois achados não eram defeito do diff: a contagem de tool calls confere com a
  notificação, e a descrição da tarefa que o refutador recebeu estava errada, não o diff. Um fica aceito e
  declarado: decisão done com plane DEV, seguindo 81 precedentes do corpus.
---

# A síntese afirmava mais do que o run mediu

O pesquisador fui eu. Escrevi a síntese à mão sobre o retorno do workflow, e a passada adversarial a reprovou
pelo defeito que este repositório mais persegue: **o texto declarava com mais força do que a medição
sustentava.**

## Os seis ALTA, e o que virou cada um

1. **O critério aparecia como achado das fontes.** O próprio retorno do run diz que é síntese do sintetizador,
   e que a pergunta central segue sem evidência direta. Título e veredito agora dizem "a rodada 1 propõe".
2. **"O art. 88(1) do GDPR autoriza".** A claim foi cortada por orçamento, não tem nó, e o artigo é cláusula
   de abertura para os Estados-membros. Virou NÃO-VERIFICADO, e a frase "B cai no direito" saiu da síntese e
   dos labels das opções A, B e da decisão.
3. **O Mercado contradizia duas objeções que o grafo registra.** A identidade do Glean serve para permissão e
   é compatível com a posição do adotante. O piso de grupo do Viva **confirma** a restrição do adotante. A seção
   foi reescrita.
4. **As restrições de C diziam vir das arestas CONSTRAINS, e quatro não existem no grafo.** Agora estão
   separadas: as que são aresta, e as que são texto da recomendação ainda sem fonte lida. "Reuso proibido"
   virou "reuso só compatível e declarado".
5. **O nó de lacunas dizia "3 descartes reabertos" e "41 fontes".** Eram 33 reabertos e 41 URLs **cortadas**,
   de 15 lidas. Pior: das 40 objeções sobreviventes só 10 viraram nó. O nó foi corrigido, o retorno do run
   passou a ser versionado em `data/wf_88199ba9-b9a-return.json` com as 30 restantes nomeadas, e o contrato do
   `write(KG)` do workflow agora obriga a declarar a contagem exata e nomear as não modeladas.
6. **O valeu-a-pena comparava com a régua errada.** 68–74 mil por nó é o censo, outro pipeline; 1,3M e 3,4M
   eram custo por run. No mesmo formato a faixa é 180–264 mil por nó. "Regressão clara" e "metade do dinheiro
   pagou uma discordância" saíram: nenhuma das duas tinha medição.

## MÉDIA, em uma linha cada

- **M1:** o texto tratava a posição do maestro como critério que caiu. Ele pediu a pesquisa porque não havia critério.
- **M2:** o label do nó do maestro trazia adjetivos que ele não disse. Agora carrega a frase literal.
- **M3:** a aresta `DEPENDS_ON D_FRONTEIRA` saiu, porque os eixos são ortogonais, como o próprio sinal diz.
- **M4:** a aresta pesquisa→claim do maestro estava invertida e com semântica errada. Virou `C DEPENDS_ON Q_RESEARCH`.
- **M5:** C deixava "organização→indivíduo aberto", e o vazamento medido pelo adotante é desse lado. Restringido
  ao dado da própria pessoa e às decisões que a afetam. A colisão está declarada.
- **M6:** "≥20 empresas" não foi "refutada e confirmada": foi refutada numa claim e não verificada na outra.
- **M7:** as objeções do Elenxo são afirmação de um agente só, sem votação. A confiança das 10 foi limitada a
  0,6, e o contrato do workflow agora exige isso.
- **M8:** a cura do log de corpus era parcial. O contador passa a contar só linhas canônicas. A mensagem diz
  "formato não-canônico" e nomeia os 4 prompts onde o corpus entra. Declarei meu desvio: condensei o bloco
  que a skill manda passar verbatim.

## BAIXA

- **B1, aceito e declarado:** decisão `done` com `plane: DEV`. O `verified_against` ganhou a ressalva do maestro.
- **B2:** "vale para QUALQUER desenho" generalizava além da medição. Agora diz o que foi medido e o que o
  banco de provas testa.
- **B3, não real:** 459 tool calls e 0 erro constam da notificação e do diário do run.
- **B4, não real:** a descrição que o refutador recebeu dizia "ganhou nota", mas o nó era novo. O erro estava
  no meu prompt, não no diff.
- **B5, pré-existente e curado:** o `fronteira-decision.kg.yaml` ganhou `schema_version: "1"`. O radar confirma.

## Gate

```
radar --integrity --schema : exit 0 nos dois grafos (25/48 · 18 nós)
lint (LC_ALL=C)            : 0 HARD · 17 SOFT
backlog                    : em dia
onion-research.js          : node --check OK (corpo embrulhado em async function)
contador novo              : 1 linha canônica → 1 · cabeçalho '#' → 0 · prosa → 0
```
