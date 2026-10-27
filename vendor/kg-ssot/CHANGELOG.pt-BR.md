# Changelog

[English](CHANGELOG.md) | **Português (Brasil)**

As mudanças relevantes do KG-SSOT ficam aqui, no formato do [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com as releases marcadas como `kg-ssot-vX.Y.Z`. A versão do contrato (`v4.N`) é a do contrato do `.kg.yaml` e do
`.kg.json` que a release leva; ela só muda quando o contrato muda. Cada seção é também o corpo da release no GitHub.
Esta é a tradução; a fonte é o [CHANGELOG.md](CHANGELOG.md) em inglês. As releases anteriores à 4.16.0 estão no
[ADOPTING.pt-BR.md](ADOPTING.pt-BR.md).

## [Unreleased]

## [4.31.0] - 2026-10-26

Um site de documentação em https://marciocar.github.io/kg-ssot/, construído do README, do guia de adoção, do changelog e
do manual pelo `tools/kg_site.py` e pelo Zensical, e publicado no GitHub Pages pelo workflow de release; e uma demo de
40 segundos no README, gravada do `docs/demo/demo.sh` e listada no novo `mirror_only` do `spec/release.json`, que a
publica no repositório público e no site, mas não a leva ao vendor dos adotantes. O README e o manual contavam a suíte de conformidade como 438
casos, e `latest/` tinha 457; a contagem foi corrigida, e a checagem de higiene agora a amarra aos manifestos da suíte.
Contrato v4.15, sem mudança.

## [4.30.0] - 2026-10-26

A release traz a skill de agente `skills/kg-ssot/` (formato Agent Skills) e um marketplace de plugin do Claude Code em
`.claude-plugin/`. Num teste pré-registrado, os agentes com a skill acertaram tanto quanto os sem ela (12 de 12), com
45% dos tokens de saída e 54% das chamadas de ferramenta. Contrato v4.15, sem mudança.

## [4.29.1] - 2026-10-26

O `kg_prov_export.py` não emite mais IRI quebrada para ponta de aresta malformada. Contrato v4.15, sem mudança.

### Corrigido

- **O `kg_prov_export.py` não emite mais IRI quebrada para ponta de aresta malformada.** Com `--edges` ou `--full`, uma
  ponta que não era id de nó válido nem referência externa (um caminho absoluto, por exemplo, que o contrato recusa)
  virava IRI local com `/` ou um segundo `#`. O rdflib mantinha a tripla, mas o pyoxigraph e o pyrudof a descartavam
  sem erro, e a mesma saída virava grafos diferentes conforme o leitor. Uma ponta assim agora vai como o literal
  `kg:fromRef` ou `kg:toRef`. Achado pela dissecação dos leitores RDF em outro repositório que usa o KG-SSOT.

## [4.29.0] - 2026-10-26

O extra `rdf` traz o rdflib para ler a exportação PROV, com um job de CI que reconstrói toda aresta a partir do RDF; e o
`kg_prov_export.py --full` exporta o documento inteiro, de modo que o YAML carregado pode ser remontado a partir do RDF.
Contrato v4.15, sem mudança.

### Adicionado

- **O `kg_prov_export.py --full` exporta o documento inteiro.** Ele implica `--edges` e leva também todo campo de cada
  nó e do `meta` como `kg:<chave>` (texto como literal, o resto como JSON tipado `kg:json`). Assim, o YAML carregado
  pode ser remontado a partir do RDF, para SPARQL ou SHACL sobre o mesmo dado. Medido contra critérios registrados
  antes da medição:
  - **Correção:** igualdade estrutural do YAML carregado em 209 grafos.
  - **Custo:** 0,25 s e 19,7 MB para o corpus inteiro do core num runner de CI, contra tetos de 10 s e 100 MB.

  Uma primeira série reprovou num teto de 3 vezes a exportação simples: a razão real é de cerca de 3,6. Esse teto foi
  substituído, depois do resultado, por tetos absolutos fixados sabendo que o custo era de cerca de 1 s. A página da
  medição diz isso, e o código foi congelado antes da segunda série.
- **O extra `rdf`.** O `pip install "kg-ssot[rdf]"`, ou o `tools/requirements-rdf.txt` com hash no vendor, traz o
  rdflib, para ler a saída do `kg-prov-export --edges` em ferramentas RDF. Ele fica fora do perfil `gate`. Um job novo
  de CI lê a saída `--edges` de todo caso válido da suíte e dos grafos do repo, reconstrói cada aresta só a partir do
  RDF, confere as triplas-padrão e serializa em N-Triples.

## [4.28.0] - 2026-10-25

O `kg_prov_export.py --edges` exporta as arestas, com `cito:supports`, `cito:refutes` e `dcterms:replaces` onde há
termo-padrão; sem a opção, a saída não muda. Contrato v4.15, sem mudança.

### Adicionado

- **`kg_prov_export.py --edges` exporta as arestas.** Por padrão, o exportador continua deixando as arestas de fora,
  porque derivação em PROV é produção, não suporte evidencial, e a PROV não tem par para `REFUTES`. Com `--edges`, toda
  aresta, de `edges` e de `external_edges`, vira um recurso `kg:Edge` com o tipo, as pontas e todas as chaves, e por
  isso volta inteira a partir do RDF. Entre dois nós locais, `SUPPORTS`, `REFUTES` e `SUPERSEDES` ganham também as
  triplas-padrão `cito:supports`, `cito:refutes` e `dcterms:replaces`. Nenhuma aresta gera `prov:wasDerivedFrom`, e
  sem a opção a saída não muda.
  - **Como foi medido:** contra critérios registrados antes da medição, em 213 grafos e 9.988 arestas. Todas as
    arestas voltaram a partir do RDF lido pelo rdflib 7.6.0, todas as triplas-padrão saíram na direção certa, e o custo
    foi de 1,7 vez o da exportação simples.

## [4.27.0] - 2026-10-25

Contrato v4.15: a ponta externa pode morar numa pasta com ponto como `.github/`, e `.` e `..` seguem reprovando; o
armazém git julga com o mesmo corpus do gate; o `kg_trace` sai com rc 3 no corpus vazio.

### Mudado

- **Contrato v4.15: a ponta externa pode morar numa pasta com ponto.** O `<caminho>#<id>` exigia que cada segmento
  começasse por letra, dígito ou `_`, e por isso `.github/` e `.config/`, onde um repositório guarda a
  maquinaria, não podiam ser apontadas. O segmento agora pode começar por um ponto seguido de um deles; os segmentos
  `.` e `..` seguem reprovando, porque a regra existe para barrar a travessia. Nada que passava reprova. Os dois
  leitores mudam juntos, na ponta que sai e na que entra, com oito casos novos na suíte (cinco de forma e três de corpus
  com alvo numa pasta com ponto). Achado de um adotante cujos estudos apontam para um registro
  numa pasta com ponto.
- **O armazém git julga com o mesmo corpus do gate.** O `kg_store` (`GitStore`) passa a ler os grafos rastreados em
  pasta com ponto ao conferir a ponta externa: um grafo que aponta para lá pode ser gravado, e uma mudança lá pode
  barrar uma gravação que deixaria a ponta sem alvo. Ele continua sem escrever em pasta com ponto, e o `list()`, o
  `read()` e as ferramentas `kg_query` e `kg_terms` do servidor MCP veem só os nomes do próprio armazém.
- **O `kg_trace.py check` sai com rc 3 quando nenhum grafo foi lido.** Ele imprimia "no graph read" com rc 0, que um
  CI que só olha o rc lia como "todo trace resolve". O JSON já dizia `graphs: 0`.

## [4.26.0] - 2026-10-25

O `kg_query --semantic` acha o nó quando a pergunta usa outras palavras que não as do label, fundindo a busca por
texto e um modelo de embedding local; opcional, e fora de todo veredito. Contrato v4.14, sem mudança.

### Adicionado

- **O `kg_query --semantic`, a busca por sentido.** Uma pergunta com outras palavras que não as do label não achava
  nada: o `--text` casa palavras. O `--semantic "<pergunta>"` ordena os nós que passam nos outros filtros por
  semelhança, com um modelo de embedding multilíngue local; com `--text <termo>`, as duas listas se fundem por RRF
  (k=60). Numa bancada pré-registrada de 20 perguntas de um curador, a fusão achou 14, o vetor sozinho 12 e o texto
  sozinho 9. O JSON ganha `semantic` (modo, modelo com revisão e sha256, uso do índice) e um `rank` por nó; o rc 3 diz
  que o vetor não roda ali, para quem chama cair no `--text` e dizer isso. Sem `--semantic`, a saída não muda. A
  ferramenta `kg_query` do servidor MCP também aceita `semantic`.
- **O `kg_vector.py`, o modelo e o índice.** O `fetch` baixa o modelo ONNX fixado por revisão e sha256, e o `index`
  mantém um cache em `.kg-ssot/vector/` que refaz só os nós que mudaram. Opcional: `pip install "kg-ssot[vector]"`
  (onnxruntime, tokenizers, numpy), ou o `tools/requirements-vector.txt` com hash no vendor. Nada aqui entra em
  veredito. Também no PyPI como `kg-vector`. O perfil `gate` leva o `tools/kg_vector.py` e o
  `tools/requirements-vector.txt` (17 arquivos), porque o `kg_query` importa o módulo para o `--semantic`.

### Corrigido

- **O `kg_query`, o `kg_diff` e o `kg_migrate` escrevem UTF-8 quando a saída vai para arquivo ou pipe.** No Windows
  o padrão era cp1252, e um label com `→` ou um caractere fora dele derrubava o comando; o label com acento saía em
  outra codificação. Achado pelo job novo do CI, que gravava o JSON de uma consulta num arquivo.

## [4.25.1] - 2026-10-24

O `kg_trace.py` passa a dizer onde cada trace resolve, e o perfil `gate` leva o que ele precisa para rodar. Contrato
v4.14, sem mudança.

### Adicionado

- **O `kg_trace.py` diz onde cada trace resolve.** O JSON (`kg-ssot.trace/1`) ganha `resolved_targets`: para cada
  trace que resolve, o arquivo, o id e o tipo do nó, o alvo julgado, o `path` do que o check viu existir, relativo à
  raiz e com os links seguidos, e o `kind` (`file` ou `dir`). Quem monta um índice de leitura a partir dos traces não precisa mais de um resolvedor
  próprio. O campo é aditivo e não obrigatório, e a saída da 4.25.0 segue válida.

### Corrigido

- **O perfil `gate` leva o que o `kg_trace.py` importa.** O perfil passa a ter 15 arquivos: o `tools/kg_trace.py`, o
  `tools/kg_query.py`, que ele importa, e o `spec/trace.schema.json`, que define a saída dele, vêm junto. Antes, um adotante no `--profile gate` não conseguia rodar o check
  do trace. A conferência da release passa a exigir que cada ferramenta de um perfil leve os módulos `kg_*` que importa.

## [4.25.0] - 2026-10-24

O `trace:` de um nó que aponta para um arquivo movido não passa mais em silêncio: o `kg_trace.py` confere cada âncora
contra os arquivos do repositório. Contrato v4.14, sem mudança.

### Adicionado

- **O `kg_trace.py`, o trace que não resolve.** Um `trace:` de nó que aponta para um arquivo movido ou renomeado passava
  no gate em silêncio: o leitor não toca o disco. O `kg_trace.py check --root .` confere cada âncora a partir da raiz
  do repositório e aponta `integrity.trace-target-missing` (`kg-ssot.trace/1`). Ele julga só o texto que parece
  caminho do repositório e conta à parte o que não julga (absoluto ou URL, um `--external-root` declarado, não
  caminho). Um nome sem barra só entra como arquivo rastreado na raiz com o nome exato. Resolve na raiz, na pasta do
  grafo ou na pasta pai dele, e um alvo que sai da raiz não resolve. As regras são o resolvedor de um adotante, medido
  em milhares de traces; no corpus desse adotante a ferramenta julga os mesmos 2.500 nós, com 0 faltando. Também no
  PyPI, como `kg-trace`.

## [4.24.0] - 2026-10-24

Um adotante testa um commit antes da tag sem refazer a tag na máquina, e o vendor de bancada nunca passa por release.
Contrato v4.14, sem mudança.

### Adicionado

- **O `kg_vendor.py update --ref <commit>`, para a bancada antes da tag.** Um adotante que testa uma release antes de
  ela existir precisava refazer a tag de um commit na máquina, porque o `--tag` recusa, com razão, o commit cujo
  `spec/release.json` declara outra versão. O `--ref` traz a árvore de um commit como ela é; o carimbo diz
  `unreleased` e guarda o commit, e o `check` reprova esse vendor (`VENDOR FORA DE RELEASE`, rc 1) sem o
  `--allow-unreleased`, para um vendor de bancada nunca passar por release no CI. O `kg_gate.py` o recusa do mesmo
  jeito (`--allow-unreleased`, e nunca `--update` a partir de um vendor de bancada), para um CI que roda só o gate
  não tomar a bancada por release. Um `update --tag` depois o substitui sem `--force`. Pedido pela bancada de um
  adotante.

## [4.23.0] - 2026-10-23

Um código curto ganha nome legível no próprio vocabulário, e os códigos da prosa são conferidos contra ele, com
catraca. Contrato v4.14: o `x_term.scheme` e um aviso no SHOULD, e nada que passava reprova.

### Adicionado

- **Um código curto com nome legível (contrato v4.14).** Um código como `O1` ou `r16` mantém o id curto e estável e ganha
  um nome num vocabulário: o código é a `notation` de um `x_term`, o nome é o `pref`, e o novo `x_term.scheme` (um slug)
  diz a que vocabulário ele pertence, como o `skos:notation`, o `skos:prefLabel` e o `skos:inScheme` no SKOS. Sem
  esquema, o esquema é o grafo. Os dois leitores alertam `integrity.term-notation-duplicate` quando dois termos vivos
  têm a mesma notation no mesmo esquema (SKOS §6.5.3). Só SHOULD: nada que passava reprova. Medido antes do desenho: 71
  códigos opacos nos grafos do próprio produto, com duas colisões reais (`O1` e `V1` queriam dizer duas coisas cada), e
  centenas nos de um adotante.
- **O `kg_vocab.py` resolve códigos e os confere na prosa.** O `lookup` casa uma `notation` exata, sozinha ou como
  `esquema:notation`; o `terms` dá a cada termo o `scheme` efetivo; o `export --to skos` escreve o `skos:inScheme` e o
  `skos:ConceptScheme`. O novo `lint` lê labels e narrativas, acha códigos por uma regex (`--pattern`) e aponta
  `vocab.notation-duplicate` no corpus inteiro, `vocab.code-unresolved` e `vocab.code-ambiguous` (um código em dois
  esquemas, nenhum do próprio grafo). O `--external soc2='CC[0-9]+'` declara um sistema de códigos de fora, e o
  `--baseline <arquivo> [--update]` é a catraca do gate: os códigos que existem não travam, o novo tem de nascer com
  nome, e nomear o primeiro termo de um código que colide não cobra pelas menções antigas (`reclassified`).

### Mudado

- **O `kg_query.py --text` não dá mais zero calado.** Ele compara sem maiúscula nem acento (`verificacao` casa
  `Verificação`); quando o texto inteiro é um termo do vocabulário (o `pref`, um sinônimo atual ou a `notation`),
  casam também o termo e todo nó com qualquer forma dele como palavra inteira (`expanded`; o sinônimo de caso ou
  aposentado não expande, e a notation casa exata); e o resultado vazio traz um `hint` que diz quando o zero vem dos
  outros filtros. Pedido de um
  adotante que mediu «PDF digitalizado», «reconhecimento óptico» e «verificacao» dando 0 em silêncio.

## [4.22.0] - 2026-10-23

O pacote de auditoria por pergunta: uma linha por item de questionário, com a resposta, a evidência datada e as lacunas
que ele calcula, em CSV, XLSX ou JSON. Contrato v4.13: o `x_questionnaire.role` no SHOULD, e nada que passava reprova.

### Adicionado

- **O pacote de auditoria por pergunta (`kg_audit.py`).** O auditor pede o pacote por pergunta, e até aqui um adotante
  o mantinha à mão ao lado do grafo. A ferramenta exporta uma linha por item de questionário (o par de nome e número
  que o `x_questionnaire` dá): a pergunta, a resposta (pelo perfil, e o nó sem perfil pelo `DEPENDS_ON` numa direção ou
  na outra), o veredito, a evidência exigida, a evidência (`SUPPORTS` para a resposta, ou `SUPPORTS` ou `TRACES_TO` para
  a pergunta, um pedido ou um requisito, também de outro grafo) com a data, o alcance e o vencimento, as contradições
  (`REFUTES`), os pedidos de evidência, o dono e as lacunas que ela calcula: `no-answer` (sem resposta viva: a
  `refuted` ou `superseded` não conta, nem a evidência dela), `contradicted`, `no-confirmed-evidence`, `evidence-unstamped`,
  `evidence-cadence-invalid`, `evidence-due` e `verdict-open`. O que ela não pode usar (um `role` fora do enum, um
  número de pergunta que não é texto, um perfil malformado) sai em `skipped`, no próprio pacote, nunca em silêncio.
  Formatos:
  - CSV, com as perguntas ou com a evidência, e um apóstrofo na frente da célula que rodaria como fórmula;
  - XLSX com as perguntas, a evidência e o que foi pulado, escrito só com a biblioteca padrão, com bytes estáveis;
  - JSON, `kg-ssot.audit/1` (`spec/audit.schema.json`).

  O `--column` traz uma chave própria do adotante na resposta como coluna, o `--as-of` fixa o dia contra o qual a
  evidência vence, e o `--fail-on-gap` dá rc 1 para o CI. Um grafo que não se lê dá rc 1, porque o pacote ficaria
  incompleto em silêncio. Também no PyPI, como `kg-audit`. Medido nos grafos de um adotante antes do corte.
- **O `x_questionnaire.role` (contrato v4.13).** `item`, o padrão; `evidence_request`, o pedido de evidência a uma
  pessoa; ou `evidence_requirement`, a evidência que um item exige. Sem ele, só o prefixo do id os separava. Só SHOULD:
  outro valor alerta como `form.enum.node.x_questionnaire.role`, e nada que passava reprova.

## [4.21.1] - 2026-10-23

O `kg_criterion.py check` acusa o que não consegue conferir em vez de pulá-lo. Contrato v4.12, sem mudança.

### Corrigido

- **O `kg_criterion.py check` não pula mais o critério que não consegue conferir.** Um `sha256` só de dígitos sem
  aspas vira número no YAML, e a versão saía do check com rc 0 e nenhum achado. Agora a versão cujo `sha256` não é
  texto, ou que não tem exatamente um de `ref` e `text` em texto, o `x_measured_under` que não é um mapa com uma lista
  de citações em mapa, e a citação de outro grafo cujo `sha256` não é texto (mesmo quando esse grafo não foi dado)
  saem como `integrity.criterion-malformed`, com rc 1. O leitor já alertava o tipo (`form.type`); só o check passava em
  silêncio. Achado pela bancada de um adotante.

## [4.21.0] - 2026-10-23

A régua fixada antes do dado entra no contrato, e as chaves `x_` próprias de um adotante vão para os perfis canônicos.
Contrato v4.12: dois perfis SHOULD e cinco avisos, e nada que passava reprova.

### Added

- **O critério pré-registrado (contrato v4.12).** Trocar a régua depois de ver o dado vira uma emenda datada em vez
  de uma reescrita, como no OSF Preregistration e nas emendas versionadas de um registro de ensaio clínico. Dois perfis
  SHOULD: `x_criterion`, um nó por versão do critério (`id`, `version`, `registered_at`, `sha256` e `ref` ou `text`;
  `amends` com `reason` na emenda), e `x_measured_under`, no resultado (`measured_at` e `criteria`, uma lista de
  `{criterion, sha256}`). Os dois leitores, Python e JavaScript, avisam cinco coisas entre nós do mesmo grafo, sem
  calcular hash:
  - `integrity.criterion-unknown`: o critério citado, ou o `amends`, não é um nó de critério do grafo;
  - `integrity.criterion-amends-mismatch`: a emenda aponta a versão de outro critério, ou volta a ela mesma;
  - `integrity.criterion-sha-mismatch`: o `sha256` citado não é o da versão;
  - `integrity.measured-post-hoc`: medido na rodada que motivou a versão, ou antes do registro dela;
  - `integrity.measured-order-unknown`: as datas não dizem a ordem (o mesmo dia, ou um dia de distância quando uma
    delas não tem fuso).

  `ref` e `text` juntos alertam `form.exclusive.node.x_criterion`, um tipo novo de forma. Pedido de um adotante cujo
  próprio revisor pegou uma régua trocada depois do dado.
- **O `kg_criterion.py`** imprime o `sha256` de um critério (`digest`):
  - do `text`: UTF-8, LF, sem espaço no fim da linha;
  - de um arquivo inteiro: os bytes, com CRLF trocado por LF;
  - de um item de lista num JSON ou YAML: a forma JCS (RFC 8785), escolhido por JSON Pointer ou pelo `id`.

  O `check` confere cada versão contra o texto ou o arquivo, e cada citação `<caminho>#<id>` de outro grafo
  (`kg-ssot.criterion/1`, `spec/criterion.schema.json`); ele reprova com achado ou com grafo que não se lê, e vai ao
  lado do gate no CI, porque o leitor não calcula hash. É também o comando `kg-criterion` do pacote PyPI.
- A suíte vai de 390 a 438 casos (`latest/form/profiles/` e a nova `latest/integrity/criterion/`).
- **O `kg_migrate.py nest` leva as chaves `x_` próprias de um adotante para um perfil canônico de nó** (`x_mirror`,
  `x_doc_cycle`, `x_questionnaire`), como um mapa diz (`spec/kg-migrate-nest.schema.json`): cada campo de uma
  constante, de uma chave `x_` que sai do nó ou de uma chave que fica, por uma regex e uma tabela de valores
  opcionais. A chave movida por regex ou por prefixo pede `raw: true`, que guarda o valor original em `x_raw`, e nenhum
  texto se perde. O valor sem código, a fonte obrigatória ausente, o perfil que não passa no schema, o alias e o nó em
  estilo de fluxo vão para quem revisa já no plano, nunca são chutados. Pedido de um adotante; numa cópia dos dois
  grafos dele (108 nós, 168 chaves), 106 perfis montados e 2 para revisão.

### Fixed

- **O campo obrigatório ausente conta uma vez.** No leitor de referência, um objeto com N campos obrigatórios faltando
  contava cada um N vezes: o `meta` sem `schema_version` e sem `id` mostrava `form.required.meta.id ×2`, e o nó com três
  campos ausentes, `×3` em cada. O leitor JavaScript já contava certo. O veredito, o conjunto de códigos e a suíte não
  mudam; as contagens no resumo, no `--where`, no veredito JSON e na base do gate por ocorrência caem para o número real.
  Achado da bancada de um adotante.

## [4.20.0] - 2026-10-23

O armazém deixa de julgar de novo o grafo que não mudou, o carimbo do vendor vira regra pública em todas as
ferramentas, e o `kg_diff` dá nome à árvore de trabalho. Contrato v4.11, sem mudança.

### Added

- **O `kg_diff.py` compara com a árvore de trabalho pelo nome.** `--to WORKTREE` é o mesmo que omitir o `--to`, e
  `WORKTREE:CAMINHO` lê o arquivo da árvore de trabalho, então `HEAD:x.kg.yaml WORKTREE:x.kg.yaml` revisa uma edição
  antes do commit (pedido de um adotante; `--to WORKTREE` era revisão inválida). O `WORKTREE:CAMINHO` parte da raiz do
  repositório, como o `REV:CAMINHO`, e o caminho que sai do repositório é entrada quebrada. No JSON, o `after` passa a
  ser `WORKTREE`, no lugar do rótulo em português que a árvore de trabalho tinha. Uma branch ou tag chamada `WORKTREE`
  passa a ser alcançada por `refs/heads/WORKTREE` ou `refs/tags/WORKTREE`.

### Changed

- **O armazém não rejulga mais o grafo que aponta para o gravado e não mudou.** O `kg_store` guarda na memória o
  veredito de cada grafo julgado (`kg_validate.JudgeCache`), pela chave do texto, dos dois schemas, da língua, do limit
  e de se cada ponta externa resolve. Com 50 apontadores de 820 KB, a segunda gravação do alvo foi de 41 s para 3,3 s,
  e gravar o mesmo texto de novo, de 44 s para 0,35 s; a primeira gravação de um processo custa o mesmo. Uma ponta
  externa quebrada ainda reprova, e um contrato novo julga tudo de novo. O `kg_validate.judge()` aceita o cache no
  argumento opcional `cache=`.
- **Uma pasta com o carimbo `.kg-ssot-version` é o vendor, em toda ferramenta que lê um repositório.** Desde a 4.19.1,
  só o `kg_gate.py` a deixava fora do corpus; o `kg_query.py`, o `kg_vocab.py`, o `kg_migrate.py` e o
  `kg_diff.py --from` excluíam só o `vendor/*` na raiz, e um vendor em outra pasta trazia os grafos de exemplo dele. O
  carimbo na raiz do que se lê não conta, em toda ferramenta, inclusive no gate: ler uma pasta que é o vendor lê os
  grafos dela. A regra agora é pública (`kg_validate.VENDOR_STAMP`, `vendor_dirs`, `in_vendor`, `find_vendor_dirs`)
  e está no ADOPTING, para as ferramentas de quem adota seguirem (pedido de um adotante cujo resolvedor de trace
  contou o grafo de exemplo do vendor).

### Fixed

- **Um teste do gate dependia da data.** Cada regressão aceita mora em `accepted/<hash>.json`, e o hash leva a data,
  então a ordem de leitura mudava de um dia para o outro. O teste agora confere que as regressões se acumulam, não a
  ordem delas.

## [4.19.1] - 2026-10-22

O gate deixa o vendor do KG-SSOT fora do corpus do adotante. Contrato v4.11, sem mudança.

### Fixed

- **O `kg_gate.py` contava o grafo de exemplo do vendor como grafo do adotante.** O vendor da 4.19.0 traz
  `spec/vocab-examples/cmed-dictionary.kg.yaml` fora de `fixtures/`, e um `--update` o gravaria na base (achado por um
  adotante antes de qualquer `--update`). O gate passa a deixar fora, por padrão, todo arquivo numa pasta com o
  carimbo `.kg-ssot-version`, onde quer que o vendor esteja; o `--no-default-excludes` o traz de volta.

## [4.19.0] - 2026-10-22

Um vocabulário de domínio que se confere sinônimo por sinônimo, e uma forma para as chaves `x_` que os adotantes
repetem. Contrato v4.11.

### Added

- **O perfil `x_term` (contrato v4.11, SHOULD):** um termo é um nó com o rótulo preferido (`pref`) e os sinônimos,
  cada um com `kind` (`alt` ou `hidden`, como no SKOS), `source`, `locator`, a `version` do documento, `verified_at`,
  `reverify_every`, `scope` (`domain`, ou `case` com o caso nomeado, e uma jurisdição opcional) e `retired` (`true`
  para o nome antigo). O termo aposentado é o nó com `status: superseded` e uma aresta `SUPERSEDES` do termo que o
  substitui. Um exemplo real, tirado do dicionário de dados aberto da CMED/ANVISA, vai em
  `spec/vocab-examples/cmed-dictionary.kg.yaml`.
- **O `kg_vocab.py`:** o `terms` lista os termos e o que vence, o `lookup` resolve um texto para o termo (sem
  maiúscula, acento nem espaço repetido; o sinônimo de caso só com `--case`), e o `export` grava SKOS-XL com os nomes
  da ISO 25964 em Turtle (`--to skos`) ou um item por termo para o Apache Ossie, com o `ai_context.synonyms` e a
  proveniência de cada sinônimo em `custom_extensions` (`--to ossie`). Saída JSON: `kg-ssot.vocab/1`
  (`spec/vocab.schema.json`). Vai também como o comando `kg-vocab` no pacote do PyPI.
- **A ferramenta `kg_terms` no servidor MCP:** a mesma resolução sobre o armazém, só de leitura, com a proveniência
  dos sinônimos e o termo que substitui um termo substituído.
- **Os outros perfis canônicos de `x_` (SHOULD, julgados só quando a chave está presente):** `x_mirror` (um registro
  copiado de outro sistema, com `synced_at` e `resync_every`), `x_doc_cycle` (o ciclo de vida de um documento
  externo), `x_questionnaire` (o elo com as perguntas de um questionário externo), `x_severity` (de `critical` a
  `info`), e `x_confidence` e `x_provisional` na aresta.
- **O `kg_migrate.py keys`:** renomeia para `x_<chave>` cada chave que o contrato não conhece, pelo texto e com
  conferência de invariância; as chaves conhecidas vêm do schema MUST. Medido numa cópia dos 15 grafos do core que
  reprovavam no MUST por chave estranha: 14 passam depois.
- **O `meta.title` e o `meta.slug`** viram chaves conhecidas (MUST, uma ampliação: nada que passava reprova).

### Changed

- **O relatório de vencimento** (`kg_validate.py --due`) lista também os sinônimos do `x_term`, o `x_mirror` e o
  `x_doc_cycle`, com `subject` e `detail`; a entrada do nó e o `schema_version` ficam iguais.
- **Um item de lista dentro do nó leva o caminho no código** (`form.type.node.x_term.labels.item`), nos dois leitores.
- **Nota de atualização:** se você já usa um dos nomes de perfil com outra forma, o gate mostra um código SHOULD
  novo. Medido antes da tag nos três adotantes: um usa (`x_severity` com valores em português, já convertidos). Converta os
  valores ou aceite uma vez com `--accept-regression`. A suíte vai a 390 casos.

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

[Unreleased]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.19.1...HEAD
[4.19.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.19.0...kg-ssot-v4.19.1
[4.19.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.18.0...kg-ssot-v4.19.0
[4.18.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.2...kg-ssot-v4.18.0
[4.17.2]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.1...kg-ssot-v4.17.2
[4.17.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.0...kg-ssot-v4.17.1
[4.17.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.1...kg-ssot-v4.17.0
[4.16.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.0...kg-ssot-v4.16.1
[4.16.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.15.1...kg-ssot-v4.16.0
