---
title: 'Resíduo — kg-radar alinhado ao contrato v4.1: testemunho em PROD e decisão com provenance (SAC-96)'
date: 2026-10-09
branch: fix/radar-contract-alignment
reviewed_diff_sha256: 2c671301e2e89745d09007cf44d36eb30151c8fa71977a044981593c39649b16
reviewed_code_sha256: d7cfefae3dda04849bd697c77c8276cdd19ca341b7cefcdb35e415f9d8f49eba
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 45
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  A passada é do autor. O juízo do comportamento esperado é do dono do contrato, pelas fixtures da matriz
  latest/integrity/coherence do vendor kg-ssot; aqui se prova que o radar as segue, que nenhum grafo do
  corpus passa a reprovar e que a mudança de avisos bate, nó a nó, com uma contagem independente em PyYAML.
---

# O que mudou

O `kg-radar.sh` divergia do contrato v4.1 em dois avisos SHOULD.

1. **`integrity.testimony-in-prod`.** O `MISPLANED` lia só `evidence_class: testimony`. Agora lê também o
   bloco `provenance` e avisa quando o nó é `plane: PROD` e o `method` começa com `testemunho:`. A
   severidade é a mesma (aviso do FRESCOR, não reprova). Um nó com os dois marcadores gera um aviso só.
2. **`integrity.untraced-decision`.** A decisão viva com `provenance.source` não vazio passa a contar como
   tendo origem, ao lado de `trace:` e da aresta `TRACES_TO`.

A leitura do bloco é **posicional**. Ele abre com `provenance:` sem valor, na coluna dos campos do nó, e
só vale a chave que está na coluna do 1º filho. Um `method:` ou `source:` em outro mapa aninhado (um `x_`,
por exemplo) não conta. O caso (g) da bancada prova isso. O limite fica declarado: o radar não lê a forma
de fluxo (`provenance: {…}`) nem `method: >-`. No corpus, os dois aparecem ZERO vezes em nó.

# Medição no corpus (146 grafos, `git ls-files '*.kg.yaml' | grep -v /fixtures/`, `LC_ALL=C`)

| Aviso | Antes | Depois |
|---|---:|---:|
| `MISPLANED` | 45 | 147 (+102 em 35 grafos, nenhum removido) |
| `decisão-sem-proveniência` | 64 | 38 (−26 em 11 grafos, nenhum novo) |
| `--integrity --schema` com rc ≠ 0 | 0 | 0 |

Conferência independente em PyYAML:

- **Testemunho em PROD.** São 102 nós PROD vivos com `method` testemunho, mais 19 reconciliados, que o
  FRESCOR não cobra. A adoção do v4.1 mediu 125, antes das ondas 2 e 3 da O3.
- **Decisões.** As 26 que saíram são exatamente as decisões vivas com `provenance` e sem `trace` nem
  `TRACES_TO`: o conjunto bate, não só o número. A adoção do v4.1 mediu 9 em 4 grafos. A diferença vem
  das ondas 2 e 3, que escreveram `provenance` depois.

# Consumidores

Nenhum consumidor lê o texto desses dois avisos:

- `kg-realign-project`, `kg-drive-project`, `kg-backlog-project` e `kg-census-parity` leem os TSV
  (`--freshness-tsv`, `--open-tsv`, `--status-tsv`, `--triples`) e o rc de `--integrity --schema`.
- O `kg-view` confere paridade por `--weights-tsv` e pela linha de integridade.

Nada disso mudou. Nenhuma catraca SOFT conta esses avisos, então não há baseline a tratar.

**Fio aberto, fora deste PR:** o veredito do `--freshness-tsv` segue tratando como `TESTIMONY` só o
`evidence_class`. Um nó com `method` testemunho ainda entra na fila de re-verificação como medido.
Mudar isso mexe na fila de `/meta:kg-freshness` e do realign, e pede decisão própria.

# Bancada

A família nova `kg_radar_contract` roda o radar sobre as fixtures do vendor:

- (a) o `warn-testimony-method-in-prod` avisa;
- (b) o `warn-testimony-class-in-prod` avisa uma vez só;
- (c) o `valid-testimony-in-dev` cala;
- (d) o `valid-decision-with-provenance` cala;
- (e) o `warn-untraced-decision` segue cobrado;
- (f) as fixtures passam em `--integrity --schema`;
- (g) a leitura é posicional.

Há um mutante por cura: (h) desliga a leitura do `method` e o caso (a) cala; (i) tira a `provenance` como
origem e o caso (d) volta a cobrar. Os dois reprovam como esperado. Com as famílias `kg_freshness` e
`kg_provenance`, deu 38/38 com `LC_ALL=C`. Sem o vendor, a família pula com ⊘ visível.
