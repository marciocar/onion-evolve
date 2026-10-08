---
title: "O spike do contrato do .kg.yaml mediu o corpus do core: 65 de 138 grafos cumprem a gramática escrita, e parte da diferença é dado a corrigir"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: medium
decision_owner: core (maestro sela)
---

# A gramática está atrás do uso, e dois campos já fazem leitores discordarem

O pedido é para o core **decidir pela lente do Onion**: medir antes de curar, registrar a decisão como
nó, passar pelo Elenxo, preferir mecanismo a conselho e declarar o teto. Este sinal traz a medição e a
separação entre o que é **dado** (o core corrige) e o que é **gramática** (decisão de contrato). A
escolha é do core.

## De onde vem

O primeiro marco do onion-kg-ssot é o contrato formal do `.kg.yaml` (nó `Q_KG_SCHEMA_FORMAL_SPIKE`,
grafo `docs/onion/graph/kg-ssot-product.kg.yaml` deste repo). O spike (PR #6 do onion-kg-ssot,
mergeado) escreveu um JSON Schema 2020-12 que traduz **literalmente** a gramática do core e um leitor
neutro (`tools/kg_validate.py`: Python, PyYAML e jsonschema, sem Claude Code). O leitor lê o core por
`git show`, sem copiar nada.

## O que foi medido no core VIVO (HEAD `4541da12b656`)

Corpus: os 138 `.kg.yaml` fora de `.claude/validation/fixtures/` e de `docs/materials/` (é a mesma
lista do spike em `d31ef4c0da6a`). As fixtures ficam de fora porque são quebradas de propósito.

| Camada | Passam |
|---|---|
| parse (YAML válido, um documento) | 138 / 138 |
| integridade (ids únicos, arestas sem ponta órfã, nenhum nó de grau 0) | 138 / 138 |
| **schema estrito** | **65 / 138** |

**A forma está sã.** O que falha é a gramática estar atrás do uso real. Em `d31ef4c0da6a` eram 66; o
commit `4541da12` acrescentou `meta.drive_checkpoint: sealed` em
`docs/evolution/research/fila-2026-10-06/fila-2026-10-06.kg.yaml`, uma chave que a gramática não tem.
**A diferença cresce a cada commit**, porque nada reprova chave desconhecida.

## Parte 1 — defeitos de DADO (o core pode corrigir já, sem esperar o contrato)

1. **Ids com prefixo de nome de arquivo.** `docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml`
   tem **29 nós** com id `SYNTHESIS.md_*` (ex.: linha 992, `SYNTHESIS.md_REUSE_NOT_INVENTION`). O ponto
   no id parece artefato do gerador da reconciliação (último commit no arquivo: `fe8359e3`). É o
   **único** arquivo que não passa nem com todos os relaxamentos.
2. **`valid_from` como inteiro.** São 6 ocorrências em 4 grafos de pesquisa, todas no formato
   `valid_from: 2026` (ou `2025`) sem aspas, que o YAML lê como **número**, não como data parcial:
   `company-brain-e-conducao-como-servico-2026-10` (linhas 151, 262),
   `motores-de-regras-deterministicos-2026-10` (132), `plugin-directory-landscape-2026-09` (99, 112) e
   `radar-E3-2026-09-04-r4` (59). Provável origem: o `write(KG)` do `onion-research.js` grava o ano sem
   aspas quando a fonte só tem ano.
3. **`meta` legado em 15 grafos:**
   - 6 sem `schema_version`;
   - 9 sem `meta.id`;
   - **7 com `schema_version: 1` (inteiro).** O radar em awk compara texto e aceita igual a `"1"`, mas um
     leitor tipado vê `1 ≠ "1"`. **É a mesma classe do item 4: dois leitores discordam do mesmo byte.**

## Parte 2 — GRAMÁTICA (decisão de contrato, não de dado)

4. **A chave `on:` das arestas `TRANSITIONS` não está na `kg-grammar.md`.** Ela é usada em 5 grafos (7
   chaves, ex.: `colaboracao-onion-2026-07.kg.yaml:384`, `on: EV_RELAY`), e o radar a trata como
   referência (`kg-radar.sh:323` e `:448`, "on: conecta o evento"). **O dano medido foi semântico:** um
   leitor YAML 1.1 (PyYAML padrão, e com ele o extrator do onion-slm se usar o mesmo default) lê `on:`
   como o booleano `True`. Aí o evento referenciado parece órfão, e esse leitor acusava 3 nós órfãos em
   2 grafos que o radar aprova. Com os booleanos do YAML 1.2 os dois concordam. É a **única** diferença
   entre 1.1 e 1.2 no corpus. **O perfil de YAML é parte da gramática, não detalhe.**
5. **Chaves de extensão sem lugar na gramática.** Em `meta` e no topo: `note` (21 arquivos),
   `supersedes_none`, `title`, `supersedes_external`, `drive_checkpoint`... Nos nós: `drive_kind`,
   `owner`, `evidence_class`, `sealed_by`/`sealed_at`. No spike (`d31ef4c0da6a`), relaxar só essas duas
   famílias levou o corpus de 66 para 111.
6. **PROD sem `verified_at`:** 70 nós em 22 arquivos. A gramática pede, e o radar só **avisa**
   (`⚠ STALE-MISSING`, `kg-radar.sh:924`) sem reprovar. O contrato precisa dizer qual dos dois vale:
   MUST ou SHOULD.

## O que o onion-kg-ssot pede

- **Parte 1:** que o core corrija o dado (itens 1 a 3) e, onde houver gerador (reconciliação,
  `write(KG)` da pesquisa), **a causa no gerador**, não só os arquivos. Os itens 1 e 2 parecem ter
  origem em gerador.
- **Parte 2:** **não decidir sozinho, e não decidir já.** O contrato que vai fixar isso está sendo
  desenhado aqui. As decisões estão abertas para o maestro no grafo do produto:
  `Q_CONTRACT_EXTENSION_POLICY` (itens 5 e 6) e `Q_CONTRACT_CONFORMANCE_LEVELS` (perfil YAML 1.2 e
  MUST × SHOULD). O que o core pode fazer agora sem antecipar o contrato é **documentar `on:` na
  `kg-grammar.md`**, porque o radar já a usa.
- **Mecanismo candidato (para o core medir, não para adotar às cegas):** uma família de bancada que
  rode um leitor tipado sobre o corpus vivo e reprove regressão do número de grafos que cumprem a
  gramática. O caso `drive_checkpoint` mostra que, sem catraca, o número só cai.

## Reproduzir

```bash
cd onion-kg-ssot
git -C <core> ls-tree -r --name-only HEAD | grep '\.kg\.yaml$' \
  | grep -v -e '^\.claude/validation/fixtures/' -e '^docs/materials/' > /tmp/corpus.txt
python3 -I tools/kg_validate.py --schema spec/kg-strict.schema.json \
  --git <core> --rev HEAD --list /tmp/corpus.txt
```

## Teto declarado

- O schema estrito é a **régua** do spike, não o contrato. Uma chave "desconhecida" é desconhecida para
  a gramática **escrita**, e não necessariamente um erro.
- A origem nos geradores (itens 1 e 2) é **inferência** pelo padrão do dado; os geradores não foram
  lidos.
- O extrator do onion-slm não foi medido. A frase sobre ele é condicional.
