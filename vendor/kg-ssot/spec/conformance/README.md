# Suíte de conformidade do `.kg.yaml`

> **Projeção do grafo do produto KG-SSOT, nunca fonte paralela** (os ids entre crases são nós dele). O formato
> é o de `A_CONFORMANCE_SUITE_SEED` (`EPIC_1_SUITE_FORMAT`). Os casos medem o contrato v4
> (`A_CONTRACT_V4`): `spec/kg-contract-v4.schema.json` (MUST) e `spec/kg-contract-v4.should.schema.json`
> (SHOULD), com as cinco decisões do E0, a proveniência estruturada e a rampa do v4 (`EPIC_9_CONTRACT_V4_RAMP`).

Todo leitor de `.kg.yaml` tem de passar nesta suíte: o radar e o drive do Onion, um extrator de grafos,
o port JS de um adotante e o leitor de referência `tools/kg_validate.py`. Os casos são **dados puros**,
no molde da JSON-Schema-Test-Suite (`E_JSONSCHEMA_TEST_CASE_AS_PURE_DATA`), e não dependem de Claude
Code (`D_KG_SSOT_INDEPENDENTE_DE_HARNESS`).

## Formato

Um **grupo** é uma pasta com um `manifest.json` e um `.kg.yaml` real por caso. O arquivo é real, e não
texto embutido no JSON, para que qualquer CLI receba o caminho e leia como leria um grafo de verdade.

```json
{
  "description": "enums do nó",
  "layer": "form",
  "pending_on": [],
  "cases": [
    { "file": "bad-node-type.kg.yaml",
      "description": "node_type fora do enum",
      "valid": false,
      "codes": ["form.enum.node.node_type"],
      "warnings": [] }
  ]
}
```

| Campo | Regra |
|---|---|
| `layer` | `parse`, `form`, `integrity`, `yaml` ou `semantic`: a camada que o grupo exercita. `semantic` só existe em `optional/`. |
| `pending_on` | Ids das decisões abertas de que o veredito depende. Vazio em `latest/`, não vazio em `proposals/`. |
| `valid` | `true` exige `codes: []`. `false` exige pelo menos um código. |
| `codes` | Violações de **MUST**: reprovam o arquivo. |
| `warnings` | Violações de **SHOULD**: só alertam, e o arquivo continua válido. É opcional, e ausente vale `[]`. |

O `manifest.schema.json` (JSON Schema 2020-12) valida todo manifesto. A própria suíte se valida com a
mesma tecnologia do contrato (`E_JSONSCHEMA_SUITE_SELF_METASCHEMA_CI`, no mesmo grafo de pesquisa). Em `metaschema-tests/` há os
manifestos que ele tem de aceitar (`good/`) e os que tem de recusar (`bad/`).

**Um caso, um defeito.** O leitor passa num caso quando o **conjunto** de códigos que emite é
**igual** ao esperado, tanto em `codes` quanto em `warnings`. Igualdade, não inclusão: um leitor que
acusa tudo não pode passar. Ordem e repetição não contam.

## Códigos

Cada código é um slug estável por camada, e o metaschema confere a forma.

| Camada | Forma | Exemplos |
|---|---|---|
| parse | `parse.<motivo>` | `parse.yaml-error`, `parse.duplicate-key`, `parse.empty-document`, `parse.not-single-document`, `parse.root-not-mapping` |
| form | `form.<tipo>.<escopo>.<campo>` | `form.required.node.label`, `form.enum.node.node_type`, `form.range.node.impact`, `form.pattern.edge.to`, `form.type.node.item` |
| integrity | `integrity.<regra>` | `integrity.duplicate-id`, `integrity.dangling-from`, `integrity.dangling-to`, `integrity.dangling-trigger`, `integrity.orphan-node` (MUST); `integrity.testimony-in-prod`, `integrity.verified-before-fact`, `integrity.untraced-decision` (SHOULD) |
| yaml | `yaml.<regra>` | `yaml.forbidden-key-on` (MUST), `yaml.unquoted-date` (SHOULD) |
| semantic | `semantic.<regra>` | `semantic.contradiction` (MUST); `semantic.supersedes-unreconciled`, `semantic.answered-question-open`, `semantic.decision-done-dev`, `semantic.stale-missing`, `semantic.stale-old`, `semantic.review-overdue`, `semantic.testimony-unmarked` e os `semantic.domain-*` da camada domain (SHOULD) — só em `optional/` |

`<tipo>` ∈ `required enum type pattern range const unknown-key`. `<escopo>` ∈ `top meta node edge`.
Num objeto aninhado, `<campo>` é o caminho com ponto: `form.required.node.provenance.locator`.
`range` cobre também o tamanho de texto: `label: ""` (MUST) e `label` acima de 280 caracteres
(SHOULD, a narrativa vai para `narrative`). O tamanho conta code points, como o `maxLength` do JSON
Schema: um emoji vale 1, não 2 unidades UTF-16 (`str.length` de JS erraria), e não há normalização.
Data completa tem de existir no calendário, e o código é `form.pattern`: o `format: date` do schema é
**asserção**, e todo leitor tem de checá-lo. `.nan` e `.inf` reprovam como `form.type` em qualquer
posição, também em chave `x_` e dentro de lista, porque o JSON não os representa. Um item de lista que não é mapa usa o
campo `item` (`form.type.node.item`). Nome de chave que não é slug (`<<`, `1.0`, `a.b`) reprova como
`form.pattern.<escopo>.key` e, com o prefixo `x_`, só alerta. As chaves são comparadas na forma JSON: `1` e `"1"` colidem
(`parse.duplicate-key`), `true` vira `true`, não `True`. Uma aresta com `on` reprova por
`yaml.forbidden-key-on`; se o alvo de `on` não existir, sai também `integrity.dangling-on`. Os `pattern` têm a
semântica do ECMA-262, a do JSON Schema: `$` não casa antes de uma quebra de linha final.

O que o v4 mudou de severidade, e o que entrou:

| Código | No v3 | No v4 |
|---|---|---|
| `form.required.node.provenance` (nó `confirmed` ou PROD sem `provenance`; o `unverifiable` não exige) | SHOULD | **MUST** |
| `form.unknown-key.<escopo>.<chave>` (chave fora da gramática e sem `x_`, no topo, no meta, no nó e na aresta) | SHOULD | **MUST** |
| `form.pattern.<escopo>.key` (nome que não é slug, sem `x_`) | SHOULD | **MUST** (com `x_`, segue SHOULD) |
| `form.pattern.node.provenance.source` (`source` placeholder: só espaço, `desconhecida`, `unknown`, `n/a`, `none`, `null`, `sem fonte`, `tbd`, hífens, travessão, `?`...) | — | **MUST** (o vazio segue `form.range`) |
| `form.pattern.node.provenance.method` (fora de `'<classe>: <detalhe>'`, classe em `medição`, `leitura`, `juízes`, `derivado`, `testemunho`) | — | SHOULD (MUST no v5) |
| `form.unknown-key.node.provenance.<chave>` (chave desconhecida dentro de `provenance`) | SHOULD | SHOULD |

O v4.1 acrescenta quatro avisos SHOULD (não muda veredito; `latest/form/unanchored/` e `latest/integrity/coherence/`).
Os três `integrity.*` cruzam campos ou arestas, por isso o leitor os computa fora do schema:

| Código | Quando alerta |
|---|---|
| `form.required.node.verified_against` | `claim` com `verified_at` e sem `verified_against`: carimbo sem alvo (os outros tipos já se ancoram por outro campo) |
| `integrity.testimony-in-prod` | nó PROD cuja base é testemunho (`evidence_class: testimony` ou `method` da classe `testemunho`) |
| `integrity.verified-before-fact` | `verified_at` anterior a `valid_from`, comparados na granularidade do mais curto (`AAAA`, `AAAA-MM`, `AAAA-MM-DD`); data fora dessa forma não é comparada |
| `integrity.untraced-decision` | `decision` que não é `superseded` nem `refuted` sem `trace`, sem `provenance` e sem aresta `TRACES_TO` saindo dela |

O v4.3 acrescenta `external_edges`, opcional, no topo: arestas entre grafos com **exatamente uma** ponta externa
`<caminho relativo à raiz do repo>#<id>`, e a outra um id deste arquivo ou ausente (`from` ausente vale o grafo inteiro).
Os tipos são `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`, `TRACES_TO` e `DEPENDS_ON`. Os casos estão em
`latest/form/external-edges/`, `latest/integrity/external-local/` e `latest/integrity/external-corpus/`.

| Código | Quando reprova |
|---|---|
| `form.pattern.top.external_edges.to` (ou `.from`) | as duas pontas externas, as duas locais, ou a referência fora da forma (caminho absoluto, sem `.kg.yaml#`) |
| `form.enum.top.external_edges.edge_type` | tipo fora dos seis (os da camada domain não cruzam grafos) |
| `integrity.dangling-external-local` | a ponta local não existe neste arquivo |
| `integrity.dangling-external` | **com o corpus**: o arquivo ou o id da ponta externa não existe |

A aresta externa conta como ligação: o nó ligado só por ela não é órfão. Sem o corpus, a ponta externa não é conferida, e
o leitor diz isso na saída. A referência é relativa e com `/`: segmentos começam por letra, dígito ou `_`, sem `.` ou
`..`, sem `\` e sem `:`.

O v4.2 acrescenta `provenance.locality`, opcional, com o enum `repo`, `web`, `host` ou `pessoa`. O valor fora do enum
alerta como `form.enum.node.provenance.locality` (`latest/form/provenance-locality/`), e nenhum veredito muda.
O mesmo código pode aparecer como MUST num caso e como SHOULD em outro, porque a severidade é do
caso, não do código.

## Pastas

Os casos moram em `fixtures/`, a convenção de diretório de teste que validadores de repositório
costumam isentar. Sem isso, os grafos quebrados de propósito reprovariam o próprio repo. A exceção
é `latest/parse/document/bad-yaml-syntax.yaml`: há validador que varre todo `.kg.yaml` rastreado sem
respeitar a convenção, e o único caso não parseável usa a extensão `.yaml` (o metaschema aceita as
duas). Dentro de cada pasta, o grupo é livre; por convenção, `latest/<camada>/<grupo>/`.

| Pasta | O que vale |
|---|---|
| `fixtures/latest/` | O contrato vigente. O leitor **tem** de passar em todos os casos. |
| `fixtures/optional/` | Comportamento que um leitor **pode** implementar; hoje, `semantic/`, a camada do radar. Roda e reporta, mas não reprova, e entra na matriz leitor × caso. |
| `fixtures/proposals/` | O veredito depende de decisão aberta (`pending_on`). Roda e reporta, mas não reprova. |

**Regra de promoção.** Um grupo sai de `proposals/` para `latest/` só quando **todas** as decisões em
`pending_on` estiverem seladas, isto é, mergeadas no grafo do produto, **e** o schema de `spec/` já
aceitar o que o grupo exige (ex.: `trigger` em `integrity-trigger`). O PR da promoção esvazia
`pending_on` e cita o nó selado. Nada antecipa decisão aberta.

**O placar de hoje.** O leitor de referência passa em 100% de `latest/`: 222 casos contra o v4.3. Os grupos do
rascunho do v4 saíram de `proposals/` para `latest/form/` (`provenance-required`, `placeholder-source`,
`unknown-key`, `method-vocabulary`, `should-remains`), e os casos herdados do v3 que o v4 muda de veredito
viraram `bad-*`. Todo caso usa `method` canônico (`medição: caso de conformidade`), para que o aviso de
vocabulário só apareça onde o caso o pede. `proposals/` está vazia.

## Rodar

```bash
pip install -r tools/requirements.txt          # PyYAML e jsonschema, versões exatas
python3 -I tools/kg_conformance.py             # --suite DIR, --schema F, --should-schema F, --json OUT
# proposals/ contra um contrato candidato, quando houver um rascunho de versão futura
python3 -I tools/kg_conformance.py --proposals-schema <candidato>.schema.json \
  --proposals-should-schema <candidato>.should.schema.json
```

As duas opções `--proposals-*` vão juntas e medem só `proposals/` contra um contrato candidato; `latest/` e
`optional/` seguem no `--schema`, e o rc não muda.

rc `0` se `latest/` passa inteiro, `1` se algum caso de `latest/` falha e `2` se a própria suíte está
quebrada: metaschema ou manifesto ilegível ou inválido, `pending_on` fora da regra, pasta
desconhecida, arquivo ausente, repetido ou fora de todo manifesto, ou `latest/` vazia. Um leitor que
cai num caso conta como falha daquele caso. `optional/` (hoje só a camada `semantic`, que o leitor de referência
não implementa) e `proposals/` reportam
e nunca mudam o rc.

## O contrato de runner

Para ser medido caso a caso (a matriz leitor × caso do produto), um leitor implementa o **contrato de
runner**: `runner <caso>` imprime, na última linha do stdout, UM objeto JSON, e sai com rc 0:

```json
{"verdict": "accept" | "reject" | "error", "codes": [...] | null, "warnings": [...] | null, "detail": "..."}
```

- `verdict` é o nível 1, e todo leitor o tem: o arquivo é aceito ou reprovado? Um caso com `codes` MUST
  espera `reject`; um caso válido, mesmo com `warnings`, espera `accept`.
- `codes` é o nível 2, só para quem expõe motivo, comparado por conjunto nas camadas que o registro declara
  em `layers`. `null` quer dizer que o leitor não diz o porquê.
- **Caso de corpus** (v4.3): o caso que declara `corpus` no manifesto é julgado com a raiz desse diretório como o
  repo, e o runner recebe `runner <caso> --corpus <dir>`. Um leitor que não confere a ponta externa das
  `external_edges` fica `n/a` nesses casos.
- `error` quer dizer que o leitor caiu. Saída que não é JSON, `verdict` desconhecido, rc diferente de 0 ou
  tempo estourado também viram `error`. É divergência e nunca some da matriz.

## Higiene

Os casos são escritos aqui, sem copiar as fixtures do core, e usam ids sintéticos (`Q_A`, `EV_A`...),
sem caminho de máquina e sem id de nó privado (`EPIC_7_PUBLICATION_HYGIENE`). Este arquivo viaja na release
(`spec/release.json`): o que é operação do repo do produto (a matriz, a catraca, a paridade) não mora aqui, e o
a conferência de higiene do mantenedor reprova referência privada em `spec/` e nos arquivos da release.
