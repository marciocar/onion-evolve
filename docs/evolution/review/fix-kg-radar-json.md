---
branch: fix/kg-radar-json
pr: 1734
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 8
findings_blocking: 6
tokens: 171205
duration_min: 25
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "subagente general-purpose (opus), mandato refutar, sobre ea8e26ff2"
nota: "Refutador comparou os 75 grafos de docs/onion/graph convertidos pelo kg_migrate em 15 modos (1125 rodadas, rc igual em todas) e achou os defeitos em JSON válido no contrato que o kg_migrate não produz hoje. Re-medido depois das curas: 1125 rodadas, rc igual, 43 saídas de texto diferentes, 42 só no escape do texto livre e 1 por o JSON ter sido gerado de uma versão anterior do grafo editado nesta branch."
---

# Passada adversarial: `fix/kg-radar-json`

## O que muda

- `.claude/validation/kg-radar.sh` lê `.kg.json`: o `json` da biblioteca padrão traduz o grafo para o YAML de
  bloco que o mesmo awk lê. Chave repetida, NaN, surrogate solto, sintaxe fora da RFC 8259 e raiz que não é
  objeto param com rc 2 e o código do contrato. O sufixo `.proposal.kg.json` liga o modo proposta.
- Defeito latente do radar no `.kg.yaml`, curado junto: com `schema_version` (ou `baseline`, ou o próprio
  `review_after`) como 1ª chave de `meta`, a coluna dos campos de meta não era medida e o `review_after` sumia
  em silêncio. No corpus, 0 de 200 grafos com `review_after` estavam cegos.
- `.claude/validation/kg-contract-check.sh` lê `.kg.json` pelo perfil JSON do contrato (`as_source`).
- Bancada: família nova `radar_json_format` (12 casos) e o caso (a2) em `kg_contract_check`.
- Grafo `sinais-de-campo-2026-09`: dois nós e uma pergunta aberta; o sinal do hub vai para `_processed/`.

## Achados

1. ALTA, real, curado: mapa aninhado num campo `x_` saía em bloco, e o awk lia o `status:`/`trace:` de dentro
   como campo do nó (a decisão aberta sumia da fila e ganhava proveniência). Cura: valor aninhado além do campo
   do nó vai em flow numa linha; só o `provenance` do nó desce em bloco. Caso (g).
2. ALTA, real, curado: chaves do topo em ordem alfabética (`edges` antes de `meta`) faziam o `review_after`
   sumir. Cura: `meta` sai primeiro; e a causa de fundo era o defeito latente do `.kg.yaml` acima. Caso (h).
3. MÉDIA, real, curado: lista de mapas com `id` num campo `x_` virava nó fantasma (id duplicado, rc 1).
   Mesma cura do 1. Caso (i).
4. MÉDIA, real, não curado: a linha citada numa acusação é a do arquivo traduzido. Vai em Limites.
5. MÉDIA, real, curado: quatro mutantes sobreviviam (raiz não-objeto só por rc, pré-filtro do `--due` no
   arquivo original, escape de controle, trap do tmp). Casos (d) com o código, (k), (j) e (l).
6. MÉDIA, real, curado: o nó dizia que o `kg-contract-check.sh` já lia `.kg.json`; ele lia pelo caminho YAML
   e dava "conforme" para JSON com vírgula sobrando, comentário ou corpo em YAML. Curado com `as_source`,
   caso (a2), e o nó reescrito.
7. BAIXA, real, curado: o comentário dizia que o radar acusa toda chave repetida; acusa só em campo de nó.
8. Achado meu antes da passada, real, curado: `null` saía como a palavra `null`, e o awk lia `layer null`
   como valor inválido e `trace null` como proveniência. Cura: vazio, como no `.kg.yaml`. Caso (f).
9. Não real: as rodadas com rc 127 do refutador vieram de ele medir o worktree enquanto eu editava; ele
   mesmo refez numa cópia fixa.

Bloqueantes: 1, 2, 3, 5, 6 e 8.

## Mutantes

Primeira passada, todos mortos (helper rc 1): ramo JSON desligado, chave repetida aceita, sem reordenar
id/from, sufixo `.proposal.kg.json`, rc 2 trocado por 1, NaN aceito.

Segunda passada (curas desta revisão), todos mortos (helper rc 1), cada um plantado por
`ops/mutate-and-restore.sh`: aninhado em bloco, meta fora de ordem, null escrito, sem escape de controle,
pré-filtro do `--due` no arquivo original, trap sem o tmp do JSON, raiz lista aceita, coluna do meta pulando
schema_version e review_after, e `kg-contract-check` sem `as_source`. Total: 15 de 15 mortos.

## Limites declarados

- Texto livre (`label`, `verified_against`) aparece com o valor do JSON; o escape escrito à mão no `.kg.yaml`
  (`\"`, `''`) não volta. Rc e colunas estruturadas iguais.
- A linha citada numa acusação do radar sobre `.kg.json` é a do arquivo traduzido; o id e o campo valem.
- Faixa de número I-JSON e profundidade seguem com o contrato (`kg-contract-check.sh`), nos dois formatos.
- Leitores de corpus que enumeram só `*.kg.yaml` (kg-corpus-grep, kg-backlog-project, kg-census-extract e mais
  25 scripts) e o `kg-decide-seal.sh`, que escreve por texto: lacuna nomeada no nó
  `Q_LEITORES_DO_CORPUS_SO_ENUMERAM_KG_YAML_1122`. O core não tem `.kg.json` próprio hoje.
- Itens 1 e 2 do sinal (o `kg_gate.py` não descobre `.kg.json`; `external_edges` no perfil JSON) são do kg-ssot.

## Re-revisão por rebase (2026-11-22)

O #1734 ficou em conflito com a main depois que o #1733 (`/engineer:spike`) entrou: inventário, backlog e
projeções geradas. Rebase pela casa (`ops/pr-finalize.sh --rebase --push`), com a projeção regenerada pelo
gerador e nunca editada à mão, e os dois blocos mantidos se a âncora do `lint-selftest.sh` colidisse. O código
revisado (radar, contract-check, bancada, grafo) não muda no rebase; o diff volta a `pendente` e o
`pr-finalize` carimba de novo.
