---
branch: fix/provenance-triage-scrub
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: pendente
findings_total: 13
findings_real: 13
findings_blocking: 9
tokens: 0
duration_min: 0
findings_fixed: 13
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: refutador independente do #1649 (três rodadas: 2 bloqueios e 2 correções, depois 1 bloqueio), sobre a passada do próprio executor (8 achados)
nota: "tokens e duração não medidos. Achados 1 a 8: passada do próprio executor, que não é independente. B1, B2, C1 e C2: refutador independente, curados no mesmo PR."
---

# Passada adversarial: `fix/provenance-triage-scrub`

## O que muda

- **provenance-triage:** os 41 arquivos de `docs/evolution/research/contrato-kg-absorcao-2026-10/data/provenance-triage/`
  são limpos:
  - a citação de repositório privado vira o marcador `private-cite:<id>`. O id é o mesmo da tabela privada quando a
    citação (grafo, nó, repo) já estava nela, e um novo, do `kg_trace.py private-cite-id`, quando não estava;
  - o caminho de home vira caminho relativo ao repo quando é o core, o marcador quando é clone de repo privado, e
    `⟨caminho⟩` no resto;
  - o commit de repositório privado vira `⟨commit⟩`.
- **Varredura do resto:** os outros arquivos de dado (csv, tsv, json, jsonl, txt e md sob `data/`) passam pela mesma
  limpeza: são 31 arquivos de pesquisa.
- **Configuração funcional:** `ops/moat-targets.tsv` e `ops/cc-sdk-targets.tsv` ficam de fora, de propósito. Os hooks
  leem esses caminhos, que são os alvos que o veto do MOAT protege, e trocá-los desarmaria a guarda. A exclusão é uma
  lista declarada na guarda.
- **A REGRA 121 (`private-repo-cite-check.sh`)** passa a varrer os arquivos de dado: o tocado, ou todos com `--all`.
  Cada linha é julgada por três códigos:
  - `CAMINHO-DE-MAQUINA-EM-DADO`, para home de conta com segmento, pela classe do `machine_path.py` (a da REGRA 99);
  - `MARCADOR-COM-COMMIT`, a mesma regra dos grafos;
  - `PRIVADO-SEM-MARCADOR-EM-DADO`, só com `--private-repos`.
- **Tabela privada:** os originais estão nela, com arquivo, linha, grafo e nó, e ficam fora do repo.
- **História:** não foi reescrita. **45 commits** da main acrescentam linhas com esses valores aos arquivos limpos, e
  reescrevê-los é decisão do maestro.

## Medido

| | Antes (main) | Depois |
|---|---:|---:|
| Linhas com padrão privado na provenance-triage | 393 | 0 |
| Linhas com caminho de home na provenance-triage | 342 | 0 (sobram 9 com `/home` nu, como conceito) |
| Arquivos de dado fora da provenance-triage com padrão ou home | 31 | 0 |
| A guarda nova com `--all` | 425 HARD | rc 0 |
| Hex nas linhas acrescentadas que resolvem para commit privado | — | 0 |

A resolução do hex é offline (`git cat-file`) e confere 226 hex contra 27 repositórios privados com clone local; os
outros 116 são commits do core alcançáveis de um ref remoto.

## Achados

| # | Triagem | Achado | Cura |
|---|---------|--------|------|
| 1 | (blocking) | o Python em modo texto trocava CRLF por LF, e três CSV saíam com o arquivo inteiro no diff | leitura e escrita com `newline=""`, e o CRLF original restaurado linha a linha |
| 2 | (blocking) | trocar só o nome deixava 1.164 hex soltos que resolvem para commit privado (140 distintos), mais os das outras pastas | todos viraram `⟨commit⟩`, registrados por arquivo e linha |
| 3 | (blocking) | a guarda nova acusou 49 linhas com hex ao lado do marcador que nenhum clone local resolve (repositórios sem clone) | ao lado do marcador de um repo privado, o hex é tratado como commit dele e vira `⟨commit⟩`. A guarda falha fechada |
| 4 | (blocking) | a 1ª regra de home acusava `/home.` no fim de frase e `/home` como conceito | a regra passou a exigir barra e segmento depois da raiz; `./home/` relativo cala pela classe do `machine_path.py` |
| 5 | (non-blocking) | com `--private-repos` apontando para um arquivo dentro da árvore, o próprio arquivo de padrões era julgado | ele fica fora da varredura |
| 6 | (non-blocking) | a 1ª medida pela API esgotou o limite da conta (cerca de 4,7 mil chamadas) | a medida passou a usar clones locais; os 2 repositórios sem clone foram clonados pelo git, sem a API REST |
| 7 | (blocking) | o lint do commit (REGRA 119, nome de repo ou clone de adotante não federado) achou o nome nu de um clone sem registro numa linha da limpeza | o nome virou `⟨clone sem registro⟩`, registrado na tabela privada |
| 8 | (blocking) | a guarda viaja para as portas e citava os dois arquivos de configuração funcional pelo caminho em `ops/` (REGRA 100) | a isenção passou a ser por pasta e nome (`FUNCTIONAL_DIR`, `FUNCTIONAL_NAMES`), sem o caminho literal; o mutante da isenção morreu de novo |
| B1 | (blocking) | sobravam 45 commits privados distintos em `data/`, em qualquer linha, contados contra os clones (38 no methods-manifest.tsv; 4 em arquivos que o PR não tocava, inclusive dois `register.js`) | todo hex de 7 a 40 caracteres de todo arquivo de texto sob `data/` foi classificado offline: commit do core alcançável, do core só por ref de PR, de repo público da lista, de repo privado ou desconhecido. As 116 ocorrências privadas (47 distintos) viraram `⟨commit⟩`, com arquivo e linha na tabela. Recontado do jeito do refutador, sobra 0 privado nos 636 arquivos |
| B2 | (blocking) | a guarda só procurava hex em linha com o marcador; `repo-secreto (HEAD abc1234)` e `commit abc1234` passavam | duas camadas. `COMMIT-PRIVADO-EM-DADO`, com `ONION_PRIVATE_CLONES` (local do dono), pega o hex de qualquer linha que é commit de um clone privado. `HEX-NAO-CONFERIDO-EM-DADO`, sempre ligada e falhando fechada, pega o hex NOVO: o que está numa linha acrescentada e não estava no arquivo da base. Esse hex só passa se for commit do core alcançável, `dono/repo@<hex>` da lista pública ou de dono de terceiro, ou se levar um rótulo de não-commit (md5, sha256, sessão, subagente, uuid). Caso (s2) e 5 mutantes mortos. O escopo passou a ser todo arquivo de texto sob `data/`, e a guarda não julga mais os próprios artefatos (o baseline e a lista pública) |
| C1 | (non-blocking) | commits tidos como públicos tinham virado `⟨commit⟩` | foram devolvidos por alinhamento de tokens com a linha original da tabela e qualificados como `<dono/repo>@<hex>`. Os do core seguem assim; os de um dos repos da lista voltaram a `⟨commit⟩` em D1, porque o repo era privado |
| C2 | (non-blocking) | colchete angular aninhado no `o7-proposta.csv`, que já vinha da main (7 lá) | o par externo saiu nos 6 casos; o `[[...]]` de link de wiki ficou |
| D1 | (blocking) | um repo estava como `public` na lista pública desde 2026-11-10, mas é privado: o HTTP anônimo dá 404. A lista tinha sido conferida pelo `gh` autenticado, que enxerga o privado do dono, e C1 levou 17 commits dele qualificados para o core, mais 4 que já estavam em `data/` | o repo saiu da lista pública e entrou na lista privada local do dono. As 21 ocorrências viraram `⟨commit⟩`, registradas na tabela. O `--verify-allowlist` passou a ser HTTP anônimo, uma requisição por repo, e o lint o roda: 4xx é HARD `LISTA-ERRADA`, rede fora é SOFT não medido, e `ONION_OFFLINE=1` pula avisando. Os outros 13 repos da lista deram 200. A camada de clones passou a ser derivada no lint local, dos irmãos do checkout principal, como a REGRA 119 deriva. Casos (v) e (s3) e 3 mutantes mortos. Recontado: 0 commit privado em `data/` |

## Mutantes

- Case (s), na família `private_repo_cite`, com 48 de 48 passando.
- 4 mutantes, todos mortos: a acusação de caminho desligada, o `.csv` fora do escopo, a isenção da configuração
  funcional removida, e a exigência de segmento removida.

## Limites declarados

- **Fora de `data/`:** a guarda varre os csv, tsv, json, jsonl e txt de todo o repo, e todo arquivo de texto sob
  `data/`. O resto, como `.md` e `.py` fora de `data/`, não é varrido.
- **Configuração funcional:** `ops/moat-targets.tsv` e `ops/cc-sdk-targets.tsv` ficam de fora de propósito, porque são
  os alvos que o veto do MOAT lê.
- **Binários:** `tar.gz`, imagens e PDF não são lidos.
- **Formas de caminho que a guarda não cobre:** `~/`, `$HOME`, e a forma codificada `/tmp/claude-<uid>/-home-<conta>-…`.
  Nesta passada trocaram-se 28 ocorrências desta última, em 5 arquivos, mas a guarda não a acusa.
- **Hex antigo:** o hex que já estava na main e não é commit de nenhum clone alcançável (1.072 ocorrências de
  desconhecidos, quase todos hash e id de sessão) não é julgado sem os clones.
- **Isenções da falha fechada:** um rótulo forjado (escrever `md5` antes de um commit) cala o hex. O `dono/repo@<hex>`
  de um dono que a guarda não julga é tratado como terceiro e cala. O hex que já estava no arquivo na base cala mesmo
  que a linha tenha mudado, e um hex antigo repetido numa linha nova também.
- **Rede:** a conferência anônima da lista pública depende de rede. Fora dela, o lint diz não medido e não julga.
- **Clones derivados:** a camada de clones privados só existe onde há irmãos do checkout (a máquina do dono). No CI ela
  fica vazia, e o passivo antigo só é guardado localmente. O commit de um repo privado sem clone na máquina não é
  visto.
- **Nome nu pré-existente:** o nome do repo que saiu da lista pública segue em arquivos que este PR não toca, como o
  registro da federação, um site do Caddy e resíduos antigos, como nome nu. A REGRA 119 cobre esse caso.
- **Repositórios fora do alcance:** 8 repositórios privados da lista não são alcançáveis nem pela API nem pelo git
  (apagados, renomeados ou sem acesso). Um commit deles que já estava na main não é visto; o hex novo cai na falha fechada.
- **Nome nu:** o nome de repositório sem dono e sem `@` segue, como nos grafos.
- **Edição de evidência:** os arquivos limpos são evidência arquivada de pesquisas (retornos de workflow, vereditos de
  juiz), e o texto deles mudou. A tabela privada guarda cada original.
