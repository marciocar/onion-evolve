---
branch: fix/provenance-triage-scrub
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 8
findings_blocking: 6
tokens: 0
duration_min: 0
findings_fixed: 8
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: passada adversarial do próprio agente executor, sem subagente (o brief proíbe spawnar), contra a guarda nova e a medida por clones
nota: "tokens e duração não medidos. A passada não é independente: cada achado saiu de uma medida (guarda, resolução de hex, diff) e não de um segundo leitor."
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

## Mutantes

- Case (s), na família `private_repo_cite`, com 48 de 48 passando.
- 4 mutantes, todos mortos: a acusação de caminho desligada, o `.csv` fora do escopo, a isenção da configuração
  funcional removida, e a exigência de segmento removida.

## Limites declarados

- **Repositórios fora do alcance:** 8 repositórios privados da lista não são alcançáveis nem pela API nem pelo git
  (apagados, renomeados ou sem acesso). Um commit deles que não esteja ao lado de um marcador não é visto.
- **Nome nu:** o nome de repositório sem dono e sem `@` segue, como nos grafos.
- **Edição de evidência:** os arquivos limpos são evidência arquivada de pesquisas (retornos de workflow, vereditos de
  juiz), e o texto deles mudou. A tabela privada guarda cada original.
- **Arquivos fora do escopo de dado:** `.py` e `.md` fora de `data/` não são varridos pela guarda.
