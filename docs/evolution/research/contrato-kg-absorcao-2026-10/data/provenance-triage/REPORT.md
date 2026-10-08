# Triagem da dívida de provenance do corpus — 2026-10-08

Projeção do nó `E_TRIAGEM_DA_PROVENANCE_DO_CORPUS` (grafo `contrato-kg-absorcao-2026-10`). O fato
mora no grafo; aqui fica o critério, os números e os tetos para quem for executar as ondas.

## Universo

3.794 nós em 139 grafos (de 145 rastreados; sem `fixtures/`, `docs/materials/`, `vendor/`). Duas
medições independentes batem: `kg-migrate-v3 --check` (2.539 deriváveis + 1.255 sem fonte) e
`kg_gate.measure_texts` do vendor (`form.required.node.provenance` nos mesmos 139 grafos).

**"Derivável" ≠ "correto"**, nos dois sentidos: 634 dos "sem fonte" têm fonte no `trace` (a
ferramenta exige `verified_against` como locator); ~250 "deriváveis" citam o próprio grafo, um
arquivo que não sustenta o label ou um caminho que sumiu.

## Classes (classificador v3, `classify.py`, determinístico, importa o `kg-migrate-v3`)

| Classe | Critério | Nós | Concordância (rodada 2, amostra nova) |
|---|---|---|---|
| **A1 aceitar** | a fonte existe e o registro mostra que foi ela a lida (URL/caminho no `verified_against`, `gh: PR #N`, citação verbatim) | 1.442 | 70/71 (98,6%) |
| **A2 aceitar com ressalva** | a fonte vem do `trace`, existe, é o artefato de que o nó fala (não necessariamente o lido) | 1.546 | 73/77 (94,8%) |
| C corrigir (dica) | fonte existe mas errada/mal escrita | 375 | 16/22 (73%) → resíduo |
| T testemunho (dica) | pessoa nomeada, sinal de adotante, grafo pessoal | 34 | 6/10 (60%) → resíduo |
| U rebaixar (dica) | sem trace nem va, ou va em prosa | 312 | 9/16 (56%) → resíduo |
| R resíduo | medição de sessão sem artefato, localizador não registrado | 85 | 9/11 (82%) |

Regra de corte: classe com concordância < 90% não decide — vira resíduo (806), e a subclasse
serve só de **dica** para a onda O3.

Classe de `method` proposta (`"<classe>: <detalhe>"`): leitura 1.062 · derivado 1.161 · juízes 624 ·
medição 504 · testemunho 134 · sem classe 309.

## Políticas seladas (maestro, 2026-10-08, sobre a posição do onion-kg-ssot)

Ver o nó `D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE`.

## Ondas (depois da tag contract-v4.0.0, re-medindo)

| Onda | O quê | Nós |
|---|---|---|
| O0 | `kg-migrate-v3` emite `method: "<classe>: <detalhe>"` a partir de `routing.tsv` e pula ids fora de A1/A2 (SAC-79) | — |
| O1 | A1 + A2 deriváveis, um PR por grafo | 2.354 |
| O2 | trace válido sem `verified_against` vira locator (`derivado: trace do nó, sem registro de medição`) | 634 |
| O3 | resíduo: worker propõe pela dica, juiz refuta, aplicação determinística; **todo flip de status é selo do maestro** | 806 |

Pré-requisito: a guarda rebase→provenance (SAC-80) antes da O1.

## Tetos

1. Juiz único e não independente (o autor do classificador julgou a amostra): concordância provavelmente superestimada.
2. Curas medidas na rodada 2 não aplicadas: acento, expansão de chaves, afirmação de ausência, duplicatas de `plugins/`.
3. Vivacidade de URL medida só na amostra (~100 URLs).
4. Suporte do label é métrica lexical.
5. Classe de `method` é heurística por regex.
6. Caminhos `/home/onion/…` ilegíveis por esta conta: `exists=False` ali é permissão, não ausência.
7. Medido contra o contrato v3 vigente: com o v4, os PROD `unverifiable` deixam de contar como dívida.

## Arquivos

- `routing.tsv`: por nó — grafo, id, status, plano, classe, subclasse, destino final, classe de method, se a ferramenta deriva.
- `per-graph.json`: contagens por grafo.
- `classify.py`, `measure.py`, `sample.py`, `sample2.py`: o classificador e a amostragem (caminhos de entrada eram `/tmp/prov-triage/`).
