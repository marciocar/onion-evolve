<!-- translation-of: ADOPTING.md sha256:26887e82f5729581 -->
# Adotar o contrato KG-SSOT

[English](ADOPTING.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

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
- a língua da saída humana (`tools/kg_i18n.py` e o catálogo pt-BR em `locale/`): inglês por padrão, português do
  Brasil com `KG_SSOT_LANG=pt-BR` ou um locale `pt_BR`;
- o armazém com gate (`tools/kg_store.py`), para quem grava grafo por programa: só escreve o que o contrato aprova
  ([cap. 5 do manual](docs/manual/pt-BR/05-ferramentas.md));
- o servidor MCP de referência (`tools/kg_mcp.py`), para um modelo julgar e gravar grafos pelo contrato, por stdio ou
  HTTP local;
- o exportador de proveniência para PROV-O em JSON-LD (`tools/kg_prov_export.py`);
- as dependências fixadas (`tools/requirements.txt`: Python 3.11 ou mais com PyYAML e jsonschema). Cada arquivo traz o
  sha256, que o pip confere ao instalar; o `--require-hashes` faz a instalação falhar se um dia o arquivo perder os
  hashes;
- a receita do pacote PyPI (`packaging/python/`): o script de build, o README do cadastro e as ferramentas de build
  fixadas por hash. O mesmo kit sai no PyPI como `kg-ssot`, para usar como biblioteca, comando ou servidor MCP. Para o
  gate no CI, o vendor por tag continua o canal recomendado;
- o leitor JS (`tools/runners/ajv/`) e a receita do pacote npm (`packaging/npm/`): o mesmo leitor sai no npm como
  `kg-ssot`, com o validador do contrato pré-compilado, para Node e React Native/Expo. No vendor, eles viajam como
  receita: para usar o leitor JS, instale o pacote (`npm install kg-ssot`). Um `npm install` ou um build dentro do
  vendor deixa arquivos sobrando, e o `kg_vendor.py check` os acusa;
- a receita do MCP Bundle (`packaging/mcpb/`): o servidor MCP de referência empacotado para clientes como o Claude
  Desktop, que instalam o pacote `kg-ssot` pelo `uv`, e o modelo do `server.json` do MCP Registry
  (`packaging/mcp-registry/`). Também são receitas no vendor;
- este guia, o `README.md` e o manual do produto (`docs/manual/`), que explica o formato, o contrato e as ferramentas;
- o `llms.txt` (índice para agentes de IA) e o `llms-full.txt` (a documentação inteira num texto só, gerada dos
  arquivos da release);
- a licença (`LICENSE`, Apache-2.0) e o `NOTICE`, que diz o escopo dela.

Tudo isso é **Apache-2.0**, inclusive os casos `.kg.yaml` da suíte. A Apache-2.0 dá, além do direito autoral,
uma licença das patentes do autor e dos contribuidores sobre o que eles contribuíram. Essa licença termina para
quem processar alegando que o contrato infringe patente. Quem escreve um leitor próprio pode usar o contrato e a
suíte, inclusive comercialmente, mantendo o `LICENSE` e o `NOTICE`.

Do lado do mantenedor, uma conferência de higiene que não viaja confere essa lista no CI:
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
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.19.1 --dest vendor/kg-ssot
```

Para atualizar, rode a partir do vendor, com `--source` obrigatório. Ele aceita caminho ou URL, e uma URL
vira um clone nu descartável. Dentro do vendor, o repo git é o do adotante, que não tem a tag:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.19.1 --source https://github.com/marciocar/kg-ssot
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
- **Perfil mínimo:** quem só roda o gate e o check pode trazer o perfil `gate` com `--profile gate`. São 12 arquivos:
  o contrato (MUST e SHOULD), o `release.json`, o leitor, o gate, o vendor, o módulo de língua e o catálogo dele
  (`tools/kg_i18n.py` e `locale/pt_BR/LC_MESSAGES/kg-ssot.po`), o `requirements.txt`, o guia de adoção em inglês
  (`ADOPTING.md`), a `LICENSE` e o `NOTICE`. A suíte de conformidade fica de fora, e por isso o `kg_conformance.py` e o
  `spec/conformance/README.md` que este guia cita não vêm. O carimbo registra o perfil, o `check` confere só o que ele
  trouxe, e o update seguinte **herda** o perfil do carimbo (`--profile full` volta à release inteira).
  Quem está numa tag anterior à `contract-v4.1.1` migra em dois passos, porque o vendor antigo não conhece
  `--profile`: primeiro o update normal para a 4.1.1, depois o update com `--profile gate`.
- **Carimbo:** `vendor/kg-ssot/.kg-ssot-version` guarda a tag, o commit e o sha256 de cada arquivo.
- **O carimbo marca o vendor (regra pública desde a 4.20.0):** uma pasta com `.kg-ssot-version` é o vendor do
  KG-SSOT, onde quer que ela esteja, e nenhum arquivo dentro dela é grafo seu. As ferramentas que leem um repositório
  (`kg_gate.py`, `kg_query.py`, `kg_vocab.py`, `kg_migrate.py` e `kg_diff.py --from`) a deixam de fora por padrão, e o
  `--no-default-excludes` a traz de volta; o carimbo na raiz do que se lê não conta, e ler a própria pasta do vendor
  lê os grafos dela. O
  armazém (`kg_store.py`, e o servidor MCP por cima dele) lê a área dele, onde não mora vendor, e não aplica a regra. Uma ferramenta sua que percorre os seus grafos pode seguir a mesma regra com
  `kg_validate.find_vendor_dirs(raiz)` e `kg_validate.in_vendor(caminho, pastas)`, no lugar de um caminho fixo
  `vendor/`.
- **Commit:** o vendor não commita. Num PR próprio, o adotante commita o diretório inteiro com o carimbo.

## 2. Gravar a linha de base

Na raiz do adotante, **nesta ordem**:

```bash
pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt         # ou o venv da nota de ambiente, abaixo
git add vendor/kg-ssot                                       # antes do gate: ele só mede arquivo rastreado
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update      # grava a pasta .kg-ssot/gate/
```

O gate mede os `.kg.yaml` rastreados por git (`git ls-files`, lidos da árvore de trabalho). Um arquivo que
ainda não está no git não entra. Por padrão, `*/fixtures/*` e `docs/materials/*` ficam de fora, e o próprio vendor do
KG-SSOT também, qualquer pasta com o carimbo `.kg-ssot-version` (desde a 4.19.1; o vendor da 4.19.0 traz um grafo de
exemplo fora de `fixtures/`). Por isso o
`git add vendor/kg-ssot` vem antes do `--update`: com o vendor rastreado, a base gravada é a mesma que o CI vai
medir depois do commit. Um grafo seu ainda não adicionado também precisa de `git add` antes.

`--exclude GLOB` é repetível e se soma a esses padrões. O glob é `fnmatch` sobre o caminho relativo, e `*`
atravessa `/`. `--no-default-excludes` desliga os padrões, e aí as fixtures do vendor, quebradas de propósito,
entram no corpus.

A linha de base é a pasta `.kg-ssot/gate/`:
- `contract.json`: a identidade do contrato (o nome do schema MUST e o sha256 dos dois schemas).
- `graphs/<meta.id>.json`: um registro por grafo, com os códigos MUST que ele carrega (a dívida herdada) e a contagem
  de cada aviso SHOULD. O nome é o `meta.id`, e por isso um `git mv` não troca o registro. Um `meta.id` repetido
  (inclusive só na caixa, como `Foo` e `foo`, que o macOS e o Windows não distinguem), que não cabe num nome de
  arquivo ou que é dispositivo do Windows (`con`, `com1`) vai pelo hash do caminho.
- `accepted/`: uma regressão aceita por arquivo, com o motivo.

Nada agregado é gravado: a contagem de grafos e a dívida por código saem dos registros. Duas branches que mexem em
grafos diferentes mexem em arquivos diferentes, e o merge do git não conflita. Commite a pasta inteira.

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
`herdado`; em inglês, `new`, `regressed` ou `inherited`) e a dívida SHOULD por código. Para ver as ocorrências de um
grafo, rode o leitor de referência sem `--schema`: ele usa o mesmo contrato e o mesmo vocabulário do gate (`parse.*`,
`form.*`, `integrity.*`, `yaml.*`), com a contagem de cada código. Os exemplos abaixo rodam com `KG_SSOT_LANG=pt-BR`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/my-graph.kg.yaml
# REPROVA docs/my-graph.kg.yaml
#   MUST   form.required.node.provenance ×1 · yaml.forbidden-key-on ×1
#   SHOULD form.required.node.verified_at ×1 · integrity.testimony-in-prod ×1
# · 1 arquivos; 0 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

Para saber **em qual nó ou aresta** cada código sai, acrescente `--where`. A saída padrão não muda; cada ocorrência
ganha uma linha com o lugar, e cada ocorrência MUST ganha a correção logo abaixo:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/my-graph.kg.yaml
# REPROVA docs/my-graph.kg.yaml
#   MUST   form.required.node.provenance ×1 · yaml.forbidden-key-on ×1
#   SHOULD form.required.node.verified_at ×1 · integrity.testimony-in-prod ×1
#     MUST   form.required.node.provenance  nó C_RETRY_SAFE
#            → Acrescente provenance com source, locator e method; sem fonte recuperável, mude o status para unverifiable.
#     MUST   yaml.forbidden-key-on  aresta #2 (C_X -> Q_A)
#            → Troque on: por trigger:.
#     SHOULD form.required.node.verified_at  nó C_RETRY_SAFE
#     SHOULD integrity.testimony-in-prod  nó C_SLA_99
# · 1 arquivos; 0 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

O lugar é dado e por isso não muda com a língua da saída: `nó <id>`, `aresta #<n> (<from> -> <to>)`, `meta`, `topo`
(o nível de cima) ou `arquivo` para o que não tem lugar mais fino (o erro de parse, o `.nan`/`.inf` e a data sem
aspas).

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
mostrar a remoção. Para travar, rode `kg_gate.py --update` no mesmo PR.

Sobre `--update`:
- sem base ainda, ele grava a primeira (rc 0);
- com uma piora e sem `--accept-regression "<motivo>"`, ele recusa (rc 1) e não grava nada;
- com o motivo, ele grava, e o motivo fica na base (um arquivo em `accepted/`; as regressões aceitas se
  acumulam).

**rc 0:** nada piorou, ou o vendor está íntegro. **rc 1:** algo piorou, ou o vendor diverge do carimbo.
**rc 2:** entrada quebrada, que nunca passa como verde:
- no `kg_gate.py`:
  - `--repo` não é um repo git;
  - a base está ausente (sem `--update`), ilegível ou fora do formato. Na pasta: `contract.json` com `contract` e
    `contract_sha256` como texto e, opcional, `granularity` como `graph` ou `node`; cada registro de `graphs/` com
    `graph` (o caminho), `id` (texto ou null), `must` como [códigos] e `should` como código → inteiro > 0. No arquivo
    de antes da 4.16.0: `contract` como texto, `failing` como caminho → [códigos], `debt` como código → inteiro ≥ 0,
    `accepted_regressions` como lista e, opcional, `granularity`;
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
3. grava a base com `--update` quando o contrato muda a identidade. Desde a 4.16.0, isso não é obrigatório: sem
   veredito trocado, o gate passa com um aviso `· identidade` (em inglês, `· identity`), e o `--update` pode vir
   depois.

Aviso novo no SHOULD sobe a dívida por desenho. As rampas do contrato (SHOULD hoje, MUST depois) chegam assim,
como compromisso medido.

Da `contract-v4.0.x` para a `contract-v4.1.x`, nenhum veredito muda: entram quatro avisos SHOULD (carimbo sem alvo,
testemunho em PROD, verificação antes do fato e decisão sem origem; a tabela está em
[`spec/conformance/README.pt-BR.md`](spec/conformance/README.pt-BR.md)). Se a dívida SHOULD subir (por desenho, quando o
corpus tem o que os avisos novos acusam), o `--update` desse PR vai com `--accept-regression "<motivo>"`; se não subir,
o `--update` grava a identidade nova sem motivo.

Da `kg-ssot-v4.7.x` para a `kg-ssot-v4.8.0`, o sha256 dos schemas não muda, e nenhum veredito MUST de `.kg.yaml` muda.
Entram três avisos SHOULD no `.kg.yaml`, os pontos do perfil JSON em rampa: `yaml.unsafe-integer` (inteiro fora de
±(2^53−1)), `yaml.lone-surrogate` (surrogate solto) e `yaml.depth-over-128` (mais de 128 coleções aninhadas). Um
grafo que tenha um desses ganha um código de dívida novo, e o `kg_gate.py` reprova até o `--update` com
`--accept-regression "<motivo>"`, ou até o grafo ser corrigido. A 4.8.0 foi medida nos 454 `.kg.yaml` de um repositório
adotante e nos deste repositório, e nenhum dispara os avisos novos.

Da `kg-ssot-v4.8.0` para a `kg-ssot-v4.8.1`, nem o contrato nem o leitor mudam. Muda o vendor: o `update` grava
`vendor/kg-ssot/.gitattributes` com `* -text`, e o carimbo passa a conferi-lo. Na 4.8.0, um repositório com regra de
fim de linha para `*.json` (`*.json text eol=lf`, por exemplo) normalizava no índice as duas fixtures da suíte que
têm CRLF de propósito, e o `kg_vendor.py check` reprovava num checkout novo, como o do CI, embora passasse na árvore
de trabalho.

**De qualquer tag anterior à 4.8.1, rode o update duas vezes.** O `update` roda pelo `kg_vendor.py` que já está no
vendor, e o de uma tag anterior traz a 4.8.1 sem gravar o `.gitattributes`. O `check` da 4.8.1 acusa isso ("rode o
update de novo"). O segundo `update`, já com o kit novo, grava o arquivo sem precisar de `--force`. Depois do
`git add`, o `check --index` confirma que o índice guarda os bytes da release. Outra saída é rodar o update uma vez
só, pelo clone da tag (`../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.8.1 --dest vendor/kg-ssot`). Uma regra
própria para o vendor no `.gitattributes` da raiz (`vendor/kg-ssot/** -text`) continua valendo e pode ficar.

Da `kg-ssot-v4.21.1` para a `kg-ssot-v4.22.0`, o contrato vai ao v4.13, e só o nível SHOULD muda: nada que passava
reprova, e o gate registra a identidade nova do contrato sem pedir `--update` enquanto nenhum veredito muda (medido nos
184 grafos do core antes da tag). O que você pode ver e fazer:

- O `x_questionnaire` ganha o `role`: `item` (o padrão), `evidence_request` (o pedido de evidência a uma pessoa) ou
  `evidence_requirement` (a evidência que um item exige). Outro valor alerta como `form.enum.node.x_questionnaire.role`.
  Se você separa pedidos ou requisitos pelo prefixo do id, dê a eles o `role` (o `kg_migrate.py nest` com um campo
  `const` faz isso).
- Se um auditor pede o pacote por pergunta, o `kg_audit.py --root .` o exporta (CSV, XLSX ou JSON). Escreva os números
  de `questions` como texto (`["7"]`, não `[7]`): o número que não é texto é pulado e relatado. Use
  `KG_SSOT_LANG=pt-BR` para os cabeçalhos em português. No CI, o `--fail-on-gap` dá rc 1 quando um item tem lacuna ou
  algo foi pulado.

Da `kg-ssot-v4.21.0` para a `kg-ssot-v4.21.1`, o contrato não muda (segue o v4.12), e o gate não pede `--update`. Só
o `kg_criterion.py check` muda: o que ele não consegue conferir agora sai como `integrity.criterion-malformed`, com rc 1,
em vez de deixar o check em silêncio. O caso típico é um `sha256` só de dígitos sem aspas, que o YAML lê como número. Se
você roda o check no CI e ele falha depois da atualização, ponha o `sha256` entre aspas e dê a cada versão exatamente um
de `ref` e `text`.

Da `kg-ssot-v4.20.0` para a `kg-ssot-v4.21.0`, o contrato vai ao v4.12, e só o nível SHOULD muda: nada que passava
reprova, e o gate registra a identidade nova do contrato sem pedir `--update` enquanto nenhum veredito muda. O que você
pode ver e fazer:

- Se os seus grafos registram uma régua e resultados medidos sob ela, use o `x_criterion` (um nó por versão, com o
  `sha256` que o `kg_criterion.py digest` dá) e o `x_measured_under` no resultado. Depois ponha
  `python3 -I -B vendor/kg-ssot/tools/kg_criterion.py check --root .` ao lado do gate no CI: o leitor não calcula hash,
  então o critério editado no lugar só é pego ali.
- Se os seus grafos têm chaves `x_` próprias que correspondem a um perfil canônico (`x_mirror`, `x_doc_cycle`,
  `x_questionnaire`), o `kg_migrate.py nest --map <mapa>` mostra o plano e, com `--apply`, as move.
- O leitor de referência passa a contar uma vez o campo obrigatório ausente; as contagens de uma base por ocorrência
  só descem.
- Desde a 4.20.0, o `kg_store` chama `kg_validate.judge(..., cache=...)`. Um dublê de teste que troca o `judge` pela
  assinatura antiga cai com `TypeError`, e o armazém responde "não julgado": aceite `cache=None` no dublê.

Da `kg-ssot-v4.19.1` para a `kg-ssot-v4.20.0`, o contrato não muda (segue o v4.11), e nada nos seus grafos precisa
de edição. Uma pasta com o carimbo `.kg-ssot-version` passa a ficar de fora também no `kg_query.py`, no `kg_vocab.py`,
no `kg_migrate.py` e no `kg_diff.py --from`, não só no gate; o carimbo na raiz do que se lê não conta mais em nenhuma
ferramenta. Se uma ferramenta sua percorre os seus grafos com um caminho fixo `vendor/`, ela pode passar a usar
`kg_validate.find_vendor_dirs(raiz)` e `kg_validate.in_vendor(caminho, pastas)`. Um processo longo que mantém um
objeto do `kg_store` aberto (o servidor MCP, um app) passa a julgar uma vez o grafo que aponta, enquanto ele não muda.
No `kg_diff --format json` sem `--to`, o `after` passa a ser `WORKTREE`.

Da `kg-ssot-v4.19.0` para a `kg-ssot-v4.19.1`, o contrato não muda (segue o v4.11). O gate deixa fora do corpus,
por padrão, todo arquivo numa pasta com o carimbo do vendor, `.kg-ssot-version`, onde quer que o vendor esteja. O
vendor da 4.19.0 traz um grafo de exemplo (`spec/vocab-examples/cmed-dictionary.kg.yaml`) fora de `fixtures/`, e o
gate o contava como um grafo seu: um `--update` na 4.19.0 o gravaria na sua base. Se você já rodou o `--update` na
4.19.0, rode de novo na 4.19.1: o exemplo sai do corpus, e o gate acusa esse grafo como saído.

Da `kg-ssot-v4.18.0` para a `kg-ssot-v4.19.0`, entra o contrato v4.11. O gate acusa a identidade nova na linha
`· identidade` e decide pelo que cada grafo ganha, como desde a 4.16.0:
- **O `meta.title` e o `meta.slug` viram chaves conhecidas.** Um grafo que reprovava no MUST só por uma delas passa;
  o gate mostra o ganho e pede para travá-lo com `--update`.
- **Os perfis canônicos de `x_` são SHOULD** e só julgam a chave presente: `x_term`, `x_mirror`, `x_doc_cycle`,
  `x_questionnaire` e `x_severity` no nó, `x_confidence` e `x_provisional` na aresta
  ([manual, capítulo 3](docs/manual/pt-BR/03-formato.md)). Se você já usa um desses nomes com outra forma, o aviso novo
  é um código de dívida novo, e o gate reprova. Ou converta os valores (um `x_severity` escrito em outra língua vira
  `critical`, `high`, `medium`, `low` ou `info`), ou aceite uma vez com
  `kg_gate.py --update --accept-regression "<motivo>"`. Medido antes da tag nos três adotantes: um usa um dos nomes
  (`x_severity` com valores em português, já convertidos); os outros grafos ficam com o mesmo veredito e os mesmos códigos.
- **O `kg_migrate.py keys`** renomeia para `x_<chave>` cada chave que o contrato não conhece, que era o que segurava
  a maior parte da dívida MUST herdada de um adotante. Rode o plano primeiro, depois o `--apply`.
- **O relatório de vencimento** (`--due`) lista também os sinônimos do `x_term`, o `x_mirror` e o `x_doc_cycle`, com
  `subject` e `detail` no JSON; a entrada do nó não muda, nem o `schema_version`.
- **A release traz** `tools/kg_vocab.py`, `spec/vocab.schema.json` e `spec/vocab-examples/`; o perfil `gate` não muda.
  O servidor MCP ganha a ferramenta de leitura `kg_terms`.

Um `update` basta. O gate só precisa de `--update` para travar um ganho, ou para aceitar um aviso de perfil.

Da `kg-ssot-v4.17.2` para a `kg-ssot-v4.18.0`, o contrato não muda (segue o v4.10, com a mesma identidade), e nenhum
veredito nem código muda. Muda a língua da saída humana:
- **As ferramentas falam inglês por padrão.** Elas escolhem a língua do jeito do gettext: `KG_SSOT_LANG`, depois
  `LANGUAGE`, `LC_ALL`, `LC_MESSAGES` e `LANG`. Um locale `pt_BR` ou `KG_SSOT_LANG=pt-BR` dá português do Brasil; `C`,
  `POSIX` e qualquer língua sem catálogo dão inglês. Um runner de CI com `LANG=C.UTF-8` recebe inglês.
- **Se o seu CI procura texto na saída humana**, fixe `KG_SSOT_LANG=pt-BR` naquele passo, ou case as duas línguas:
  `PASS` ou `PASSA`, `FAIL` ou `REPROVA`, `✗ WORSE` ou `✗ PIOROU`, `BROKEN INPUT` ou `ENTRADA QUEBRADA`. Melhor
  ainda, decida pelo código de saída.
- **Dado não muda de língua.** As chaves e a estrutura do JSON, os códigos, os códigos de saída, o `place` (`nó X`,
  `aresta #n`, `arquivo`) e o `path` do veredito e o TSV do `kg_migrate` ficam exatamente como antes. As frases de
  `message`, `hint` e `error` dentro do JSON são texto para pessoas: eram sempre em português e agora seguem a língua,
  então compare pelo código, nunca pela mensagem. O servidor MCP fala inglês em qualquer locale.
- **O vendor traz dois arquivos a mais:** `tools/kg_i18n.py` e o catálogo `locale/pt_BR/LC_MESSAGES/kg-ssot.po`. Os
  dois estão no perfil `gate`, que passa a ter 12 arquivos. As ferramentas do vendor não sobem sem o `kg_i18n.py`, e
  sem o catálogo só falam inglês.
- **O vendor parcial também leva os dois.** O `kg_store.py` importa o `kg_i18n` desde a 4.18.0, então um harness que
  copie só o `kg_store.py` (ou qualquer ferramenta avulsa) quebra com `ModuleNotFoundError`: copie junto o
  `tools/kg_i18n.py` e o `locale/`.

Um `update` basta, e o gate não precisa de `--update`.

Da `kg-ssot-v4.17.1` para a `kg-ssot-v4.17.2`, o contrato não muda (segue o v4.10), nem o gate. O servidor MCP passa a
anunciar as anotações de ferramenta: as seis de leitura saem como só leitura e idempotentes, e o `kg_write` e o
`kg_delete` como destrutivas, todas sem mundo aberto. O cliente MCP pode dispensar a confirmação do que só lê.

Da `kg-ssot-v4.17.0` para a `kg-ssot-v4.17.1`, o contrato não muda (segue o v4.10), e o gate não muda de veredito nem
de identidade. Duas correções de campo nas ferramentas de leitura, achadas pelos adotantes no primeiro uso:
- **O `kg_query --root` deixa de fora o vendor e os fixtures por padrão** (`vendor/*`, `fixtures/*`, `*/fixtures/*`,
  `docs/materials/*`). Num adotante, o `--root` lia 411 grafos para 29 reais, e 35 dos 50 primeiros abertos vinham de
  fixtures. `--no-default-excludes` volta a ler tudo. O `kg_diff --from` sem caminhos ganha o mesmo padrão, para a
  atualização do vendor não afogar o diff do grafo. O JSON da consulta passa a dizer a raiz lida (`root`).
- **O campo renomeado com o mesmo valor aparece como renomeação** no `kg_diff`, e não mais como remoção e acréscimo
  soltos: num adotante, duas renomeações de chave apareciam 21 vezes cada. No JSON as duas entradas ficam, ligadas
  por `renamed_to` e `renamed_from`, então quem já lia o formato `kg-ssot.diff/1` não perde nada; só o valor não
  trivial e único dos dois lados é pareado. Os testes da consulta e do diff passam a rodar no CI.

Da `kg-ssot-v4.16.1` para a `kg-ssot-v4.17.0`, o contrato não muda (segue o v4.10, com a mesma identidade). Entram
duas ferramentas de leitura, que não julgam nem gravam:
- **`kg_query.py`, a consulta e a projeção.** Seleciona nós num corpus inteiro (id, prefixo, tipo, status, plano,
  camada, palavras do label, a fila dos abertos, os sem carimbo ou conferidos antes de uma data, a vizinhança de um
  nó) e projeta cada aresta com o label da outra ponta, local ou externa, paginado, no formato `kg-ssot.query/1`. No
  servidor MCP, é a ferramenta `kg_query`, sobre a área do armazém; no perfil atrás de proxy, só a área da identidade.
- **`kg_diff.py`, o diff por id.** Compara dois grafos, ou tudo o que mudou entre duas revisões do git, nó a nó e campo
  a campo, no formato `kg-ssot.diff/1`; `--ignore` tira da comparação o campo que um gerador recarimba.
- **A suíte ganha 2 casos** (356), dois achados da revisão do v4.10 que só tinham teste de unidade: duas chaves
  repetidas na ordem do documento, e a quebra escapada num mapa de fluxo na raiz. Nenhum veredito da referência muda,
  e o gate não muda de identidade. Na 4.16.1, o README e o `llms-full.txt` ainda diziam 349 casos em dois lugares; a
  4.17.0 corrige.

Da `kg-ssot-v4.16.0` para a `kg-ssot-v4.16.1`, entra o contrato v4.10: três pontos do perfil YAML em que o leitor de
referência e o leitor JS divergiam, achados por fuzz e resolvidos pela especificação do YAML. Nenhum dos grafos reais
medidos tem os casos, e nenhum veredito do leitor de referência muda.
- **A ordem dos erros segue o documento.** Uma chave repetida que vem antes de uma âncora repetida ou de um alias sem
  âncora dá `parse.duplicate-key`, como no leitor JS; antes, a referência dava `parse.yaml-error`. A âncora repetida,
  o alias sem âncora e o alias seguido de `:` (`*x:`, que no YAML 1.2 é um alias de nome `x:`) seguem recusados.
- **A linha vazia depois de uma quebra escapada entre aspas duplas vira `\n`**, como pede a especificação e como a
  referência já lia; o leitor JS (o pacote npm) dobrava como espaço.
- **O BOM no começo do arquivo não conta como coluna.** O leitor JS recusava o documento indentado depois dele; a
  referência já aceitava.
- **A suíte ganha 5 casos** (354). A identidade do contrato muda, e o `kg_gate.py` mostra a linha de identidade com
  rc 0, sem pedir `--update`. A exceção é um grafo herdado que reprovava com `parse.yaml-error` e passa a reprovar
  com `parse.duplicate-key`: o veredito é o mesmo, mas o código mudou, e o gate acusa piora até o `--update` registrar
  a troca. Nenhum dos 1.633 grafos reais medidos em quatro repos tem o caso.

Da `kg-ssot-v4.15.1` para a `kg-ssot-v4.16.0`, o contrato não muda (segue o v4.9, com a mesma identidade). Muda o
gate, nas duas dores que os três adotantes mediram.
- **A base vira uma pasta, `.kg-ssot/gate/`, com um registro por grafo.** O arquivo único conflitava em quase todo
  merge entre branches que regravavam a base: num adotante, os 4 merges da semana. Refeitos com a pasta, os mesmos 4
  mergeiam sem conflito, e o gate passa na árvore mergeada. O gate da 4.16.0 ainda lê o `gate.json`, e o primeiro
  `--update` grava a pasta e apaga o arquivo, sem veredito trocado (medido nos três adotantes). Commite a pasta e a
  remoção do arquivo juntos.
- **O primeiro merge entre uma branch já migrada e outra que ainda mexe no `gate.json` conflita uma vez.** O git vê
  a remoção do arquivo como um rename para `.kg-ssot/gate/contract.json` (os dois são pequenos e parecidos), ou como
  modify/delete, e o conflito cai num deles. Medido num adotante: aconteceu no merge da branch longa depois da
  migração. A cura é a mesma nos dois casos: fique com a pasta da branch migrada (`git checkout --theirs
  .kg-ssot/gate`, ou `--ours`, conforme o lado), remova o `gate.json` (`git rm .kg-ssot/gate.json`) e rode
  `kg_gate.py --update`, que regrava os registros com o corpus mergeado. Para não ter o conflito, migre as branches
  vivas antes de mergear entre elas: com as duas na pasta, o merge não conflita.
- **Um `trace:` que aponta para `.kg-ssot/gate.json` fica sem alvo depois da migração.** Troque por
  `.kg-ssot/gate/` (ou `.kg-ssot/gate/contract.json`) no mesmo PR. Achado de um adotante, cujo lint de traces acusou
  o caminho movido: `git grep -n 'kg-ssot/gate.json' -- '*.kg.yaml' '*.kg.json'` lista os casos antes do update.
- **A troca de identidade do contrato sem veredito trocado passa com aviso.** O gate segue acusando a identidade
  numa linha `· identidade` (em inglês, `· identity`), mas o rc vem da comparação, feita com o contrato novo: a regra
  nova que piora um grafo continua reprovando. Uma tag que só muda os schemas sem mudar veredito deixa de pedir um PR
  só para o `--update`. Quem quiser o comportamento antigo passa `--strict-identity`. O que a troca de identidade
  protegia, o schema do vendor editado à mão, o gate passa a conferir sozinho: rodando de um vendor, ele compara o
  sha256 dos dois schemas com o carimbo (`.kg-ssot-version`) e reprova quando divergem ou quando o carimbo sumiu, e o
  `--update` recusa gravar a base, mesmo com `--accept-regression`. Quem edita o schema e reescreve o carimbo junto
  passa pelo gate, como antes passava editando o schema e a base: a defesa aí é o diff do PR, que mostra o carimbo
  mexido.
- **A base guarda a versão do kit** (`kit` no `contract.json`). Medir com um kit mais antigo que o da base reprova: uma
  regra que só a release nova tinha deixaria de ser medida. Uma volta consciente passa com `--update
  --accept-regression "<motivo>"`.
- **O registro segue o `meta.id` num `git mv`.** O gate acusa a tradução numa linha `· A → B: o registro da base
  seguiu pelo meta.id`. Ele não distingue um `git mv` de "apagar um grafo e criar outro com o mesmo `meta.id`", e por
  isso a linha existe: quem revisa o PR vê de onde veio a dívida herdada. Um `meta.id` repetido na base nunca é
  seguido.
- **Depois de um merge, o `contract.json` pode vir de um lado e um registro do outro**, medido com o contrato antigo.
  O veredito segue certo, porque a comparação é sempre feita com o contrato de agora. O que pode ficar velho é a
  identidade gravada; o próximo `--update` a acerta.
- **Um script que passa `--baseline <arquivo>.json`** continua lendo e gravando o arquivo único. Sem `--baseline`, o
  padrão é a pasta.

Da `kg-ssot-v4.15.0` para a `kg-ssot-v4.15.1`, entra o contrato v4.9, que corrige um defeito do desenho da 4.15.0
achado por um adotante ao gravar regras de coleta de evidência.
- **`reverify_every` sem `verified_at` deixa de alertar.** Uma regra com cadência e ainda sem coleta está no estado
  inicial dela, e não em dívida: na 4.15.0, o `kg_gate.py` acusava piora em `form.required.node.verified_at` a cada
  regra nova. Quem lista esse caso é o relatório de vencimento (`kg_validate.py --due`, na lista `unstamped`), fora
  do veredito. O nó PROD sem `verified_at` segue alertando.
- **A suíte segue com 349 casos**, e o caso da cadência sem carimbo passa a ser válido, sem aviso. A identidade do
  contrato muda (o `kg_gate.py` pede `--update`). A dívida SHOULD só pode cair, e nenhum veredito MUST muda.

Da `kg-ssot-v4.14.0` para a `kg-ssot-v4.15.0`, entra o contrato v4.8: as chaves da verificação, desenhadas com dois
adotantes a partir de um caso real de auditoria contínua. Todas são opcionais, e quem não usa não ganha dívida.
- **`reverify_every`**: de quanto em quanto tempo a verificação de um nó tem de ser refeita, em duração ISO 8601 só com
  data (`P3M`, `P1Y`). Zerada (`P0D`), alerta. Na 4.15.0, alertava também sem `verified_at`; a 4.15.1 tirou esse aviso.
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
  `--no-default-excludes` tira os padrões. Antes, o plan pegava as fixtures, e `*/fixtures/*` não casava caminho
  aninhado.
- **O `kg_migrate.py` não grava bytecode no vendor**, mesmo rodado sem `-B`; antes, o `check` seguinte reprovava pelo
  `.pyc` do `kg_validate` no `__pycache__`.
- **O nó cujo `verified_scope` já é o do perfil sai como `same`** no plan, separado do que muda.

Da `kg-ssot-v4.12.0` para a `kg-ssot-v4.13.0`, entram o contrato v4.6 (um MUST raro do YAML e o `\r` normalizado no
leitor JS) e o migrador por perfil.
- **O `kg_migrate.py`** propõe a `provenance` que o v4 pede pelas regras de um perfil que você versiona
  ([cap. 5 do manual](docs/manual/pt-BR/05-ferramentas.md); exemplo em `spec/migrate-examples/`). O `plan` não grava
  nada, e o `apply` grava só o que o plano propôs. A fixture de aceitação, um corpus real anonimizado de 1.024 nós,
  fica em `tools/fixtures/migrate/adopter-hub/`.
- **A linha de continuação de texto entre aspas** tem de ser mais indentada que o mapa ou a lista que o contém; menos
  que isso reprova como `parse.yaml-error`, como a especificação pede.
- **O leitor JS trata o `\r\n` e o `\r` sozinho como quebra de linha**, como a referência, e recusa o texto entre
  aspas que não fecha (a aspa escapada no fim da linha), que ele cortava ali.
- **A suíte ganha 16 casos** (328).
- **No Windows, o update para a 4.13.0 ou posterior roda pelo kit da tag nova.** O `kg_vendor.py` das tags anteriores
  passa ao `git archive` a lista inteira de arquivos da release, e na 4.13.0 ela passa do limite da linha de comando do
  Windows (`WinError 206`). Rode o update pelo clone da tag (`../kg-ssot/tools/kg_vendor.py update --tag
  kg-ssot-v4.19.1 --dest vendor/kg-ssot`). O kit desde a 4.13.0 passa só as entradas da release. No Linux e no macOS
  o limite é bem maior, e o update de sempre funciona.

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
dois schemas muda, então o PR do `update` roda o `kg_gate.py --update` depois de trazer a tag; sem o caso no corpus,
sem motivo.

Da `kg-ssot-v4.10.0` para a `kg-ssot-v4.11.0`, entra o contrato v4.4: um aviso SHOULD e três vereditos MUST raros do
YAML.
- **`integrity.refutes-unreconciled`:** nó que recebe `REFUTES` e segue vivo (nem `superseded` nem `refuted`; só a
  `question` `done` não alerta). O grafo afirma e refuta a mesma coisa. O radar de um adotante já reprova o caso como
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
  nada muda. Desde a 4.18.0, o gate que o `kg_mcp.py` roda recebe `KG_SSOT_LANG=en`, porque o veredito dele vai ao
  modelo; pelo `kg_store.py`, ele herda a sua língua.
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
emitir um código redundante: ela passou a casar os regex por inteiro, como o ECMA-262 dos patterns do contrato. O kit
passa a sair também no PyPI como `kg-ssot`, o leitor JS no npm como `kg-ssot` e o servidor MCP como MCP Bundle (as
receitas em `packaging/` viajam na release), e os módulos acham o `spec/` ao lado de si no pacote instalado ou no
diretório pai no vendor. Para quem usa o vendor, nada muda: um `update` basta, e o gate não precisa de `--update`.

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
  detalhe diz que a migração não re-verificou, por exemplo
  `medição: <o que foi medido>; não reverificado na migração` (decisão do mantenedor em 2026-10-09).
  A prosa interna do adotante (um `docs/*.md` escrito por alguém do time) é `testemunho`, não `leitura`: é o relato
  de quem a escreveu, e assim o radar mostra quais `confirmed` só têm prosa por trás.
  **Atenção:** se o seu CI cobra que grafo novo saia limpo também no SHOULD, este alerta já reprova lá no v4, e não só
  no v5. Ajuste antes os geradores que escrevem `provenance`.

O caminho, num PR só:
1. `python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.19.1 --source https://github.com/marciocar/kg-ssot`
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
  - to: docs/research/other.kg.yaml#C_OLD          # este grafo supera um nó de outro grafo
    edge_type: SUPERSEDES
  - from: docs/graph/ports.kg.yaml#D_MATRIX        # um nó de fora limita um nó daqui
    to: D_CUT
    edge_type: CONSTRAINS
```

Os tipos são `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`, `TRACES_TO` e `DEPENDS_ON`. O gate confere o alvo contra
os `.kg.yaml` e `.kg.json` rastreados do repo, inclusive os que o `--exclude` tira do corpus, e lê só os que alguma
referência cita: alvo que não existe, ou grafo-alvo apagado, reprova quem aponta (`integrity.dangling-external`). Fora
do gate, `kg_validate.py --corpus <raiz do repo>` faz a mesma conferência: num repo git, contra os `.kg.yaml` e
`.kg.json` rastreados; fora de um repo, contra todo grafo sob o diretório. Sem `--corpus`, o leitor confere só a forma
e a ponta local, e diz quantos arquivos ficaram com a ponta externa sem conferir. Uma referência ao próprio arquivo
passa como externa; use `edges` para isso. Uma chave `x_` própria que fazia esse papel migra para cá; a que só declara
algo, sem ser aresta, segue como `x_`.

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
nada, e o `apply` grava só o que o plano propôs, conferindo que nada mais mudou
([cap. 5 do manual](docs/manual/pt-BR/05-ferramentas.md)). Uma chave própria sem `x_` se resolve renomeando para
`x_<nome>`.

## Conformidade de outro leitor

Para provar que um leitor próprio concorda com o contrato, rode a suíte com o leitor de referência, **depois** do
`git add vendor/kg-ssot`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_conformance.py
```

A ordem importa: os casos de corpus conferem a ponta externa contra os grafos rastreados quando a suíte mora num
repo git, e com o vendor ainda fora do git esses casos falham (`latest: 384/390`). Depois compare com os códigos que o
seu leitor emite. O formato dos casos e como rodar a suíte com um leitor em outra linguagem estão em
[`spec/conformance/README.pt-BR.md`](spec/conformance/README.pt-BR.md).
