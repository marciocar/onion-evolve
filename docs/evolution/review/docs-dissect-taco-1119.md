---
branch: docs/dissect-taco-1119
pr: pendente
date: 2026-11-19
reviewed_diff_sha256: c12aa80190c7658cdcd9a577f95977ec66b2f19d2ed600c8c07c736b41b8f0f0
reviewed_code_sha256: e0b3d5e49e105b09e5cff97d52024c4e84989d8c2593ef989d05646825d3dd31
findings_total: 8
findings_real: 8
findings_blocking: 2
tokens: 170499
duration_min: 6
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: subagente refutador isolado (general-purpose), uma passada sobre o diff inteiro, com o clone do taco no pino 04062d4b e o venv descartável, sem escrita no repo
nota: >-
  A passada achou 2 ALTOS (bloqueiam), 4 MÉDIOS e 2 BAIXOS. Os dois bloqueantes derrubaram duas razões da
  1ª versão do veredito: a falsa analogia estendida a todo o taco e a superação pelo a2a-sdk Python, que
  não roda no bridge TypeScript nem entrega a camada genérica. Curados no grafo: o veredito segue rejeitar
  com razões novas, a superação virou nenhuma com a busca na web, e a objeção do veredito em peças ficou
  como nó CONSTRAINS. Tokens e duração são do harness para o revisor.
---

# Passada adversarial: `docs/dissect-taco-1119`

## O que muda

A dissecação do `pelles-ai/taco` até o N3 (nível 3, transferibilidade) foi conduzida direto pela sessão.
Entram a Etapa 0, o grafo, a síntese e duas sondas, todos em `docs/evolution/dissect/taco-2026-11/`. O
revisor tentou derrubar o N3 e o veredito, conferiu os números contra o clone e o registro de ideias contra
o core, e rodou as guardas de forma.

## Achados

| # | Sev. | Triagem | Achado | Destino |
|---|---|---|---|---|
| 1 | ALTO | bloqueia | A razão «o próprio do taco é vocabulário de construção» é falsa distinção. Com um card A2A comum, uma tarefa `code-review` sai `completed`. O despacho, o escopo por tipo e o store são neutros quanto ao domínio. | **Curado.** Novo nó `E_N2_PROBE_PLAIN_CARD`, com a sonda reproduzida pela sessão e commitada. A falsa analogia se estreitou a `C_N3_CONSTRUCTION_EXTENSION_FALSE_ANALOGY` (só a `x-construction` e o `find`). Entrou `C_N3_GENERIC_LAYER_TRANSFERS_AS_CONCEPT`, e as razões do veredito foram reescritas. |
| 2 | ALTO | bloqueia | A superação `E_A2A_SDK_DIRECT` consola. O bridge é TypeScript, o `a2a-sdk` Python não tem despacho por tipo nem escopo por tipo, só se mediu o import, e «Linux Foundation» não estava na fonte citada. | **Curado.** O veredito declara `x_dissect_overcoming: nenhuma`, com a medida e três buscas (corpus, npm, PyPI). O nó foi trocado por `E_OVERCOMING_SEARCH_A2A_SDKS`: o Python 1.3.1 rodado, o JS 1.3.0 lido no npm, e nenhum entrega a camada genérica. Novo nó `C_N3_SUBSTRATE_MISMATCH`. |
| 3 | MÉDIO | limite | Os números do N0 e do N2 não conferiam: 63 contra 77 commits «Claude», 15/03 contra 01/03, 7 de 15 contra 7 de 16 módulos (8 de 22 com o monitor), 48 contra 46 ramos. | **Curado** no nó e na síntese, com a sessão remedindo cada número. |
| 4 | MÉDIO | limite | O nó da sonda dizia que o grep devolvia zero, quando há `model_validate` de tipos de fio. Também omitia a validação opcional (`get_schema_model`, usada no exemplo de referência). | **Curado.** O texto cita o grep real e a validação opcional. O `why` de `I_GATE_THE_DECLARED_SCHEMA` foi corrigido. |
| 5 | MÉDIO | limite | Comparativo errado em duas ideias. `I_SCOPE_PER_TASK_TYPE` marcava `nao-temos` (o certo é `diferente`: o core autoriza por par e tipo de ação). `I_REGISTRY_ASSIGNED_TRUST_TIER` ignorava `.claude/utils/trust/`. | **Curado** nos dois `why`. |
| 6 | MÉDIO | limite | Faltou a ideia da delegação com token estreitado (RFC 8693, `spec/security.md`), relevante à orquestração de sessões. | **Curado.** Novo nó `I_DELEGATION_TOKEN_EXCHANGE`, com valor 3 e destino `D_A2A_BACKBONE_PRODUCT_2026_11`. |
| 7 | BAIXO | limite | Arestas mal ligadas: a sonda de esquema sustentava a tese do vocabulário, e não havia nó de objeção. | **Curado.** A sonda liga direto ao veredito, e a objeção do veredito em peças virou `C_OBJ_PIECES_ALTERNATIVE` CONSTRAINS `D_TACO_VERDICT`. |
| 8 | BAIXO | limite | Os destinos `onion-curation:…#Q_…` apontam para um repo privado. A REGRA 121 (grafo novo ou tocado não cita repositório não conferível por terceiro) sai rc 0, porque o vocabulário dela não cobre a forma `repo:caminho`. | **Declarado.** A síntese diz que o destino é privado e não conferível por terceiro. Alargar a REGRA 121 fica fora deste PR, que não toca guarda. |

## Mutantes

Não se aplica: o PR não traz guarda nem código de produção. As sondas são medidas reproduzíveis do objeto,
e as guardas de forma rodaram sobre o grafo curado. `dissect-object-check` saiu com 0 achados e o
`kg-radar --integrity --schema`, o contrato e o `dissect-census --check-verdict taco` saíram todos rc 0.

## Limites declarados

- A REGRA 121 é cega à forma `repo:caminho` (achado 8). O nome do repo já é público no `members.yaml`, e não
  há vazamento.
- A objeção do veredito em peças sobrevive como limite (`C_OBJ_PIECES_ALTERNATIVE`), e quem decide é o
  maestro.
- O revisor não reconferiu que a 1.3.1 é a última versão do índice. A sessão a mediu com `pip index versions`.
