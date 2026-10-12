---
title: "Revisão — /meta:decide forjado pelo /meta:forge (medidor, selador, doutrina, superfície, bancada, grafo)"
date: 2026-10-12
branch: feat/meta-decide
reviewer: "refutador isolado (subagente general-purpose, mandato REFUTAR, default reprovado), que executou cada ataque em cópias descartáveis fora do repo; mais o dogfood de carga headless do próprio comando"
reviewed_diff_sha256: 209d44de5e061e6d8ed500e62d0b7ea1f58f99c8adedbacefe50fe4ea134fdcd
reviewed_code_sha256: 874a8b5e287e66f22fe58be7cf629114c479ad467fbad7327574a7dc8ae70129
findings_total: 17
findings_real: 17
verdict: REPROVADO_E_CURADO
nota: "o refutador reprovou a 1ª versão (17 achados); todos curados ou declarados neste PR"
elenxo: sim
tokens: 183589
duration_min: 240
---

# Resíduo — REGRA 56

Forja do `/meta:decide` (pedido e topologia do maestro, 2026-10-12): superfície
`.claude/commands/meta/decide.md`, doutrina `common/prompts/decide-doctrine.md`, medidor
`.claude/validation/decide-census.sh`, selador `.claude/validation/kg-decide-seal.sh`, família
`run_decide_selftests` e o grafo `docs/evolution/research/forge-decide-2026-10/`. Censo da forja:
o comando entrou com **6 de 7** peças (a peça 4 está ausente por desenho, declarada).

## Achados do dogfood (antes do refutador, curados no mesmo laço)

1. A janela por bloco inteiro trazia o corpus quase todo (migração em massa toca todo nó): agora só
   id/label/narrative contam.
2. Id citado e inexistente sumia calado: virou aviso nomeado (caso i).
3. Os trechos de opção paravam em 4 e escondiam (e) e (f): sem teto.
4. Opções que vivem como nós vizinhos (`C_OPCAO_*`) não apareciam: coluna "quem chega por aresta" (caso j).
5. O selo subia para PROD e o contrato reprovava testemunho em PROD: o selo fica em DEV.
6. A carga real propôs selar em lote, sem perguntar, o que julgou derivável: a doutrina e o passo 2
   proíbem o selador fora de resposta do maestro.
7. role-cut (k) e role-bundle (p3) reprovaram com `decide` em `pending`: exceção com razão e predicado
   de p3 corrigido para o que ele protege.

## Achados do refutador (17; veredito REPROVADO)

1. **BLOQUEAVA**: o selador re-carimbava `confirmed` com proveniência medida (195 no corpus). Cura: só
   `open` (lista positiva); caso s8.
2. Proveniência anterior perdia locator e method. Cura: vai inteira para a narrative; caso s9.
3. Narrative em bloco ou lista era achatada. Cura: bloco `|-` verbatim; caso s9.
4. `--chosen` só de espaços selava escolha vazia. Cura: recusa; caso s10.
5. Dívida de contrato pré-existente virava rc 3 "culpa do selo". Cura: contrato no passo 0; caso s11.
6. Caminho relativo deixava o contrato não julgado com rc 0. Cura: `realpath`; caso s7 com relativo.
7. Data futura aceita. Cura: recusa; caso s10.
8. Nada ligava o selo a uma pergunta feita. Cura: `--question` obrigatório; caso s10. Teto: o selador
   não sabe se a pergunta foi de fato feita — isso segue sendo disciplina da sessão (declarado no grafo).
9. Campo cego só de 1º nível. Cura: chaves em qualquer nível e valores aninhados; caso s6.
10. Comparação com caixa e `«»` ambíguo. Cura: casefold e recusa de `«»`; caso s10.
11. Nó aberto fora da forma de bloco sumia da janela. Cura: aviso nomeado; caso k.
12. Grafo vazio, `nodes` não-lista e status fora do vocabulário calados. Cura: avisos; caso k.
    Declarado: `drifted` fica fora da fila (0 hoje).
13. Clone raso inundava a janela. Cura: janela NÃO MEDIDA com aviso; caso k.
14. `--cite` com caixa diferente sumia. Cura: casefold. Declarado: id com hífen/ponto (o radar já
    reprova id fora do alfabeto).
15. rc 1 em opção sem valor e grafo não UTF-8. Cura: rc 2 nomeado; caso k.
16. Três mutantes não mordiam (narrative descartada, janela por bloco, citado fechado). Cura: casos
    s9, b (linha fora do sentido mudada na janela) e i (citado já fechado).
17. Números da doutrina defasados pelos nós da própria forja. Cura: datados "antes da forja".

## Bancada

`run_decide_selftests`: 22 casos sob `LC_ALL=C`, 27 mutantes por `ops/mutate-and-restore.sh` (ao menos
um por caso), todos reprovando o caso que vigiam. Famílias tocadas também rodadas: role_bundle, role_cut,
forge, vendor_manifest, cited_directive e mais 10 da faixa — verdes após as curas. A bancada completa
não foi rodada localmente (o CI é o gate final, declarado).

## Tetos declarados

- O FILTRO (o que é do maestro) é julgamento da sessão; o selador não sabe se houve pergunta.
- `kg-decide-seal.sh` fica fora da zona de peças do corte por papel e viaja para o standalone com a
  menção a `/meta:decide` no docstring; o comando, a doutrina e o medidor não viajam (conjunto `pending`).
- Contrato de custo não se aplica: não há run de workflow; medidor e selador são 0 tokens.

Ids (para a guarda): E_PEDIDO_DO_MAESTRO_QUESTIONARIO D_TOPOLOGIA_DO_DECIDE_SELADA
E_CORPUS_SEM_OPCOES_ESTRUTURADAS E_JANELA_POR_BLOCO_ERA_RUIDO E_SELO_EM_PROD_REPROVA_NO_CONTRATO
E_DOGFOOD_ACHOU_TRES_SILENCIOS_DO_MEDIDOR E_DOGFOOD_DE_CARGA_PROPOS_SELO_EM_LOTE
E_REFUTADOR_REPROVOU_O_SELADOR E_BANCADA_22_CASOS_27_MUTANTES C_O_FILTRO_E_JULGAMENTO_DA_SESSAO
Q_DECIDE_FICA_EM_PENDING Q_OPCOES_EM_CAMPO_ESTRUTURADO
