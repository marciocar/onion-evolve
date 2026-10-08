# Adotar o contrato KG-SSOT

Este guia é para um repo que guarda grafos `.kg.yaml` e quer validá-los contra o contrato formal: o JSON Schema
2020-12 em dois níveis (MUST e SHOULD), a suíte de conformidade e o leitor de referência. O adotante fixa uma
**tag** deste repo e traz a superfície da release por script. O contrato nunca é copiado à mão nem é código
compartilhado.

## O que vem na release

A lista está em [`spec/release.json`](spec/release.json):
- o contrato (`spec/kg-contract-v3.schema.json` e `spec/kg-contract-v3.should.schema.json`);
- a suíte (`spec/conformance/`);
- o leitor de referência (`tools/kg_validate.py`, `tools/kg_conformance.py`);
- o gate (`tools/kg_gate.py`) e o vendor (`tools/kg_vendor.py`);
- as dependências fixadas (`tools/requirements.txt`, Python 3 com PyYAML e jsonschema);
- este guia.

Do lado do mantenedor deste repo, `kg_vendor.py release-check` confere essa lista no CI:
- toda entrada é coberta por arquivo rastreado;
- a tag é `contract-v<version>`;
- o contrato citado é o vigente;
- nenhum arquivo da release tem referência privada.

O adotante usa só `update` e `check`.

## 1. Trazer a release

A primeira vez, a partir de um clone deste repo:

```bash
python3 -I tools/kg_vendor.py update --tag contract-v3.0.0 --dest <adotante>/vendor/kg-ssot
```

Para atualizar, rode a partir do vendor, com `--source` obrigatório. Ele aceita caminho ou URL, e uma URL
vira um clone nu descartável. Dentro do vendor, o repo git é o do adotante, que não tem a tag:

```bash
python3 -I vendor/kg-ssot/tools/kg_vendor.py update --tag contract-v3.1.0 --source <caminho ou URL deste repo>
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
- **Carimbo:** `vendor/kg-ssot/.kg-ssot-version` guarda a tag, o commit e o sha256 de cada arquivo.
- **Commit:** o vendor não commita. Num PR próprio, o adotante commita o diretório inteiro com o carimbo.

## 2. Gravar a linha de base

Na raiz do adotante:

```bash
pip install -r vendor/kg-ssot/tools/requirements.txt
python3 -I vendor/kg-ssot/tools/kg_gate.py --update      # grava .kg-ssot/gate.json
```

O gate mede os `.kg.yaml` rastreados por git (`git ls-files`, lidos da árvore de trabalho). Um arquivo que
ainda não está no git não entra. Por padrão, `*/fixtures/*` e `docs/materials/*` ficam de fora, e isso já
exclui as fixtures do próprio vendor.

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
    python3 -I vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
    python3 -I vendor/kg-ssot/tools/kg_gate.py
```

**`check`** reprova (rc 1) quando um arquivo do vendor foi editado, apagado ou acrescentado. Isso inclui
bytecode num `__pycache__`, que trocaria o leitor sem mudar a fonte, e symlink. Os scripts do kit não gravam
bytecode, então rodar o gate não suja o vendor.

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
    `failing` como caminho → [códigos], `debt` como código → inteiro ≥ 0 e `accepted_regressions` como lista;
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
1. roda `kg_vendor.py update` com a tag nova;
2. roda `kg_gate.py` e explica no PR a diferença que aparecer;
3. grava a base com `--update`, porque um contrato novo muda a identidade.

Aviso novo no SHOULD sobe a dívida por desenho. As rampas do contrato (SHOULD hoje, MUST depois) chegam assim,
como compromisso medido.

## Conformidade de outro leitor

Para provar que um leitor próprio concorda com o contrato, rode a suíte com o leitor de referência:

```bash
python3 -I vendor/kg-ssot/tools/kg_conformance.py
```

Depois compare com os códigos que o seu leitor emite. O formato dos casos e o contrato de runner estão em
`spec/conformance/README.md`.
