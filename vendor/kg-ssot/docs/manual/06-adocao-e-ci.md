# 6. Adoção e CI

[← Ferramentas](05-ferramentas.md) · [Índice](README.md) · [Conformidade e leitores →](07-conformidade-e-leitores.md)

Este capítulo é o mapa. O guia completo, com cada caso de borda, é o [`ADOPTING.md`](../../ADOPTING.md).

## O caminho em quatro passos

```mermaid
flowchart LR
  A["1. vendor update<br/>traz a tag"] --> B["2. git add vendor/<br/>+ gate --update"]
  B --> C["3. commit<br/>vendor + base"]
  C --> D["4. CI: check + gate<br/>em todo PR"]
```

Na raiz do seu repo, com Python 3.11 ou mais (o `rpds-py`, dependência do jsonschema, declara `Requires-Python >=3.11`):

```bash
# 1. trazer a release, por tag, do repositório público
git clone https://github.com/marciocar/kg-ssot ../kg-ssot
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.10.0 --dest vendor/kg-ssot

# 2. as dependências num venv, e a linha de base (o gate só mede arquivo rastreado: git add antes)
python3 -m venv .venv && .venv/bin/pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt
echo .venv/ >> .gitignore
git add vendor/kg-ssot .gitignore docs/          # e os seus .kg.yaml, onde estiverem
.venv/bin/python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update

# 3. commitar o vendor, com o carimbo, e a base
git add .kg-ssot/gate.json && git commit -m "adota o contrato KG-SSOT"
```

Os grafos que já reprovam viram dívida herdada, nomeada por caminho. O passo 4 é o CI, em todo PR: o workflow
completo do GitHub Actions está na seção "O passo de CI" do [`ADOPTING.md`](../../ADOPTING.md), e o passo em si é:

```yaml
- name: Contrato KG-SSOT (vendor íntegro + gate por grafo)
  run: |
    pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt
    python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
    python3 -I -B vendor/kg-ssot/tools/kg_gate.py
```

## O que o gate garante

- Nenhum grafo **novo** entra reprovando no MUST.
- Nenhum grafo herdado ganha um código MUST que não tinha.
- A dívida SHOULD, por código, não sobe.
- Uma troca de contrato aparece no PR: a base guarda o nome e o sha256 dos schemas.

Consertar um grafo não compensa quebrar outro: a comparação do MUST é por grafo.

O gate mede só `.kg.yaml`. Um `.kg.json` no repositório fica fora dele, e quem quer o CI cobrando roda
`kg_validate.py` nesses arquivos num passo próprio.

## Atualizar a tag

No mesmo PR: `kg_vendor.py update` com a tag nova (de dentro do vendor, com
`--source https://github.com/marciocar/kg-ssot`), `git add vendor/kg-ssot`,
`kg_vendor.py check --dest vendor/kg-ssot --index` para conferir o que o commit vai levar (saindo de uma tag anterior à
4.8.1, rode o `update` duas vezes: o kit antigo não grava o `.gitattributes` do vendor, e o da 4.8.1 grava),
`kg_gate.py` para ver a diferença, e `kg_gate.py --update` para gravar a identidade nova. Se uma versão menor
trouxe um aviso SHOULD que o seu corpus já tinha, a dívida sobe por desenho, e o `--update` vai com
`--accept-regression "<motivo>"`.

## Subir de uma versão maior (v3 → v4)

O v4 reprova o que o v3 só alertava. A subida é pela **rampa**: os grafos que passam a reprovar entram na base
como dívida herdada, e a dívida só encolhe dali em diante. Não há truque de data no schema nem conserto do corpus
inteiro de uma vez. O passo a passo, com os comandos, está na seção "Do v3 para o v4" do
[`ADOPTING.md`](../../ADOPTING.md).

## Nota de ambiente

Em sistemas com PEP 668 (Ubuntu 24.04 em diante), o `pip install` fora de um venv é recusado. Use um venv e rode
o kit com o Python dele. No GitHub Actions com `actions/setup-python`, o `pip install` funciona direto.

## Num app

O KG-SSOT guarda **conhecimento sobre o produto**: decisões, regras de negócio, afirmações e a evidência de cada uma.
Não é banco de dados de runtime: o progresso, os pontos e a sequência de um usuário continuam no banco do app. O que
vai para o grafo é, por exemplo, "a sequência zera depois de um dia sem registro", com a fonte da decisão, a data em
que foi conferida e a aresta `TRACES_TO` até o código ou o teste que a implementa (a receita está no
[capítulo 8](08-receitas.md#uma-regra-de-negócio-ligada-ao-código)).

- **No CI:** o caminho acima vale para qualquer repo, de qualquer linguagem: o gate só precisa de Python no CI.
- **Em tempo de execução, em Python, pelo pacote:** desde a 4.9.0 o kit também sai no PyPI como `kg-ssot`
  (`pip install kg-ssot`), com os módulos em `kg_ssot` e os comandos `kg-validate`, `kg-conformance`, `kg-gate`,
  `kg-store`, `kg-mcp` e `kg-prov-export`. O contrato e a suíte viajam dentro do pacote:

  ```python
  from kg_ssot import kg_store
  store = kg_store.GitStore("/var/lib/meu-app/grafos", init=True)   # fora do repo do app
  ```

  O pacote é o caminho para o app; para o **gate no CI**, o vendor por tag continua o canal recomendado, porque o
  contrato que julga o grafo fica no diff do repositório.
- **Em tempo de execução, em Python, pelo vendor:** ponha `vendor/kg-ssot/tools` no `sys.path` e rode sem
  gravar bytecode, para o `check` do vendor seguir íntegro:

  ```python
  import sys
  sys.dont_write_bytecode = True                    # ou PYTHONDONTWRITEBYTECODE=1 no ambiente
  sys.path.insert(0, "vendor/kg-ssot/tools")
  import kg_store                                    # o armazém que só grava o que o contrato aprova
  store = kg_store.GitStore("/var/lib/meu-app/grafos", init=True)   # fora do repo do app
  ```

  A raiz do armazém fica **fora** do repo do app. Dentro de um repo git, o `DiskStore` e o `VersionedStore`
  recusam a raiz; o `GitStore` com a raiz no próprio repo commita no branch em que ele estiver, fora do PR, e numa
  subpasta do repo cria um repositório git aninhado.
- **Em JavaScript (Node, React Native, Expo):** desde a 4.9.0 o leitor JS sai no npm como `kg-ssot`
  (`npm install kg-ssot`). A entrada não importa nada do Node, e o validador do contrato vem pré-compilado, sem
  `new Function` nem `eval`, então roda no Hermes. `verdict(texto, { format })` devolve o veredito MUST com os códigos
  da suíte, e o comando `kg-ssot-validate` julga arquivos. Desde a 4.10.0 ele mede também os avisos SHOULD, com os mesmos códigos da referência em todos os casos da suíte; a linha e as dicas
  ficam com o leitor de referência em Python.
- **Num cliente de MCP, como o Claude Desktop:** desde a 4.9.0 o servidor MCP de referência também sai como MCP
  Bundle (`kg-ssot-<versão>.mcpb`). Ele é anexado à release da tag no repositório público depois que o pacote
  `kg-ssot` da mesma versão sai no PyPI, porque o bundle instala o pacote de lá. Ao instalar, o cliente pergunta o
  diretório do armazém e se o servidor fica só leitura, e instala o pacote pelo `uv` na sua máquina. O `uv` cria o
  ambiente dentro da pasta da extensão, travado por um `uv.lock` com o hash de cada dependência. O bundle tem a
  atestação de proveniência do GitHub (`gh attestation verify kg-ssot-<versão>.mcpb --repo marciocar/kg-ssot`) e
  aparece no MCP Registry oficial como `io.github.marciocar/kg-ssot`. O armazém é o versionado: cada gravação fica registrada, e o `kg_history` a
  mostra. Uma pasta dentro de um repositório git usa o git, num repositório aninhado (o repositório de fora passa a
  vê-la como pasta não rastreada). Quando a pasta não abre, o servidor sobe só com o julgamento e diz o motivo ao
  modelo, que o conta no chat (desde a 4.9.1; na 4.9.0 o motivo ia só para o log). Roda no macOS, no Linux e no
  Windows; no Windows, o armazém roda desde a 4.9.1 (na 4.9.0 ele não abria lá), com a proteção de caminho descrita no
  capítulo 5. O servidor roda local, por stdio, e não fala com nenhum serviço externo.
- **Em outra linguagem:** não há leitor pronto além do Python e do JavaScript. Valide pelo CLI
  (`kg_validate.py --format json` devolve o veredito JSON de `spec/verdict.schema.json`) ou por um modelo pelo
  servidor MCP (`kg_mcp.py`); um leitor próprio prova que concorda com o contrato passando na suíte (capítulo 7).
