---
branch: docs/design-setup-option1-and-context-graph
pr: 1406
date: 2026-10-27
reviewed_diff_sha256: 458a182ab4100d0a92ddc028d4a55e1f2a534442971b6c62a1df3235ad6dad4f
reviewed_code_sha256: 56e434cff9261faa24187ef10563aeab003d40d7985bbdf12d884553f6960b1a
findings_total: 7
findings_real: 7
tokens: 94617
duration_min: 5
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: code-reviewer (agente novo com brief, sem a conclusão do autor)
nota: "Um refutador leu o 1º commit (3 nós e 3 arestas no grafo de sinais de campo) contra o pedido do maestro, o grafo do estudo na origin/main da curadoria e o kg-ssot, e rodou peer-ref-check, radar e contrato. Achou 7 defeitos (nenhum bloqueante, 3 importantes). Os 7 foram curados no 2º commit. Os tokens e a duração são do refutador."
---

# Passada adversarial: `docs/design-setup-option1-and-context-graph`

## O que muda

- A escolha do maestro de 2026-10-27 para o setup de design (opção 1, o fio fino em três ondas, com o design como piloto de contexto como grafo) vira o nó `D_DESIGN_SETUP_OPCAO1_GRAFO_PILOTO_1027`, criado pelo selador com rc 0.
- Duas evidências: a proposta da curadoria, fixada por commit, e o desenho do contrato vindo do kg-ssot.
- A pergunta aberta `Q_CONTEXTOS_COMO_GRAFO_EXTENSAO_1027`, com os três degraus e o gatilho do terceiro.
- Uma emenda na narrativa de `Q_DESIGN_CONTEXT_PRIMEIRA_CLASSE_1027`.

## Achados

| # | Achado | Sev. | Destino |
|---|---|---|---|
| 1 | `Q_DESIGN_CONTEXT_PRIMEIRA_CLASSE_1027` continuava dizendo que o estudo não estava na main da curadoria | importante | curado: emenda na narrativa com o PR 138 e o sha 19b9e500c010; a frase antiga fica, datada pela medição @ 8d64aef |
| 2 | A evidência estava `confirmed` mas metade dela era testemunho da sessão do kg-ssot, sem fonte conferida | importante | curado: separada em duas; a da curadoria segue `confirmed`, e o desenho do kg-ssot ficou `open` |
| 3 | A lacuna dizia que não há conferente do locator, mas a curadoria mergeou um protótipo (check_design_context.py) 52 s depois do commit | importante | curado: hoje não há conferente no contrato nem no core, só o protótipo da curadoria, e onde ele mora é a pergunta Q_KG_SSOT_LOCATOR_CHECK de lá |
| 4 | Os "três degraus" daqui e os da curadoria (Q_PROJECTION_CHECK_DEPENDENCY) têm conteúdo diferente | menor | curado: a pergunta mapeia os dois (os de lá são migração dentro de um contexto, os daqui são de alcance) |
| 5 | O desenho fixava o contraste como `invariant`; a curadoria mediu `invariant` ou `rule` e o brief como `claim` | menor | curado: a variante está citada, e quem constrói a onda 1 escolhe e declara |
| 6 | O `verified_against` dizia "conferido por peer-ref-check", mas o script não aceita a URL que o nó cita | menor | curado: as chamadas exatas, com caminho#id e sha, estão no `verified_against` |
| 7 | "11 de 98" não é reproduzível: a curadoria também só repassou o número, e o design-context do kg-ssot (2 de 6) ficou de fora | menor | curado: o número diz "informado pelo kg-ssot e não medido pelo core", leva o 2 de 6 e a aproximação do refutador (13 de 100) |

## Mutantes

Não se aplica: o PR não tem código executável. O que serve de prova está noutros instrumentos:

- o radar `--integrity --schema` sai com exit 0 no grafo de sinais de campo;
- o `kg-contract-check.sh` sai conforme;
- o lint de nomes (`kg_vocab.py lint`) não tem achado nos nós novos (69 achados no grafo, os mesmos de antes do selo);
- o `peer-ref-check.sh` sai rc 0 para cada nó da curadoria citado (D_DESIGN_SETUP_PROPOSAL, C_WAVE1_WITH_GRAPH, E_LAB_GRAPH_RESULT, Q_KG_SSOT_LOCATOR_CHECK, Q_PROJECTION_CHECK_DEPENDENCY, E_KGSSOT_PRECEDENT_IS_DISCIPLINE) e para os dois commits (19b9e500c010 e 668e13ba9132), ambos ancestrais da origin/main dela.

## Limites declarados

- O desenho do contrato vem por mensagem da sessão do kg-ssot; o core não conferiu nó dela na main.
- O "11 de 98" não foi medido pelo core.
- O 2º commit, com as curas, não voltou ao refutador.
