<!-- translation-of: docs/manual/05-tools.md sha256:501642872725376c -->
# 5. Ferramentas

[English](../05-tools.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← O contrato](04-contrato.md) · [Índice](README.md) · [Adoção e CI →](06-adocao-e-ci.md)

As ferramentas que viajam na release ficam em `tools/`. Elas dependem só de Python 3.11 ou mais e das versões
fixadas, e com hash, em [`tools/requirements.txt`](../../../tools/requirements.txt) (PyYAML e jsonschema, mais as
dependências do jsonschema).

```bash
python3 -m venv .venv && .venv/bin/pip install --require-hashes -r tools/requirements.txt
```

Todo `rc` segue a mesma convenção: **0** passou, **1** algo reprovou, **2** a entrada está quebrada (arquivo
ilegível, base ausente, tag inexistente). Um rc 2 nunca passa por verde.

Os exemplos abaixo rodam num repositório de demonstração com o kit em `vendor/kg-ssot`. Num clone do produto,
troque `vendor/kg-ssot/tools/` por `tools/`.

## Língua da saída

Desde a 4.18.0, as ferramentas imprimem a saída humana em inglês por padrão, e em português do Brasil quando você
pede. Cada ferramenta escolhe a língua do jeito do gettext e para na primeira variável definida:

1. `KG_SSOT_LANG`, a escolha só para o KG-SSOT (`pt-BR`, `pt_BR` ou `en`);
2. `LANGUAGE`, uma lista separada por dois-pontos (`pt_BR:en`), em que vence a primeira língua com catálogo;
3. `LC_ALL`, depois `LC_MESSAGES`, depois `LANG` (`pt_BR.UTF-8`).

Uma variável vazia conta como não definida. `C` e `POSIX` são o inglês. Uma língua sem catálogo também: a variável
definida decide do mesmo jeito, e as ferramentas não passam para a próxima. Um `pt` sozinho casa com `pt_BR`. A frase que ainda não tem tradução sai
em inglês. O catálogo é `locale/pt_BR/LC_MESSAGES/kg-ssot.po`, e ele viaja na release e no vendor (também no
`--profile gate`).

```bash
KG_SSOT_LANG=pt-BR python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/broken.kg.yaml
KG_SSOT_LANG=en python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/broken.kg.yaml
```

Dado não muda de língua. A estrutura do JSON e as chaves dele, os códigos (`form.required.node.label`), os códigos de
saída, o lugar de uma ocorrência (`nó C_RETRY_SAFE`, `aresta #3`, `arquivo`) e a planilha TSV do `kg_migrate.py` ficam
iguais em toda língua. Os campos `message` e `hint` de um veredito são texto para pessoas: seguem a língua na linha
de comando. O servidor MCP fala inglês em qualquer locale, porque as descrições, os erros e os resultados dele são
protocolo e prompt para o modelo. Como no gettext, o `LANGUAGE` só vale quando o locale efetivo não é o `C`, então
`LC_ALL=C` força o inglês. Para um passo de CI não depender da língua, decida pelo rc, como mostra o
[capítulo 6](06-adocao-e-ci.md#a-língua-da-saída-no-ci).

## `kg_validate.py`: o leitor de referência

Valida um ou mais arquivos contra o contrato vigente.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/example.kg.yaml docs/broken.kg.yaml
```

```text
PASSA   docs/example.kg.yaml
REPROVA docs/broken.kg.yaml
  MUST   form.required.node.provenance ×1 · form.unknown-key.node.priority ×1
  SHOULD form.required.node.verified_against ×1 · integrity.untraced-decision ×1 · yaml.unquoted-date ×1
· 2 arquivos; 1 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

rc 1. Para ver **de qual nó** sai cada código, use `--where`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/broken.kg.yaml
```

```text
REPROVA docs/broken.kg.yaml
  MUST   form.required.node.provenance ×1 · form.unknown-key.node.priority ×1
  SHOULD form.required.node.verified_against ×1 · integrity.untraced-decision ×1 · yaml.unquoted-date ×1
    MUST   form.required.node.provenance  nó C_RETRY_SAFE
           → Acrescente provenance com source, locator e method; sem fonte recuperável, mude o status para unverifiable.
    MUST   form.unknown-key.node.priority  nó C_RETRY_SAFE
           → Renomeie a chave com o prefixo x_ (extensão que os leitores ignoram) ou remova-a.
    SHOULD form.required.node.verified_against  nó C_RETRY_SAFE
    SHOULD integrity.untraced-decision  nó D_RETRY_POLICY
    SHOULD yaml.unquoted-date  arquivo
· 1 arquivos; 0 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

Opções úteis:

| Opção | Efeito |
|---|---|
| `--where` | Uma linha por ocorrência, com o nó ou a aresta; numa ocorrência MUST, a correção vem logo abaixo |
| `--corpus DIR` | Confere a ponta externa de cada entrada de `external_edges` contra os `.kg.yaml` e `.kg.json` que o git rastreia sob `DIR` (fora de um repositório git, todos) |
| `--schema F` | Valida contra outro schema MUST (o schema SHOULD vizinho vem junto, se existir) |
| `--format json` | O veredito estruturado em stdout (ver abaixo), para ferramentas e servidores MCP |
| `--limit N` | Com `--format json`, quantas ocorrências por arquivo (default 50); o resumo conta todas |
| `-` no lugar do arquivo | Lê o grafo do stdin, sem arquivo temporário; `--stdin-format json` lê um grafo `.kg.json` (default `yaml`) |
| `--should-schema F` | Com `--schema`, o schema SHOULD que acompanha (no lugar do vizinho) |
| `--due AAAA-MM-DD` | No lugar do veredito, o relatório de vencimento na data (desde a 4.15.0): cada nó com `reverify_every` cujo `verified_at` somado à cadência cai na data ou antes, cada nó que tem cadência e não tem carimbo, e cada nó que só tem `reverify_on`. Desde a 4.19.0 lista também os perfis canônicos com cadência: cada sinônimo de um `x_term` que não está aposentado, o `x_mirror` (`synced_at` mais `resync_every`) e o `x_doc_cycle` (`checked_at` mais `recheck_every`), com `subject` e `detail` no JSON. O rc é 0 (ou 2 com entrada quebrada): o vencimento nunca reprova, e o relatório não julga o grafo (o gate segue sendo o `kg_gate.py`). Um arquivo que não parseia sai como `NÃO LIDO`; num job agendado, olhe essa lista, porque o rc não a acusa. A cadência fora da forma ou zerada fica fora do relatório (o aviso SHOULD a acusa), e o vencimento depois do ano 9999 também. Com `--format json`, a saída usa o formato `kg-ssot.due/1` (`spec/due.schema.json`) |

As opções `--json OUT`, `--spike`, `--git`, `--rev` e `--list` são do instrumento de medição que deu origem ao
contrato (o "spike"). Elas gravam e reproduzem um formato legado, congelado, e não fazem parte da interface estável.
Para ferramentas, use `--format json`.

Com `external_edges` e sem `--corpus`, o leitor avisa que não conferiu a ponta externa:

```text
PASSA   docs/decision.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 1 arquivo(s) com external_edges: a ponta externa NÃO foi conferida (rode com --corpus <raiz do repo>)
```

### O veredito estruturado (`--format json`)

Se você chama o leitor por programa (um job de CI, um servidor MCP, um chat), o `--format json` devolve o veredito
num formato versionado, `kg-ssot.verdict/1`, com JSON Schema em `spec/verdict.schema.json`. Saída real de um caso da
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
  "release": "kg-ssot-v4.22.0",
  "sha256": { "must": "6a05cb1e…", "should": "04327d29…" }
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

(Os dois sha256 e o caminho estão abreviados aqui, e alguns objetos ficam numa linha só.)

- **O que é estável:** `code` é o vocabulário da suíte e do gate, e é por ele que uma ferramenta decide. `message` e
  `hint` são texto para pessoas: seguem a [língua da saída](#língua-da-saída) e podem mudar.
- **O lugar da ocorrência:** `path` aponta no documento (`nodes[7].provenance.method`) e `line` é a linha no arquivo,
  no `.kg.yaml` e no `.kg.json`, para quem edita corrigir o ponto certo sem reescrever o grafo.
- **O corte:** `summary` conta todas as ocorrências. `occurrences` traz até `--limit`, e `truncated` e `total` dizem
  se a lista foi cortada. Assim um grafo grande não enche o contexto de um modelo.
- **O contrato que julgou:** `contract` traz o caminho, o sha256 de cada schema e a release, para quem precisa provar
  qual contrato julgou.
- **O rc:** 0 quando todos os arquivos passam, 1 quando algum reprova (um arquivo que não parseia reprova com
  `parse.*`, como na suíte) e 2 quando a entrada está quebrada (arquivo ilegível, opção inválida).
- **O desempenho:** com a libyaml instalada (o caso comum do PyYAML), o parse usa o parser em C, com o mesmo perfil
  YAML 1.2. Ele só cai no parser puro, mais lento, nos raros textos em que os dois podem divergir (tab, `%YAML`,
  escape de surrogate ou `\U`, BOM fora do início).

## `kg_conformance.py`: a suíte

Roda a suíte de conformidade contra o leitor de referência. Primeiro o metaschema se auto-testa, depois cada
manifesto é validado, depois cada caso roda.

```bash
python3 -I tools/kg_conformance.py
```

As últimas linhas:

```text
—
latest: 438/438 (reprova)
optional: 10/24 (só reporta)
```

rc 0. `latest/` é o contrato vigente, e um caso que falha ali reprova a rodada (rc 1). `optional/` é comportamento
que um leitor **pode** implementar (hoje, a camada semântica de frescor e domínio, que o leitor de referência não
implementa) e nunca muda o rc. rc 2 quer dizer que a própria suíte está quebrada: manifesto inválido, arquivo fora
de manifesto, pasta desconhecida.

## `kg_gate.py`: a catraca por grafo

O gate é para o CI de um repositório que guarda grafos. Ele mede todos os `.kg.yaml` **que o git rastreia** e
compara o resultado com uma linha de base (a pasta `.kg-ssot/gate/`). A regra: **nada piora**. Um grafo que já
reprovava fica registrado como dívida herdada; um grafo novo tem de passar.

Sem base, o gate se recusa a rodar:

```text
GATE QUEBRADO  linha de base ausente (.kg-ssot/gate): grave a primeira com --update
```

rc 2. A primeira base:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

```text
  MUST   docs/broken.kg.yaml (herdado): form.required.node.provenance · form.unknown-key.node.priority
  SHOULD form.required.node.verified_against: 1 grafo
  SHOULD integrity.untraced-decision: 1 grafo
  SHOULD yaml.unquoted-date: 1 grafo
linha de base gravada: .kg-ssot/gate (2 grafos, 1 na dívida herdada)
```

Um grafo novo que reprova, depois de `git add`:

```text
✗ PIOROU  docs/new.kg.yaml falha no MUST: form.required.node.provenance, form.unknown-key.node.priority
✗ PIOROU  debt.form.required.node.verified_against: 1 → 2
✗ PIOROU  debt.integrity.untraced-decision: 1 → 2
✗ PIOROU  debt.yaml.unquoted-date: 1 → 2
· 3 grafos; 1 passam no MUST; 1 na dívida herdada
  MUST   docs/broken.kg.yaml (herdado): form.required.node.provenance · form.unknown-key.node.priority
  MUST   docs/new.kg.yaml (novo): form.required.node.provenance · form.unknown-key.node.priority
  SHOULD form.required.node.verified_against: 2 grafos
  SHOULD integrity.untraced-decision: 2 grafos
  SHOULD yaml.unquoted-date: 2 grafos
```

rc 1. E quando a dívida é paga (o grafo herdado consertado):

```text
↑ melhorou docs/broken.kg.yaml: passa no MUST (trave o ganho: kg_gate.py --update)
↑ melhorou debt.form.required.node.verified_against: 1 → 0 (trave o ganho: kg_gate.py --update)
↑ melhorou debt.integrity.untraced-decision: 1 → 0 (trave o ganho: kg_gate.py --update)
↑ melhorou debt.yaml.unquoted-date: 1 → 0 (trave o ganho: kg_gate.py --update)
· 2 grafos; 2 passam no MUST; 0 na dívida herdada
```

rc 0, com o pedido de travar o ganho. Rode `--update` no mesmo PR para a dívida não voltar.

| Opção | Efeito |
|---|---|
| `--update` | Grava a base. Se algo piorou, recusa, a menos que você passe `--accept-regression` |
| `--accept-regression "<motivo>"` | Aceita uma piora; o motivo fica gravado na base |
| `--exclude GLOB` | Tira caminhos do corpus (repetível). `*/fixtures/*`, `docs/materials/*` e o vendor do KG-SSOT (qualquer pasta com o carimbo `.kg-ssot-version`, desde a 4.19.1) já saem por padrão; o `--no-default-excludes` os traz de volta |
| `--granularity node` | Com `--update`: conta a dívida SHOULD por ocorrência, não por grafo |
| `--no-default-excludes` | Desliga os excluídos padrão (e aí as fixtures do vendor entram no corpus) |
| `--repo DIR` · `--baseline ARQ` | Outro repositório, outra base |

## `kg_vendor.py`: trazer e conferir a release

O adotante nunca copia o contrato à mão. A ferramenta de vendor lê uma **tag** com `git archive` e grava um carimbo
com o sha256 de cada arquivo.

Rode da raiz do adotante, com um clone do repositório público em `../kg-ssot`. As saídas abaixo são de execuções
reais da ferramenta da 4.18.0 (o `update` e o `check`) com a tag `kg-ssot-v4.17.2`. As ferramentas das releases
anteriores à 4.18.0 imprimem em português. Numa release mais nova, a tag, o commit e a contagem de arquivos mudam:

```bash
git clone https://github.com/marciocar/kg-ssot ../kg-ssot
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.17.2 --dest vendor/kg-ssot
```

```text
vendor atualizado: vendor/kg-ssot ← kg-ssot-v4.17.2 (d5a6cab1cb09), 504 arquivos
```

O `update` grava também `vendor/kg-ssot/.gitattributes` com `* -text`. Um atributo aninhado vence o do repositório,
e assim a regra de fim de linha do adotante (`*.json text eol=lf`, `core.autocrlf`) não reescreve no índice os bytes
da release. A suíte tem fixtures com CRLF de propósito, que sem isso chegariam alteradas ao CI.

O `check` recalcula os sha256 e compara com o carimbo. Um arquivo editado, apagado ou sobrando (inclusive bytecode
num `__pycache__`) dá rc 1, e o `check` também confere o `.gitattributes` do vendor. Com `--index`, o `check` confere
os blobs do índice do git, que é o que o commit vai levar, e não a árvore de trabalho. Rode-o depois do
`git add vendor/kg-ssot`: ele pega, antes do commit, uma normalização que a árvore de trabalho esconde.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
```

```text
✓ vendor íntegro: vendor/kg-ssot = kg-ssot-v4.17.2 (d5a6cab1cb09), 504 arquivos
```

| Opção | Efeito |
|---|---|
| `--source REPO` | O repositório (caminho ou URL, como `https://github.com/marciocar/kg-ssot`) que tem a tag. Obrigatório quando você roda de dentro de um vendor |
| `--dest DIR` | Onde fica o vendor (default `vendor/kg-ssot`) |
| `--profile gate` | Traz só o mínimo para rodar o gate e o check (12 arquivos desde a 4.18.0, sem a suíte); `--profile full` volta à release inteira |
| `--force` | Substitui um vendor editado localmente |
| `--index` (no `check`) | Confere o índice do git em vez da árvore de trabalho |

**Por que `-B`?** Os scripts do kit não gravam bytecode, mas uma ferramenta sua que **importa** um módulo do kit
grava o `.pyc` dentro do vendor, e o próximo `check` reprova. Rode tudo com `python3 -I -B`, ou com
`PYTHONDONTWRITEBYTECODE=1`.

## `kg_store.py`: o armazém que só grava o que passa

Se você grava grafo por programa (um servidor de escrita, um chat, um pipeline que gera o grafo de um caso), o
`kg_store.py` é uma biblioteca, com um CLI por cima, que só escreve depois do veredito PASS do contrato. Há três
armazéns com a mesma interface (`read`, `list`, `write`, `delete`, `history`). O formato vem do nome: `.kg.yaml` é
julgado no perfil YAML e `.kg.json` no perfil JSON do contrato
([capítulo 3](03-formato.md#o-mesmo-modelo-em-kgjson)):

- `DiskStore`: só a cabeça em disco, sem histórico;
- `GitStore`: um commit por gravação ou remoção. O git roda isolado na raiz do armazém e nunca sobe para um
  repositório de fora. O autor vem de quem grava (`author="Name <email>"`), e o committer é uma identidade fixa do
  serviço;
- `VersionedStore`: a cabeça em disco mais um registro de eventos e as versões no diretório oculto `.kg-store/`,
  sem git.

Pelo pacote PyPI, é `from kg_ssot import kg_store`. Para importar do vendor, ponha `vendor/kg-ssot/tools` no
`sys.path` e rode sem gravar bytecode, como no [capítulo 6](06-adocao-e-ci.md#num-app):

```python
import kg_store

store = kg_store.GitStore("areas/ana", init=True)
r = store.write("graphs/case.kg.yaml", text, message="first graph", author="Ana <ana@example.org>",
                expected_sha256=kg_store.NEW)
if not r["written"]:
    print(r["reason"], r["verdict"])   # "gate", "conflict", "missing", or "not_judged"
```

O gate julga mais que o candidato. A ponta externa de cada entrada de `external_edges` é conferida contra o próprio
armazém, já com o candidato no lugar. Cada grafo que aponta para o nome gravado é julgado de novo, porque trocar ou
apagar um grafo pode deixar a aresta externa de outro sem ponta. O armazém só grava com PASS em todos.

Desde a 4.20.0, um objeto de armazém guarda, na memória, o veredito de cada grafo que já julgou, pela chave de tudo de
que o veredito depende: o texto e o formato dele, os dois schemas, o `limit`, a língua das mensagens, se há corpus e,
para cada ponta externa, se o id citado existe. Um grafo que aponta para o nome gravado e não mudou não é julgado de
novo enquanto as pontas dele seguem resolvidas, e um processo longo (o servidor MCP, um app que mantém o armazém
aberto) paga o custo uma vez. Gravar o mesmo texto de novo também não o rejulga pelo contrato; o gate externo
(`--gate-cmd`), se houver, roda em toda gravação. Um processo novo começa com o cache vazio, e a primeira gravação paga
o custo inteiro.

O corpus é o mesmo que o gate do repositório veria. No `GitStore`, isso quer dizer só o rastreado: um `.kg.yaml` que
está no disco sem commit não conta, nem na lista, nem no julgamento, nem na trava (para a trava, o nome está livre, e
a gravação substitui o arquivo). O `DiskStore` e o `VersionedStore` recusam uma raiz dentro de um repositório git,
onde o gate leria o rastreado e o armazém leria o disco. E a cabeça só fica trocada com o registro feito: se o commit
ou o evento falha, ela volta ao que era, e a exceção chega a quem chamou.

Para regenerar grafos que se citam, use `write_many` (desde a 4.14.0). Um a um, a troca do primeiro grafo deixaria a
aresta externa do segundo sem ponta, e o rejulgamento barraria. O conjunto inteiro, inclusive com remoções (texto
`None`), é julgado de uma vez, com todas as mudanças no lugar, e entra num registro só (um commit, ou um bloco de
eventos), ou nada entra:

```python
r = store.write_many([("case.kg.yaml", case), ("crossing.kg.json", crossing), ("old.kg.yaml", None)],
                     message="regenerate the case", expected={"case.kg.yaml": sha_read})
if not r["written"]:
    print(r["reason"], [x["reason"] for x in r["results"]])
```

Em `conflict` e `missing`, o nome que barrou o conjunto leva o motivo, e os outros voltam como `skipped`. Em `gate` e
`not_judged`, o julgamento é do conjunto inteiro, e todos os nomes voltam com esse motivo. O gate externo
(`--gate-cmd`), se houver, julga cada mudança isolada, como no `write`. Nomes do conjunto que só diferem pela caixa
são recusados, como no armazém.

O CLI tem um subcomando por operação, com a saída em JSON no stdout:

```text
kg_store.py --backend disk|git|versioned --root DIR [--init] [--gate-cmd CMD [--gate-timeout S]] list
kg_store.py ... read NAME [--ref REF]
kg_store.py ... write NAME [FILE|-] [--message M] [--author "Name <email>"] [--expected-sha256 S|new]
kg_store.py ... delete NAME [--message M] [--author A] [--expected-sha256 S]
kg_store.py ... write-many SET.json [--message M] [--author A]
kg_store.py ... history NAME
```

Pelo CLI, um grafo que passa e um que reprova:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_store.py --backend git --root areas/ana --init \
  write graphs/valid-minimal.kg.yaml vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/valid-minimal.kg.yaml \
  --author "Ana <ana@example.org>" --message "first graph"
```

```text
{
 "written": true,
 "reason": null,
 "name": "graphs/valid-minimal.kg.yaml",
 "sha256": "b725f37669f2e5979ed8c02eaae3c59ba80a490177e2f28c0cb8a580cf51cfd7",
 "ref": "2c6e97cc668be073020246d673228ec11dddb9aa",
 "verdict": { … },
 "error": null,
 "unchanged": false
}
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_store.py --backend git --root areas/ana \
  write graphs/x.kg.yaml vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml
```

```text
{
 "written": false,
 "reason": "gate",
 "name": "graphs/x.kg.yaml",
 ...
 "verdict": { "results": [ { "source": "graphs/x.kg.yaml", "verdict": "FAIL",
              "summary": { "MUST": { "form.required.node.label": 1 }, "SHOULD": {} }, ... } ] }
}
```

(O `verdict` está abreviado aqui; ele é o documento `kg-ssot.verdict/1` inteiro.)

- **`reason`:** é `null` quando gravou. `"gate"` quer dizer que o contrato reprovou o grafo, e o `verdict` diz onde.
  `"conflict"` quer dizer que o `expected_sha256` não bate com a cabeça. `"missing"` aparece quando você remove o que
  não existe. `"not_judged"` aparece quando o julgamento falhou ou saiu fora de `spec/verdict.schema.json`: nunca
  vira PASS nem `"gate"`, para quem chama distinguir "reprovou" de "não deu para julgar". Com um gate externo,
  `"gate"` com `error: "reprovado pelo gate externo"` quer dizer que o contrato aprovou e o gate de fora reprovou o
  grafo; o `verdict` é o do gate externo.
- **A trava otimista:** `expected_sha256` é o sha256 da cabeça que quem grava leu, ou `NEW` (no CLI, `new`) para
  exigir que o nome ainda não exista. Gravar o mesmo texto da cabeça devolve `written` com `unchanged` e sem commit.
- **O caminho:** o nome é relativo, termina em `.kg.yaml` ou `.kg.json` e não tem `..` nem segmento oculto. Para o
  armazém ser copiável entre sistemas, ele recusa criar um nome com segmento reservado do Windows (`CON`, `NUL`,
  `COM1`...) ou que termina em ponto (o que já existe segue funcionando), e nenhuma operação aceita um nome que só
  difere pela caixa de um que já está no armazém. A raiz, as pastas e o arquivo não podem ser link:
  - **no macOS e no Linux (POSIX),** tudo se abre por `dir_fd` com `O_NOFOLLOW`, e trocar uma pasta no meio da
    operação não desvia nada;
  - **no Windows,** que não tem `dir_fd`, cada passo do caminho é conferido por `lstat` (link simbólico, junção e
    ponto de montagem são recusados; o reparse point que não redireciona o nome, como o arquivo do OneDrive sob
    demanda, passa), o arquivo aberto tem de ser o mesmo que o `lstat` viu, e o caminho é conferido de novo depois da
    leitura e, na gravação, antes da troca final. É mais fraco: quem pode escrever dentro da raiz consegue trocar uma
    pasta entre a conferência e o uso. Num sistema de arquivos sem id de arquivo (o FAT de um pendrive), a comparação
    do arquivo aberto não prova nada, e só a recusa de link sobra. Num armazém de uma pessoa só, na pasta dela, isso
    não muda nada; para um armazém compartilhado, prefira POSIX.
- **O histórico:** `history(name)` lista as operações, da mais nova para a mais antiga, com `ref`, `op` (`write` ou
  `delete`), autor, data e mensagem. `read(name, ref=...)` lê uma versão anterior: o sha do commit no git, o `seq` do
  evento no versionado.
- **O git isolado:** o `GitStore` não lê a config do sistema nem a do usuário (sem hooks, sem gpg, sem `autocrlf`, sem
  arquivo de exclusão), então o que ele guarda é byte a byte o texto aprovado, com o sha256 do resultado.
- **O gate externo (`--gate-cmd`):** é o gancho por onde um adotante liga um segundo gate, o dele, sem o produto
  depender desse gate. O comando roda depois de o contrato aprovar, em cada gravação e cada remoção, e o armazém só
  grava com PASS dos dois. Um grafo que o contrato reprova nunca chega ao comando. O gate que o `kg_mcp.py` roda
  recebe `KG_SSOT_LANG=en`, porque o veredito dele vai ao modelo; pelo `kg_store.py`, ele herda a sua língua.
  - **A entrada:** o texto candidato vai pelo stdin em UTF-8 (vazio na remoção); leia-o como bytes e decodifique, para
    não depender da página de código do sistema. O nome e a operação vão pelo ambiente, como `KG_GATE_NAME` e
    `KG_GATE_OP` (`write` ou `delete`). O comando herda o resto do ambiente do processo, menos a variável do segredo do
    `kg_mcp` (`--secret-env`).
  - **A saída:** um documento `kg-ssot.verdict/1` válido por `spec/verdict.schema.json`, com ao menos um resultado, rc
    0 quando tudo passa e rc 1 quando algo reprova, e no máximo 16 MiB (o teto vale enquanto ele roda). O stderr do
    gate é descartado: para diagnosticar, rode o comando à mão com o mesmo stdin e o mesmo ambiente. O código de uma
    ocorrência tem de começar por uma camada do contrato (`parse.`, `form.`, `integrity.` ou `yaml.`); um gate de fora
    usa, por exemplo, `integrity.external.<nome>`.
  - **Fail-closed:** comando que não roda, que passa de `--gate-timeout` (padrão 60 s, no máximo 86.400), que sai sem
    JSON, com saída grande demais, com JSON fora do schema ou sem resultado, com rc fora de 0 e 1 ou com rc que não
    bate com o veredito dá `"not_judged"`, nunca PASS, e nada é gravado. No tempo esgotado, numa interrupção (Ctrl+C),
    num SIGTERM ao processo ou com a saída grande demais, morrem o comando e os processos que ele abriu. No Windows,
    matar o processo à força (o "Finalizar tarefa") não deixa tratador nenhum agir, e o gate que estiver rodando pode
    ficar. No macOS e no Linux, um processo que o gate deixa rodando depois de terminar bem também é morto (o grupo de
    processos dele); no Windows, não, então o gate de um adotante não deve deixar nada para trás. `--gate-cmd ""` dá
    rc 2, para uma variável vazia nunca subir um servidor sem o gate dele; `--gate-timeout` sem `--gate-cmd` e, no
    `kg_mcp.py`, `--gate-cmd` com `--read-only` (o gate nunca rodaria) também dão rc 2.
  - **A trava:** o gate roda sob a trava da gravação. Um gate lento segura as outras gravações do mesmo armazém até o
    `--gate-timeout`; no stdio, segura o servidor.
  - **O mesmo texto:** gravar de novo o texto da última versão também passa pelo gate. Se ele reprovar agora, a
    resposta é `"gate"`, mesmo sem nada a mudar.
  - **Sem shell:** o comando é uma lista de argumentos, nunca uma linha de shell. No macOS e no Linux, a linha segue
    as regras do `shlex` (a barra invertida escapa; ponha o caminho entre aspas). No Windows, as aspas duplas agrupam
    e a barra invertida fica como está, como no comando `"C:\Program Files\Python\python.exe" C:\gates\x.py`. As
    aspas valem em volta do argumento inteiro: `--opt="a b"` vira dois argumentos, e aspas simples não agrupam. O
    texto do grafo só chega pelo stdin, então `$(...)` ou `;` nele não executam nada.
  - **Pela biblioteca:** `open_store(..., gate=CommandGate(argv, timeout))`, ou qualquer chamável
    `(name, text, op) -> (verdict, error)`. Um chamável que levanta exceção também dá `"not_judged"`.

  Um gate de exemplo, só com a biblioteca padrão, que reprova todo texto com a palavra FORBIDDEN:

  ```python
  import json, os, sys
  bad = "FORBIDDEN" in sys.stdin.buffer.read().decode("utf-8")
  occ = [{"level": "MUST", "code": "integrity.external.forbidden-word", "place": "arquivo", "path": "",
          "line": None, "message": "the text has a forbidden word"}] if bad else []
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
    --gate-cmd "python3 -I gates/forbidden.py" write graphs/a.kg.yaml graph.kg.yaml
  ```
- **O que fica com o adotante, de propósito:** autenticação, identidade, área por usuário (uma raiz por usuário),
  tamanho máximo, número de grafos, timeout e a trava entre processos onde não há `flock` nem `msvcrt`.
- **O rc do CLI:** 0 gravou ou leu, 1 recusado (`gate`, `conflict`, `missing`, nome inexistente) e 2 entrada
  quebrada ou `not_judged`.

## `kg_mcp.py`: o servidor MCP de referência

Para dar a um modelo o contrato e o armazém sem escrever um servidor, o `kg_mcp.py` fala o
[Model Context Protocol](https://modelcontextprotocol.io) por stdio (uma mensagem JSON-RPC por linha) ou por HTTP
(`POST /mcp`, resposta JSON, sem stream). Ele usa só a biblioteca padrão, o leitor e o armazém, e é um adaptador: o
produto não depende dele, e ele não depende de nenhum cliente específico.

| Ferramenta | O que faz |
|---|---|
| `kg_validate` | Julga um texto `.kg.yaml` sem gravar e devolve o `kg-ssot.verdict/1` (com o armazém como corpus, se há armazém) |
| `kg_write` | Grava pelo armazém, só com PASS; devolve o resultado do `kg_store` com o veredito |
| `kg_delete` | Remove pelo armazém, se nenhum grafo que aponta para o nome reprovar sem ele |
| `kg_get` | Lê um grafo, ou uma versão anterior com `ref` |
| `kg_list` | Lista os grafos do armazém |
| `kg_history` | As operações de um grafo, da mais nova para a mais antiga |
| `kg_query` | A consulta e a projeção do `kg_query.py` sobre o armazém: filtros, a fila dos abertos, a vizinhança e `fields`, paginada por cursor |
| `kg_terms` | Desde a 4.19.0: resolve um termo de domínio pelo nome preferido ou por um sinônimo (o perfil `x_term`), com a fonte, a versão e a data de conferência de cada sinônimo e o termo que substitui um termo substituído; sem `text`, lista os termos |
| `kg_schema_help` | O contrato vigente, para um modelo: os schemas MUST e SHOULD inteiros, um exemplo mínimo que passa, as regras de integridade e a correção dos códigos mais comuns |

Desde a 4.17.2, cada ferramenta anuncia no `tools/list` as anotações do MCP: as de leitura (`kg_validate`, `kg_get`,
`kg_list`, `kg_query`, `kg_terms`, `kg_history`, `kg_schema_help`) com `readOnlyHint` e `idempotentHint`, e o `kg_write` e o
`kg_delete` com `destructiveHint`; todas com `openWorldHint: false`, porque o armazém é local. São dicas para o cliente
pedir ou dispensar a confirmação; o gate do armazém segue decidindo o que é gravado.

Sem `--root`, só `kg_validate` e `kg_schema_help` aparecem. Com `--read-only`, `kg_write` e `kg_delete` somem da
lista.

Com `--store-optional`, uma raiz que não abre (um arquivo no lugar da pasta, uma pasta sem permissão) não derruba o
servidor. Ele sobe só com `kg_validate` e `kg_schema_help` e diz o motivo ao modelo, nas instruções, na descrição das
duas ferramentas e num campo `store` do `kg_schema_help`. Assim o modelo conta ao usuário por que não há `kg_write`, em
vez de supor um modo só leitura. Sem a opção, a raiz que não abre é rc 2, com a mensagem no stderr.

Uma configuração de cliente por stdio, com um armazém versionado fora do repositório:

```json
{
  "mcpServers": {
    "kg-ssot": {
      "command": "python3",
      "args": ["-I", "-B", "vendor/kg-ssot/tools/kg_mcp.py",
               "--root", "/path/to/store", "--backend", "versioned", "--init",
               "--author", "Assistant <assistant@example.org>"]
    }
  }
}
```

| Opção | Efeito |
|---|---|
| `--root DIR` | O armazém. Sem ele, só `kg_validate` e `kg_schema_help` |
| `--backend disk\|git\|versioned` | O tipo de armazém (default `disk`) |
| `--init` | Cria a raiz se não existir |
| `--author "Name <email>"` | Quem assina as gravações |
| `--read-only` | Tira `kg_write` e `kg_delete` |
| `--http PORT` · `--host H` · `--allow-remote` | HTTP no lugar do stdio; fora do loopback, só com `--allow-remote`, que exige `--secret-env` |
| `--secret-env VAR` · `--secret-header H` | O segredo compartilhado, lido da variável `VAR`, que cada requisição HTTP traz no header `H` (padrão `X-Api-Key`), comparado por hmac |
| `--identity-header H` | O perfil "atrás de proxy": a identidade de cada requisição vem do header `H` (um e-mail), com área e autor próprios; exige `--secret-env` |
| `--max-bytes N` | O tamanho máximo de um grafo (default 2.000.000) |
| `--max-graphs N` | Grafos por armazém, ou por área no perfil; além disso, um nome novo é recusado |
| `--max-concurrent N` | Requisições HTTP ao mesmo tempo; além disso, 503 |
| `--store-optional` | Uma raiz que não abre não derruba o servidor: ele sobe sem armazém e diz o motivo ao modelo |
| `--gate-cmd CMD` · `--gate-timeout S` | Um gate externo depois do contrato, em toda gravação e remoção, também por área no perfil (veja o `kg_store.py`) |

Uma gravação recusada, como o modelo a recebe (o `structuredContent`, abreviado):

```text
{
 "written": false,
 "reason": "gate",
 "name": "graphs/x.kg.yaml",
 "verdict": { "results": [ { "verdict": "FAIL",
   "occurrences": [ { "code": "form.required.node.label", "place": "nó Q_A", "path": "nodes[0]", "line": 5,
                      "message": "Falta o campo obrigatório «label» no nó.",
                      "hint": "Acrescente label: a afirmação curta do nó, até 280 caracteres." } ] } ] },
 ...
}
```

A resposta de `tools/call` traz o mesmo objeto em `structuredContent` e, como texto JSON, em `content`. Uma gravação
recusada ou um nome inexistente vem com `isError: true`, para o modelo corrigir e tentar de novo.

- **Quem assina:** o autor das gravações é o `--author` do servidor ou, no perfil "atrás de proxy", a identidade
  autenticada da requisição. Nunca é um argumento da ferramenta: o modelo não escolhe quem assina.
- **Os limites:** `--max-bytes` (padrão 2.000.000) limita o texto de um grafo. Os argumentos são conferidos contra o
  `inputSchema` que o `tools/list` anuncia: tipo errado, campo obrigatório ausente e campo desconhecido voltam como
  `isError`. Uma falha interna vira o erro JSON-RPC -32603, e o processo segue atendendo.
- **O leitor por trás:** um documento que abre mais de 1.000 coleções de uma vez (em flow, em bloco ou por
  indentação), ou cujos aliases expandem para mais que o dobro do tamanho do texto, reprova com `parse.yaml-error`
  antes de ser construído. Sem esse teto, uma mensagem de 60 KB derrubava o processo. Colchete dentro de texto não
  conta.
- **O protocolo:** uma mensagem por vez; lote JSON-RPC é recusado (saiu do MCP em 2025-06-18), e o id tem de ser
  texto ou inteiro. O stdio lê e escreve UTF-8 como bytes, independente do locale, e a resposta sai em JSON ASCII.
- **O HTTP:** escuta em `127.0.0.1` por padrão. Recusa `Origin` cujo host não seja de loopback (contra DNS
  rebinding), `MCP-Protocol-Version` desconhecida (400) e corpo sem `Content-Length`. Não há TLS: o servidor só sai
  do loopback com `--allow-remote`, que exige `--secret-env`, para rodar numa rede privada atrás de um proxy com TLS.
- **O perfil "atrás de proxy" (`--identity-header`):** é o modo para um cliente com muitos usuários, como o
  LibreChat, que manda o usuário logado num header.
  - **Recusa por padrão:** toda requisição traz a identidade (um e-mail) e o segredo compartilhado. Sem identidade,
    com identidade vazia (o LibreChat troca um placeholder ausente por texto vazio) ou malformada, ou com o segredo
    errado, a resposta é 401, antes de qualquer ferramenta rodar.
  - **Área e autor:** cada identidade grava na própria área sob `--root`, num diretório `u-<nome>-<hash>`, e não
    enxerga a dos outros. As gravações dela são assinadas na forma `parte-local <e-mail>`. O e-mail não distingue
    caixa: `Ana@X.org` e `ana@x.org` são a mesma identidade.
  - **Por requisição:** identidade, área e autor viajam num contexto de cada requisição, e nunca num atributo do
    servidor, que é um só entre as threads. Guardá-los no servidor deixaria uma requisição concorrente gravar na área
    de outra, a classe do CVE-2026-25536 do SDK TypeScript. Um teste determinístico confere que nenhuma requisição
    deixa ou troca estado no servidor, e outro teste, com duas identidades em paralelo, exercita o isolamento de
    ponta a ponta. Um header de identidade ou de segredo repetido é recusado, para um proxy que acrescente o header em
    vez de substituí-lo não deixar o cliente escolher a identidade.
  - **O modelo de confiança:** quem tem o segredo afirma qualquer identidade. O segredo autentica o proxy (o
    LibreChat), e é o proxy que autentica o usuário. Por isso o segredo nunca vai a um cliente final, e o servidor
    fica numa rede que só o proxy alcança.
  - **Os limites:** `--max-graphs` vale por área e é contado sob a trava da gravação, então gravações paralelas não
    passam juntas dele. `initialize`, `ping` e as notificações não abrem nem criam área, e com `--read-only` a área
    que ainda não existe não é criada. O número de áreas não tem limite: quem tem o segredo cria uma por identidade
    nova (o modelo de confiança acima), e o servidor guarda as áreas abertas em memória enquanto roda.
  - **A raiz das áreas:** é conferida ao subir. Valor vazio, raiz inexistente sem `--init`, arquivo ou link dá rc 2,
    a menos que você passe `--store-optional`, como na raiz fora do perfil.
  - **O envelope `untrusted_data`:** `kg_get`, `kg_list`, `kg_history`, `kg_query` e `kg_terms` devolvem `{"untrusted_data": ...,
    "notice": ...}`, para o modelo tratar o texto gravado por outros como dado, nunca como instrução.
  - **O que o perfil não é:** é "atrás de proxy", numa rede privada. Não é o perfil OAuth da especificação MCP, que
    espera até haver uma matriz medida de clientes.
- **A imagem OCI:** `ghcr.io/marciocar/kg-ssot:<version>` traz o `kg-mcp` pronto, para rodar como serviço ao lado de
  um cliente sem Python, como o LibreChat. Ela é construída do mesmo wheel do PyPI, com as dependências fixadas por
  hash e a base fixada por digest (`packaging/oci/Dockerfile`), roda com um usuário sem privilégio (uid 10001) e
  guarda o armazém no volume `/data`. Leva o label `io.modelcontextprotocol.server.name`, que o MCP Registry usa para
  conferir a posse. O workflow do espelho a publica atrás de aprovação, com a atestação de proveniência
  (`gh attestation verify oci://ghcr.io/marciocar/kg-ssot:<version> --repo marciocar/kg-ssot`).
  - **Por stdio:** `docker run -i --rm ghcr.io/marciocar/kg-ssot:<version>` só julga. Com `-v kg-data:/data` e
    `--root /data/graphs --init`, grava.
  - **Ao lado do LibreChat:** o perfil "atrás de proxy", na rede do compose e sem porta publicada no host:

    ```yaml
    # docker-compose.override.yml
    services:
      kg-ssot:
        image: ghcr.io/marciocar/kg-ssot:<version>
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
      allowedDomains:  # a CLOSED list: only the listed domains pass, for every MCP server reached by URL
        - kg-ssot        # the service name in compose
        # - the domains of the other MCP servers this librechat.yaml already uses
    mcpServers:
      kg-ssot:
        type: streamable-http
        url: http://kg-ssot:8080/mcp
        headers:
          X-User-Email: "{{LIBRECHAT_USER_EMAIL}}"
          X-Api-Key: "${KG_MCP_SECRET}"
    ```

    Uma lista `allowedDomains` que não está vazia é fechada: só os domínios dela passam, para todos os servidores MCP
    alcançados por URL. Se o seu `librechat.yaml` já tem outros servidores, ponha os domínios deles na mesma lista,
    senão eles param de funcionar.

    O `--host 0.0.0.0` é o de dentro do container: sem porta publicada, só os containers da rede do compose alcançam
    o serviço (a rede padrão do compose não é `internal`, então o container ainda sai para a internet). Sem
    `KG_MCP_SECRET`, o container sai com rc 2 e não serve nada. O segredo fica no `.env` do compose, nunca no
    `librechat.yaml` versionado. Como toda variável de ambiente de container, ele aparece no `docker inspect`: quem
    tem acesso ao docker do host o lê, como já lê o `.env`.
  - **O volume:** com um volume nomeado, como no compose acima, o `/data` já nasce do usuário da imagem. Com uma pasta
    do host montada em `/data`, ela tem de ser do uid 10001 (`chown 10001:10001 <pasta>`); senão o container sai com
    rc 2 e `Permission denied`.
  - **A plataforma:** a imagem sai só para `linux/amd64`.
  - **O que a imagem não faz:** TLS e exposição para fora da rede do compose ficam com o proxy do adotante, como no
    perfil.
- **Num repositório:** o armazém de disco e o versionado recusam raiz dentro de um repositório git (veja o
  `kg_store.py`). Dentro do repositório, use `--backend git --root .`, que faz um commit por gravação no branch atual,
  fora de qualquer PR (rode-o num branch de trabalho), ou rode sem `--root` para só julgar.
- **O que fica com o adotante, de propósito:** o TLS, o perfil OAuth, cota por usuário e timeout por ferramenta.
- **Cliente que guarda o `tools/list`:** alguns clientes, como o LibreChat, validam os argumentos contra o
  `tools/list` que guardaram ao subir. Depois de uma atualização que muda o `inputSchema` de uma ferramenta (um
  argumento novo, um valor novo num enum), reinicie o cliente, ou ele recusa o argumento novo antes de chamar o
  servidor. Um adotante já tropeçou nisso e passou a reiniciar o cliente no deploy quando o `tools/list` muda.
- **As duas eras do protocolo:** o servidor fala as duas, e cada requisição escolhe a sua era.
  - **A era nova, `2026-07-28`, sem estado:** toda requisição traz no `params._meta` a versão
    (`io.modelcontextprotocol/protocolVersion`) e as capacidades do cliente
    (`io.modelcontextprotocol/clientCapabilities`).
    - **O que o servidor implementa:** `server/discover`.
    - **O que todo resultado traz:** `resultType` e o `serverInfo` no `_meta`.
    - **As dicas de cache:** `server/discover` e `tools/list` trazem `ttlMs` e `cacheScope`, que é `private` no
      perfil "atrás de proxy", porque a lista depende da área.
    - **Os erros, com o status HTTP da especificação:**
      - falta um campo obrigatório do `_meta`: -32602, com 400;
      - versão que o servidor não suporta: -32022, com 400 e, em `data.supported`, a mesma lista do
        `server/discover` (as duas eras), por qualquer caminho; uma versão da era antiga pedida no `_meta` também dá
        -32022, com a mensagem de que ela só vale pelo `initialize`;
      - método desconhecido: -32601, com 404;
      - header que falta ou diverge do corpo (`MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`, com o sentinela
        base64): -32020, com 400.
  - **A era antiga (`2025-11-25`, `2025-06-18`, `2025-03-26`, `2024-11-05`):** segue com `initialize`, que responde
    com a versão pedida quando a conhece. O servidor nunca emite `Mcp-Session-Id`, e GET e DELETE dão 405.
  - **Medido com clientes oficiais:** o SDK Python `mcp` 2.3.0, que é o v2, na era nova, por stdio e por HTTP; e os
    SDKs TypeScript 1.30.0, o que o LibreChat usa, e 1.32.1 na era antiga. O CI roda os três.

## `kg_query.py`: a consulta e a projeção do corpus

Lê muitos grafos de uma vez e seleciona nós, sem julgá-los (o veredito é do `kg_validate.py`). Cada nó sai
projetado: as arestas de saída e de entrada, com a outra ponta resolvida para o label, local ou externa, e se essa
ponta existe no corpus lido. Com `--root`, o corpus são os `.kg.yaml` e `.kg.json` que o git rastreia sob a pasta
(fora do git, todos sob ela), e os caminhos saem relativos a ela, porque é a raiz contra a qual a ponta externa
`<caminho>#<id>` se resolve.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --open --sort impact          # the open queue
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --around alvo.kg.yaml#EV_A    # the neighborhood of a node
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --text "gate base" --type decision --format json
```

Saída real, na pasta `external-corpus` da suíte (cortada):

```text
alvo.kg.yaml  EV_A  evidence/confirmed/DEV imp=3  A evidência sintética que sustenta A.
    → SUPPORTS Q_A  A pergunta sintética A.
    → REFUTES valid-corpus-external-refutes-refuted.kg.yaml#EV_A  A evidência sintética que sustenta A.
    → REFUTES warn-corpus-external-refutes-live.kg.yaml#EV_A  A evidência sintética que sustenta A.
    ← REFUTES valid-corpus-external-refutes-outgoing.kg.yaml#EV_A  A evidência sintética que sustenta A.
    ← SUPERSEDES valid-corpus-target-exists.kg.yaml (o grafo inteiro)
```

| Opção | O que faz |
|---|---|
| `--root DIR` ou arquivos | O corpus. Com `--root`, o vendor e as fixtures ficam de fora por padrão (`vendor/*`, `fixtures/*`, `*/fixtures/*`, `docs/materials/*` e, desde a 4.20.0, toda pasta com o carimbo `.kg-ssot-version`); `--exclude GLOB` (repetível) tira mais caminhos, e `--no-default-excludes` lê tudo. Um arquivo que você nomeia um a um nunca é excluído |
| `--id`, `--id-prefix`, `--type`, `--status`, `--plane`, `--layer`, `--file` | Filtros, todos combinados em E |
| `--text PALAVRAS` | Palavras que o label contém, todas, sem distinguir maiúscula; `--in-narrative` procura também na narrative |
| `--open` | A fila dos abertos (status `open`) |
| `--verified-before AAAA-MM-DD` | Os nós sem `verified_at`, ou conferidos antes da data |
| `--around ID` | A vizinhança: `<caminho>#<id>`, ou um id único no corpus; `--depth`, `--edge-type` (repetível), `--direction out\|in\|both` |
| `--sort corpus\|impact` | A ordem do corpus, ou o impacto declarado. A fórmula de atenção fica com o radar de quem a usa |
| `--limit N` e `--cursor C` | A página (até 1000) e o cursor da próxima, que vale para a mesma consulta sobre o mesmo corpus |
| `--fields GLOB` | Chaves do nó que saem em `extra`, como estão no grafo: `--fields 'x_*'` |
| `--narrative` | Inclui a narrative de cada nó |
| `--format json` | O formato estável `kg-ssot.query/1` (`spec/query.schema.json`) |

O grafo que não parseia sai em `unreadable`, com o código `parse.*` dele, e não derruba a consulta. O label da outra
ponta de cada aresta sai cortado em 200 caracteres: um nó de label longo citado por milhares de arestas não
multiplica a resposta. rc 0 quando consultou, mesmo sem nó; 2 na entrada quebrada. No servidor MCP, a mesma consulta
é a ferramenta `kg_query`, sobre o armazém: a página para no teto de bytes do servidor (com ao menos um nó), e o
`next_cursor` continua de onde ela parou. Cada chamada relê e reparseia o armazém da área, e num armazém de dezenas
de MB a primeira chamada leva dezenas de segundos; o cache do julgamento vem na 4.19.

## `kg_diff.py`: o diff por id entre revisões

Compara dois grafos, ou todos os grafos que mudaram entre duas revisões do git, alinhando os nós pelo id e as
arestas pelas pontas e o tipo. O que só existe de um lado foi acrescentado ou removido, e o que existe nos dois sai
com cada campo que mudou, antes e depois. A ordem dos nós no arquivo não conta; uma troca de id é remoção mais
acréscimo; uma lista dentro do nó é comparada inteira; a aresta que troca de tipo com as mesmas pontas sai como
mudança de `edge_type`. A revisão é lida pelo `git show`, sem checkout. Não é patch: o diff informa, não se aplica.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_diff.py notice.kg.yaml erratum.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_diff.py HEAD~1:docs/x.kg.yaml HEAD:docs/x.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_diff.py --from origin/main --ignore verified_at      # everything that changed on the branch
```

Saída real, entre dois casos da suíte:

```text
valid-node-touched-only-as-target.kg.yaml (modificado)
  ~ meta.id: valid-chain → valid-node-touched-only-as-target
  + C_ALVO  Nó sintético C_ALVO.
  - C_B  Nó sintético C_B.
  + aresta EV_A -SUPPORTS-> C_ALVO
  - aresta C_B -SUPPORTS-> EV_A
· 1 grafo(s): 1 modificado(s), 0 acrescentado(s), 0 removido(s), 0 não lido(s); nós +1 -1 ~0; arestas +1 -1 ~0
```

O campo que sai de um caminho e entra noutro com o mesmo valor, num nó, numa aresta ou no meta, aparece como
renomeação (`x_location → x_storage (renomeado)`) quando o valor não é trivial e é único dos dois lados. No JSON, as
duas entradas ficam, cada uma com o valor do seu caminho, ligadas por `renamed_to` e `renamed_from`; o texto humano e
o resumo por campo mostram uma linha só. Com `--from` e sem caminhos, o vendor e as fixtures ficam de fora (também uma
pasta `fixtures/` na raiz e, desde a 4.20.0, toda pasta com o carimbo `.kg-ssot-version` em qualquer dos lados), como
no `kg_query`: uma atualização do vendor muda as fixtures da suíte às centenas.
`--exclude` e `--no-default-excludes` valem do mesmo jeito. O meta sai junto com as outras chaves da raiz, os valores
se comparam na forma JSON do contrato, um arquivo renomeado sai como remoção mais acréscimo, e sem `--to` (ou com
`--to WORKTREE`, desde a 4.20.0) o lado de depois é a árvore de trabalho, e entram também os grafos novos ainda não
adicionados ao git. `WORKTREE:CAMINHO` lê o arquivo da árvore de trabalho, a partir da raiz do repositório como o
`REV:CAMINHO` e nunca fora dele (o `./` e o `../` do git, relativos ao diretório atual, não valem), para revisar uma
edição antes
do commit (`HEAD:docs/x.kg.yaml WORKTREE:docs/x.kg.yaml`); uma branch chamada `WORKTREE` se lê como
`refs/heads/WORKTREE`. O lado que não se lê (não é UTF-8, ou não parseia) sai em
`unreadable` e conta como diferença; a revisão que começa com `-` é entrada quebrada. Num argumento, o caminho que
existe no disco vence a leitura `REV:CAMINHO`.

`--ignore CAMPO` (repetível) tira um campo da comparação, com tudo o que fica abaixo dele (`provenance` tira os três;
no meta, `meta.date`): o `verified_at` que um gerador recarimba a cada execução esconde o sinal, e o resumo conta os
nós por campo mudado para mostrar isso. `--format json` dá o `kg-ssot.diff/1` (`spec/diff.schema.json`). rc 0 sem
diferença, 1 com diferença, 2 na entrada quebrada.

## `kg_vocab.py`: o vocabulário de domínio

Lê os termos do perfil `x_term` (capítulo 3) de um corpus, com `--root` ou com os arquivos, e faz três coisas: lista,
resolve um texto para o termo e exporta.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vocab.py terms --root . --as-of 2027-05-01      # termos, sinônimos, o que vence
python3 -I -B vendor/kg-ssot/tools/kg_vocab.py lookup "codigo de barras" --root .     # o termo por trás de um texto
python3 -I -B vendor/kg-ssot/tools/kg_vocab.py lookup "cod barras" --case "edital 12" --root .
python3 -I -B vendor/kg-ssot/tools/kg_vocab.py export --to skos --root . > vocab.ttl
python3 -I -B vendor/kg-ssot/tools/kg_vocab.py export --to ossie --root . > vocab.ossie.json
```

- **O `lookup` compara sem maiúscula, acento nem espaço repetido.** Casa o termo preferido ou um sinônimo. O sinônimo
  com escopo de caso só casa com `--case` igual ao caso dele. O sinônimo aposentado ainda casa, marcado como
  aposentado, e o termo substituído vem com os termos que o substituem. rc 1 quando nada casa.
- **O `terms` mostra quando cada sinônimo vence** (`verified_at` mais `reverify_every`, na data do `--as-of`, hoje por
  padrão). O sinônimo aposentado nunca vence.
- **O `export --to skos`** grava Turtle em SKOS-XL com os nomes da ISO 25964 (iso-thes). O conceito ganha
  `skos:prefLabel`, mais `skos:altLabel` e `skos:hiddenLabel` para os sinônimos atuais de domínio, para um leitor de
  SKOS simples enxergá-los. Cada rótulo vira um `skosxl:Label` com a forma literal e a proveniência (`dc:source`,
  `kg:locator`, `kg:sourceVersion`, `kg:verifiedAt`, `kg:reverifyEvery`). O sinônimo de caso é ligado por `kg:caseLabel`, com
  `kg:scope` e `kg:case`, e não por `skosxl:altLabel`, que implicaria um `skos:altLabel` válido para o conceito
  inteiro. Um escopo que não se lê conta como um caso que nunca casa. O aposentado sai como `isothes:status "retired"` e uma
  `skos:historyNote`. O sinônimo que repete um literal já dito no conceito vai por `kg:repeatedLabel`, e o conceito nunca
  tem o mesmo rótulo duas vezes. O termo substituído ganha `dct:isReplacedBy`. O IRI do conceito é `<base><meta.id>#<id>`, o mesmo
  que o `kg_prov_export.py` dá ao nó (`--base`, `urn:kg-ssot:graph:` por padrão); sem `meta.id`, o caminho relativo
  dado, ou o nome do arquivo, nunca um caminho absoluto.
- **O `export --to ossie`** grava um item por termo vivo para o [Apache Ossie](https://github.com/open-semantic-interchange/OSI):
  `name` (o termo preferido), `description`, `ai_context.synonyms` (os sinônimos atuais de domínio) e uma entrada de
  `custom_extensions` do `KG_SSOT` com a proveniência de cada sinônimo, porque o Ossie não tem campo para ela. Você
  junta cada item à entidade do seu modelo semântico (dataset, field ou metric) pelo nome.
- Com `--format json`, o `terms` e o `lookup` usam o formato `kg-ssot.vocab/1` (`spec/vocab.schema.json`). A ferramenta
  não julga: o `x_term` fora do perfil é lido no que dá para ler, e o SHOULD acusa o resto.

## `kg_criterion.py`: o critério pré-registrado (4.21.0)

O leitor já avisa, entre nós do mesmo grafo, o critério que não existe, o `sha256` citado que não é o da versão e o
resultado medido depois de ver o dado (capítulo 3, `x_criterion` e `x_measured_under`). Ele não calcula hash nem lê
corpus, para que um leitor JavaScript fique sem criptografia. Esta ferramenta faz o resto, a partir da raiz do
repositório:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_criterion.py digest --text "Passes with 9 of 10 replicas."
python3 -I -B vendor/kg-ssot/tools/kg_criterion.py digest --ref criteria/a7.tsv                  # o arquivo inteiro
python3 -I -B vendor/kg-ssot/tools/kg_criterion.py digest --ref data/judge-verdicts.json#CU1      # um item de lista
python3 -I -B vendor/kg-ssot/tools/kg_criterion.py check --root .
```

- **`digest`** imprime o `sha256` a escrever no `x_criterion`. As formas:
  - `text`: UTF-8, com CRLF e CR sozinho trocados por LF, e sem o espaço (U+0020) no fim de cada linha. O TAB fica.
  - `ref` sem fragmento: os bytes do arquivo com CRLF trocado por LF, e mais nada. Um TSV guarda as colunas vazias, com
    TAB no fim da linha.
  - `ref` com fragmento: o item na forma canônica JCS ([RFC 8785](https://www.rfc-editor.org/rfc/rfc8785)), de um
    arquivo `.json`, `.yaml` ou `.yml`. O fragmento é um JSON Pointer (`#/criteria/0`) ou o `id` de um item de lista
    (`#CU1`), único no arquivo.
- **`check`** confere cada `x_criterion` com exatamente um de `ref` e `text` contra ele:
  - `integrity.criterion-digest` quando o `sha256` não bate;
  - `integrity.criterion-ref-unreadable` quando o arquivo, o fragmento ou um valor não se lê: um NaN no JSON, um
    inteiro além de ±(2^53−1), uma chave repetida, uma chave de mapa YAML que não é texto, ou um caminho que não é
    arquivo comum ou passa de 64 MiB;
  - `integrity.criterion-malformed` quando a versão não se confere: o `sha256` não é texto (um hash só de dígitos, sem
    aspas, vira número), ou não há exatamente um de `ref` e `text`, em texto. O `x_measured_under` que não é um mapa com
    uma lista de citações em mapa, e a citação de outro grafo cujo `sha256` não é texto (mesmo quando esse grafo não foi
    dado), saem do mesmo jeito. Desde a 4.21.1; antes, o check os pulava.
- **Citações de outro grafo.** O `check` segue também cada citação `<caminho>#<id>` de um `x_measured_under`, pela
  mesma regra do leitor: `integrity.criterion-unknown`, `integrity.criterion-sha-mismatch`,
  `integrity.measured-post-hoc` e `integrity.measured-order-unknown`.
- **O que ele lê.** Só com o `--root`, o `check` lê os grafos que o git rastreia sob ele, sem o vendor. Com arquivos,
  lê só eles, cada um pelo caminho relativo ao `--root` (a pasta atual, sem ele), que é também de onde parte cada `ref`,
  então `g/a.kg.yaml#C1` acha o arquivo como quer que ele tenha sido digitado; a citação de um grafo que não foi dado é
  contada como sem conferir, não como achado, e o `--exclude` dado vale para os arquivos também.
- **Caminhos.** O `ref` não pode sair da raiz. O último `#` separa o caminho do fragmento, e o fragmento vazio
  (`a.json#`) é o documento inteiro. Um `.yaml` pede um mapa na raiz. A marca de ordem de bytes no começo do
  `--text-file` não faz parte do texto.
- **Saída e rc.** `--format json` dá o `kg-ssot.criterion/1` (`spec/criterion.schema.json`). rc 0 sem achado, 1 com
  achado ou com grafo que não se lê, e 2 na entrada quebrada.
- **O que ele não confere.** O `check` confere que cada versão bate hoje com o texto dela, não o histórico: editar um
  critério no lugar e escrever o `sha256` novo passa, e só um resultado que cite o `sha256` antigo mostra a troca.
  Revise no `kg_diff` um `x_criterion.sha256` que mudou (ele aparece como campo mudado do nó): uma régua nova é uma
  emenda, um nó novo com `amends`.
- **No CI.** O leitor não calcula hash, então o critério editado no lugar sem `sha256` novo só é pego aqui: se os seus
  grafos usam `x_criterion`, ponha `python3 -I -B vendor/kg-ssot/tools/kg_criterion.py check --root .` ao lado do
  gate.

## `kg_audit.py`: o pacote de auditoria por pergunta (4.22.0)

O auditor pede o pacote por pergunta: a resposta, as afirmações, a evidência com data, a lacuna e o dono, numa planilha.
O grafo já guarda tudo isso; esta ferramenta o dispõe, uma linha por item de questionário, em CSV, XLSX ou JSON. Ela
não julga a forma (isso é do `kg_validate.py`) e não escreve nada no grafo.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_audit.py --root . --questionnaire "Q-2026" --as-of 2026-10-23
python3 -I -B vendor/kg-ssot/tools/kg_audit.py --root . --format xlsx --output pacote.xlsx
python3 -I -B vendor/kg-ssot/tools/kg_audit.py --root . --format csv --view evidence > evidencia.csv
```

- **O item** é o par (questionário, número) que o `x_questionnaire` nomeia (`name` e `questions`). Quem entra:
  - a pergunta: o nó `question` com o perfil;
  - a resposta: o nó (não `question`) com o perfil do item, e o nó sem perfil ligado à pergunta por `DEPENDS_ON`, numa
    direção ou na outra (as duas convivem nos grafos reais; a resposta sai uma vez). O nó com perfil já disse a que
    item responde, então uma aresta nunca o puxa para outro item;
  - a evidência: o nó com `SUPPORTS` para uma resposta, ou com `SUPPORTS` ou `TRACES_TO` para a pergunta, para um pedido
    ou para um requisito de evidência do item, local ou de outro grafo (`external_edges`); uma pergunta, um pedido ou um
    requisito nunca é evidência;
  - a contradição: o nó com `REFUTES` para a resposta ou a pergunta. Só a resposta viva traz evidência e contradição:
    a `superseded` ou a `refuted` (uma refutação já reconciliada) não fecha nem abre lacuna do item;
  - o pedido de evidência (`role: evidence_request`) e o requisito de evidência (`role: evidence_requirement`, "que
    evidência este item exige", em coluna própria): nunca são tomados por pergunta nem por resposta. Cada evidência diz
    de que pedido veio (o pedido para o qual ela aponta por `SUPPORTS` ou `TRACES_TO`). O item que só um pedido ou um
    requisito cita também sai, com as lacunas do que falta.
- **As lacunas** são calculadas, nunca escritas à mão:
  - `no-answer`: sem resposta viva (a resposta `refuted` ou `superseded` entra na lista, com o status, mas não conta);
  - `contradicted`: um `REFUTES` de um nó que não é `refuted` nem `superseded`;
  - `no-confirmed-evidence`: nenhuma evidência com `status: confirmed` (a evidência não confirmada entra na lista, mas
    não fecha lacuna);
  - `evidence-unstamped`: evidência confirmada sem `verified_at` válido;
  - `evidence-cadence-invalid`: evidência confirmada cujo `reverify_every` não é duração, e que por isso nunca venceria;
  - `evidence-due`: evidência confirmada cujo `verified_at` mais o `reverify_every` cai no `--as-of` ou antes (hoje, por
    padrão);
  - `verdict-open`: sem veredito vivo, ou um que não é `meets` nem `not_applicable`.
- **Nada some em silêncio.** O nó cujo `x_questionnaire` não tem `name` ou uma lista `questions` não vazia, o nó com `role` fora do
  enum e o número de `questions` que não é texto (`questions: [7]` sem aspas) não entram: saem em `skipped`, no próprio
  pacote (a planilha Pulados do XLSX, o `--view skipped` no CSV, o JSON), no stderr e na listagem humana, e o
  `--fail-on-gap` dá rc 1 com eles.
- **As suas colunas.** `--column <chave>` traz uma chave do nó de resposta (uma `x_` sua, como a lista de cards de
  remediação) como mais uma coluna. Uma lista vira itens separados por `; `.
- **Os formatos.**
  - `csv`: as perguntas (uma linha por item) ou, com `--view evidence`, a evidência (uma linha por item e evidência,
    com os problemas do carimbo) ou, com `--view skipped`, o que foi pulado, em UTF-8 com a marca de ordem de bytes para o Excel ler. A célula que começa com `=`,
    `+`, `-`, `@`, tab ou retorno de carro ganha um apóstrofo na frente, para nunca rodar como fórmula (a regra da OWASP
    contra injeção em CSV).
  - `xlsx`: as três planilhas (perguntas, evidência, pulados) num arquivo, escrito só com a biblioteca padrão, todo valor como texto, o cabeçalho
    congelado e a célula cortada no teto do Excel, de 32.767 unidades UTF-16. O mesmo pacote dá os mesmos bytes.
  - `json`: `kg-ssot.audit/1` (`spec/audit.schema.json`), com tudo aninhado.
  - `human`: uma listagem curta para o terminal.
- **Saída e rc.** rc 0 quando exportou, 1 quando um grafo não se lê (o pacote ficaria incompleto em silêncio) ou, com
  `--fail-on-gap`, quando um item tem lacuna ou algo foi pulado, e 2 com entrada quebrada. O `xlsx` pede `--output`. Dê o corpus com
  `--root`: a aresta para outro grafo se resolve pelo caminho a partir da raiz.

## `kg_prov_export.py`: a proveniência em PROV-O

Exporta um `.kg.yaml` para [PROV-O](https://www.w3.org/TR/prov-o/) em JSON-LD, para quem já usa ferramentas do
ecossistema W3C PROV. Cada nó vira uma `prov:Entity`. Um nó com `provenance` ganha `prov:wasDerivedFrom` apontando
para a fonte e uma `prov:Derivation` cuja atividade carrega o `method`; o `locator` e a `locality` vão como
propriedades `kg:`. Uma fonte que é inteira uma URL http(s) vira a própria IRI; qualquer outra fonte (um caminho, um
comando, duas URLs juntas) vira um nó em branco rotulado, um por texto distinto, para que nós com a mesma fonte
apontem para a mesma entidade.

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

O exportador não valida o grafo: rode o `kg_validate.py` antes. `--base IRI` troca o prefixo das IRIs dos nós (o
default é `urn:kg-ssot:graph:`, e cada nó fica em `<base><meta.id>#<id>`); o vocabulário `kg:` mora em
`urn:kg-ssot:vocab#`, fora desse espaço. rc 2 quando o arquivo é ilegível, não é um documento YAML único ou tem
`meta` ou `nodes` fora da forma.

## `kg_migrate.py`: o migrador por perfil

Propõe a `provenance` que o contrato v4 pede aos nós `confirmed` ou PROD que ainda não a têm, a partir de um
**perfil** que o adotante escreve e versiona: uma lista de regras em ordem (`spec/kg-migrate-profile.schema.json`),
em que a primeira que casa decide. Há um exemplo comentado em `spec/migrate-examples/company-brain.profile.yaml`,
medido sobre um corpus real de 25 grafos e 1.024 nós.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py plan  --profile kg-migrate.profile.yaml --out proposals.tsv
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py apply --profile kg-migrate.profile.yaml
```

- **O `plan` não escreve nada.** Imprime as contagens por regra e grava, com `--out`, a planilha de propostas, uma
  linha por nó, com o que vai para quem revisa e por quê. Leia a planilha antes de rodar o `apply`.
- **Cada regra faz uma de três coisas:** propor a `provenance`, rebaixar o nó para `unverifiable` (a fonte é
  irrecuperável, que é o padrão do contrato) ou só mandar o nó para revisão. O nó que nenhuma regra casa também vai
  para revisão e não recebe nada.
- **O `when` casa pelo que o nó já traz:** o trace (vazio, URL, caminho, glob, existência na árvore, expressão
  regular), o tipo, o status, o plano, o `verified_against`, o `source_kind` e as arestas `SUPPORTS` que chegam ao
  nó, com `not` e `any_of`.
- **Os templates usam os campos do nó:** `{trace}`, `{trace_path}`, `{trace_line}`, `{verified_against}`,
  `{supports}` e `{source_kind}`, e `{a|b}` pega o primeiro que não for vazio. O `note` do perfil vai no fim de todo
  detalhe do `method`, por exemplo `não reverificado na migração de 2026-10-20` (o note do perfil de exemplo).
- **O `scopes` dá `verified_scope` só por lista de ids**, nunca por padrão de texto.
- **O perfil escolhe dentro do contrato e nunca o relaxa.** Toda proposta é conferida contra o schema MUST e o schema
  SHOULD de forma antes de virar proposta. A que reprovaria vai para revisão com o motivo, e o template que resolve
  para vazio também. Um aviso de coerência que a proposta acende não a barra, porque o aviso diz a verdade sobre o
  nó. Por exemplo, um `testemunho` num nó PROD acende `integrity.testimony-in-prod`: a proposta segue, e o nó vai para
  quem revisa com o aviso nomeado.
- **O `apply` grava arquivo por arquivo, por texto, e os comentários ficam.** Depois ele relê o arquivo e confere a
  invariância: cada nó fica igual ao de antes, fora as chaves que a ação autoriza, e o diff só acrescenta linhas,
  fora a linha do status rebaixado. Um arquivo que ganharia código MUST novo, ou aviso SHOULD que o plan não
  anunciou, fica como estava. A quebra de linha do arquivo é mantida (CRLF fica CRLF), e o arquivo com quebras
  misturadas é recusado. Rodar de novo não muda nada.
- **Sem lista de grafos, a ferramenta lê os `.kg.yaml` do `git ls-files`.** Ficam de fora os padrões do `kg_gate.py`
  (`*/fixtures/*` e `docs/materials/*`), o `vendor/*`, toda pasta com o carimbo `.kg-ssot-version` (desde a 4.20.0) e
  os globs de `--exclude`, com a semântica do gate: `fnmatch`
  sobre o caminho relativo, em que `*` atravessa `/`; o `**/` do dialeto do perfil, que casa zero pastas, também
  vale. `--no-default-excludes` tira os padrões. Atenção: no `trace_path_glob` do perfil, `*` não atravessa `/`. Um
  grafo da lista que não parseia vira linha de revisão e não aborta a rodada.
- **O nó cujo `verified_scope` já é o do perfil sai como `same`**, separado dos nós que mudam, e o `apply` não o toca.
- **O caminho do trace é léxico e fica dentro da raiz do repositório.** Ele é normalizado (`./`, `a/../b`), e o que
  sai da raiz com `../` deixa de ser caminho. Um caminho absoluto ou com `~` conta como inexistente, sem consultar o
  disco da máquina.

O que fica fora, de propósito, porque é julgamento: reescrever label, mudar plano, re-medir, refutar, reconciliar com
`SUPERSEDES` e promover um nó `unverifiable`. rc 0 quando o plano sai ou o `apply` termina; rc 1 quando o `apply`
recusou algum arquivo, que fica como estava e com o motivo no relatório; rc 2 com entrada quebrada (perfil fora do
schema, regra ou id repetido, expressão regular inválida, `when` que casaria todo nó, grafo dado na linha de comando
que não parseia). O migrador viaja no vendor e não no pacote do PyPI nem no do npm.

### `keys`: a chave estranha vira `x_<chave>` (4.19.0)

```bash
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py keys            # o plano: o que seria renomeado e o que vai para revisão
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py keys --apply    # grava as renomeações
```

Uma chave que o contrato não conhece reprova no MUST. O `keys` a renomeia para `x_<chave>`, o prefixo de extensão, no
topo, no `meta`, nos nós, nas arestas e nas arestas externas, pelo texto, então os comentários ficam. As chaves
conhecidas vêm do schema MUST da release, nunca de uma lista no código. A chave vai para quem revisa quando não é slug,
quando `x_<chave>` já existe no mesmo mapa, ou quando o nome novo é um perfil canônico (`severity` viraria
`x_severity`, cujo valor o perfil julga). Com `--apply`, cada arquivo só é gravado se a releitura for o documento de
antes com só as chaves renomeadas, se o diff tocar só essas linhas e se o arquivo não ganhar código MUST nem aviso
SHOULD. A quebra de linha fica como estava, o arquivo com quebras misturadas é recusado, e rodar de novo não muda nada.
Medido numa cópia dos 15 grafos do core que reprovavam no MUST por chave estranha: com o `meta.title` conhecido desde o
v4.11 e 76 chaves renomeadas em 12 arquivos, 14 passam; o que sobra também não tem proveniência. Rodado pelo core no
próprio corpus (2026-10-23), com os excludes do gate: o gate foi de 170 para 182 de 184 grafos no MUST, e a dívida
herdada de 14 grafos para 2, os dois sem proveniência.

### `nest`: as suas chaves `x_` viram um perfil canônico (4.21.0)

```bash
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py nest --map mapa-nest.yaml            # o plano
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py nest --map mapa-nest.yaml --apply    # grava os perfis
```

O `keys` dá o prefixo `x_` à chave estranha; o `nest` vai um passo além e leva as chaves `x_` que um adotante inventou
para os perfis canônicos de nó do [capítulo 3](03-formato.md), `x_mirror`, `x_doc_cycle` e `x_questionnaire`. O mapa
(`spec/kg-migrate-nest.schema.json`) tem uma regra por perfil. A regra vale para o nó que tem a chave `when`, e cada
campo do perfil vem de uma fonte: `const` (um valor fixo), `move` (uma chave `x_` que sai do nó) ou `copy` (qualquer
chave, que fica, como `verified_at`). A fonte pode passar por `match` (uma regex com um grupo, lida como o ECMA-262 a
lê: `\w` e `\d` em ASCII, `\s` com os espaços Unicode, `.` sem quebra de linha, `$` só no fim do texto; o que os dois
motores leem diferente é entrada quebrada, e o valor com caractere além de U+FFFF vai para quem revisa) e por uma tabela
de valores, `values` para o valor exato e `prefixes` para o prefixo mais longo que casa. Com `raw: true`, o valor
original de cada chave movida que tinha texto além do código (entrou por prefixo, ou a regex cortou parte dele) fica em
`<perfil>.x_raw`; o valor exato da tabela não fica. A chave movida por `match` ou `prefixes` perde o texto que o código
deixa de fora, então essa regra pede `raw: true` (sem ele, o mapa é entrada quebrada):

```yaml
nest_version: "1"
nest:
  - into: x_mirror
    when: x_board_status
    fields:
      system: {const: board}
      state: {move: x_board_status}
      ref: {copy: verified_against, match: "/t/([a-z0-9]+)$"}
      url: {copy: verified_against}
      synced_at: {copy: verified_at}
  - into: x_doc_cycle
    when: x_issuer
    raw: true
    fields:
      issuer: {move: x_issuer}
      state: {move: x_in_force, values: {vigente: in_force}, prefixes: {"vigente (": in_force}}
```

Nada é chutado. O nó vai para quem revisa, sem ser tocado, quando um valor não tem código na tabela, quando falta a
fonte de um campo obrigatório, quando o nó já tem o perfil, quando o perfil que ele ganharia não passa no schema SHOULD
do perfil (um `synced_at` que não é data, um `state` fora do enum) quando o nó está em estilo de fluxo (`{...}`), quando
a chave `when` dele é null, quando um valor é `.nan` ou `.inf`, ou quando a edição do texto daquele nó não releria igual
(um valor movido com âncora `&x` ou alias `*x`). O plano ensaia a edição do arquivo inteiro uma vez, e só a divide
quando ela falha, então o nó que ela não sabe editar vai para quem revisa ali, e o `--apply` grava os outros. O
`--apply` grava cada arquivo sob as mesmas conferências do `keys`: a releitura tem de ser o documento de antes com só as
chaves movidas e os perfis novos, e o arquivo não pode ganhar código MUST nem aviso SHOULD. A quebra de linha fica, os
comentários fora das chaves movidas ficam, e rodar de novo não muda nada. Medido numa cópia dos dois grafos de um
adotante (108 nós com 168 dessas chaves): 106 perfis montados, 2 para quem revisa (dois `x_in_force` com texto livre que
o mapa não cobria), os dois arquivos gravados com o mesmo veredito de antes.
