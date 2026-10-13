---
branch: feat/kg-writer-gitstore-v4.7.0
date: 2026-10-13
reviewed_diff_sha256: e4a3537d94579a798001f6d38e42aa72dc40a5e84844d42bcbd0e2a3c94efc56
reviewed_code_sha256: 900182da1a0fb0ff0890e71cb11932cd9f7561f07086cd3d899629993fc530ec
findings_total: 9
findings_real: 9
findings_fixed: 7
tokens: 0
duration_min: 150
verdict: APROVADO
reviewer: passada adversarial própria (refutador com default reprovado, sem subagente) — gate mecânico: kg_vendor check, kg_gate do CI, famílias mcp_onion_kg_writer, kg_contract_check, census_seal, seed_adoption_graph e kg_migrate_v3 com LC_ALL=C e mutantes; 19 textos hostis contra o servidor real
---

# kg-ssot-v4.7.0, e o armazém do writer vira o GitStore do produto

## O que muda

- **Vendor**: de `kg-ssot-v4.6.0` para `kg-ssot-v4.7.0` (1fe102ab0b9a, 313 arquivos). O leitor da 4.7.0
  recusa documento hostil: mais de 1.000 coleções abertas viram `parse.yaml-error`, e a expansão de alias tem
  teto de 2× o texto. Medido no core: o `--format json` dá o mesmo veredito nos 443 `.kg.yaml` rastreados (a
  única diferença é um `hint` novo numa fixture do vendor), a saída de texto é byte a byte igual, e o `kg_gate`
  com os `--exclude` do CI sai rc 0 com a saída byte a byte igual à do main (156 grafos, 139 no MUST, 17 na
  dívida herdada). O sha256 dos schemas MUST e SHOULD, do `verdict.schema.json` e do `kg_gate.py` não mudou.
  O `tools/kg_mcp.py` chega no vendor e não é usado.
- **Armazém do writer** (`ops/mcp-onion-kg-writer/server.py`): gravar, ler, listar e remover passam pelo
  `vendor/kg-ssot/tools/kg_store.py` → `GitStore(<área>, init=True, committer=("onion-kg-writer",
  "onion-kg-writer@localhost"))`, com o autor = o e-mail do header. Nova tool `kg_delete`, trava otimista
  `expected_sha256` no `kg_write` e no `kg_delete`, e `sha256` no `kg_my_get` e no `kg_my_list`.
- **Gate**: o radar fica no writer, porque o armazém julga só o contrato. O contrato é julgado pelo armazém
  **antes** de gravar, na mesma área (usuário sem área: num armazém vazio temporário, para reprovado não criar
  a área). O veredito é conferido de novo pelo writer: schema, versão, coerência de cada resultado com os
  MUST e ponta externa conferida. A aresta externa entre grafos da **mesma** área, que no #1070 era sempre
  NAO JULGADO, agora é julgada e aceita. Ponta para fora da área reprova.
- **Guarda de aninhamento**: antes de compor, mede a profundidade no stream de eventos do YAML com a libyaml
  **e** o parser puro, e recusa acima de 64 coleções abertas ou com âncora/alias. O desenho segue o `_too_deep`
  de `vendor/kg-ssot/tools/kg_validate.py` na 4.7.0 e os casos do
  `test_aninhamento_fundo_e_bomba_de_aliases_sao_erro_de_parse` do produto, citados, não copiados.
- **Envelope**: além do `served_commit`, declara o `store_commit`, o HEAD do code root quando o armazém foi
  importado, e avisa (`aviso_codigo`) quando os dois divergem.

## Notas do produto (2026-10-13) e onde cada uma é cobrada

| Nota | Caso da bancada |
|---|---|
| (a) o GitStore enxerga só o rastreado | `store-so-rastreado`: um arquivo plantado sem commit não aparece na lista nem na leitura, e não serve de ponta externa |
| (b) `StoreError` = não gravado | `store-error-recusa-nomeada`: com `.git/info` trocado por symlink, a recusa é nomeada, sem commit e sem o caminho do servidor; `symlink-plantado-recusa` |
| (c) texto igual ao HEAD | `reescrita-identica-unchanged`: `written`, `unchanged`, `commit: null`, e o número de commits não muda |
| (d) `not_judged` nunca grava | `armazem-not-judged-na-gravacao`, onde o 1º julgamento passa e o da gravação quebra, e `armazem-nao-julga-recusa` |
| (e) julga quem aponta, ponta relativa à raiz | `externa-na-area-aprova`, `externa-no-inexistente-reprova`, `externa-fora-da-area-reprova` (core, área de outro usuário, `../`), `dependente-rejulgado-na-regravacao`, `delete-bloqueado-por-dependente` |

## Achados

1. **O armazém julga dentro do processo, e a libyaml derruba o processo.** Medido: `yaml.load` de 30.000 `[`
   com `CSafeLoader` sai com segfault (rc 139), e com o parser puro sai com `RecursionError`. No #1070 o
   contrato era subprocesso, então quem caía era o filho. Com o GitStore, quem cairia é o servidor. Curado
   pela guarda de aninhamento, com um caso por classe: `[`, `- - -`, `? ?`, indentação crescente, as quebras
   `\r`, `\x85`, U+2028 e U+2029, tab no começo, bomba de alias pelo compositor e bomba de alias pelo stream.
   Cada caso confere que o processo segue vivo. A 4.7.0 é a segunda camada.
2. **Inteiro com mais de 4.300 dígitos** sobe `ValueError` no compositor, não `YAMLError`. O processo não caía,
   mas a resposta era "erro interno" sem nome. Curado: vira `parse`, e o veredito é REPROVADO
   (`inteiro-gigante-nao-derruba`).
3. **A recusa do armazém vazava o caminho absoluto** da raiz de dados e o nome da área (por exemplo,
   `<raiz>/<área>/.git/info é symlink`). Curado: o `scrub` corta a raiz e o diretório temporário, e a bancada
   confere a ausência.
4. **O cache de parse do leitor** (`parse_v1`, `lru_cache` de 1.024 textos) guardaria até 200 grafos × N
   usuários × 512 KB no processo de vida longa. Curado: o cache é limpo depois de cada chamada ao armazém.
5. **`expected_sha256: "new"` numa remoção era ignorado em silêncio.** Curado: agora é recusa nomeada.
6. **`served_commit` deixou de bastar.** O armazém e o leitor são importados no boot. Depois de um
   `checkout --detach` sem reinício, o radar julgaria no SHA novo e o contrato no velho, e o envelope
   declararia só o novo. Curado: o envelope traz `store_commit`, o `aviso_codigo` quando divergem, e o runbook
   do README manda reiniciar.
7. **Bancada**: com a limpeza de fixture frágil, um mutante que muda o estado derrubava o harness antes do
   caso nomeado, o que dava falso "NÃO morde" (visto no mutante da migração). Curado com o `wipe`. O custo
   também era alto: 58 mutantes em série levaram 788 s. Agora rodam 4 em paralelo, com `--until <caso>`, e a
   família leva cerca de 240 s. Mutante sem arquivo de rc conta como falha.
8. **Não curado, teto declarado: o julgamento do contrato não tem timeout.** Ele roda dentro do processo,
   limitado pelos tetos de tamanho, pela guarda e pelos tetos do leitor. O radar tem timeout.
9. **Não curado, teto declarado: se o armazém disser que gravou com um veredito que o writer não crê**, o
   writer responde com erro alto que nomeia o `ref`, mas não desfaz o commit. Esse caso não se alcança pela
   entrada do usuário com o armazém real (o writer julga antes, com a mesma régua).

## Passada adversarial (refutador com default reprovado)

- **Gravação sem julgamento**: todo caminho de escrita passa por `store.write`/`store.delete`, que julgam
  sempre, depois do radar e do julgamento prévio. No code root falso, julgamento que quebra, `not_judged` na
  gravação, versão `/2`, veredito incoerente (PASS com MUST, que o armazém sozinho gravaria) e ponta externa
  não conferida terminam sem nenhum `.kg.yaml` no disco. **Refutado.**
- **Fuga de área**: o corpus do armazém é a área. A ponta para o core, para a área de outro usuário e para
  `../` reprova, symlink na área ou dentro dela é recusado, e o isolamento A×B, o `kg_delete` de outro usuário
  e o e-mail inválido são cobrados. **Refutado.**
- **Aresta para fora da área aceita**: os três alvos acima reprovam, e o mutante que julga sem a área
  (`external_checked: false`) morde os três casos. **Refutado.**
- **Processo derrubável por texto**: as 9 classes da bancada e mais 19 textos fora dela, contra o servidor
  real. Entre eles: BOM no meio, CRLF, tab como separador, `? -` misturado, chave complexa em flow, mapa em
  sequência indentada, inteiro de 400 KB, float gigante, 40.000 chaves repetidas, tag python, `%YAML`,
  multidocumento e surrogate. Todos terminaram com o processo **vivo** e nada gravado. **Refutado.**

## Conferido

- `mcp_onion_kg_writer`: 62 casos por HTTP (eram 39) e 64 mutantes (eram 35), todos mordendo o caso
  nomeado, com `LC_ALL=C`. Junto rodaram `kg_contract_check`, `census_seal`, `seed_adoption_graph` e
  `kg_migrate_v3`: 114 passaram e 0 falharam. O harness também passa com o Python do sistema
  (`/usr/bin/python3`: jsonschema 4.10.3, PyYAML 6.0.1 com libyaml), que é o da unidade publicada.
- **Migração**: o caso `migracao-area-antiga` monta, em mktemp, uma área no layout do writer de antes do
  GitStore: repo git, branch `main`, `slug/slug.kg.yaml` rastreado, committer `onion-kg-writer@localhost`
  e um `.kgw-*` não rastreado. Lista, leitura e gravação funcionam. O commit antigo continua raiz e ancestral
  do HEAD, e o branch continua `main`. O diretório de produção **não foi lido nem tocado**.
- Tetos de defesa dupla (o mutante sobrevive, por isso fica fora da lista): o `--git-dir` e o
  `GIT_CEILING_DIRECTORIES`; o `O_NOFOLLOW` do armazém dentro da área; a âncora antes do alias no compositor;
  a reconferência do `verdict.schema.json` (o `_verdict_ok` do armazém já recusa); e o REPROVADO forçado
  quando o `meta.id` não é conferível.

## Deploy (do maestro, depois do merge)

1. Antes de reiniciar, faça uma cópia de segurança da raiz de dados de produção (ex.: um `tar` dela). Cada
   área já é um repo git.
2. Atualize a worktree de código da unidade (`ONION_KG_CODE_ROOT`) para o novo `origin/main` com
   `checkout --detach` e **reinicie a unidade**. Desde este PR o armazém é importado no boot, e sem reiniciar
   o contrato seguiria o velho (o envelope avisa: `aviso_codigo`).
3. Confira com `curl -s http://172.23.0.1:3037/health`: `tools: 6`. Num `tools/call`, `served_commit` tem de
   ser igual a `store_commit`.
4. Nas áreas existentes, o armazém acrescenta `.kg-store.lock` na raiz e a linha dela em `.git/info/exclude`.
   Não reinicia o repo nem reescreve histórico. Arquivo na área sem commit deixa de existir para as tools.
5. Opcional: o `serverInstructions` do LibreChat pode citar o `kg_delete` e o `expected_sha256`.
