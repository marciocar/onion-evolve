# Changelog

[English](CHANGELOG.md) | **Português (Brasil)**

As mudanças relevantes do KG-SSOT ficam aqui, no formato do [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com as releases marcadas como `kg-ssot-vX.Y.Z`. A versão do contrato (`v4.N`) é a do contrato do `.kg.yaml` e do
`.kg.json` que a release leva; ela só muda quando o contrato muda. Cada seção é também o corpo da release no GitHub.
Esta é a tradução; a fonte é o [CHANGELOG.md](CHANGELOG.md) em inglês. As releases anteriores à 4.16.0 estão no
[ADOPTING.md](ADOPTING.md).

## [Unreleased]

## [4.17.2] - 2026-10-22

O servidor MCP diz ao cliente quais ferramentas só leem. Contrato v4.10, sem mudança.

### Adicionado

- Toda ferramenta do `kg_mcp` passa a anunciar as anotações de ferramenta do MCP: `kg_validate`, `kg_get`, `kg_list`,
  `kg_query`, `kg_history` e `kg_schema_help` só leem e são idempotentes; `kg_write` e `kg_delete` são destrutivas.
  Nenhuma sai do armazém local (`openWorldHint: false`). O cliente pode dispensar a confirmação da leitura e pedir a
  da gravação e da remoção. São dicas; quem decide o que é gravado segue sendo o gate do armazém.

## [4.17.1] - 2026-10-22

Correções de campo na consulta e no diff, achadas pelos adotantes no primeiro uso real da 4.17.0. Contrato v4.10, sem
mudança.

### Modificado

- O `kg_query --root` e o `kg_diff --from` deixam de fora, por padrão, o código vendorizado e os fixtures de teste
  (`vendor/*`, `fixtures/*`, `*/fixtures/*`, `docs/materials/*`). Num adotante, o `--root` lia 411 grafos para 29
  reais. `--no-default-excludes` lê tudo; o caminho dado explicitamente nunca é excluído.
- O JSON do `kg_query` passa a dizer a raiz do corpus (`root`).

### Adicionado

- O `kg_diff` marca como renomeação o campo renomeado com o mesmo valor (`renamed_from` e `renamed_to`). As duas
  entradas ficam no JSON, então o formato `kg-ssot.diff/1` não muda; só o valor não trivial e único dos dois lados é
  pareado.
- Os testes da consulta e do diff rodam no CI.

## [4.17.0] - 2026-10-21

Consulta, projeção e diff de um corpus inteiro de grafos. Contrato v4.10, sem mudança.

### Adicionado

- `kg_query.py`: seleciona nós em muitos grafos (id, prefixo, tipo, status, plano, camada, palavras do label, a fila
  dos abertos, os não conferidos desde uma data, a vizinhança de um nó) e projeta cada aresta com o label da outra
  ponta, local ou externa, com paginação por cursor. Formato `kg-ssot.query/1` (`spec/query.schema.json`).
- A ferramenta `kg_query` no servidor MCP, restrita à área do armazém de quem chama, com teto de bytes por página.
- `kg_diff.py`: compara dois grafos, ou tudo o que mudou entre duas revisões do git, alinhando pelo id do nó e campo a
  campo, lendo o git sem checkout. `--ignore` tira um campo que um gerador recarimba. Formato `kg-ssot.diff/1`
  (`spec/diff.schema.json`).
- Os comandos `kg-query` e `kg-diff` no PyPI; o MCPB lista 8 ferramentas.
- Dois casos de conformidade (356 em `latest/`).

## [4.16.1] - 2026-10-21

Contrato v4.10: o leitor de referência e o leitor JavaScript concordam em três casos raros do YAML. Nenhum veredito
da referência muda, e nenhum dos 1.633 grafos reais medidos em quatro repositórios muda de código.

### Corrigido

- A ordem dos erros segue o documento: a chave repetida que vem antes de uma âncora repetida ou de um alias sem âncora
  dá `parse.duplicate-key`, como no leitor JavaScript.
- Leitor JavaScript: a linha vazia depois de uma quebra escapada entre aspas duplas é uma quebra de linha, como pede a
  especificação do YAML; o BOM no começo não conta como coluna.
- Cinco casos de conformidade (354).

## [4.16.0] - 2026-10-21

O gate sem atrito. Contrato v4.9, sem mudança.

### Modificado

- A base do gate é uma pasta, `.kg-ssot/gate/`, com um registro por grafo pelo `meta.id`: branches que mexem em grafos
  diferentes mexem em arquivos diferentes, e a base mergeia sem conflito.
- A troca de identidade do contrato sem veredito trocado passa com aviso (rc 0); `--strict-identity` volta ao
  comportamento antigo. O vendor confere os schemas contra o carimbo.

[Unreleased]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.2...HEAD
[4.17.2]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.1...kg-ssot-v4.17.2
[4.17.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.0...kg-ssot-v4.17.1
[4.17.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.1...kg-ssot-v4.17.0
[4.16.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.0...kg-ssot-v4.16.1
[4.16.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.15.1...kg-ssot-v4.16.0
