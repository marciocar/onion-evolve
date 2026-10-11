---
title: 'Resíduo — eol=lf no .gitattributes sem mudar um byte rastreado'
date: 2026-10-11
branch: chore/gitattributes-eol-lf
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 0
tokens: 120000
duration_min: 40
verdict: APROVADO_COM_RESSALVA
elenxo: nao
nota: >-
  Passada adversarial curta, com o refutador começando de reprovado: procurar arquivo rastreado que
  mude de bytes ou binário marcado como texto. Nenhum dos dois apareceu. Os dois achados reais são de
  escopo: os CSVs que ficam fora e o .gitattributes que não viaja às portas. Sem Elenxo porque a
  mudança é declarativa e a verificação foi direta: renormalize, checkout simulado e mutantes.
---

# eol=lf fixado, medido antes e depois

## A medição

- **Antes:** `git ls-files --eol` dava 2790 `i/lf`, 13 `i/crlf`, 6 `i/none` e 3 `-text`. Os 13 CRLF
  são todos `.csv` de `contrato-kg-absorcao-2026-10/data/provenance-triage/`. Um `checkout-index` com
  `core.autocrlf=true` (o checkout do Windows) saía com CRLF em **209/209 `.sh`**, nos 2 hooks sem
  extensão de `.githooks/` e em 2438 arquivos md/yaml/json/py/js/mjs.
- **Depois:** `git add --renormalize .` mudou **zero bytes rastreados** além do próprio
  `.gitattributes`. O mesmo checkout sai com **0 CRLF** nesses tipos, e o woff2 sai idêntico byte a
  byte.

## Refutador: arquivo que muda de bytes, binário marcado como texto

- **Arquivo que muda de bytes:** o renormalize pôs no índice só o `.gitattributes`. O único
  conjunto com CRLF rastreado (os 13 CSVs) ficou de fora do atributo de propósito.
- **Binário como texto:** depois da mudança, `git ls-files --eol` mostra os 3 binários do repo
  (2 woff2 e 1 jpg) com `attr/-text`. Nenhuma das extensões declaradas como texto aparece como
  `i/-text`.

## Achado 1 (ressalva aberta): os CSVs ficam fora

Os 13 CSVs já CRLF continuam sem atributo, e os 2 CSVs LF ganham CRLF num checkout Windows. Nenhum
script do hook os executa. Normalizá-los mudaria 13 arquivos de dados de pesquisa, por isso a decisão
fica com o maestro e não entra nesta mudança.

## Achado 2 (recomendação): o .gitattributes não viaja

O `vendor-manifest.sh` cobre só `.claude/` e `docs/` nos papéis source e standalone, e a raiz da porta
(`ops/materialize-door.sh`, passo 5) leva README, CLAUDE.md, LICENSE e LICENSE-DOCS. Quem clona uma
porta no Windows continua recebendo os `.sh` com CRLF. A cura recomendada é a porta levar um
`.gitattributes` mínimo na raiz. Fica registrada aqui e não foi forçada.

## Guarda

A família `gitattributes_eol` (core-only, 5 casos) lê o atributo resolvido com `git check-attr`. Os
5 mutantes plantados por `ops/mutate-and-restore.sh` morreram: `*.sh` sem eol, `.githooks/*` sem
atributo, `merge=union` removido, woff2 sem `binary` e `*.csv` declarado `eol=lf`, este último
pego pelo caso de dívida no índice.
