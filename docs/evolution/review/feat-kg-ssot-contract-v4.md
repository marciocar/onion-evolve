---
title: 'Resíduo — adoção do contrato v4 e extensões com x_ (SAC-79)'
date: 2026-10-08
branch: feat/kg-ssot-contract-v4
reviewed_diff_sha256: 1bc6ff45505584a18b9bc717564b4cf603228508ea325cb0e30dbb3b16d8e2bd
reviewed_code_sha256: a5aca5a3f7543d1a2e7558215089fcb2c46df711f0a97dc351a666115bbe5f32
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A passada é do autor, que roda cada leitor e escritor tocado e prova o mutante de cada caso novo.
  O contrato é vendorizado por pin, então o juízo dele é do adotante dedicado (onion-kg-ssot), que
  testou a tag num adotante descartável. Aqui se prova a integração: vendor íntegro, gate rc 0 com a
  base nova, e os geradores que escreveriam chave reprovada no v4.
---

# O que o v4 mudou e o que precisou mudar aqui

O v4 (tag `contract-v4.0.0`, commit 93f61ac) torna MUST:
- a provenance em nó confirmed ou PROD, com `unverifiable` isento em qualquer plano;
- a recusa de placeholder em `provenance.source`;
- a recusa de chave desconhecida sem `x_`.

Medido no corpus, apareceram três classes de escritor que fariam todo grafo NOVO reprovar no gate:

| Escritor | Chave | Cura |
|---|---|---|
| `kg-drive-project.sh --close-lot/--seal` | `drive_checkpoint(_note)` | escreve `x_`; lê as duas formas (grafo herdado) |
| `/meta:dissect` (prosa) e `dissect-census.sh` | `dissect_tool/level/verdict` | prosa ensina `x_`; o censo lê as duas formas |
| `/meta:radar` (prosa) | `supersedes_none/external` | prosa ensina `x_`; a REGRA 89 já aceitava as duas formas desde o #979 |

Também mudaram:
- **Leitor:** `kg-seal-exception.sh` lê o checkpoint nas duas formas.
- **Migrador:** `kg-migrate-v3.py` passa a emitir `method: "derivado: …"`, a forma canônica `<classe>: <detalhe>` (SHOULD no v4, MUST no v5).
- **Dados do corpus:** as 15 ocorrências dos arquivos rastreados foram migradas para `x_`, o que diminuiu a dívida.
- **Escopo:**
  - o `cafe-aroma-demo` foi para `docs/onion/graph/fixtures/`;
  - `kg-inbox/_rejected`, `kg-inbox/_sealed` e os grafos proto do Onion pessoal saem por `--exclude`, explícito no comando do CI.
- **Base:** `.kg-ssot/gate.json` foi regravada com `--accept-regression` e motivo, com os mesmos `--exclude` do CI. São 138 grafos, 7 passam no MUST e 131 ficam na dívida herdada, que queima pelas ondas do SAC-73.

# Achados (reais, curados)

1. **Backreference deslocada no `dissect-census.sh`.** O grupo `\(x_\)` novo empurrou a captura para `\2`. Com `\1`, o censo devolvia `x_` como nome da ferramenta e nível 0. Foi pego na releitura do sed, antes de rodar. O caso (x) prova a cura, e o mutante `\1` reprova (a), (c1), (c2), (x), (c3) e (h).
2. **Escrita do checkpoint sem `x_` faria todo lote fechado reprovar no v4.** O caso novo da família `drive` exige `x_drive_checkpoint(_note)` e a ausência da forma antiga. O mutante (escritor sem `x_`) reprova.
3. **O migrador emitia method fora da forma canônica.** O caso (b) da família `kg_migrate_v3` passou a exigir `derivado: \S`, e o mutante com a string antiga reprova.

4. **Seis geradores emitiam `method` fora da forma canônica.** No v4, `form.pattern.node.provenance.method`
   é SHOULD, e o `kg-contract-check` reprova grafo novo com SHOULD. A bancada inteira pegou quatro famílias:
   `kg_contract_check` (a), `cc_delta_census` (e), `census_seal` (v3) e `seed_graph` (v3). Curados:
   - `census-seal.py` passa a emitir `juízes: …`;
   - `seed-adoption-graph.sh` emite `leitura: …`, `medição: …` e `derivado: …`;
   - `cc-delta-census.sh` emite `medição: …`;
   - o prompt do `write(KG)` do `onion-research.js` ensina a forma.

   O mutante de volta à forma livre reprova `seed-graph (v3)`.

# Fora deste PR (pré-existente, medido também na main)

- `cited-directive: (f) DERIVA` reprova na bancada LOCAL: o Claude Code 2.1.295 mudou o parser de
  diretivas, e a cópia das regex é da 2.1.290. O CI não tem o binário, por isso não vê. Registrado como
  SAC-84, que também cobra o `/meta:cc-update` por não ter medido essa superfície.

# Tetos

- Os leitores aceitam a forma antiga de propósito, porque o grafo herdado continua na base. Nada impede um humano de escrever à mão a forma sem prefixo num grafo novo: quem barra isso é o gate do CI (MUST), não o escritor.
- O `cafe-aroma-demo` saiu do `docs/backlog.md`, que é projeção, e o `Q_excecao_enterprise` dele deixa de aparecer. É fictício, então é o efeito pretendido.
