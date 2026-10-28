<!-- translation-of: docs/manual/04-contract.md sha256:ef4d3d84ea1b98fe -->
# 4. O contrato

[English](../04-contract.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← Referência do formato](03-formato.md) · [Índice](README.md) · [Ferramentas →](05-ferramentas.md)

## Dois níveis: MUST e SHOULD

| Nível | Arquivo | Efeito |
|---|---|---|
| **MUST** | `spec/kg-contract-v4.schema.json` | Reprova o arquivo. O leitor sai com rc 1 |
| **SHOULD** | `spec/kg-contract-v4.should.schema.json` | Só alerta. O arquivo segue válido |

Os dois são JSON Schema 2020-12 escritos à mão. Além deles, o contrato tem as regras de **perfil YAML** (um
documento só, chave duplicada, chave `on`) e as de **integridade** (ids, pontas, órfãos), que o JSON Schema não
vê. Por isso, um validador de JSON Schema sozinho não é um leitor completo: o leitor de referência aplica as três
camadas, e a suíte cobra as três de todo leitor.

O `format: date` do schema é **asserção**: a data tem de existir no calendário (`2026-02-30` reprova). Muitos
validadores tratam `format` como anotação por padrão, e por isso a suíte tem casos para isso.

## Códigos

Toda violação tem um código estável, com a forma da camada:

| Camada | Forma | Exemplos |
|---|---|---|
| parse | `parse.<motivo>` | `parse.yaml-error`, `parse.duplicate-key`, `parse.not-single-document` |
| form | `form.<tipo>.<escopo>.<campo>` | `form.required.node.label`, `form.enum.node.status`, `form.unknown-key.node.prioridade` |
| integrity | `integrity.<regra>` | `integrity.orphan-node`, `integrity.dangling-to` |
| yaml | `yaml.<regra>` | `yaml.forbidden-key-on` (MUST), `yaml.unquoted-date` (SHOULD) |

`<tipo>` é um de `required`, `enum`, `type`, `pattern`, `range`, `const` ou `unknown-key`. `<escopo>` é um de
`top`, `meta`, `node` ou `edge`. Num campo aninhado, o caminho leva ponto: `form.required.node.provenance.locator`.
Nas `external_edges`, o escopo é `top` e o campo leva o nome da lista
(`form.enum.top.external_edges.edge_type`). Uma data fora do calendário (`format: date`) reprova como `form.pattern.<escopo>.<campo>`.

A lista completa, com o que cada código pega, está em
[`spec/conformance/README.pt-BR.md`](../../../spec/conformance/README.pt-BR.md#códigos).

## Onde na fonte (v4.17)

O `locator` era texto livre: "linhas 10 a 12", "a seção License". Uma pessoa lê; uma ferramenta não confere. Desde o
v4.17, o nó pode dizer como lê-lo e guardar o hash do que leu. Os dois são opcionais e só alertam: nada que passava
reprova.

```yaml
provenance:
  source: "https://github.com/acme/brain/blob/9f2c1e0/docs/payments.md"
  locator: "line=41,44"
  method: "reading: a seção de retentativa"
  scheme: text
  sha256: "3f1d…"   # 64 dígitos hex minúsculos: o SHA-256 do arquivo naquele commit
```

| `scheme` | Norma | Locator | Conta a partir de |
|---|---|---|---|
| `json-pointer` | RFC 6901 | `/a/b`, ou `#/a/b` em fragmento (com percent-encoding, sem espaço cru) | — |
| `text` | RFC 5147 | `line=10`, `line=10,20`, `char=5,9`, com um `;length=N` opcional | 0, posições entre linhas ou caracteres; `char` conta code points, e cada quebra de linha (CRLF, LF ou CR) é um caractere |
| `csv` | RFC 7111 | `row=4;6-*`, `col=2`, `cell=4,2-6,3`: um tipo de seleção por vez, `*` para a última | 1 |
| `pdf` | RFC 8118 e ISO 32000-2 | `page=3`, entre outros parâmetros | 1, a página física |
| `media` | W3C Media Fragments | `t=10,20`, `t=npt:1:02:03` | segundos; o fim fica de fora |
| `quote` | W3C TextQuoteSelector | o texto exato | — |
| `html` | um fragmento HTML | `#id` | — |
| `kg-node` | este contrato | `#ID` ou `ID`, um nó do grafo nomeado no `source` | — |

As URIs do `conformsTo` do modelo Web Annotation do W3C valem como alias, inclusive a da RFC 3778, que a tabela dele
ainda usa para PDF. O hash vai num campo próprio: o `md5=` da RFC 5147 não é usado, porque o MD5 não resiste a colisão
(RFC 6151). Avisos: `form.enum.node.provenance.scheme`, `form.pattern.node.provenance.locator` (o locator não cabe no
esquema) e `form.pattern.node.provenance.sha256`. O `kg_trace check` então abre a fonte e confere o locator e o hash
(capítulo 5). O que as normas deixam em aberto é decisão deste contrato, escrita como tal: o JSON Pointer que não
resolve numa fonte JSON reprova no `kg_trace`, o `char` conta code points em todo leitor, linhas e colunas do CSV
contam a partir de 1 e se escrevem sem zero à esquerda (a RFC 7111 aceita `0` e `01`), e o intervalo de mídia exclui
o fim. A forma não confere o que só a fonte diz, como o início
depois do fim ou a linha que não existe: isso é do `kg_trace`.

## O que mudou do v3 para o v4

O v4 é uma versão **maior**: o que alertava passou a reprovar.

| Código | v3 | v4 |
|---|---|---|
| `form.required.node.provenance` (nó `confirmed` ou PROD sem `provenance`, fora o `unverifiable`) | SHOULD | **MUST** |
| `form.unknown-key.<escopo>.<chave>` (chave fora da gramática, sem `x_`) | SHOULD | **MUST** |
| `form.pattern.<escopo>.key` (nome de chave que não é slug, sem `x_`) | SHOULD | **MUST** |
| `form.pattern.node.provenance.source` (`source` marcador) | — | **MUST** |
| `form.pattern.node.provenance.method` (fora de `<classe>: <detalhe>`) | — | SHOULD (MUST no v5) |

As versões menores da linha 4.x acrescentaram recursos sem mudar o veredito MUST de um grafo bem escrito, com uma exceção
registrada: a 4.11.0, a 4.12.0 e a 4.13.0 passaram a reprovar construções raras do YAML (o perfil estrito). Foram
menores porque nenhum dos grafos reais medidos em quatro repositórios adotantes mudou de veredito. Mesmo assim, contam
como MUST novo para o critério de estável, e cada uma zerou o relógio de 30 dias. Desde a 4.11.0, o contrato tem
rótulo de versão próprio (v4.4 na 4.11.0, v4.5 na 4.12.0, v4.6 na 4.13.0, v4.7 na 4.14.0, v4.8 na 4.15.0, v4.9 na 4.15.1 e na
4.16.0, v4.10 da 4.16.1 à 4.18.0, v4.11 na 4.19.0 e na 4.20.0, v4.12 na 4.21.0, v4.13 na 4.22.0, v4.14 da 4.23.0 à 4.26.0, v4.15 da 4.27.0 à 4.31.1, v4.16 da 4.32.0 à 4.36.0, v4.17 desde a 4.37.0), que não é o número da release.

| Release | O que entrou |
|---|---|
| 4.1 | Quatro avisos SHOULD: `verified_against` ausente em claim carimbada, `testemunho` em PROD, verificação antes do fato, decisão sem origem |
| 4.2 | `provenance.locality`, e a dívida SHOULD do gate contada por ocorrência, como opção |
| 4.3 | `external_edges`, com a ponta externa conferida contra o corpus |
| 4.4 | O exportador de proveniência para PROV-O (`kg_prov_export.py`) |
| 4.5 | O veredito estruturado `kg-ssot.verdict/1` (`kg_validate.py --format json`) |
| 4.6 | O armazém que só grava o que o contrato aprova (`kg_store.py`) |
| 4.7 | O servidor MCP de referência (`kg_mcp.py`) e os limites de aninhamento e de aliases do leitor |
| 4.8 | O `.kg.json` como formato do contrato, lido no perfil JSON; o vendor com o próprio `.gitattributes` (4.8.1) e o veredito com a linha de cada ocorrência (4.8.2) |
| 4.9 | O pacote PyPI (`kg-ssot`) e o pacote npm; na 4.9.1, o armazém no Windows |
| 4.10 | O servidor MCP pronto para produção: perfil atrás de proxy, as duas eras do protocolo, o gate externo por comando e a imagem OCI |
| 4.11 | Contrato v4.4: o aviso `integrity.refutes-unreconciled` e o perfil YAML estrito em três construções raras (MUST novo) |
| 4.12 | Contrato v4.5: `verified_scope`, `locality: privado`, as `REFUTES` externas contadas com o corpus, e o tab no começo de continuação entre aspas (MUST novo) |
| 4.13 | Contrato v4.6: a continuação entre aspas mais indentada que a coleção dona (MUST novo) e o `\r` como quebra de linha no leitor JS; na 4.13.1, a identidade do contrato acusa a versão que só o leitor muda, e o migrador lê o corpus do gate |
| 4.14 | Contrato v4.7: a ponta externa pode ser um `.kg.json`; o armazém grava um conjunto de grafos de uma vez (`write_many`) |
| 4.15 | Contrato v4.8: a cadência da verificação (`reverify_every`, `reverify_on`), a retenção (`retain_for`), o `owner` como papel e o relatório de vencimento (`kg_validate.py --due`), fora do veredito; na 4.15.1, o contrato v4.9 deixa de alertar a cadência sem `verified_at`, que é o estado inicial de uma regra de coleta |
| 4.16 | Contrato v4.9, sem mudança. O gate sem atrito: a base vira uma pasta com um registro por grafo, e a troca de identidade do contrato sem veredito trocado passa com aviso; na 4.16.1, o contrato v4.10 alinha os dois leitores em três pontos do perfil YAML, sem veredito trocado na referência |
| 4.17 | Contrato v4.10, sem mudança. A consulta e a projeção (`kg_query.py`, e a ferramenta `kg_query` no MCP) e o diff por id entre revisões (`kg_diff.py`); na 4.17.1, o código vendorizado e os fixtures fora do corpus por padrão, e os campos renomeados detectados pelo `kg_diff`; na 4.17.2, as anotações de ferramenta no servidor MCP |
| 4.18 | Contrato v4.10, sem mudança. O inglês passa a ser a língua-fonte da documentação, com a tradução pt-BR completa ao lado; as ferramentas imprimem a saída humana em inglês por padrão, e em pt-BR com `KG_SSOT_LANG=pt-BR` ou um locale `pt_BR` |
| 4.19 | Contrato v4.11: `meta.title` e `meta.slug` viram chaves conhecidas, e o SHOULD ganha os perfis canônicos de `x_` (`x_term` para o vocabulário de domínio, `x_mirror`, `x_doc_cycle`, `x_questionnaire`, `x_severity`, e `x_confidence` e `x_provisional` na aresta); a ferramenta do vocabulário (`kg_vocab.py`, com exportação para SKOS-XL e Apache Ossie, e a ferramenta `kg_terms` no servidor MCP) e o `kg_migrate.py keys`, que renomeia chave estranha para `x_` |
| 4.20 | Contrato v4.11, sem mudança. O armazém guarda o veredito de cada grafo julgado e deixa de julgar de novo o que não mudou; o carimbo `.kg-ssot-version` vira a regra pública do vendor em toda ferramenta; o `kg_diff.py` dá nome à árvore de trabalho (`WORKTREE`) |
| 4.21 | Contrato v4.12: o critério pré-registrado, com os perfis SHOULD `x_criterion` e `x_measured_under`, cinco avisos de coerência nos dois leitores, e o `kg_criterion.py`, que confere o `sha256` contra o texto ou o arquivo e segue a citação de outro grafo; o `kg_migrate.py nest`, que leva as chaves `x_` próprias de um adotante para um perfil canônico |
| 4.22 | Contrato v4.13: o `x_questionnaire.role` (`item`, `evidence_request` ou `evidence_requirement`) no SHOULD; o pacote de auditoria por pergunta, `kg_audit.py`, em CSV, XLSX ou JSON |
| 4.23 | Contrato v4.14: o `x_term.scheme` e o aviso `integrity.term-notation-duplicate`, para um código curto levar nome legível no próprio vocabulário; o `kg_vocab.py` resolve um código (`esquema:código`) e ganha o `lint`, com catraca, para os códigos da prosa; o `kg_query.py --text` sem acento, pelo vocabulário e com aviso no zero |
| 4.24 | O `kg_vendor.py update --ref` para a bancada antes da tag; o `check` e o `kg_gate.py` recusam o vendor de bancada sem `--allow-unreleased` |
| 4.25 | O `kg_trace.py`, o trace que não resolve: a âncora `trace:` de cada nó contra os arquivos do repositório |
| 4.26 | O `kg_query --semantic`, a busca opcional por semelhança (o extra `vector`, `kg_vector.py`), fundida ao `--text` por RRF |
| 4.27 | Contrato v4.15: a ponta externa pode começar por uma pasta com ponto (`.github/`, `.config/`); o `kg_trace` sai com rc 3 no corpus vazio |
| 4.28 | Contrato v4.15, sem mudança. `kg_prov_export.py --edges`: as arestas vão para o PROV-O como relações qualificadas |
| 4.29 | Contrato v4.15, sem mudança. O extra `rdf` lê a exportação PROV, e o `kg_prov_export.py --full` exporta o documento inteiro; na 4.29.1, a ponta de aresta malformada vai como literal |
| 4.30 | Contrato v4.15, sem mudança. A skill de agente (`skills/kg-ssot/`, formato Agent Skills) e o marketplace de plugin do Claude Code |
| 4.31 | Contrato v4.15, sem mudança. O site de documentação e a demo, publicados só no repositório público (`mirror_only`); na 4.31.1, o site renderiza os blocos de código |
| 4.37 | Contrato v4.17, só SHOULD: `provenance.scheme` (como ler o locator: `json-pointer`, `text`, `csv`, `pdf`, `media`, `quote`, `html`, `kg-node`) e `provenance.sha256` (o hash do que foi lido, num campo próprio); o `kg_trace check` lê a fonte pelo esquema e pelo hash, também num commit fixado de outro repositório com `--with` |
| 4.36 | Contrato v4.16, sem mudança. `kg_query --sort attention` (a fórmula do radar), `--decision` (a história de uma decisão) e `--revisit` (as decisões vivas a revisitar, com o motivo) |
| 4.35 | Contrato v4.16, sem mudança. Python 3.12 ou mais. O `kg_query --chain --with` segue a corrente para outro repositório no commit citado; o `kg_trace.py projection` confere as páginas Markdown que declaram `projection_of`; o `kg_trace check` segue um `provenance.locator` em JSON Pointer dentro do arquivo JSON |
| 4.34 | Contrato v4.16, sem mudança. O `kg_query --chain` segue primeiro o `provenance.source`, e uma origem sem `provenance.source` sai marcada e deixa a corrente `weak` |
| 4.33 | Contrato v4.16, sem mudança. `kg_query --chain`: a cadeia de transmissão de um nó até a origem, com o elo mais fraco e a força da origem em eixos separados, e um grau estrito e um leniente |
| 4.32 | Contrato v4.16: a classe de `provenance.method` ganha forma canônica em inglês (`measurement`, `reading`, `judges`, `derived`, `testimony`), e as palavras em português seguem aceitas como alias |

## Versões e tags

A release é uma tag `kg-ssot-vX.Y.Z` (até a 4.3.0, o nome era `contract-vX.Y.Z`; as tags antigas seguem
existindo). Pelo histórico das releases:

| Parte | Quando sobe |
|---|---|
| **X**, maior | Um veredito MUST muda: algo que passava reprova |
| **Y**, menor | O kit ganha um aviso SHOULD, um campo opcional ou uma ferramenta ou formato novo, e nenhum veredito MUST de grafo bem escrito muda |
| **Z**, patch | Correção ou melhoria do kit, do guia ou dos casos, com o mesmo contrato |

O gate guarda o sha256 dos dois schemas como a identidade do contrato. Uma tag que muda os bytes dos schemas,
mesmo que só no texto das descrições (a 4.7.2) ou no `$id` (a 4.7.3), muda a identidade. Desde a 4.16.0, a
identidade é composta: o gate acusa a troca numa linha `· identidade`, mas quem decide o rc é a comparação, feita
com o contrato novo. A troca que não muda veredito nenhum passa com rc 0, e o `--update` grava a identidade nova quando
você escolher. A regra nova que piora um grafo reprova pela comparação. `--strict-identity` volta ao rc 1 em
toda troca, como antes da 4.16.0. Rodando de um vendor, o gate confere o sha256 dos dois schemas contra o carimbo e
reprova o schema editado à mão. Uma regra que só o leitor vê (o perfil YAML, a quebra de linha) também entra na descrição
do schema MUST, numa linha que começa com "No v4.6 ..." (as descrições do schema estão em português): desde a 4.13.1, a higiene da release cobra essa linha para a versão que o leitor
declara, e assim toda versão do contrato move a identidade.

Um aviso SHOULD novo pode subir a dívida medida pelo gate. Isso é intencional: a rampa de um contrato é alertar
numa versão e reprovar na seguinte, e assim você vê a dívida antes de ela virar erro.

A superfície que viaja em cada tag está listada em [`spec/release.json`](../../../spec/release.json). Você não customiza o
contrato no seu repositório: o vendor reprova edição local, e uma mudança necessária volta ao produto como issue no
repositório público.

## Os contratos antigos

O repositório do produto guarda o v1, o v2 e o v3 em `spec/` como histórico; a release leva só o v4, o vigente, que
é o que o leitor usa sem `--schema`.
