---
title: 'Resíduo — as rodadas 2 e 3 do critério indivíduo × organização, e o modo de primárias virando mecanismo'
date: 2026-09-13
branch: research/sharing-criterion-round2
reviewed_diff_sha256: 42c767356f4ed4823b4636328077534126cbe7c8555f50f04f50ffeb6589b6aa
findings_total: 34
findings_real: 33
findings_fixed: 26
tokens: 4056559
duration_min: 62
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Duas rodadas de pesquisa com Elenxo próprio (95 e 22 objeções) mais a minha medição direta sobre o texto da
  CLT. 31 achados reais: 5 são mentiras do artefato que EU escrevi no PR do selo, 1 é o defeito de gate do
  mecanismo que eu acabara de mecanizar (13 de 22 claims contadas como ancoradas sem citação), 1 é uma
  conclusão da rodada 3 refutada por medição. 7 ficam ABERTOS por ordem do maestro: verificação de legislação
  segue em paralelo e não bloqueia o fechamento.
---

# A rodada complementar cumpriu a condição, e cobrou o preço de quem a escreveu

O maestro selou a opção C com a rodada complementar como **condição**. Este PR executa essa condição
(rodada 2), executa a rodada 3 com os quatro alvos que o Elenxo da 2 nomeou, e transforma o **movimento**
usado nas duas em mecanismo chamável.

## O movimento, e por que ele existe

**Primárias NOMEADAS → leitura integral → claim só existe com `quote` verbatim e `locator` → ANCORAGEM por um
segundo agente que reabre o documento → Elenxo → write(KG) que apenda.**

A peça nova é a **ancoragem**, e ela nasceu de um defeito medido: na rodada 1, a varredura larga com votação
3/2 refutou 19 de 25 claims, a maioria **por fonte fraca, não por evidência contra**. A votação julgava a
plausibilidade do claim; ninguém abria o documento para ver se a citação existia.

| | rodada 1 (varredura) | rodada 2 (primárias) |
|---|---|---|
| run | `wf_88199ba9-b9a` | `wf_1865aba9-e20` |
| tokens · agentes | 7.282.373 · 105 | 2.680.149 · 28 |
| nós | 25 | 64 |
| **custo por nó** | **≈ 291 mil** | **≈ 42 mil** |
| fontes | 56 URLs, 15 lidas, 41 cortadas | 13 nomeadas, 13 lidas, 0 inalcançáveis |
| o que reprovou | 19 de 25 por fonte fraca | 14 de 76 na ancoragem (13 exageradas, 1 não encontrada) |

**5 das 6 claims sobre o texto da LGPD caíram na ancoragem** — verbo trocado, citação não literal, inferência
que o artigo não faz. A rodada 1 teria aprovado por plausibilidade.

## O que EU escrevi errado, e o Elenxo pegou

O PR do selo (#823) deixou o grafo **mentindo sobre o próprio estado**. Não é detalhe: um grafo que mente
sobre si é pior que uma lacuna declarada, porque desarma a desconfiança do próximo leitor.

1. **`D_` estava `done` em `plane: DEV`**, contra a gramática (`decision` só vira `done` verificada em PROD).
   Medido: **829 decisões `done` no corpus, 86 fora da regra** — eu estava nos 10%. Corrigido para PROD.
   ⚠️ **A regra não é mecanismo:** o radar passa `rc=0` sobre as 86. Fica declarado como fio próprio.
2. **O rótulo de `D_` ainda abria com "DECISÃO ABERTA"** e a opção D ainda dizia "não selar agora", ao lado da
   decisão selada. Os dois ganharam o prefixo do estado real, preservando o enquadramento original.
3. **O nó de contabilidade da rodada 2 dizia "18+ objeções julgadas, TODAS sobreviventes"** — foram **95, com
   78 sobreviventes e 14 lacunas abertas**. Corrigido contra o retorno do run, que agora é versionado.
4. **`Q_R2` dizia que a rodada "CUMPRIU a condição"** — cumpriu **de forma desigual**, e agora diz isso com os
   eixos nomeados.
5. **A objeção da rodada 1 "nenhuma opção pode ser selada nesta rodada"** ficou de pé depois de o selo existir.
   Virou `superseded` com aresta `SUPERSEDES` vinda da contabilidade da rodada 2, nomeando o que dela sobrevive.

## O mecanismo: `mode: 'primaries'`

O movimento não podia morrer num script de scratchpad. Entregue no `onion-research.js`:

```js
Workflow({ scriptPath: '.claude/workflows/onion-research.js', args: {
  mode: 'primaries', question, today, corpus, kgPath,
  sources: [{ key, gap, prompt }]   // a fonte, a LACUNA que ela fecha, e como chegar nela
}})
```

- **Fail-loud:** `mode: 'primaries'` sem `sources` utilizável devolve erro nomeado. Nunca cai em varredura
  em silêncio.
- **Gatilho de escolha, documentado na skill e na doutrina:** varredura quando o campo é desconhecido e as
  lacunas não têm nome; primárias quando **as lacunas já têm nome** — rodada complementar, revisita dirigida,
  eixo declarado por um run anterior.
- **Bancada:** casos que asseriram sobre o **arquivo real**, não sobre uma cópia; dois mutantes provados
  (remover a fase de ancoragem; deixar o leitor conferir a si mesmo) reprovam o caso de forma.
- **Dogfood:** a rodada 3 rodou pelo modo novo, não pelo script.

## O terceiro defeito: o gate que eu acabara de mecanizar já nasceu fail-open

A rodada 3 foi a **primeira execução real** do `mode: 'primaries'`. **13 das 22 claims voltaram `ANCORADA`
com `quote` vazia e `locator` `—`.** O `write(KG)` foi honesto (escreveu com ressalva no rótulo e tier 5–7 em
vez de 9–10), mas o pipeline **contou as 13 como ancoradas**, e o Elenxo cravou a frase que vale como regra:

> *enquanto o gate aceitar campo vazio, contar claims ancoradas não mede nada.*

**A causa é minha e é de código:** a agregação casava a claim do ancorador com a do leitor por **texto
idêntico**; quando o ancorador reescrevia a frase, a citação se perdia em silêncio — e nada checava o campo
vazio. Curado **no motor**, porque pedir disciplina ao agente é a cura nula:

1. schema do leitor exige `quote` com ≥ 30 caracteres e `locator` com ≥ 2;
2. o ancorador devolve a citação que **ele** conferiu, com precedência sobre a do leitor;
3. o casamento passa a tolerar reescrita;
4. **fail-closed:** `ANCORADA` sem citação vira `AFIRMADA-SEM-CITACAO` e vai para as rejeitadas.

Casos `(n)` e `(n2)` na bancada, com mutante rodado no arquivo vivo.

## O quarto: uma conclusão da rodada 3 refutada por medição minha

A rodada concluiu que **não há análogo brasileiro do art. 88 do GDPR** porque a lista do art. 611-A da CLT
seria fechada. Baixei o texto oficial do Planalto e li o caput:

> *"A convenção coletiva e o acordo coletivo de trabalho têm prevalência sobre a lei quando, **entre outros**,
> dispuserem sobre:"*

A lista é **exemplificativa**. A premissa é falsa e a conclusão cai. O nó virou `refuted`, com o nó de medição
direta e aresta `REFUTES` — Aufhebung, não apagamento. A pergunta volta aberta e melhor colocada.

## O que fica ABERTO, por ordem do maestro

*"O que faltar de verificação de legislação e afins será visto em paralelo e informado no futuro."* As lacunas
legais remanescentes **não bloqueiam o merge**; ficam declaradas no grafo, com o gatilho sendo o maestro
informar.

- **As quatro emendas a C** (`Q_R2_REVISAO_DO_SELO_C`) esperam selo. Nada foi selado por mim.
- **A gramática do `plane` em decisão `done` não tem mecanismo** — 86 nós fora da regra e o radar cego.

## Uma HARD que não se reproduz, declarada

No 1º commit desta branch o pre-commit acusou **`REGRA 49 (Nó plane:PROD de alto impacto carrega VERIFICAÇÃO,
com catraca)` · FUGA-DE-ESCOPO** no nó `C_DENG` de `inference-mitigation.kg.yaml` — **arquivo que este PR não
toca** (`git diff origin/main` nele: vazio), e cujo id **não está no baseline**. Rodado logo depois, o mesmo
lint completo na mesma árvore deu **0 ocorrências**, e o `kg-verification-coverage.sh` isolado também.

Não chamo de flaky sem prova nem escondo: é a classe já registrada nesta casa de **guarda que reprova no gate
e passa isolada**. Fica declarada aqui, com o que se sabe: aconteceu uma vez, no caminho do hook, com o índice
cheio; não reproduziu em duas medições seguintes. **Gatilho:** se repetir, a investigação começa por como o
guarda deriva `prev` quando `BASE_REF` está vazio — o próprio script avisa que ali `git show ":path"` lê o
ÍNDICE, não a árvore.

## Gate

```
radar --integrity --schema : exit 0 (115 nós · 189 arestas)
realign --check            : ALINHADO — (c)=0 (b)=0 (a)=0
família research_workflow  : 18 pass · 0 fail (2 casos novos: (n) e (n2))
mutantes                   : rebaixamento removido do motor ⇒ (n) reprova no arquivo VIVO; restaurado, md5 idêntico
backlog · painel           : regenerados
```
