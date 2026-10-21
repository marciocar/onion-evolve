# 5. Ferramentas

[← O contrato](04-contrato.md) · [Índice](README.md) · [Adoção e CI →](06-adocao-e-ci.md)

As oito ferramentas que viajam na release ficam em `tools/` e dependem só de Python 3.11 ou mais com as versões fixadas, e com hash, em
[`tools/requirements.txt`](../../tools/requirements.txt) (PyYAML e jsonschema, mais as dependências do jsonschema).

```bash
python3 -m venv .venv && .venv/bin/pip install --require-hashes -r tools/requirements.txt
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
| `--where` | Uma linha por ocorrência, com o nó ou a aresta; numa ocorrência MUST, a correção vem logo abaixo |
| `--corpus DIR` | Confere a ponta externa das `external_edges` contra os `.kg.yaml` e `.kg.json` rastreados pelo git sob `DIR` (fora de um repo git, todos) |
| `--schema F` | Valida contra outro MUST (o SHOULD vizinho vem junto, se existir) |
| `--format json` | O veredito estruturado em stdout (ver abaixo), para ferramentas e servidores MCP |
| `--limit N` | Com `--format json`, quantas ocorrências por arquivo (default 50); o resumo conta todas |
| `-` no lugar do arquivo | Lê o grafo do stdin, sem gravar arquivo temporário |
| `--should-schema F` | Com `--schema`, o SHOULD que acompanha (no lugar do vizinho) |
| `--due AAAA-MM-DD` | No lugar do veredito, o relatório de vencimento na data (desde a 4.15.0): o nó com `reverify_every` cujo `verified_at` somado à cadência vence na data ou antes, o que tem cadência sem carimbo e o que só tem `reverify_on`. O rc é 0 (ou 2 com entrada quebrada): o vencimento nunca reprova, e o relatório não julga o grafo (o gate segue sendo o `kg_gate.py`). Um arquivo que não parseia sai como `NÃO LIDO`; num job agendado, olhe essa lista, porque o rc não a acusa. A cadência fora da forma ou zerada não entra no relatório (o aviso SHOULD a acusa), nem o vencimento depois do ano 9999. Com `--format json`, sai no formato `kg-ssot.due/1` (`spec/due.schema.json`) |

As opções `--json OUT`, `--spike`, `--git`, `--rev` e `--list` são do instrumento de medição que deu origem ao
contrato (o "spike"): gravam e reproduzem um formato legado, congelado, e não fazem parte da interface estável. Para
ferramentas, use `--format json`.

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
  "release": "kg-ssot-v4.10.0",
  "sha256": { "must": "0619d353…", "should": "5a7fb74a…" }
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
     "message": "Falta o campo obrigatório «label» no nó.",
     "hint": "Acrescente label: a afirmação curta do nó, até 280 caracteres."
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
- **O lugar da ocorrência:** `path` aponta no documento (`nodes[7].provenance.method`) e `line` é a linha no arquivo,
  no `.kg.yaml` e no `.kg.json`, para quem edita corrigir o ponto certo sem reescrever o grafo.
- **O corte:** `summary` conta todas as ocorrências. `occurrences` traz até `--limit`, e `truncated` e `total` dizem
  se cortou. Assim um grafo grande não enche o contexto de um modelo.
- **O contrato que julgou:** `contract` traz o caminho, o sha256 de cada schema e a release, para quem precisa provar
  qual contrato julgou.
- **O rc:** 0 quando todos passam, 1 quando algum reprova (um arquivo que não parseia reprova com `parse.*`, como na
  suíte) e 2 quando a entrada está quebrada (arquivo ilegível, opção inválida).
- **O desempenho:** com a libyaml instalada (o caso comum do PyYAML), o parse usa o parser em C, com o mesmo perfil
  YAML 1.2, e só cai no parser puro, mais lento, nos raros textos em que os dois podem divergir (tab, `%YAML`, escape
  de surrogate ou `\U`, BOM fora do início).

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
| `--no-default-excludes` | Desliga os excluídos padrão (e aí as fixtures do vendor entram no corpus) |
| `--repo DIR` · `--baseline ARQ` | Outro repositório, outra base |

## `kg_vendor.py`: trazer e conferir a release

O adotante nunca copia o contrato à mão. O vendor lê uma **tag** com `git archive` e grava um carimbo com o
sha256 de cada arquivo.

Da raiz do adotante, com um clone do repositório público em `../kg-ssot`. As saídas abaixo são de uma execução real
com a tag `kg-ssot-v4.7.1`; numa release mais nova, a tag, o commit e a contagem de arquivos mudam:

```bash
git clone https://github.com/marciocar/kg-ssot ../kg-ssot
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.7.1 --dest vendor/kg-ssot
```

```text
vendor atualizado: vendor/kg-ssot ← kg-ssot-v4.7.1 (04d73f2e2f64), 313 arquivos
```

O `update` grava também `vendor/kg-ssot/.gitattributes` com `* -text`. Um atributo aninhado vence o do repositório,
e assim a regra de fim de linha do adotante (`*.json text eol=lf`, `core.autocrlf`) não reescreve no índice os bytes
da release. A suíte tem fixtures com CRLF de propósito, que sem isso chegariam alteradas ao CI.

O `check` recalcula os sha256 e compara com o carimbo. Um arquivo editado, apagado ou sobrando (inclusive
bytecode num `__pycache__`) dá rc 1, e o `.gitattributes` do vendor também é conferido. Com `--index`, o `check`
confere os blobs do índice do git, que é o que o commit vai levar, e não a árvore de trabalho. Rode-o depois do
`git add vendor/kg-ssot`: ele pega antes do commit uma normalização que a árvore de trabalho esconde.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
```

```text
✓ vendor íntegro: vendor/kg-ssot = kg-ssot-v4.7.1 (04d73f2e2f64), 313 arquivos
```

| Opção | Efeito |
|---|---|
| `--source REPO` | O repositório (caminho ou URL, como `https://github.com/marciocar/kg-ssot`) que tem a tag. Obrigatório quando roda de dentro de um vendor |
| `--dest DIR` | Onde fica o vendor (default `vendor/kg-ssot`) |
| `--profile gate` | Traz só o mínimo para rodar o gate e o check (10 arquivos, sem a suíte); `--profile full` volta à release inteira |
| `--force` | Substitui um vendor editado localmente |
| `--index` (no `check`) | Confere o índice do git em vez da árvore de trabalho |

**Por que `-B`?** Os scripts do kit não gravam bytecode, mas uma ferramenta sua que **importa** um módulo do kit
grava o `.pyc` dentro do vendor, e o próximo `check` reprova. Rode tudo com `python3 -I -B`, ou com
`PYTHONDONTWRITEBYTECODE=1`.

## `kg_store.py`: o armazém que só grava o que passa

Para quem grava grafo por programa (um servidor de escrita, um chat, um pipeline que gera o grafo de um caso), o
`kg_store.py` é uma biblioteca, com um CLI por cima, que só escreve depois do veredito PASS do contrato. Há três
armazéns com a mesma interface (`read`, `list`, `write`, `delete`, `history`). O formato vem do nome: `.kg.yaml` é
julgado no perfil YAML e `.kg.json` no perfil JSON do contrato ([capítulo 3](03-formato.md#o-mesmo-modelo-em-kgjson)):

- `DiskStore`: só a cabeça em disco, sem histórico;
- `GitStore`: um commit por gravação ou remoção. O git roda isolado na raiz do armazém e nunca sobe para um repo
  de fora. O autor vem de quem grava (`author="Nome <email>"`), e o committer é fixo do serviço;
- `VersionedStore`: a cabeça em disco mais um registro de eventos e as versões no diretório oculto `.kg-store/`,
  sem git.

Pelo pacote PyPI, é `from kg_ssot import kg_store`. Para importar do vendor, ponha `vendor/kg-ssot/tools` no `sys.path` e rode sem gravar
bytecode, como no [capítulo 6](06-adocao-e-ci.md#num-app):

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

Para regenerar grafos que se citam, use `write_many` (desde a 4.14.0). Um a um, a troca do primeiro deixaria a aresta
externa do segundo sem ponta, e o rejulgamento barraria. O conjunto, inclusive com remoções (texto `None`), é julgado
inteiro, com todas as mudanças no lugar, e entra num registro só (um commit, ou um bloco de eventos), ou nada entra:

```python
r = store.write_many([("caso.kg.yaml", caso), ("cruzamento.kg.json", cruzamento), ("velho.kg.yaml", None)],
                     message="regenera o caso", expected={"caso.kg.yaml": sha_lido})
if not r["written"]:
    print(r["reason"], [x["reason"] for x in r["results"]])
```

Em `conflict` e `missing`, o nome que barrou leva o motivo e os outros saem como `skipped`. Em `gate` e `not_judged`, o
julgamento é do conjunto, e todos saem com esse motivo. O gate externo (`--gate-cmd`), se houver, julga cada mudança
isolada, como no `write`. Nomes do conjunto que só diferem pela caixa são recusados, como no armazém.

O CLI tem um subcomando por operação, com a saída em JSON no stdout:

```text
kg_store.py --backend disk|git|versioned --root DIR [--init] [--gate-cmd CMD [--gate-timeout S]] list
kg_store.py ... read NOME [--ref REF]
kg_store.py ... write NOME [ARQUIVO|-] [--message M] [--author "Nome <email>"] [--expected-sha256 S|new]
kg_store.py ... delete NOME [--message M] [--author A] [--expected-sha256 S]
kg_store.py ... write-many CONJUNTO.json [--message M] [--author A]
kg_store.py ... history NOME
```

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
  PASS nem `"gate"`, para quem chama distinguir "reprovou" de "não deu para julgar". Com um gate externo, `"gate"`
  com `error: "reprovado pelo gate externo"` quer dizer que o contrato aprovou e o gate de fora reprovou; o `verdict`
  é o dele.
- **A trava otimista:** `expected_sha256` é o sha256 da cabeça que quem grava leu, ou `NEW` (no CLI, `new`) para
  exigir que o nome ainda não exista. Gravar o mesmo texto da cabeça dá `written` com `unchanged` e sem commit.
- **O caminho:** o nome é relativo, termina em `.kg.yaml` ou `.kg.json` e não tem `..` nem segmento oculto. Para o
  armazém ser copiável entre sistemas, ele recusa criar um nome com segmento reservado do Windows (`CON`, `NUL`,
  `COM1`...) ou que termina em ponto (o que já existe segue funcionando), e nenhuma operação aceita um nome que só
  difere pela caixa de um que está no armazém. Raiz, pastas e arquivo não podem ser link:
  - **no macOS e no Linux (POSIX),** tudo se abre por `dir_fd` com `O_NOFOLLOW`, e trocar uma pasta no meio da operação
    não desvia nada;
  - **no Windows,** que não tem `dir_fd`, cada passo do caminho é conferido por `lstat` (link simbólico, junção e ponto
    de montagem são recusados; o reparse point que não redireciona o nome, como o arquivo do OneDrive sob demanda,
    passa), o arquivo aberto tem de ser o mesmo que o `lstat` viu, e o caminho é conferido de novo depois da leitura e,
    na gravação, antes da troca final. É mais fraco: quem pode escrever dentro da raiz consegue trocar uma pasta entre
    a conferência e o uso. Num sistema de arquivos sem id de arquivo (o FAT de um pendrive), a comparação do arquivo
    aberto não prova nada, e só a recusa de link sobra. Num armazém de uma pessoa só, na pasta dela, isso não muda
    nada; num armazém compartilhado, prefira POSIX.
- **O histórico:** `history(nome)` lista as operações, da mais nova para a mais antiga, com `ref`, `op`
  (`write` ou `delete`), autor, data e mensagem. `read(nome, ref=...)` lê uma versão anterior: o sha do commit no
  git, o `seq` do evento no versionado.
- **O git isolado:** o `GitStore` não lê a config do sistema nem a do usuário (sem hooks, sem gpg, sem `autocrlf`, sem
  arquivo de exclusão), então o que ele guarda é byte a byte o texto aprovado, com o sha256 do resultado.
- **O gate externo (`--gate-cmd`):** é o gancho por onde quem adota liga um segundo gate, o dele, sem o produto
  depender desse gate. O comando roda depois de o contrato aprovar, em cada gravação e cada remoção, e o armazém só
  grava com PASS dos dois. Um grafo que o contrato reprova nunca chega ao comando.
  - **A entrada:** o texto candidato vai pelo stdin em UTF-8 (vazio na remoção); leia-o como bytes e decodifique, para
    não depender da página de código do sistema. O nome e a operação vão pelo ambiente, `KG_GATE_NAME` e `KG_GATE_OP`
    (`write` ou `delete`). O comando herda o resto do ambiente do processo, menos a variável do segredo do `kg_mcp`
    (`--secret-env`).
  - **A saída:** um documento `kg-ssot.verdict/1` válido por `spec/verdict.schema.json`, com ao menos um resultado, rc
    0 quando tudo passa e rc 1 quando algo reprova, e no máximo 16 MiB (o teto vale enquanto ele roda). O stderr do
    gate é descartado: para diagnosticar, rode o comando à mão com o mesmo stdin e o mesmo ambiente. O código de uma ocorrência tem de começar por uma camada do contrato (`parse.`, `form.`,
    `integrity.` ou `yaml.`); um gate de fora usa, por exemplo, `integrity.external.<nome>`.
  - **Fail-closed:** comando que não roda, que passa de `--gate-timeout` (padrão 60 s, no máximo 86.400), que sai sem JSON, com saída
    grande demais, com JSON fora do schema ou sem resultado, com rc fora de 0 e 1 ou com rc que não bate com o veredito
    dá `"not_judged"`, nunca PASS, e nada é gravado. No tempo esgotado, numa interrupção (Ctrl+C), num SIGTERM ao
    processo ou com a saída grande demais, morrem o comando e os processos que ele abriu. No Windows, matar o processo
    à força (o "Finalizar tarefa") não deixa tratador nenhum agir, e o gate que estiver rodando pode ficar. No macOS e no Linux, um processo que o gate deixa
    rodando depois de terminar bem também é morto (o grupo de processos dele); no Windows, não, e o gate de quem adota
    não deve deixar nada para trás. `--gate-cmd ""` dá rc 2, para uma variável vazia nunca subir um servidor sem gate;
    `--gate-timeout` sem `--gate-cmd` e, no `kg_mcp.py`, `--gate-cmd` com `--read-only` (o gate nunca rodaria) também
    dão rc 2.
  - **A trava:** o gate roda sob a trava da gravação. Um gate lento segura as outras gravações do mesmo armazém até o
    `--gate-timeout`; no stdio, segura o servidor.
  - **O mesmo texto:** gravar de novo o texto da última versão também passa pelo gate. Se ele reprovar agora, a
    resposta é `"gate"`, mesmo sem nada a mudar.
  - **Sem shell:** o comando é uma lista de argumentos, nunca uma linha de shell. No macOS e no Linux, a linha passa
    pelas regras do `shlex` (a barra invertida escapa; ponha o caminho entre aspas). No Windows, as aspas duplas
    agrupam e a barra invertida fica como está, como no comando `"C:\Program Files\Python\python.exe" C:\gates\x.py`.
    As aspas valem em volta do argumento inteiro: `--opt="a b"` vira dois argumentos, e aspas simples não agrupam.
    O texto do grafo só chega pelo stdin, então `$(...)` ou `;` nele não executam nada.
  - **Pela biblioteca:** `open_store(..., gate=CommandGate(argv, timeout))`, ou qualquer chamável
    `(nome, texto, op) -> (veredito, erro)`. Um chamável que levanta também dá `"not_judged"`.

  Um gate de exemplo, só com a biblioteca padrão, que reprova o texto com a palavra PROIBIDO:

  ```python
  import json, os, sys
  bad = "PROIBIDO" in sys.stdin.buffer.read().decode("utf-8")
  occ = [{"level": "MUST", "code": "integrity.external.palavra-proibida", "place": "arquivo", "path": "",
          "line": None, "message": "o texto tem uma palavra proibida"}] if bad else []
  print(json.dumps({"schema_version": "kg-ssot.verdict/1",
                    "contract": {"must": None, "should": None, "release": None, "sha256": {"must": None, "should": None}},
                    "results": [{"source": os.environ["KG_GATE_NAME"], "verdict": "FAIL" if bad else "PASS",
                                 "summary": {"MUST": {occ[0]["code"]: 1} if bad else {}, "SHOULD": {}},
                                 "occurrences": occ, "total": len(occ), "truncated": False,
                                 "external_checked": False}]}))
  sys.exit(1 if bad else 0)
  ```

  ```bash
  python3 -I tools/kg_store.py --backend versioned --root areas/ana --init \
    --gate-cmd "python3 -I gates/proibido.py" write grafos/a.kg.yaml grafo.kg.yaml
  ```
- **O que fica com quem adota, de propósito:** autenticação, identidade, área por usuário (um root por usuário),
  tamanho máximo, número de grafos, timeout e a trava entre processos onde não há `flock` nem `msvcrt`.
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

Com `--store-optional`, uma raiz que não abre (um arquivo no lugar da pasta, uma pasta sem permissão) não derruba o
servidor: ele sobe só com `kg_validate` e `kg_schema_help` e diz o motivo ao modelo, nas instruções, na descrição das
duas ferramentas e num campo `store` do `kg_schema_help`. Assim o modelo conta ao usuário por que não há `kg_write`, em
vez de supor um modo só leitura. Sem a opção, a raiz que não abre é rc 2, com a mensagem no stderr.

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

| Opção | Efeito |
|---|---|
| `--root DIR` | O armazém. Sem ele, só `kg_validate` e `kg_schema_help` |
| `--backend disk\|git\|versioned` | O tipo de armazém (default `disk`) |
| `--init` | Cria a raiz se não existir |
| `--author "Nome <email>"` | Quem assina as gravações |
| `--read-only` | Tira `kg_write` e `kg_delete` |
| `--http PORTA` · `--host H` · `--allow-remote` | HTTP no lugar do stdio; fora do loopback, só com `--allow-remote`, que exige `--secret-env` |
| `--secret-env VAR` · `--secret-header H` | O segredo compartilhado, lido da variável `VAR`, que cada requisição HTTP traz no header `H` (padrão `X-Api-Key`), comparado por hmac |
| `--identity-header H` | O perfil "atrás de proxy": a identidade de cada requisição vem do header `H` (um e-mail), com área e autor próprios; exige `--secret-env` |
| `--max-bytes N` | O tamanho máximo de um grafo (default 2.000.000) |
| `--max-graphs N` | Grafos por armazém, ou por área no perfil; além disso, um nome novo é recusado |
| `--max-concurrent N` | Requisições HTTP ao mesmo tempo; além disso, 503 |
| `--store-optional` | Raiz que não abre não derruba o servidor: ele sobe sem armazém e diz o motivo ao modelo |
| `--gate-cmd CMD` · `--gate-timeout S` | Um gate externo depois do contrato, em toda gravação e remoção, também por área no perfil (veja o `kg_store.py`) |

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

- **Quem assina:** o autor das gravações é o `--author` do servidor ou, no perfil "atrás de proxy", a identidade
  autenticada da requisição. Nunca é um argumento da ferramenta: o modelo não escolhe quem assina.
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
  rebinding), `MCP-Protocol-Version` desconhecida (400) e corpo sem `Content-Length`. Não há TLS: o servidor só sai do
  loopback com `--allow-remote`, que exige `--secret-env`, para rodar numa rede privada atrás de um proxy com TLS.
- **O perfil "atrás de proxy" (`--identity-header`):** é o modo para um cliente com muitos usuários, como o LibreChat,
  que manda o usuário logado num header.
  - **Recusa por padrão:** toda requisição traz a identidade (um e-mail) e o segredo compartilhado. Sem identidade,
    com identidade vazia (o LibreChat troca um placeholder ausente por texto vazio) ou malformada, ou com o segredo
    errado, a resposta é 401, antes de qualquer ferramenta.
  - **Área e autor:** cada identidade grava na própria área sob `--root`, num diretório `u-<nome>-<hash>`, e não
    enxerga a dos outros. A gravação é assinada por ela, na forma `parte-local <e-mail>`. O e-mail não distingue
    caixa: `Ana@X.org` e `ana@x.org` são a mesma identidade.
  - **Por requisição:** identidade, área e autor viajam num contexto de cada requisição, e nunca num atributo do
    servidor, que é um só entre as threads. Guardá-los no servidor deixaria uma requisição concorrente gravar na área
    de outra, a classe do CVE-2026-25536 do SDK TypeScript. Um teste determinístico confere que nenhuma requisição
    deixa ou troca estado no servidor, e outro, com duas identidades em paralelo, exercita o isolamento de ponta a
    ponta. Um header de identidade ou de segredo repetido é recusado, para um proxy que acrescente o header em vez de
    substituí-lo não deixar o cliente escolher a identidade.
  - **O modelo de confiança:** quem tem o segredo afirma qualquer identidade. O segredo autentica o proxy (o
    LibreChat), e é o proxy que autentica o usuário. Por isso o segredo nunca vai a um cliente final, e o servidor
    fica numa rede que só o proxy alcança.
  - **Os limites:** `--max-graphs` vale por área e é contado sob a trava da gravação, então gravações paralelas não
    passam juntas dele. `initialize`, `ping` e as notificações não abrem nem criam área, e com `--read-only` a área
    que ainda não existe não é criada. O número de áreas não tem limite: quem tem o segredo cria uma por identidade
    nova (o modelo de confiança acima), e o servidor guarda as áreas abertas em memória enquanto roda.
  - **A raiz das áreas:** é conferida ao subir. Vazia, inexistente sem `--init`, arquivo ou link dá rc 2, salvo
    `--store-optional`, como a raiz fora do perfil.
  - **O envelope `untrusted_data`:** `kg_get`, `kg_list` e `kg_history` devolvem `{"untrusted_data": ..., "notice":
    ...}`, para o modelo tratar o texto gravado por outros como dado, nunca como instrução.
  - **O que o perfil não é:** é "atrás de proxy", numa rede privada. Não é o perfil OAuth da especificação MCP, que
    fica para quando houver uma matriz medida de clientes.
- **A imagem OCI:** `ghcr.io/marciocar/kg-ssot:<versão>` traz o `kg-mcp` pronto, para rodar como serviço ao lado
  de um cliente sem Python, como o LibreChat. Ela é construída do mesmo wheel do PyPI, com as dependências por hash e
  a base fixada por digest (`packaging/oci/Dockerfile`), roda com um usuário sem privilégio (uid 10001) e guarda o
  armazém no volume `/data`. Leva o label `io.modelcontextprotocol.server.name`, o que o MCP Registry usa para
  conferir a posse. O workflow do espelho a publica atrás de aprovação, com a atestação de proveniência
  (`gh attestation verify oci://ghcr.io/marciocar/kg-ssot:<versão> --repo marciocar/kg-ssot`).
  - **Por stdio:** `docker run -i --rm ghcr.io/marciocar/kg-ssot:<versão>` só julga. Com `-v kg-data:/data` e
    `--root /data/grafos --init`, grava.
  - **Ao lado do LibreChat:** o perfil "atrás de proxy", na rede do compose e sem porta publicada no host:

    ```yaml
    # docker-compose.override.yml
    services:
      kg-ssot:
        image: ghcr.io/marciocar/kg-ssot:<versão>
        command: ["--http", "8080", "--host", "0.0.0.0", "--allow-remote",
                  "--identity-header", "X-User-Email", "--secret-env", "KG_MCP_SECRET",
                  "--root", "/data/areas", "--init", "--backend", "versioned"]
        environment:
          KG_MCP_SECRET: ${KG_MCP_SECRET}
        volumes:
          - kg-data:/data
    volumes:
      kg-data:
    ```

    ```yaml
    # librechat.yaml
    mcpSettings:
      allowedDomains:  # lista FECHADA: só os domínios listados passam, para todos os servidores MCP por URL
        - kg-ssot        # o nome do serviço no compose
        # - os domínios dos outros servidores MCP que este librechat.yaml já usa
    mcpServers:
      kg-ssot:
        type: streamable-http
        url: http://kg-ssot:8080/mcp
        headers:
          X-User-Email: "{{LIBRECHAT_USER_EMAIL}}"
          X-Api-Key: "${KG_MCP_SECRET}"
    ```

    Uma lista `allowedDomains` que não está vazia é fechada: só os domínios dela passam, para todos os servidores MCP
    por URL. Se o `librechat.yaml` já tem outros, ponha os domínios deles na mesma lista, senão eles param de
    funcionar.

    O `--host 0.0.0.0` é o de dentro do container: sem porta publicada, o serviço só é alcançado pelos containers da
    rede do compose (a rede padrão do compose não é `internal`, então o container ainda sai para a internet). Sem
    `KG_MCP_SECRET`, o container sai com rc 2 e não serve nada. O segredo fica no `.env` do compose, nunca no
    `librechat.yaml` versionado. Como toda variável de ambiente de container, ele aparece no `docker inspect`: quem
    tem acesso ao docker do host o lê, como já lê o `.env`.
  - **O volume:** com um volume nomeado, como no compose acima, o `/data` já nasce do usuário da imagem. Com uma pasta
    do host montada em `/data`, ela tem de ser do uid 10001 (`chown 10001:10001 <pasta>`); senão o container sai
    com rc 2 e `Permission denied`.
  - **A plataforma:** a imagem sai só para `linux/amd64`.
  - **O que a imagem não faz:** TLS e exposição para fora da rede do compose ficam com o proxy de quem adota, como no
    perfil.
- **Num repo:** o armazém de disco e o versionado recusam raiz dentro de um repo git (veja o `kg_store.py`). Dentro
  do repo, use `--backend git --root .`, que faz um commit por gravação no branch atual, fora de qualquer PR (rode-o
  num branch de trabalho), ou rode sem `--root` para só julgar.
- **O que fica com quem adota, de propósito:** o TLS, o perfil OAuth, cota por usuário e timeout por ferramenta.
- **Cliente que guarda o `tools/list`:** alguns clientes, como o LibreChat, validam os argumentos contra o
  `tools/list` que guardaram ao subir. Depois de uma atualização que muda o `inputSchema` de uma ferramenta (um
  argumento novo, um valor novo num enum), reinicie o cliente, ou ele recusa o argumento novo antes de chamar o
  servidor. Um adotante já tropeçou nisso e passou a reiniciar o cliente no deploy quando o `tools/list` muda.
- **As duas eras do protocolo:** o servidor fala as duas, e a própria requisição escolhe a era.
  - **A era nova, `2026-07-28`, sem estado:** toda requisição traz no `params._meta` a versão
    (`io.modelcontextprotocol/protocolVersion`) e as capacidades do cliente (`io.modelcontextprotocol/clientCapabilities`).
    - **O que o servidor implementa:** `server/discover`.
    - **O que todo resultado traz:** `resultType` e o `serverInfo` no `_meta`.
    - **As dicas de cache:** `server/discover` e `tools/list` trazem `ttlMs` e `cacheScope`, que é `private` no perfil
      "atrás de proxy", porque a lista depende da área.
    - **Os erros, com o status HTTP da especificação:**
      - falta um campo obrigatório do `_meta`: -32602, com 400;
      - versão que o servidor não suporta: -32022, com 400 e, em `data.supported`, a mesma lista do `server/discover`
        (as duas eras), por qualquer caminho; uma versão da era antiga pedida no `_meta` também dá -32022, com a mensagem
        de que ela só vale pelo `initialize`;
      - método desconhecido: -32601, com 404;
      - header que falta ou diverge do corpo (`MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`, com o sentinela
        base64): -32020, com 400.
  - **A era antiga (`2025-11-25`, `2025-06-18`, `2025-03-26`, `2024-11-05`):** segue com `initialize`, que responde com a
    versão pedida quando a conhece. O servidor nunca emite `Mcp-Session-Id`, e GET e DELETE dão 405.
  - **Medido com clientes oficiais:** o SDK Python `mcp` 2.3.0, que é o v2, na era nova, por stdio e por HTTP; e os SDKs
    TypeScript 1.30.0, o do LibreChat, e 1.32.1 na era antiga. O CI roda os três.

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

## `kg_migrate.py`: o migrador por perfil

Propõe a `provenance` que o contrato v4 pede aos nós `confirmed` ou PROD que ainda não a têm, a partir de um **perfil**
que o adotante escreve e versiona: uma lista de regras em ordem (`spec/kg-migrate-profile.schema.json`), em que a
primeira que casa decide. Há um exemplo comentado em `spec/migrate-examples/company-brain.profile.yaml`, medido sobre
um corpus real de 25 grafos e 1.024 nós.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py plan  --profile kg-migrate.profile.yaml --out propostas.tsv
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py apply --profile kg-migrate.profile.yaml
```

- **O `plan` não escreve nada.** Imprime as contagens por regra e grava, com `--out`, a planilha de propostas, uma
  linha por nó, com o que vai para quem revisa e por quê. Leia a planilha antes do `apply`.
- **Cada regra faz uma de três coisas:** propor a `provenance`, rebaixar o nó para `unverifiable` (a fonte é
  irrecuperável, que é o padrão do contrato) ou só mandar o nó para revisão. O nó que nenhuma regra casa também vai para
  revisão e não recebe nada.
- **O `when` casa pelo que o nó já traz.** São o trace (vazio, URL, caminho, glob, existência na árvore, expressão
  regular), o tipo, o status, o plano, o `verified_against`, o `source_kind` e as arestas `SUPPORTS` que chegam ao nó,
  com `not` e `any_of`.
- **Os templates usam os campos do nó:** `{trace}`, `{trace_path}`, `{trace_line}`, `{verified_against}`, `{supports}` e
  `{source_kind}`, e `{a|b}` pega o primeiro que não for vazio. O `note` do perfil vai no fim de todo detalhe do
  `method`, por exemplo `não reverificado na migração de 2026-10-20`.
- **O `scopes` dá `verified_scope` só por lista de ids**, nunca por padrão de texto.
- **O perfil escolhe dentro do contrato e nunca o relaxa.** Toda proposta é conferida contra o MUST e o SHOULD de forma
  antes de virar proposta. A que reprovaria vai para revisão com o motivo, e o template que resolve para vazio também.
  Um aviso de coerência que a proposta acende não barra, porque ele diz a verdade sobre o nó. Por exemplo, um
  `testemunho` num nó PROD acende `integrity.testimony-in-prod`: a proposta segue, e o nó vai para quem revisa com o
  aviso nomeado.
- **O `apply` grava arquivo por arquivo, por texto, e os comentários ficam.** Depois ele relê o arquivo e confere a
  invariância: cada nó fica igual ao de antes, fora as chaves que a ação autoriza, e o diff só acrescenta linhas, fora
  a do status rebaixado. Um arquivo que ganharia código MUST novo, ou aviso SHOULD que o plan não anunciou, fica como
  estava. A quebra de linha do arquivo é mantida (CRLF fica CRLF), e o arquivo com quebras misturadas é recusado.
  Rodar de novo não muda nada.
- **Sem lista de grafos, a ferramenta lê os `.kg.yaml` do `git ls-files`.** Ficam de fora os padrões do `kg_gate.py`
  (`*/fixtures/*` e `docs/materials/*`), o `vendor/*` e os globs de `--exclude`, com a semântica do gate: `fnmatch` sobre
  o caminho relativo, em que `*` atravessa `/`; o `**/` do dialeto do perfil, que casa zero pastas, também vale.
  `--no-default-excludes` tira os padrões. Atenção: no `trace_path_glob` do perfil, `*` não atravessa `/`. Um grafo da lista que não
  parseia vira linha de revisão e não aborta a rodada.
- **O nó cujo `verified_scope` já é o do perfil sai como `same`**, separado do que muda, e o `apply` não o toca.
- **O caminho do trace é léxico e fica dentro da raiz do repo.** Ele é normalizado (`./`, `a/../b`), e o que sai da
  raiz com `../` deixa de ser caminho. Um caminho absoluto ou com `~` conta como inexistente, sem consultar o disco da
  máquina.

O que fica fora, de propósito, porque é julgamento: reescrever label, mudar plano, re-medir, refutar, reconciliar com
`SUPERSEDES` e promover um `unverifiable`. rc 0 quando o plano sai ou o apply termina; rc 1 quando o apply recusou
algum arquivo, que fica como estava e com o motivo no relatório; rc 2 com entrada quebrada (perfil fora do schema,
regra ou id repetido, expressão regular inválida, `when` que casaria todo nó, grafo dado na linha de comando que não
parseia). O migrador viaja no vendor e não no pacote do PyPI nem no do npm.
