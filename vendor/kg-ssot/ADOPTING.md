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
- as dependências fixadas (`tools/requirements.txt`, Python 3 com PyYAML e jsonschema);
- este guia.
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

A primeira vez, a partir de um clone deste repo:

```bash
python3 -I -B tools/kg_vendor.py update --tag kg-ssot-v4.3.2 --dest <adotante>/vendor/kg-ssot
```

Para atualizar, rode a partir do vendor, com `--source` obrigatório. Ele aceita caminho ou URL, e uma URL
vira um clone nu descartável. Dentro do vendor, o repo git é o do adotante, que não tem a tag:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.3.2 --source <caminho ou URL deste repo>
```

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
pip install -r vendor/kg-ssot/tools/requirements.txt         # ou o venv da nota de ambiente, abaixo
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
python3 -m venv .venv && .venv/bin/pip install -r vendor/kg-ssot/tools/requirements.txt
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
#     MUST   form.required.node.provenance  nó C_MODEL_EXPLAINABLE
#     MUST   yaml.forbidden-key-on  aresta #6 (C_X -> Q_A)
#     SHOULD integrity.testimony-in-prod  nó C_BIAS_AUDIT_QUARTERLY
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

```yaml
- name: Contrato KG-SSOT (vendor íntegro + gate por grafo)
  run: |
    pip install -r vendor/kg-ssot/tools/requirements.txt
    python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
    python3 -I -B vendor/kg-ssot/tools/kg_gate.py
```

**`check`** reprova (rc 1) quando um arquivo do vendor foi editado, apagado ou acrescentado. Isso inclui
bytecode num `__pycache__`, que trocaria o leitor sem mudar a fonte, e symlink. Os scripts do kit não gravam
bytecode quando rodam como script. Mas uma ferramenta sua que **importa** um módulo do kit grava o `.pyc` dele
no `__pycache__` do vendor, porque o Python compila antes de executar o módulo, e o próximo `check` reprova.
Por isso todo comando deste guia usa `python3 -I -B`, e quem importa o kit roda com `-B` ou
`PYTHONDONTWRITEBYTECODE=1`.

O contrato não se customiza no adotante: uma mudança necessária volta ao produto como sinal e vira caso ou
decisão de contrato.

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
1. roda `kg_vendor.py update` com a tag nova e `git add vendor/kg-ssot` (o gate mede só arquivo rastreado);
2. roda `kg_gate.py` e explica no PR a diferença que aparecer;
3. grava a base com `--update`, porque um contrato novo muda a identidade.

Aviso novo no SHOULD sobe a dívida por desenho. As rampas do contrato (SHOULD hoje, MUST depois) chegam assim,
como compromisso medido.

Da `contract-v4.0.x` para a `contract-v4.1.x`, nenhum veredito muda: entram quatro avisos SHOULD (carimbo sem alvo,
testemunho em PROD, verificação antes do fato e decisão sem origem; a tabela está em `spec/conformance/README.md`).
Se a dívida SHOULD subir (por desenho, quando o corpus tem o que os avisos novos acusam), o `--update` desse PR vai com
`--accept-regression "<motivo>"`; se não subir, o `--update` grava a identidade nova sem motivo.

## 5. Do v3 para o v4

O v4 é uma versão maior: o que alertava no v3 passa a reprovar. Quem está numa tag `contract-v3.x` sobe pela
**rampa** do gate, sem truque de data no schema e sem consertar o corpus inteiro de uma vez.

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
  (decisão do mantenedor em 2026-10-09, `D_METHOD_CLASS_IS_EVIDENCE`).
  **Atenção:** se o seu CI cobra que grafo novo saia limpo também no SHOULD, este alerta já reprova lá no v4, e não só
  no v5. Ajuste antes os geradores que escrevem `provenance` (no primeiro adotante, seis deles emitiam `method` livre).

O caminho, num PR só:
1. `python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.3.2 --source <caminho ou URL deste repo>`,
   e `git add vendor/kg-ssot`;
2. `python3 -I -B vendor/kg-ssot/tools/kg_gate.py` mostra a identidade nova do contrato e os grafos que passam a
   falhar no MUST;
3. `python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update --accept-regression "<motivo>"` grava esses grafos em
   `failing`, como **dívida herdada**. Sem o motivo, o `--update` recusa, porque grafo que passava e falha é
   piora. Daí em diante vale a catraca: grafo novo tem de passar no v4, grafo de `failing` não ganha código MUST
   novo, e a dívida só encolhe, com `--update` a cada conserto.

**Onde a fonte mora** (`provenance.locality`, opcional, desde a `contract-v4.2.0`): `repo` (arquivo versionado no
próprio repo), `web` (endereço público), `host` (só existe numa máquina: um journal local, um caminho fora do repo) ou
`pessoa` (o relato de alguém). Fora desses valores, alerta como `form.enum.node.provenance.locality`. Serve para medir
o que um terceiro consegue reverificar e para barrar `host` quando o grafo vai a público.

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
os `.kg.yaml` rastreados do repo, inclusive os que o `--exclude` tira do corpus, e lê só os que alguma referência cita: alvo que não existe, ou grafo-alvo
apagado, reprova quem aponta (`integrity.dangling-external`). Fora do gate, `kg_validate.py --corpus <raiz do repo>`
faz a mesma conferência: num repo git, contra os `.kg.yaml` rastreados; fora de um repo, contra todo `.kg.yaml` sob o
diretório. Sem `--corpus`, o leitor confere só a forma e a ponta local, e diz quantos arquivos ficaram com a ponta externa
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
inventado. Uma chave própria sem `x_` se resolve renomeando para `x_<nome>`.

## Conformidade de outro leitor

Para provar que um leitor próprio concorda com o contrato, rode a suíte com o leitor de referência:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_conformance.py
```

Depois compare com os códigos que o seu leitor emite. O formato dos casos e o contrato de runner estão em
`spec/conformance/README.md`.
