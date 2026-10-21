# Adotar o contrato KG-SSOT

Este guia é para um repo que guarda grafos `.kg.yaml` e quer validá-los contra o contrato formal: o JSON Schema
2020-12 em dois níveis (MUST e SHOULD), a suíte de conformidade e o leitor de referência. O adotante fixa uma
**tag** deste repo e traz a superfície da release por script. O contrato nunca é copiado à mão nem é código
compartilhado.

## O que vem na release

A lista está em [`spec/release.json`](spec/release.json):
- o contrato v4, o vigente (`spec/kg-contract-v4.schema.json` e `spec/kg-contract-v4.should.schema.json`);
- a suíte (`spec/conformance/`);
- o leitor de referência (`tools/kg_validate.py`, `tools/kg_conformance.py`);
- o gate (`tools/kg_gate.py`) e o vendor (`tools/kg_vendor.py`);
- o armazém com gate (`tools/kg_store.py`), para quem grava grafo por programa: só escreve o que o contrato aprova
  ([cap. 5 do manual](docs/manual/05-ferramentas.md));
- o servidor MCP de referência (`tools/kg_mcp.py`), para um modelo julgar e gravar grafos pelo contrato, por stdio ou
  HTTP local;
- o exportador de proveniência para PROV-O em JSON-LD (`tools/kg_prov_export.py`);
- as dependências fixadas (`tools/requirements.txt`, Python 3.11 ou mais com PyYAML e jsonschema, cada arquivo com o sha256, que o pip confere ao instalar; o `--require-hashes` faz a instalação falhar se um dia o arquivo perder os hashes);
- a receita do pacote PyPI (`packaging/python/`): o script de build, o README do cadastro e as ferramentas de build
  fixadas por hash. O mesmo kit sai no PyPI como `kg-ssot`, para usar como biblioteca, comando ou servidor MCP; para o
  gate no CI, o vendor por tag continua o canal recomendado;
- o leitor JS (`tools/runners/ajv/`) e a receita do pacote npm (`packaging/npm/`): o mesmo leitor sai no npm como
  `kg-ssot`, com o validador do contrato pré-compilado, para Node e React Native/Expo. No vendor, eles viajam como
  receita: para usar o leitor JS, instale o pacote (`npm install kg-ssot`). Um `npm install` ou um build dentro do
  vendor deixa arquivos que o `kg_vendor.py check` acusa como sobrando;
- a receita do MCP Bundle (`packaging/mcpb/`): o servidor MCP de referência empacotado para clientes como o Claude
  Desktop, que instalam o pacote `kg-ssot` pelo `uv`, e o modelo do `server.json` do MCP Registry
  (`packaging/mcp-registry/`). Também são receitas no vendor;
- este guia, o `README.md` e o manual do produto (`docs/manual/`), que explica o formato, o contrato e as ferramentas;
- o `llms.txt` (índice para agentes de IA) e o `llms-full.txt` (a documentação inteira num texto só, gerada dos
  arquivos da release);
- a licença (`LICENSE`, Apache-2.0) e o `NOTICE`, que dizem o escopo dela.

Tudo isso é **Apache-2.0**, inclusive os casos `.kg.yaml` da suíte. A Apache-2.0 dá, além do direito autoral,
uma licença das patentes do autor e dos contribuidores sobre o que eles contribuíram. Essa licença termina para
quem processar alegando que o contrato infringe patente. Quem escreve um leitor próprio pode usar o contrato e a
suíte, inclusive comercialmente, mantendo o `LICENSE` e o `NOTICE`.

Do lado do mantenedor deste repo, uma conferência de higiene que não viaja confere essa lista no CI:
- toda entrada é coberta por arquivo rastreado;
- a tag é `kg-ssot-v<version>` (até a 4.3.0, `contract-v<version>`; as tags antigas continuam valendo);
- o contrato citado é o vigente;
- nenhum arquivo da release tem referência privada.

O adotante usa só `update` e `check`.

## 1. Trazer a release

> **O nome da tag mudou na 4.3.1:** de `contract-vX.Y.Z` para `kg-ssot-vX.Y.Z`, para a tag dizer o produto também
> no carimbo do adotante. Nada mais muda: as tags antigas seguem existindo, e o próximo update só troca a string do
> `--tag`.

O repositório público é `https://github.com/marciocar/kg-ssot`: cada commit dele é uma release, com a tag. A
primeira vez, clone-o fora do seu repo e rode o vendor a partir da raiz do seu repo (o adotante):

```bash
git clone https://github.com/marciocar/kg-ssot ../kg-ssot
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.15.0 --dest vendor/kg-ssot
```

Para atualizar, rode a partir do vendor, com `--source` obrigatório. Ele aceita caminho ou URL, e uma URL
vira um clone nu descartável. Dentro do vendor, o repo git é o do adotante, que não tem a tag:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.15.0 --source https://github.com/marciocar/kg-ssot
```

As tags publicadas estão em `git ls-remote --tags https://github.com/marciocar/kg-ssot`.

- **Leitura:** o vendor lê a tag com `git archive`, nunca a árvore de trabalho. Os nomes são literais: um `*`
  num nome de arquivo não vira glob.
- **O que a release aceita:** só arquivos regulares. Um symlink na tag é entrada quebrada.
- **Troca:** o `--dest` padrão é `vendor/kg-ssot`. O diretório é trocado por rename e nunca fica pela metade.
  Um arquivo que saiu da release some.
- **O que o vendor recusa substituir:**
  - um diretório sem carimbo, porque nunca apaga um diretório alheio;
  - um vendor que diverge do carimbo, a menos que venha `--force`. Isso evita que uma edição local suma em
    silêncio.
- **Perfil mínimo:** quem só roda o gate e o check pode trazer o perfil `gate` com `--profile gate`. São 10 arquivos:
  o contrato (MUST e SHOULD), o `release.json`, o leitor, o gate, o vendor, o `requirements.txt`, este guia, a
  `LICENSE` e o `NOTICE`. A suíte de conformidade fica de fora, e por isso o `kg_conformance.py` e o
  `spec/conformance/README.md` que este guia cita não vêm. O carimbo registra o perfil, o `check` confere só o que ele
  trouxe, e o update seguinte **herda** o perfil do carimbo (`--profile full` volta à release inteira).
  Quem está numa tag anterior à `contract-v4.1.1` migra em dois passos, porque o vendor antigo não conhece
  `--profile`: primeiro o update normal para a 4.1.1, depois o update com `--profile gate`.
- **Carimbo:** `vendor/kg-ssot/.kg-ssot-version` guarda a tag, o commit e o sha256 de cada arquivo.
- **Commit:** o vendor não commita. Num PR próprio, o adotante commita o diretório inteiro com o carimbo.

## 2. Gravar a linha de base

Na raiz do adotante, **nesta ordem**:

```bash
pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt         # ou o venv da nota de ambiente, abaixo
git add vendor/kg-ssot                                       # antes do gate: ele só mede arquivo rastreado
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update      # grava .kg-ssot/gate.json
```

O gate mede os `.kg.yaml` rastreados por git (`git ls-files`, lidos da árvore de trabalho). Um arquivo que
ainda não está no git não entra. Por padrão, `*/fixtures/*` e `docs/materials/*` ficam de fora, e isso já
exclui as fixtures do próprio vendor: os `.kg.yaml` do vendor moram todos em `*/fixtures/*`. Por isso o
`git add vendor/kg-ssot` vem antes do `--update`: com o vendor rastreado, a base gravada é a mesma que o CI vai
medir depois do commit, e um grafo seu ainda não adicionado também precisa de `git add` antes.

**Nota de ambiente.** Num sistema com PEP 668 (Ubuntu 24.04 em diante, entre outros), o `pip install` fora de um
venv é recusado (`externally-managed-environment`). Instale as dependências num venv e rode o kit com o Python
dele:

```bash
python3 -m venv .venv && .venv/bin/pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt
echo .venv/ >> .gitignore                                    # o venv não entra no git
.venv/bin/python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

No GitHub Actions com `actions/setup-python`, o `pip install` do passo de CI funciona sem venv.

### Ler o que reprova

O gate lista, depois da comparação, cada grafo que reprova no MUST com os códigos dele (`novo`, `regredido` ou
`herdado`) e a dívida SHOULD por código. Para ver as ocorrências de um grafo, rode o leitor de referência sem
`--schema`: ele usa o mesmo contrato e o mesmo vocabulário do gate (`parse.*`, `form.*`, `integrity.*`, `yaml.*`),
com a contagem de cada código:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/meu-grafo.kg.yaml
# REPROVA docs/meu-grafo.kg.yaml
#   MUST   form.required.node.provenance ×33 · yaml.forbidden-key-on ×7
#   SHOULD form.required.node.verified_at ×33
```

Para saber **em qual nó ou aresta** cada código sai, acrescente `--where`. A saída padrão não muda; cada ocorrência
ganha uma linha com o lugar:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/meu-grafo.kg.yaml
#     MUST   form.required.node.provenance  nó C_RETRY_SAFE
#     MUST   yaml.forbidden-key-on  aresta #6 (C_X -> Q_A)
#     SHOULD integrity.testimony-in-prod  nó C_SLA_99
```

O que não tem lugar mais fino sai como `arquivo`: o erro de parse, o `.nan`/`.inf` e a data sem aspas.

rc 0 todo arquivo passa no MUST, 1 algum reprova, 2 entrada quebrada.

### A chave `on:` em aresta vira `trigger:`

`yaml.forbidden-key-on` é uma aresta com a chave `on:`. Ela é proibida desde o v1 porque um leitor YAML 1.1 (o
PyYAML padrão, entre outros) lê `on` como o booleano `true`, e o evento referenciado parece órfão para esse leitor
enquanto outro o aprova. O gatilho de uma `TRANSITIONS` se escreve `trigger:`, e a integridade aceita `trigger`
como referência ao evento:

```yaml
- from: ST_IDLE
  to: ST_BUSY
  edge_type: TRANSITIONS
  trigger: EV_START      # era: on: EV_START
```

A troca é mecânica (só o nome da chave) e tira o código do grafo. Se ela vier depois da base, o gate mostra o
ganho e pede para travar com `--update`.

`--exclude GLOB` é repetível e se soma a esses padrões. O glob é `fnmatch` sobre o caminho relativo, e `*`
atravessa `/`. `--no-default-excludes` desliga os padrões, e aí as fixtures do vendor, quebradas de propósito,
entram no corpus.

A linha de base guarda o contrato (o nome do schema MUST e o sha256 dos dois schemas) e mais duas coisas:
- `failing`: os grafos que hoje falham no MUST, por caminho. É a dívida herdada.
- `debt`: quantos grafos carregam cada aviso SHOULD.

Commite o `.kg-ssot/gate.json`.

## 3. O passo de CI

No GitHub Actions, o workflow inteiro, em `.github/workflows/kg-ssot.yml`:

```yaml
name: KG-SSOT
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  kg-ssot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: Contrato KG-SSOT (vendor íntegro + gate por grafo)
        run: |
          pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt
          python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
          python3 -I -B vendor/kg-ssot/tools/kg_gate.py
```

Em outro CI, o passo é o mesmo: Python 3.11 ou mais, as dependências fixadas com `--require-hashes` e os dois comandos.

**`check`** reprova (rc 1) quando um arquivo do vendor foi editado, apagado ou acrescentado. Isso inclui
bytecode num `__pycache__`, que trocaria o leitor sem mudar a fonte, e symlink. Os scripts do kit não gravam
bytecode quando rodam como script. Mas uma ferramenta sua que **importa** um módulo do kit grava o `.pyc` dele
no `__pycache__` do vendor, porque o Python compila antes de executar o módulo, e o próximo `check` reprova.
Por isso todo comando deste guia usa `python3 -I -B`, e quem importa o kit roda com `-B` ou
`PYTHONDONTWRITEBYTECODE=1`.

O contrato não se customiza no adotante: uma mudança necessária volta ao produto como issue no repositório público
e vira caso ou decisão de contrato.

Limite: o carimbo atesta a si mesmo. O `check` pega uma edição acidental, mas não quem edita um arquivo e
recalcula o carimbo. Isso o review do PR do adotante pega, porque o diff do carimbo fica à vista.

**O gate** reprova (rc 1) quando:
- um grafo fora de `failing` falha no MUST, inclusive um grafo novo;
- um grafo de `failing` ganha um código MUST que não tinha;
- a dívida de um código SHOULD sobe, ou aparece um código novo;
- o contrato mudou: o nome do schema MUST, ou o sha256 dos schemas por uma tag nova. A comparação continua
  sendo feita contra a base antiga, e a base nova se grava com `--update` no mesmo PR.

No MUST, a comparação é por grafo: consertar um grafo não compensa quebrar outro. A dívida SHOULD é por código,
um total de grafos. Tirar um aviso de um grafo e pôr o mesmo em outro empata.

**Dívida por nó.** Por grafo, uma melhora espalhada aparece como piora: consertar 3 ocorrências num grafo e criar 1
em outro conta como +1 grafo. Desde a `contract-v4.2.0`, `kg_gate.py --update --granularity node` passa a contar e
travar a dívida SHOULD por ocorrência, somada em todos os grafos. A base guarda a granularidade, e o gate a usa sem
precisar da opção outra vez; `--granularity graph` volta ao padrão. Trocar não é piora: na passada que troca, a
dívida é comparada na granularidade da base, e o `--update` só pede motivo se ela piorou de verdade. O MUST segue por
grafo nas duas granularidades. Ocorrência é por nó ou aresta na maioria dos códigos; os que valem para o arquivo
inteiro (`yaml.unquoted-date`, `form.range.top.nodes`) contam 1 por grafo.

Um ganho passa e pede para travar: o grafo saiu de `failing` porque foi consertado, ou a dívida caiu. Um grafo
apagado não conta como conserto: o gate diz que ele saiu do corpus, e diz quando o corpus encolhe, para o PR
mostrar a remoção. Para
travar, rode `kg_gate.py --update` no mesmo PR.

Sobre `--update`:
- sem base ainda, ele grava a primeira (rc 0);
- com uma piora e sem `--accept-regression "<motivo>"`, ele recusa (rc 1) e não grava nada;
- com o motivo, ele grava, e o motivo fica na base (`accepted_regressions`, que se acumula).

**rc 0:** nada piorou, ou o vendor está íntegro. **rc 1:** algo piorou, ou o vendor diverge do carimbo.
**rc 2:** entrada quebrada, que nunca passa como verde:
- no `kg_gate.py`:
  - `--repo` não é um repo git;
  - a base está ausente (sem `--update`), ilegível ou fora do formato. O formato é `contract` como texto,
    `failing` como caminho → [códigos], `debt` como código → inteiro ≥ 0, `accepted_regressions` como lista e,
    opcional, `granularity` como `graph` ou `node`;
  - um `.kg.yaml` não pôde ser lido.
- no `kg_vendor.py`:
  - o `--source` não é repo git, a tag não existe, ou o `spec/release.json` dela está ausente, ilegível ou
    declara outra tag;
  - uma entrada da release não cobre nenhum arquivo, ou um membro da tag não é arquivo regular;
  - o carimbo está ausente, ilegível ou fora do formato;
  - no `update`: o destino não é um vendor, ou é um vendor editado sem `--force`, ou faltou `--source` dentro
    de um vendor.

## 4. Atualizar a tag

O PR que muda a tag faz três coisas:
1. roda `kg_vendor.py update` com a tag nova, `git add vendor/kg-ssot` (o gate mede só arquivo rastreado) e
   `kg_vendor.py check --dest vendor/kg-ssot --index`, que confere o que o commit vai levar. Desde a 4.8.1, o vendor
   traz o próprio `.gitattributes` (`* -text`), para a regra de fim de linha do repositório não reescrever os bytes
   da release no índice. Quem sai de uma tag anterior à 4.8.1 roda o `update` duas vezes (a nota abaixo explica);
2. roda `kg_gate.py` e explica no PR a diferença que aparecer;
3. grava a base com `--update`, porque um contrato novo muda a identidade.

Aviso novo no SHOULD sobe a dívida por desenho. As rampas do contrato (SHOULD hoje, MUST depois) chegam assim,
como compromisso medido.

Da `contract-v4.0.x` para a `contract-v4.1.x`, nenhum veredito muda: entram quatro avisos SHOULD (carimbo sem alvo,
testemunho em PROD, verificação antes do fato e decisão sem origem; a tabela está em `spec/conformance/README.md`).
Se a dívida SHOULD subir (por desenho, quando o corpus tem o que os avisos novos acusam), o `--update` desse PR vai com
`--accept-regression "<motivo>"`; se não subir, o `--update` grava a identidade nova sem motivo.

Da `kg-ssot-v4.7.x` para a `kg-ssot-v4.8.0`, o sha256 dos schemas não muda, e nenhum veredito MUST de `.kg.yaml` muda.
Entram três avisos SHOULD no `.kg.yaml`, os pontos do perfil JSON em rampa: `yaml.unsafe-integer` (inteiro fora de
±(2^53−1)), `yaml.lone-surrogate` (surrogate solto) e `yaml.depth-over-128` (mais de 128 coleções aninhadas). Um
grafo que tenha um desses ganha um código de dívida novo, e o `kg_gate.py` reprova até o `--update` com
`--accept-regression "<motivo>"`, ou até o grafo ser corrigido. A 4.8.0 foi medida nos 454 `.kg.yaml` do core e
nos deste repositório, e nenhum dispara os avisos novos.

Da `kg-ssot-v4.8.0` para a `kg-ssot-v4.8.1`, nem o contrato nem o leitor mudam. Muda o vendor: o `update` grava
`vendor/kg-ssot/.gitattributes` com `* -text`, e o carimbo passa a conferi-lo. Na 4.8.0, um repositório com regra de
fim de linha para `*.json` (`*.json text eol=lf`, por exemplo) normalizava no índice as duas fixtures da suíte que
têm CRLF de propósito, e o `kg_vendor.py check` reprovava num checkout novo, como o do CI, embora passasse na árvore
de trabalho.

**De qualquer tag anterior à 4.8.1, rode o update duas vezes.** O `update` roda pelo `kg_vendor.py` que já está no
vendor, e o de uma tag anterior traz a 4.8.1 sem gravar o `.gitattributes`. O `check` da 4.8.1 acusa isso ("rode o update de novo"). O segundo `update`,
já com o kit novo, grava o arquivo sem precisar de `--force`. Depois do `git add`, o `check --index` confirma que o
índice guarda os bytes da release. Outra saída é rodar o update uma vez só, pelo clone da tag
(`../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.8.1 --dest vendor/kg-ssot`). Uma regra própria para o vendor no `.gitattributes` da raiz (`vendor/kg-ssot/** -text`) continua valendo e
pode ficar.

Da `kg-ssot-v4.14.0` para a `kg-ssot-v4.15.0`, entra o contrato v4.8: as chaves da verificação, desenhadas com dois
adotantes a partir de um caso real de auditoria contínua. Todas são opcionais, e quem não usa não ganha dívida.
- **`reverify_every`**: de quanto em quanto tempo a verificação de um nó tem de ser refeita, em duração ISO 8601 só com
  data (`P3M`, `P1Y`). Sem `verified_at`, alerta, porque a cadência conta do carimbo; zerada (`P0D`), também.
- **`reverify_on`**: o gatilho por evento, em texto ("por admissão", "a cada mudança de configuração").
- **`retain_for`**: por quanto tempo a evidência tem de ser guardada, na mesma duração.
- **O `owner`** é o papel que responde pelo nó, e não uma pessoa. Não muda nada no veredito.
- **`kg_validate.py --due AAAA-MM-DD`**: o relatório de vencimento, que nunca muda o veredito do gate. Um veredito que
  mudasse com o calendário, sem commit, quebraria a base e a catraca. Rode o relatório num job agendado, se quiser
  cobrar a cadência.
- **A suíte ganha 13 casos** (349). A identidade do contrato muda (o `kg_gate.py` pede `--update`), sem veredito
  trocado.

Da `kg-ssot-v4.13.1` para a `kg-ssot-v4.14.0`, entra o contrato v4.7 e a gravação de conjunto no armazém. As duas
lacunas foram achadas por um adotante que grava parte dos grafos em `.kg.json`.
- **A ponta externa das `external_edges` pode ser um `.kg.json`** (`<caminho>.kg.json#<id>`), o formato JSON do mesmo
  modelo. O corpus que confere a ponta (o `kg_gate.py`, o `--corpus` dos dois leitores e o `kg_store.py`) passa a ler
  os dois formatos. É ampliação: nada que passava reprova. A identidade do contrato muda (o `kg_gate.py` pede
  `--update`), sem veredito trocado.
- **`kg_store.write_many`** (e `kg_store.py write-many`) grava um conjunto de grafos de uma vez, ou nada. É o caminho
  para regenerar grafos que se citam.
- **A suíte ganha 8 casos** (336), três deles para recusar a extensão fora da forma (`.kg.yml`, `.KG.JSON`) e o
  `.kg.json` que não existe quando só existe o `.kg.yaml` de mesmo nome-base.

Da `kg-ssot-v4.13.0` para a `kg-ssot-v4.13.1`, a identidade do contrato passa a acusar o v4.6. As duas regras novas da
4.13.0 moram só no leitor, e o sha256 dos schemas, que o `kg_gate.py` guarda como identidade, não mudou: uma base
gravada na 4.12.0 seguia julgando com regra nova sem que a identidade acusasse. A descrição do schema MUST passa a
declarar o v4.6, e a higiene da release cobra que toda versão do contrato apareça na descrição de um dos schemas. O
`kg_gate.py` mostra a identidade nova e pede `--update`; nenhum veredito muda.
- **O `kg_migrate.py` lê o mesmo corpus que o gate.** Sem lista de grafos, ficam de fora os padrões do `kg_gate.py`
  (`*/fixtures/*`, `docs/materials/*`) e o `vendor/*`, e o `--exclude` usa a semântica do gate (`*` atravessa `/`),
  sem perder o `**/` de antes, que casa zero pastas;
  `--no-default-excludes` tira os padrões. Antes, o plan pegava as fixtures, e `*/fixtures/*` não casava caminho aninhado.
- **O `kg_migrate.py` não grava bytecode no vendor**, mesmo rodado sem `-B`; antes, o `check` seguinte reprovava pelo
  `.pyc` do `kg_validate` no `__pycache__`.
- **O nó cujo `verified_scope` já é o do perfil sai como `same`** no plan, separado do que muda.

Da `kg-ssot-v4.12.0` para a `kg-ssot-v4.13.0`, entram o contrato v4.6 (um MUST raro do YAML e o \r normalizado no
leitor JS) e o migrador por perfil.
- **O `kg_migrate.py`** propõe a `provenance` que o v4 pede pelas regras de um perfil que você versiona (manual, cap. 5;
  exemplo em `spec/migrate-examples/`). O `plan` não grava nada, e o `apply` grava só o que o plano propôs. A fixture
  de aceitação, um corpus real anonimizado de 1.024 nós, fica em `tools/fixtures/migrate/adopter-hub/`.
- **A linha de continuação de texto entre aspas** tem de ser mais indentada que o mapa ou a lista que o contém; menos
  que isso reprova como `parse.yaml-error`, como a especificação pede.
- **O leitor JS trata o `\r\n` e o `\r` sozinho como quebra de linha**, como a referência, e recusa o texto entre aspas que
  não fecha (a aspa escapada no fim da linha), que ele cortava ali.
- **A suíte ganha 16 casos** (328).
- **No Windows, o update para a 4.13.0 ou posterior roda pelo kit da tag nova.** O `kg_vendor.py` das tags anteriores passa ao
  `git archive` a lista inteira de arquivos da release, e na 4.13.0 ela passa do limite da linha de comando do Windows
  (`WinError 206`). Rode o update pelo clone da tag (`../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.15.0 --dest
  vendor/kg-ssot`). O kit desde a 4.13.0 passa só as entradas da release. No Linux e no macOS o limite é bem maior, e o
  update de sempre funciona.

Medido em 2026-10-20, nenhum dos 1.507 `.kg.yaml` de quatro repos adotantes muda no MUST nem no SHOULD. O sha256 dos
schemas não mudou na 4.13.0, e o `kg_gate.py` não pedia `--update`: a identidade não acusava as regras novas do
leitor. A 4.13.1 corrige isso.

Da `kg-ssot-v4.11.0` para a `kg-ssot-v4.12.0`, entra o contrato v4.5: um MUST raro do YAML e três ampliações do SHOULD.
- **O tab no espaço inicial de uma linha de continuação de texto entre aspas** reprova como `parse.yaml-error`.
- **`verified_scope`**, opcional: `fato`, `mecanismo` ou `nenhum`, o alcance do `verified_at`.
- **`locality: privado`**, para documento fora do repo, não público e reverificável por quem tem acesso.
- **Com `--corpus`, a `REFUTES` que chega de outro grafo** a um nó vivo conta para `integrity.refutes-unreconciled`.
- **A suíte ganha 18 casos** (312).

Medido em 2026-10-20, nenhum dos 1.457 `.kg.yaml` de quatro repos adotantes muda no MUST nem no SHOULD. O sha256 dos
dois schemas muda, então o PR do `update` roda o `kg_gate.py --update` depois de trazer a tag; sem o caso no corpus, sem
motivo.

Da `kg-ssot-v4.10.0` para a `kg-ssot-v4.11.0`, entra o contrato v4.4: um aviso SHOULD e três vereditos MUST raros do YAML.
- **`integrity.refutes-unreconciled`:** nó que recebe `REFUTES` e segue vivo (nem `superseded` nem `refuted`; só a
  `question` `done` não alerta). O grafo afirma e refuta a mesma coisa. O radar do core já reprova o caso como
  contradição; aqui ele alerta agora e vira MUST numa versão futura.
- **O perfil YAML estrito:** a tag `!` sem nome (também `!<!>`), o `!!timestamp` cujo texto não é data e o tab fora
  de aspas, de bloco e de comentário reprovam como `parse.yaml-error`, na referência e no leitor JS. O tab já
  reprovava na referência; mudam a tag `!` e o `!!timestamp`. Medido em 2026-10-20, nenhum dos 1.391 `.kg.yaml` de
  quatro repos adotantes muda de veredito.
- **A suíte ganha 31 casos** (294): 10 em `latest/integrity/coherence/` e 21 em `latest/yaml/strict-profile/`.

O sha256 do SHOULD muda, então o PR do `update` roda o `kg_gate.py --update` depois de trazer a tag. Se o corpus não
tem o caso, ele grava a identidade nova sem motivo. Se tem, a dívida sobe por desenho, e o `--update` vai com
`--accept-regression "<motivo>"`; ou reconcilie antes o alvo (`refuted` ou `superseded`).

Da `kg-ssot-v4.9.1` para a `kg-ssot-v4.10.0`, nenhum veredito MUST muda. Muda o servidor MCP e o leitor JS:
- **O perfil "atrás de proxy" do `kg_mcp.py`** (`--identity-header`, `--secret-env`): identidade por header que
  recusa por padrão, segredo comparado por hmac, uma área e um autor por identidade, por requisição, os limites
  `--max-graphs` e `--max-concurrent`, e o envelope `untrusted_data`. Fora do perfil, nada muda.
- **As duas eras do protocolo MCP:** o `kg_mcp.py` fala a 2026-07-28, sem estado (`server/discover` e o `_meta` por
  requisição), e segue falando a 2025-11-25, com `initialize` e sem sessão. A era é escolhida por requisição.
- **O gate externo** (`--gate-cmd`, no `kg_store.py` e no `kg_mcp.py`): um comando seu, sem shell, que julga depois do
  contrato em cada gravação e remoção e devolve um `kg-ssot.verdict/1`. O armazém só grava com PASS dos dois, e um gate
  que falha nunca vira PASS. É por ele que se liga um gate próprio (um radar, uma política) ao servidor. Sem a opção,
  nada muda.
- **A imagem OCI** `ghcr.io/marciocar/kg-ssot:4.10.0`: o `kg-mcp` do mesmo wheel do PyPI, sem root, com o armazém em
  `/data` e o label de posse do MCP Registry, para rodar ao lado do LibreChat (o manual, em "A imagem OCI", traz o
  compose e o `librechat.yaml`).
- **Uma mudança de comportamento:** `--allow-remote` passa a exigir `--secret-env`. Quem servia fora do loopback sem
  segredo, atrás de um proxy, precisa pôr um segredo e mandá-lo no header (`--secret-header`, padrão `X-Api-Key`).
- **O leitor JS mede os avisos SHOULD,** com os mesmos códigos da referência em todos os casos da suíte, e o pacote npm
  traz o `should.mjs` pré-compilado.
- **A suíte ganha 2 casos** (263), sobre o `trace` só com espaço.

Um `update` basta, e o gate não precisa de `--update`.

Da `kg-ssot-v4.9.0` para a `kg-ssot-v4.9.1`, nenhum veredito muda. Muda o armazém e o servidor MCP:
- **O armazém roda no Windows.** Na 4.9.0 ele recusava abrir lá, e o MCPB no Claude Desktop do Windows subia só com o
  julgamento. No Windows, que não tem `dir_fd`, cada passo do caminho é conferido por `lstat` (link simbólico, junção e
  ponto de montagem são recusados; o arquivo do OneDrive sob demanda passa), o arquivo aberto tem de ser o que o
  `lstat` viu, e o caminho é conferido de novo depois da leitura e antes da troca final na gravação. A trava entre
  processos é a do `msvcrt`. É mais fraco que no POSIX, e o manual diz onde.
- **Nomes portáveis.** O armazém recusa criar um nome com segmento reservado do Windows (`CON`, `NUL`, `COM1`...) ou que
  termina em ponto; um nome assim que já está no armazém continua lendo, gravando e sendo removido. Nenhuma operação
  (ler, gravar, remover, histórico) aceita um nome que só difere pela caixa de um que está no armazém: no Windows e no
  macOS os dois seriam o mesmo arquivo, e remover `ALVO.kg.yaml` apagaria `alvo.kg.yaml` sem julgar quem aponta para
  ele. Um par antigo com as duas caixas, num disco que as distingue, segue funcionando pela caixa exata.
- **O servidor diz por que subiu sem armazém.** Com `--store-optional`, uma raiz que não abre não derruba o
  `kg_mcp.py`: ele sobe só com `kg_validate` e `kg_schema_help` e põe o motivo nas instruções, na descrição das duas
  ferramentas e no `kg_schema_help`. Sem a opção, uma raiz sem permissão agora dá rc 2 com a mensagem, em vez de
  traceback. O MCPB usa a opção, e uma raiz que chega com `${...}` sem expandir não cria armazém.
- **Os módulos acham o `spec/` pelo próprio caminho.** O `kg_store.py`, o `kg_mcp.py` e o `kg_conformance.py` deixam de
  usar o `_ROOT` do `kg_validate` importado; um `kg_validate` falso num teste não desvia mais o spec dos vizinhos.

Um `update` basta, e o gate não precisa de `--update`.

Da `kg-ssot-v4.8.2` para a `kg-ssot-v4.9.0`, nenhum veredito muda. Num valor com `\n` no fim, a referência deixa de
emitir um código redundante: ela passou a casar os regex por inteiro, como o ECMA-262 dos patterns do contrato. O kit passa a sair também no PyPI
como `kg-ssot`, o leitor JS no npm como `kg-ssot` e o servidor MCP como MCP Bundle (as receitas em `packaging/`
viajam na release), e os módulos acham o `spec/` ao lado de si no
pacote instalado ou no diretório pai no vendor. Para quem usa o vendor, nada muda: um `update` basta, e o gate não
precisa de `--update`.

Da `kg-ssot-v4.8.1` para a `kg-ssot-v4.8.2`, nenhum veredito nem código muda. Só a saída melhora: o veredito do
`.kg.json` passa a trazer a linha de cada ocorrência, a dica do `integrity.orphan-node` traz o id do nó e a aresta
que o conserta, a mensagem e a dica do `integrity.verified-before-fact` dizem as duas leituras (vigência futura ou
datas trocadas), e o `--where` mostra a correção abaixo de cada ocorrência MUST. Um `update` basta, e o gate não
precisa de `--update`.

**O `.kg.json`.** A 4.8.0 lê o mesmo modelo de dados num arquivo `.kg.json`, por um parser JSON, no perfil JSON do
contrato: RFC 8259 com um BOM inicial aceito, I-JSON (RFC 7493, sem surrogate solto e com inteiro dentro de
±(2^53−1)), no máximo 128 coleções aninhadas e chave única. No `.kg.json`, esses pontos reprovam (MUST).
`kg_validate.py`, `kg_conformance.py`, `kg_store.py` e `kg_mcp.py` leem os dois formatos pela extensão (sensível a
maiúsculas: `.kg.json`). **O gate continua só com `.kg.yaml`**: um `.kg.json` commitado no repositório não é medido
pelo `kg_gate.py`. Desde a 4.14.0 (contrato v4.7), as `external_edges` apontam também para `.kg.json`, e o gate os lê
como alvo. Quem guarda `.kg.json` no repo e quer o CI cobrando roda `kg_validate.py` neles num passo próprio.

## 5. Do v3 para o v4

O v4 é uma versão maior: o que alertava no v3 passa a reprovar. Quem está numa tag `contract-v3.x` (anterior à
publicação do repositório público, que começa no v4) sobe pela **rampa** do gate, sem truque de data no schema e sem
consertar o corpus inteiro de uma vez. Quem adota agora começa no v4 e pode pular para a lista do que muda, que vale
como resumo do contrato.

O que muda no v4:
- **`provenance` é MUST** em nó `confirmed` ou PROD (`form.required.node.provenance`), com `source`, `locator` e
  `method` não vazios. O nó `unverifiable` não exige, nem em PROD.
- **`provenance.source` placeholder reprova** (`form.pattern.node.provenance.source`): só espaço, `desconhecida`,
  `desconhecido`, `unknown`, `n/a`, `na`, `n.a.`, `none`, `null`, `sem fonte`, `tbd`, hífens, travessão ou `?`,
  sem distinguir maiúscula e ignorando pontuação final e espaço em volta.
- **Chave desconhecida sem o prefixo `x_` reprova** no topo, no `meta`, no nó e na aresta
  (`form.unknown-key.<escopo>.<chave>`), e o nome sem `x_` que nem é slug reprova como
  `form.pattern.<escopo>.key`. Dentro de `provenance`, a chave desconhecida segue só alertando.
- **`provenance.method` tem vocabulário** (SHOULD no v4, MUST no v5): `'<classe>: <detalhe>'`. A classe diz **de que
  tipo é a evidência que sustenta a afirmação**: `medição` (quem estabeleceu a afirmação executou e registrou o
  comando), `leitura` (documento primário), `juízes` (painel de agentes ou juízes), `testemunho` (uma pessoa ou sessão
  afirmou; inclui a medição de terceiro lida aqui) ou `derivado` (a afirmação é concluída de outras afirmações ou
  campos, sem evidência própria). Fora disso alerta como `form.pattern.node.provenance.method`.
  Quando uma migração preenche a `provenance` a partir do que o nó já trazia, a classe é a da evidência original, e o
  detalhe diz que a migração não re-verificou, por exemplo `medição: <o que foi medido>; não reverificado na migração`
  (decisão do mantenedor em 2026-10-09).
  A prosa interna do adotante (um `docs/*.md` escrito por alguém do time) é `testemunho`, não `leitura`: é o relato
  de quem a escreveu, e assim o radar mostra quais `confirmed` só têm prosa por trás.
  **Atenção:** se o seu CI cobra que grafo novo saia limpo também no SHOULD, este alerta já reprova lá no v4, e não só
  no v5. Ajuste antes os geradores que escrevem `provenance`.

O caminho, num PR só:
1. `python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.15.0 --source https://github.com/marciocar/kg-ssot`
   duas vezes (o kit do v3 não grava o `.gitattributes` do vendor, e o segundo update, já com o kit novo, grava),
   `git add vendor/kg-ssot` e `kg_vendor.py check --dest vendor/kg-ssot --index`;
2. `python3 -I -B vendor/kg-ssot/tools/kg_gate.py` mostra a identidade nova do contrato e os grafos que passam a
   falhar no MUST;
3. `python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update --accept-regression "<motivo>"` grava esses grafos em
   `failing`, como **dívida herdada**. Sem o motivo, o `--update` recusa, porque grafo que passava e falha é
   piora. Daí em diante vale a catraca: grafo novo tem de passar no v4, grafo de `failing` não ganha código MUST
   novo, e a dívida só encolhe, com `--update` a cada conserto.

**Onde a fonte mora** (`provenance.locality`, opcional, desde a `contract-v4.2.0`): `repo` (arquivo versionado no
próprio repo), `web` (endereço público), `host` (só existe numa máquina: um journal local, um caminho fora do repo) ou
`pessoa` (o relato de alguém). Fora desses valores, alerta como `form.enum.node.provenance.locality`. Serve para medir
o que um terceiro consegue reverificar e para barrar `host` quando o grafo vai a público. Desde o v4.5 entra `privado`:
documento fora do repo, não público e reverificável por quem tem acesso (Google Drive, wiki interna). O valor segue
onde está a cópia lida, não a classificação do documento: um PDF que o emissor marca como público, lido de uma cópia
no Drive, é `privado` até alguém achar a URL pública, quando passa a `web` com o locator novo.

**Referência a nó de outro grafo** (`external_edges`, opcional, desde a `contract-v4.3.0`): uma lista no topo do grafo,
cada aresta com exatamente uma ponta externa `<caminho relativo à raiz do repo>#<id>` e a outra um id deste arquivo.
Sem `from`, quem aponta é o grafo inteiro.

```yaml
external_edges:
  - to: docs/pesquisa/outra.kg.yaml#C_ANTIGA      # este grafo supera um nó de outro grafo
    edge_type: SUPERSEDES
  - from: docs/graph/portas.kg.yaml#D_MATRIZ       # um nó de fora limita um nó daqui
    to: D_CORTE
    edge_type: CONSTRAINS
```

Os tipos são `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`, `TRACES_TO` e `DEPENDS_ON`. O gate confere o alvo contra
os `.kg.yaml` e `.kg.json` rastreados do repo, inclusive os que o `--exclude` tira do corpus, e lê só os que alguma referência cita: alvo que não existe, ou grafo-alvo
apagado, reprova quem aponta (`integrity.dangling-external`). Fora do gate, `kg_validate.py --corpus <raiz do repo>`
faz a mesma conferência: num repo git, contra os `.kg.yaml` e `.kg.json` rastreados; fora de um repo, contra todo
grafo sob o diretório. Sem `--corpus`, o leitor confere só a forma e a ponta local, e diz quantos arquivos ficaram com a ponta externa
sem conferir. Uma referência ao próprio arquivo passa como externa; use `edges` para isso. Uma chave `x_` própria que fazia esse papel migra para cá; a que só declara algo, sem ser
aresta, segue como `x_`.

**Label corrigido.** Quando uma revisão troca o label de um nó, o label anterior vai para a `narrative`, começando
por `label anterior: …`. O git guarda o resto do histórico; o contrato não tem campo próprio para isso.

O que fazer com um nó `confirmed` ou PROD **sem fonte recuperável**:
- **o padrão é rebaixar** o `status` para `unverifiable`, que não exige `provenance`: o que não se rastreia não
  está confirmado;
- **quando a origem é uma pessoa ou sessão recuperável**, a `provenance` aponta essa origem, com `method` de
  `testemunho`, e o nó segue `confirmed`;
- **nunca um placeholder** em `source`: ele reprova.

Trocar o `status` de um nó é decisão sobre a verdade do grafo, e fica com quem é dono dele. A migração pode
propor `provenance` a partir de campos que o nó já tem, mas o `method` é declarado por quem revisa, nunca
inventado. O `kg_migrate.py` faz isso por um perfil que você escreve: o `plan` mostra a proposta de cada nó sem gravar
nada, e o `apply` grava só o que o plano propôs, conferindo que nada mais mudou (manual, cap. 5). Uma chave própria sem `x_` se resolve renomeando para `x_<nome>`.

## Conformidade de outro leitor

Para provar que um leitor próprio concorda com o contrato, rode a suíte com o leitor de referência, **depois** do
`git add vendor/kg-ssot`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_conformance.py
```

A ordem importa: os casos de corpus conferem a ponta externa contra os grafos rastreados quando a suíte mora num
repo git, e com o vendor ainda fora do git um caso falha (`latest: 260/261`). Depois compare com os códigos que o seu
leitor emite. O formato dos casos e como rodar a suíte com um leitor em outra linguagem estão em
`spec/conformance/README.md`.
