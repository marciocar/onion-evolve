# Changelog

[English](CHANGELOG.md) | **Português (Brasil)**

As mudanças relevantes do KG-SSOT ficam aqui, no formato do [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com as releases marcadas como `kg-ssot-vX.Y.Z`. A versão do contrato (`v4.N`) é a do contrato do `.kg.yaml` e do
`.kg.json` que a release leva; ela só muda quando o contrato muda. Cada seção é também o corpo da release no GitHub.
Esta é a tradução; a fonte é o [CHANGELOG.md](CHANGELOG.md) em inglês. As releases anteriores à 4.16.0 estão no
[ADOPTING.pt-BR.md](ADOPTING.pt-BR.md).

## [Unreleased]

## [4.18.0] - 2026-10-22

O KG-SSOT passa a falar inglês primeiro. As ferramentas, a documentação e os cadastros estão em inglês, e a tradução
completa para o português do Brasil vai ao lado. Contrato v4.10, sem mudança.

### Changed

- **As ferramentas imprimem em inglês por padrão.** `kg_validate`, `kg_gate`, `kg_vendor`, `kg_store`, `kg_migrate`,
  `kg_query`, `kg_diff`, `kg_conformance`, `kg_mcp`, `kg_prov_export`, `kg_release_notes` e a CLI do npm escolhem a
  língua como o gettext: `KG_SSOT_LANG`, depois `LANGUAGE`, `LC_ALL`, `LC_MESSAGES` e `LANG`. Um locale `pt_BR` (ou
  `KG_SSOT_LANG=pt-BR`) dá o português do Brasil; `C`, `POSIX` e o que não tem catálogo dão o inglês.
- **Nota de atualização:** o dado para máquina não muda com a língua: as chaves e a estrutura do JSON, os códigos de
  erro, os códigos de saída, o `place` (`nó X`, `aresta #n`) e o `path` do veredito, o lugar do `--where` e o TSV do
  `kg_migrate`. O texto para pessoas muda: a saída de terminal e, dentro do JSON, as frases de `message`, `hint` e
  `error`, que antes eram sempre em português e agora saem em inglês, a menos que o locale seja `pt_BR` (um runner de
  CI com `LANG=C.UTF-8` recebe o inglês). Compare pelo código, nunca pela mensagem. Se o seu CI procura texto na saída
  humana (`PASSA`, `✗ PIOROU`, `ENTRADA QUEBRADA`), fixe `KG_SSOT_LANG=pt-BR` ou case as duas línguas (`PASS`,
  `✗ WORSE`, `BROKEN INPUT`); melhor ainda, decida pelo código de saída.
- O servidor MCP fala inglês em qualquer locale: as descrições das ferramentas, as instruções, os erros e o texto dentro
  dos resultados são protocolo (e prompt para o modelo), e por isso não dependem mais do ambiente do servidor. Um gate
  externo (`--gate-cmd`) chamado pelo servidor recebe `KG_SSOT_LANG=en` pelo mesmo motivo. A vitrine do Claude Desktop
  é traduzida pela localização da extensão.
- Como no gettext, o `LANGUAGE` só vale quando o locale efetivo não é o `C`: `LC_ALL=C` força o inglês mesmo num
  desktop com `LANGUAGE=pt_BR:en`.
- A documentação é escrita em inglês e traduzida para o português do Brasil: `README.md` e `README.pt-BR.md`,
  `ADOPTING.md` e `ADOPTING.pt-BR.md`, `spec/conformance/README.md` e o `.pt-BR.md` dele, e o manual em `docs/manual/`,
  com a tradução em `docs/manual/pt-BR/`. Os capítulos do manual passam a ter nome de arquivo em inglês
  (`04-contract.md`, `05-tools.md`, ...); os capítulos em português ficam com os nomes de antes em `pt-BR/`.
- Os cadastros estão em inglês: os README do PyPI e do npm, a descrição no MCP Registry e a extensão do Claude Desktop
  (`.mcpb`), que leva a localização pt-BR (`mcpb-resources/pt-BR.json`) para o cliente configurado em português.
- O `llms.txt` e o `llms-full.txt` estão em inglês e leem a documentação em inglês.

### Added

- `tools/kg_i18n.py` e o catálogo `locale/pt_BR/LC_MESSAGES/kg-ssot.po` (formato gettext, 446 mensagens). Eles vão na
  release, no perfil `gate` e no pacote Python; o `kg_vendor.py update` os traz com a tag. Sem eles, as ferramentas
  vendoradas não iniciam.
- O `kg_migrate plan --json` informa a entrada quebrada também em JSON (`{"error": ..., "reason": "broken_input"}`,
  saída 2). O erro de uso do parser de argumentos também sai 2, mas não escreve nada no stdout, então um script
  distingue os dois sem casar texto.
- `kg_store.InsideGitWorktree`, uma subclasse de `StoreError` para a raiz do disco ou do versionado dentro de uma
  worktree git, para quem escolhe o backend decidir pelo tipo, e não pela mensagem.

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

[Unreleased]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.18.0...HEAD
[4.18.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.2...kg-ssot-v4.18.0
[4.17.2]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.1...kg-ssot-v4.17.2
[4.17.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.0...kg-ssot-v4.17.1
[4.17.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.1...kg-ssot-v4.17.0
[4.16.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.0...kg-ssot-v4.16.1
[4.16.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.15.1...kg-ssot-v4.16.0
