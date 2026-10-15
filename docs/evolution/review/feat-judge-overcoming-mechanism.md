---
branch: feat/judge-overcoming-mechanism
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: ad2ab3854de705138f24c1d73f198c4824b9bf392c86d44920888d4ef59824ed
reviewed_code_sha256: 3d6800247368982b33be522d82b48db3b03e0c0998dc68ba4ce9965e571fe344
findings_total: 12
findings_real: 11
tokens: 175711
duration_min: 8
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR
nota: "tokens e duração são do refutador (usage da notificação). O achado 12 (superfície que viaja) é uma confirmação de que não havia defeito, não um achado real. Do achado 7, a parte curada é tirar a parqueada recusada da seção de parques; a dívida do Superpowers ficou declarada, sem cura."
---

# Passada adversarial: `feat/judge-overcoming-mechanism`

## O que muda

Este PR implementa o SAC-151, a partir do reforço do maestro de 2026-10-15: "um juiz de sim ou não sem tentar
superação em uma pesquisa pode restringir possibilidades de crescimento e inovação; é preciso ter medição e
critérios claros". A partir dele, todo veredito negativo leva `superacao {achada, o_que, medida}` e cita um
critério pré-registrado, com o comando que o checa. Quando falta uma das duas metades, o motor recusa o
veredito e o conta (fail-closed). A superação achada vira o nó `C_SUPERACAO_<data>_…` com aresta `TRACES_TO`.

Onde isso entra:
- o bloco `overcoming-gate` no `onion-research.js` (Verify, Elenxo de decisão, ancoragem e Elenxo de primárias);
- uma cópia idêntica no `census-workflow.mjs`;
- o nó de superação gravado pelo `census-seal.py`;
- o `judge-verdict-check.sh`, para cc-update, radar, guarda e forja;
- o `dissect-census.sh --check-verdict`;
- as doutrinas e os comandos;
- o nó D_ no grafo da doutrina Elenxo.

## Achados

1. **BLOQUEADOR.** No Verify, um voto recusado convertia uma refutação de 2 a 1 em confirmação de 1 a 1. O
   achado foi reproduzido também no meu dogfood com stubs: 6 de 6 claims saíram confirmadas. Curado: a
   sobrevivência agora exige `g.recused.length === 0`. Caso (og7) com mutante.
2. **BLOQUEADOR.** No Elenxo, a objeção recusada sumia da lista e o alvo ficava liberado. Além disso,
   `discarded-by-comodismo` era tratado como negativo. Curado: `keepRecused` mantém a objeção marcada
   `naoJulgada`, e o escritor a modela como CONSTRAINS fraca. O pedido de reabrir saiu do gate. O (og2) cobre.
3. **ALTO.** O census-seal cortava o texto depois de escapar as aspas, e o YAML saía inválido com radar 0.
   Curado: o corte vem antes do escape, e há `yaml.safe_load` antes de gravar. O caso (og) tem apóstrofo na
   fronteira do corte.
4. **ALTO.** O vocabulário do checker deixava passar EXAGERA, REJECT, FAIL, UNVERIF, `survives` e
   `refuted` em string, e a lista vazia saía com rc 0. Curado, com o caso (og6) ampliado.
5. **MÉDIO.** `--field` sem valor entrava em laço infinito, e uma regex inválida saía com rc 1. Curado: os
   dois casos agora saem com rc 3. Medido à mão.
6. **MÉDIO.** A aresta do dissect dava falso positivo: valia de outro item, REFUTES contava, ids entre aspas
   e comentários quebravam a leitura, e o critério "sim" era aceito. Curado: a leitura é por item, só
   TRACES_TO/SUPPORTS contam e o critério tem de ser um comando. O (og-d1) ganhou os quatro casos de borda.
7. **MÉDIO.** O Superpowers fica vermelho no censo. É uma decisão `done` selada pelo maestro, e eu não a
   toquei. A dívida está declarada no nó E_JUIZES_SEM_SUPERACAO_MEDIDO. A parqueada recusada saiu da seção
   "parqueadas".
8. **MÉDIO.** O verificador contava nós antigos do mesmo prefixo. Curado: há uma baseline (`count-sup`)
   medida antes do write, e as arestas TRACES_TO passam a ser contadas. O (og3) tem um cenário só com nós
   antigos.
9. **MÉDIO.** O census-seal cortava o id em 30 caracteres, o que gerava colisão, e testava o id por
   substring. Curado: o id é completo, a checagem é exata e o pulo é registrado em `skip`. O (og) tem dois
   ids longos.
10. **MÉDIO.** O plugin `onion` citava um checker que não embarcava. Curado: o checker carrega a própria
    cópia do bloco e entrou no manifesto `onion`. O (og4) confere as 3 cópias.
11. **BAIXO.** A bancada tinha mutantes fracos. Curado com casos comportamentais (og7, o og3 ampliado, o
    og6 ampliado e o seal).
12. **BAIXO.** Superfície que viaja: o refutador confirmou que está limpa. Não é achado real.

## Mutantes

Dentro da bancada há 9 mutantes, todos mortos: og1m-a, og1m-b, og2m, og3m, og5m, og6m, og7m, og-d1m e o
census-seal og-m.

Fora da bancada, plantei 5 mutantes com `ops/mutate-and-restore.sh`, todos mortos:
- trava da recusa no Verify, morto por og7;
- ordem corte/escape no seal, morto por og;
- tipo de aresta no dissect, morto por og-d1;
- lista vazia no checker, morto por og6;
- `keepRecused` no Elenxo, morto por og2.

Duas primeiras tentativas de mutante, no dissect e no checker, saíram sintaticamente quebradas, então
mediam crash e não a cláusula. Refiz as duas com mutantes válidos.

Os 8 casos primários reprovam contra os arquivos de `origin/main` (rodados à parte) e passam na branch.

## Limites declarados

- O motor confere forma e pertença do critério. Não confere se o comando citado de fato reprova.
- O workflow de pesquisa não rodou ao vivo com agentes reais por custo. O corpo inteiro foi executado com
  stubs por label (decisão e engine-verify).
- A baseline da contagem de superação vem de um agente sonnet. Se ele não devolver nada, a base vira 0 e o
  retorno marca `base.measured: false`.
- O Superpowers segue como veredito negativo recusado no censo (dívida legada declarada).
