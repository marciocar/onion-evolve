# 5. Ferramentas

[← O contrato](04-contrato.md) · [Índice](README.md) · [Adoção e CI →](06-adocao-e-ci.md)

As sete ferramentas que viajam na release ficam em `tools/` e dependem só de Python 3 com as versões fixadas em
[`tools/requirements.txt`](../../tools/requirements.txt) (PyYAML e jsonschema, mais as dependências do jsonschema).

```bash
python3 -m venv .venv && .venv/bin/pip install -r tools/requirements.txt
```

Todo `rc` segue a mesma convenção: **0** passou, **1** algo reprovou, **2** a entrada está quebrada (arquivo
ilegível, base ausente, tag inexistente). Um rc 2 nunca passa por verde.

Os exemplos abaixo rodam num repositório de demonstração com o kit em `vendor/kg-ssot`. Num clone do produto,
troque `vendor/kg-ssot/tools/` por `tools/`.

## `kg_validate.py`: o leitor de referência

Valida um ou mais arquivos contra o contrato vigente.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/exemplo.kg.yaml docs/quebrado.kg.yaml
```

```text
PASSA   docs/exemplo.kg.yaml
REPROVA docs/quebrado.kg.yaml
  MUST   form.required.node.provenance ×1 · form.unknown-key.node.prioridade ×1
  SHOULD form.required.node.verified_against ×1 · integrity.untraced-decision ×1 · yaml.unquoted-date ×1
· 2 arquivos; 1 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

rc 1. Para saber **em qual nó** cada código sai, `--where`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/quebrado.kg.yaml
```

```text
REPROVA docs/quebrado.kg.yaml
  MUST   form.required.node.provenance ×1 · form.unknown-key.node.prioridade ×1
  SHOULD form.required.node.verified_against ×1 · integrity.untraced-decision ×1 · yaml.unquoted-date ×1
    MUST   form.required.node.provenance  nó C_RETRY_SAFE
    MUST   form.unknown-key.node.prioridade  nó C_RETRY_SAFE
    SHOULD form.required.node.verified_against  nó C_RETRY_SAFE
    SHOULD integrity.untraced-decision  nó D_RETRY_POLICY
    SHOULD yaml.unquoted-date  arquivo
· 1 arquivos; 0 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

Opções úteis:

| Opção | Efeito |
|---|---|
| `--where` | Uma linha por ocorrência, com o nó ou a aresta |
| `--corpus DIR` | Confere a ponta externa das `external_edges` contra os `.kg.yaml` rastreados pelo git sob `DIR` (fora de um repo git, todos) |
| `--schema F` | Valida contra outro MUST (o SHOULD vizinho vem junto, se existir) |
| `--format json` | O veredito estruturado em stdout (ver abaixo), para ferramentas e servidores MCP |
| `--limit N` | Com `--format json`, quantas ocorrências por arquivo (default 50); o resumo conta todas |
| `-` no lugar do arquivo | Lê o grafo do stdin, sem gravar arquivo temporário |
| `--json OUT` | Grava o resultado no formato do spike (`{summary, results}`), congelado; não é o veredito |

Com `external_edges` e sem `--corpus`, o leitor avisa que não conferiu a ponta externa:

```text
PASSA   docs/decisao.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 1 arquivo(s) com external_edges: a ponta externa NÃO foi conferida (rode com --corpus <raiz do repo>)
```

### O veredito estruturado (`--format json`)

Para quem chama o leitor por programa (um CI, um servidor MCP, um chat), o `--format json` devolve o veredito num
formato versionado, `kg-ssot.verdict/1`, com JSON Schema em `spec/verdict.schema.json`. Saída real de um caso da
suíte:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --format json \
  vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml
```

```text
{
 "schema_version": "kg-ssot.verdict/1",
 "contract": {
  "must": "spec/kg-contract-v4.schema.json",
  "should": "spec/kg-contract-v4.should.schema.json",
  "release": "kg-ssot-v4.7.0",
  "sha256": { "must": "6277fc83…", "should": "034e3a6e…" }
 },
 "results": [
  {
   "source": "…/bad-node-missing-label.kg.yaml",
   "verdict": "FAIL",
   "summary": { "MUST": { "form.required.node.label": 1 }, "SHOULD": {} },
   "occurrences": [
    {
     "level": "MUST",
     "code": "form.required.node.label",
     "place": "nó Q_A",
     "path": "nodes[0]",
     "line": 5,
     "message": "Falta o campo obrigatório «label» no nó."
    }
   ],
   "total": 1,
   "truncated": false,
   "external_checked": true
  }
 ]
}
```

(Os dois sha256 e o caminho estão abreviados aqui.)

- **O que é estável:** `code` é o vocabulário da suíte e do gate, e é por ele que uma ferramenta decide. `message` e
  `hint` são texto para pessoas e podem mudar.
- **O lugar da ocorrência:** `path` aponta no documento (`nodes[7].provenance.method`) e `line` é a linha do YAML,
  para quem edita corrigir o ponto certo sem reescrever o grafo.
- **O corte:** `summary` conta todas as ocorrências. `occurrences` traz até `--limit`, e `truncated` e `total` dizem
  se cortou. Assim um grafo grande não enche o contexto de um modelo.
- **O contrato que julgou:** `contract` traz o caminho, o sha256 de cada schema e a release, para quem precisa provar
  qual contrato julgou.
- **O rc:** 0 quando todos passam, 1 quando algum reprova (um arquivo que não parseia reprova com `parse.*`, como na
  suíte) e 2 quando a entrada está quebrada (arquivo ilegível, opção inválida).
- **O desempenho:** com a libyaml instalada (o caso comum do PyYAML), o parse usa o parser em C, com o mesmo perfil
  YAML 1.2. Um grafo de 6.376 nós sai em segundos.

## `kg_conformance.py`: a suíte

Roda a suíte de conformidade contra o leitor de referência. Primeiro o metaschema se auto-testa, depois cada
manifesto é validado, depois cada caso roda.

```bash
python3 -I tools/kg_conformance.py
```

As últimas linhas:

```text
—
latest: 225/225 (reprova)
optional: 10/24 (só reporta)
```

rc 0. `latest/` é o contrato vigente, e um caso que falha ali reprova (rc 1). `optional/` é comportamento que um
leitor **pode** implementar (hoje, a camada semântica de frescor e domínio, que o leitor de referência não
implementa) e nunca muda o rc. rc 2 quer dizer que a própria suíte está quebrada: manifesto inválido, arquivo
fora de manifesto, pasta desconhecida.

## `kg_gate.py`: a catraca por grafo

O gate é para o CI de um repositório que guarda grafos. Ele mede todos os `.kg.yaml` **rastreados pelo git** e
compara com uma linha de base (`.kg-ssot/gate.json`). A regra: **nada piora**. Um grafo que já reprovava fica
registrado como dívida herdada; um grafo novo tem de passar.

Sem base, o gate se recusa:

```text
GATE QUEBRADO  linha de base ausente (.kg-ssot/gate.json): grave a primeira com --update
```

rc 2. A primeira base:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

```text
  MUST   docs/quebrado.kg.yaml (herdado): form.required.node.provenance · form.unknown-key.node.prioridade
  SHOULD form.required.node.verified_against: 1 grafo
  SHOULD integrity.untraced-decision: 1 grafo
  SHOULD yaml.unquoted-date: 1 grafo
linha de base gravada: .kg-ssot/gate.json (2 grafos, 1 na dívida herdada)
```

Um grafo novo que reprova, depois de `git add`:

```text
✗ PIOROU  docs/novo.kg.yaml falha no MUST: form.required.node.provenance, form.unknown-key.node.prioridade
✗ PIOROU  debt.form.required.node.verified_against: 1 → 2
✗ PIOROU  debt.integrity.untraced-decision: 1 → 2
✗ PIOROU  debt.yaml.unquoted-date: 1 → 2
· 3 grafos; 1 passam no MUST; 1 na dívida herdada
  MUST   docs/novo.kg.yaml (novo): form.required.node.provenance · form.unknown-key.node.prioridade
  MUST   docs/quebrado.kg.yaml (herdado): form.required.node.provenance · form.unknown-key.node.prioridade
  SHOULD form.required.node.verified_against: 2 grafos
  SHOULD integrity.untraced-decision: 2 grafos
  SHOULD yaml.unquoted-date: 2 grafos
```

rc 1. E quando a dívida é paga (o grafo herdado consertado):

```text
↑ melhorou docs/quebrado.kg.yaml: passa no MUST (trave o ganho: kg_gate.py --update)
↑ melhorou debt.form.required.node.verified_against: 1 → 0 (trave o ganho: kg_gate.py --update)
↑ melhorou debt.integrity.untraced-decision: 1 → 0 (trave o ganho: kg_gate.py --update)
↑ melhorou debt.yaml.unquoted-date: 1 → 0 (trave o ganho: kg_gate.py --update)
· 2 grafos; 2 passam no MUST; 0 na dívida herdada
```

rc 0, com o pedido de travar o ganho. Rode `--update` no mesmo PR para a dívida não voltar.

| Opção | Efeito |
|---|---|
| `--update` | Grava a base. Se algo piorou, recusa sem `--accept-regression` |
| `--accept-regression "<motivo>"` | Aceita uma piora; o motivo fica gravado na base |
| `--exclude GLOB` | Tira caminhos do corpus (repetível). `*/fixtures/*` e `docs/materials/*` já saem por padrão |
| `--granularity node` | Com `--update`: conta a dívida SHOULD por ocorrência, não por grafo |
| `--repo DIR` · `--baseline ARQ` | Outro repositório, outra base |

## `kg_vendor.py`: trazer e conferir a release

O adotante nunca copia o contrato à mão. O vendor lê uma **tag** com `git archive` e grava um carimbo com o
sha256 de cada arquivo.

Da raiz do adotante, com um clone do produto em `<clone>`. As saídas abaixo são de uma execução real com a tag
`kg-ssot-v4.3.3`; numa release mais nova, a tag, o commit e a contagem de arquivos mudam:

```bash
python3 -I -B <clone>/tools/kg_vendor.py update --tag kg-ssot-v4.3.3 --dest vendor/kg-ssot --source <clone>
```

```text
vendor atualizado: vendor/kg-ssot ← kg-ssot-v4.3.3 (c32e6496be74), 297 arquivos
```

O `check` recalcula os sha256 e compara com o carimbo. Um arquivo editado, apagado ou sobrando (inclusive
bytecode num `__pycache__`) dá rc 1.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
```

```text
✓ vendor íntegro: vendor/kg-ssot = kg-ssot-v4.3.3 (c32e6496be74), 297 arquivos
```

| Opção | Efeito |
|---|---|
| `--source REPO` | O repositório (caminho ou URL) que tem a tag. Obrigatório quando roda de dentro de um vendor |
| `--profile gate` | Traz só o mínimo para rodar o gate e o check (10 arquivos, sem a suíte) |
| `--force` | Substitui um vendor editado localmente |

**Por que `-B`?** Os scripts do kit não gravam bytecode, mas uma ferramenta sua que **importa** um módulo do kit
grava o `.pyc` dentro do vendor, e o próximo `check` reprova. Rode tudo com `python3 -I -B`, ou com
`PYTHONDONTWRITEBYTECODE=1`.

## `kg_store.py`: o armazém que só grava o que passa

Para quem grava grafo por programa (um servidor de escrita, um chat, um pipeline que gera o grafo de um caso), o
`kg_store.py` é uma biblioteca, com um CLI por cima, que só escreve depois do veredito PASS do contrato. Há três
armazéns com a mesma interface (`read`, `list`, `write`, `delete`, `history`):

- `DiskStore`: só a cabeça em disco, sem histórico;
- `GitStore`: um commit por gravação ou remoção. O git roda isolado na raiz do armazém e nunca sobe para um repo
  de fora. O autor vem de quem grava (`author="Nome <email>"`), e o committer é fixo do serviço;
- `VersionedStore`: a cabeça em disco mais um registro de eventos e as versões no diretório oculto `.kg-store/`,
  sem git.

```python
import kg_store

store = kg_store.GitStore("areas/ana", init=True)
r = store.write("grafos/caso.kg.yaml", texto, message="primeiro grafo", author="Ana <ana@example.org>",
                expected_sha256=kg_store.NEW)
if not r["written"]:
    print(r["reason"], r["verdict"])   # "gate", "conflict", "missing" ou "not_judged"
```

O gate julga mais que o candidato. A ponta das `external_edges` é conferida contra o próprio armazém, já com o
candidato no lugar. Cada grafo que aponta para o nome gravado é julgado de novo, porque trocar ou apagar um grafo
pode deixar a aresta externa de outro sem ponta. Só grava com PASS em todos.

O corpus é o mesmo que o gate do repo veria. No `GitStore`, isso quer dizer só o rastreado: um `.kg.yaml` que está no
disco sem commit não conta, nem na lista, nem no julgamento, nem na trava (para ela, o nome está livre, e a gravação
o substitui). O `DiskStore` e o `VersionedStore` recusam uma raiz dentro
de um repo git, onde o gate leria o rastreado e o armazém leria o disco. E a cabeça só fica trocada com o registro
feito: se o commit ou o evento falha, ela volta ao que era, e a exceção sobe para quem chamou.

Pelo CLI, um grafo que passa e um que reprova:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_store.py --backend git --root areas/ana --init \
  write grafos/valid-minimal.kg.yaml vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/valid-minimal.kg.yaml \
  --author "Ana <ana@example.org>" --message "primeiro grafo"
```

```text
{
 "written": true,
 "reason": null,
 "name": "grafos/valid-minimal.kg.yaml",
 "sha256": "b725f37669f2e5979ed8c02eaae3c59ba80a490177e2f28c0cb8a580cf51cfd7",
 "ref": "f47e4737c147d2e4a070bd8d07948075373814e0",
 "verdict": { … },
 "error": null,
 "unchanged": false
}
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_store.py --backend git --root areas/ana \
  write grafos/x.kg.yaml vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml
```

```text
{
 "written": false,
 "reason": "gate",
 "name": "grafos/x.kg.yaml",
 ...
 "verdict": { "results": [ { "source": "grafos/x.kg.yaml", "verdict": "FAIL",
              "summary": { "MUST": { "form.required.node.label": 1 }, "SHOULD": {} }, ... } ] }
}
```

(O `verdict` está abreviado aqui; ele é o documento `kg-ssot.verdict/1` inteiro.)

- **`reason`:** é `null` quando gravou. `"gate"` quer dizer que o contrato reprovou, e o `verdict` diz onde.
  `"conflict"` quer dizer que o `expected_sha256` não bate com a cabeça. `"missing"` aparece ao remover o que não
  existe. `"not_judged"` aparece quando o julgamento falhou ou saiu fora de `spec/verdict.schema.json`: nunca vira
  PASS nem `"gate"`, para quem chama distinguir "reprovou" de "não deu para julgar".
- **A trava otimista:** `expected_sha256` é o sha256 da cabeça que quem grava leu, ou `NEW` (no CLI, `new`) para
  exigir que o nome ainda não exista. Gravar o mesmo texto da cabeça dá `written` com `unchanged` e sem commit.
- **O caminho:** o nome é relativo, termina em `.kg.yaml` e não tem `..` nem segmento oculto. Raiz, pastas e arquivo
  não podem ser symlink: tudo se abre com `O_NOFOLLOW`, o que exige POSIX.
- **O histórico:** `history(nome)` lista as operações, da mais nova para a mais antiga, com `ref`, `op`
  (`write` ou `delete`), autor, data e mensagem. `read(nome, ref=...)` lê uma versão anterior: o sha do commit no
  git, o `seq` do evento no versionado.
- **O git isolado:** o `GitStore` não lê a config do sistema nem a do usuário (sem hooks, sem gpg, sem `autocrlf`, sem
  arquivo de exclusão), então o que ele guarda é byte a byte o texto aprovado, com o sha256 do resultado.
- **O que fica com quem adota, de propósito:** autenticação, identidade, área por usuário (um root por usuário),
  tamanho máximo, número de grafos, timeout e a trava entre processos onde não há `flock`.
- **O rc do CLI:** 0 gravou ou leu, 1 recusado (`gate`, `conflict`, `missing`, nome inexistente) e 2 entrada
  quebrada ou `not_judged`.

## `kg_mcp.py`: o servidor MCP de referência

Para dar a um modelo o contrato e o armazém sem escrever um servidor, o `kg_mcp.py` fala o
[Model Context Protocol](https://modelcontextprotocol.io) por stdio (uma mensagem JSON-RPC por linha) ou por HTTP
(`POST /mcp`, resposta JSON, sem stream). Ele usa só a biblioteca padrão, o leitor e o armazém, e é um adaptador: o
produto não depende dele, e ele não depende de um cliente específico.

| Ferramenta | O que faz |
|---|---|
| `kg_validate` | julga um texto `.kg.yaml` sem gravar e devolve o `kg-ssot.verdict/1` (com o armazém como corpus, se há armazém) |
| `kg_write` | grava pelo armazém, só com PASS; devolve o resultado do `kg_store` com o veredito |
| `kg_delete` | remove pelo armazém, se nenhum grafo que aponta para o nome reprovar sem ele |
| `kg_get` | lê um grafo, ou uma versão anterior com `ref` |
| `kg_list` | lista os grafos do armazém |
| `kg_history` | as operações de um grafo, da mais nova para a mais antiga |
| `kg_schema_help` | o contrato vigente para um modelo: os schemas MUST e SHOULD inteiros, um exemplo mínimo que passa, as regras de integridade e a correção dos códigos mais comuns |

Sem `--root`, só `kg_validate` e `kg_schema_help` aparecem. Com `--read-only`, `kg_write` e `kg_delete` somem da lista.

Uma configuração de cliente por stdio, com um armazém versionado fora do repo:

```json
{
  "mcpServers": {
    "kg-ssot": {
      "command": "python3",
      "args": ["-I", "-B", "vendor/kg-ssot/tools/kg_mcp.py",
               "--root", "/caminho/do/armazem", "--backend", "versioned", "--init",
               "--author", "Assistente <assistente@example.org>"]
    }
  }
}
```

Uma gravação recusada, como o modelo a recebe (o `structuredContent`, abreviado):

```text
{
 "written": false,
 "reason": "gate",
 "name": "grafos/x.kg.yaml",
 "verdict": { "results": [ { "verdict": "FAIL",
   "occurrences": [ { "code": "form.required.node.label", "place": "nó Q_A", "path": "nodes[0]", "line": 5,
                      "message": "Falta o campo obrigatório «label» no nó.",
                      "hint": "Acrescente label: a afirmação curta do nó, até 280 caracteres." } ] } ] },
 ...
}
```

A resposta de `tools/call` traz o mesmo objeto em `structuredContent` e, como texto JSON, em `content`. Uma
gravação recusada ou um nome inexistente vem com `isError: true`, para o modelo corrigir e tentar de novo.

- **Quem assina:** o autor das gravações é o `--author` do servidor, nunca um argumento da ferramenta. O modelo não
  escolhe quem assina.
- **Os limites:** `--max-bytes` (padrão 2.000.000) limita o texto de um grafo. Os argumentos são conferidos contra o
  `inputSchema` que o `tools/list` anuncia: tipo errado, campo obrigatório ausente e campo desconhecido voltam como
  `isError`. Uma falha interna vira o erro JSON-RPC -32603, e o processo segue atendendo.
- **O leitor por trás:** um documento que abre mais de 1.000 coleções de uma vez (em flow, em bloco ou por
  indentação), ou cujos aliases expandem para mais que o dobro do tamanho do texto, reprova com `parse.yaml-error`
  antes de ser construído. Sem esse teto, uma mensagem de 60 KB derrubava o processo. Colchete dentro de texto não
  conta.
- **O protocolo:** uma mensagem por vez; lote JSON-RPC é recusado (saiu do MCP em 2025-06-18), e o id tem de ser texto
  ou inteiro. O stdio lê e escreve UTF-8 como bytes, independente do locale, e a resposta sai em JSON ASCII.
- **O HTTP:** escuta em `127.0.0.1` por padrão. Recusa `Origin` cujo host não seja de loopback (contra DNS
  rebinding), `MCP-Protocol-Version` desconhecida (400) e corpo sem `Content-Length`. Não há autenticação nem TLS: o
  servidor só sai do loopback com `--allow-remote`, para rodar atrás de um proxy que faça os dois.
- **Num repo:** o armazém de disco e o versionado recusam raiz dentro de um repo git (veja o `kg_store.py`). Dentro
  do repo, use `--backend git --root .`, que faz um commit por gravação no branch atual, ou rode sem `--root` para
  só julgar.
- **O que fica com quem adota, de propósito:** autenticação, TLS, identidade, multiusuário e área por usuário (um
  processo ou um root por usuário), cota e timeout.
- **As versões do protocolo:** o servidor negocia `2025-11-25`, `2025-06-18`, `2025-03-26` e `2024-11-05`, e
  responde com a pedida quando a conhece.

## `kg_prov_export.py`: a proveniência em PROV-O

Exporta um `.kg.yaml` para [PROV-O](https://www.w3.org/TR/prov-o/) em JSON-LD, para quem já usa ferramentas do
ecossistema W3C PROV. Cada nó vira uma `prov:Entity`. Um nó com `provenance` ganha `prov:wasDerivedFrom` para a
fonte e uma `prov:Derivation` cuja atividade carrega o `method`; o `locator` e a `locality` vão como propriedades
`kg:`. Uma fonte que é inteira uma URL http(s) vira a própria IRI; qualquer outra (um caminho, um comando, duas
URLs juntas) vira um nó em branco rotulado, um por texto distinto, para que nós com a mesma fonte apontem para a
mesma entidade.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_prov_export.py \
  vendor/kg-ssot/spec/conformance/fixtures/latest/form/method-vocabulary/valid-method-leitura.kg.yaml
```

Trecho da saída, o nó com `provenance`:

```text
   "@id": "urn:kg-ssot:graph:valid-method-leitura#EV_A",
   "@type": "prov:Entity",
   ...
   "prov:wasDerivedFrom": {
    "@id": "_:source0"
   },
   "prov:qualifiedDerivation": {
    "@type": "prov:Derivation",
    "prov:entity": {
     "@id": "_:source0",
     "rdfs:label": "Fonte A"
    },
    "prov:hadActivity": {
     "@type": "prov:Activity",
     "rdfs:label": "leitura: seção 3 do documento A"
    },
    "kg:locator": "caso de conformidade"
   }
```

O que ele **não** exporta, de propósito:

- **As arestas.** `SUPPORTS`, `REFUTES` e as outras são relações de evidência, e derivação em PROV é relação de
  produção. Exportá-las como `wasDerivedFrom` diria algo que o grafo não diz.
- **O carimbo como tempo de geração.** `verified_at` sai como `kg:verifiedAt` (tipado `xsd:date` quando é uma data),
  não como `prov:generatedAtTime`: em PROV, o tempo de geração marca quando a entidade passou a existir, não quando
  foi conferida.

O exportador não valida o grafo: rode o `kg_validate.py` antes. `--base IRI` troca o prefixo das IRIs dos nós
(o default é `urn:kg-ssot:graph:`, e cada nó fica em `<base><meta.id>#<id>`); o vocabulário `kg:` mora em
`urn:kg-ssot:vocab#`, fora desse espaço. rc 2 quando o arquivo é ilegível, não é um documento YAML único ou tem
`meta` ou `nodes` fora da forma.
