---
branch: feat/kg-ssot-v4.5.0-writer-json
date: 2026-10-13
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_fixed: 3
tokens: 0
duration_min: 90
verdict: APROVADO
reviewer: passada adversarial própria (refutador com default reprovado, sem subagente) — gate mecânico: kg_vendor check, kg_gate do CI, famílias mcp_onion_kg_writer e decide com LC_ALL=C e mutantes
---

# kg-ssot-v4.6.0, o writer lê o veredito em JSON e o selador cobra o TETO

## O que muda

- **Vendor**: de `kg-ssot-v4.4.0` para `kg-ssot-v4.6.0` (b819a4422ad1, 312 arquivos), passando pela
  4.5.0 no mesmo PR (a branch guarda o nome da 4.5.0). A 4.5.0 deu ao `kg_validate.py` o `--format json`
  (o veredito `kg-ssot.verdict/1`, com schema em `spec/verdict.schema.json`) e a leitura do grafo pelo
  stdin. A 4.6.0 deixa o veredito mais rápido e traz o `tools/kg_store.py` (GitStore), que este PR ainda
  não usa. No `--format json`, a 4.6.0 dá `results` iguais aos da 4.5.0 nos 447 grafos, e o
  `verdict.schema.json` tem o mesmo sha256. O sha256 dos schemas MUST e SHOULD e do `kg_gate.py` não mudou. A saída de texto e a
  do `--where` do `kg_validate.py` novo são byte a byte iguais às do leitor da 4.4.0 nos 447 `.kg.yaml`
  rastreados. O `kg_gate` com os `--exclude` do CI dá rc 0 e a saída é byte a byte igual à do main
  (155 grafos, 138 no MUST, 17 na dívida herdada).
- **Writer** (`ops/mcp-onion-kg-writer/server.py`): o contrato roda como `kg_validate.py --format json
  --limit 50 -`, com os bytes pelo stdin. O relatório é conferido contra o `verdict.schema.json` antes de
  ser crido. O gate decide por `verdict` e `code`, nunca por `message`/`hint`. Viram `NAO JULGADO`, e
  nada é gravado: rc 2, JSON malformado, relatório fora do schema, versão diferente de `/1`, mais de um
  resultado, rc incoerente com o veredito e `external_checked: false`. As respostas trazem as ocorrências
  estruturadas, fundidas em level+code+path com `vezes`. O radar segue no gate. O servidor não sobe sem
  jsonschema ou sem o `verdict.schema.json`.
- **Selador** (`kg-decide-seal.sh`): a escrita vai primeiro para um stage. No escopo da REGRA 58 (O
  backlog cumpre as promessas do próprio `meta:`), que é o marcador `kg-backlog-guard`, o `--new` passa
  o grafo como ficaria pelo próprio `kg-backlog-check.sh`. A tag TETO ou SEM-TETO dá rc 2 e nada escrito,
  com uma mensagem que nomeia o teto e sugere subir com motivo ou reconciliar.

## Achados

1. **O gate antigo do writer gravava grafo com `external_edges` para alvo inexistente.** O modo texto
   sem `--corpus` sai rc 0 e o writer só olhava o rc. Medido com o contrato real:
   `to: "docs/x/y.kg.yaml#C_VELHA"` dá PASS com `external_checked: false`. Curado: agora é NAO JULGADO
   (caso `contrato-externo-real-nao-julgado`), e o `kg_schema_help` diz que este servidor não aceita
   `external_edges`.
2. **O selador criava nó além do teto.** Dogfood no vivo, `contrato-kg-absorcao-2026-10` em 27/27: o
   selador do main selou o 28º nó com rc 0. O curado recusou com rc 2 e o sha256 do arquivo ficou igual.
3. **O schema acusa o mesmo campo duas vezes** (`form.pattern.meta.baseline` ×2, em 4 fixtures do vendor).
   Curado na resposta por fusão com `vezes`.
4. **Não curado, teto declarado**: stdin e arquivo não se distinguem por caso. O radar ainda grava a
   cópia temporária, e o contrato daria o mesmo veredito lendo-a. Fora do escopo da REGRA 58 (grafo com
   TETO num comentário e sem o marcador), o selador não cobra teto, de propósito.

## Conferido

- `mcp_onion_kg_writer`: 39 casos por HTTP (eram 28) e 35 mutantes (eram 25). Os 10 novos são: aceitar
  rc 2, aceitar JSON malformado, ignorar o schema, ignorar a versão, ignorar a incoerência, ignorar a
  ponta externa, decidir por `message`, não fundir duplicata, não devolver as ocorrências e não devolver
  os códigos.
- `decide` (s15) com polaridades: no teto recusa, sem TETO recusa, teto+1 sela, sem o marcador sela e nó
  existente no teto sela. Cinco mutantes rodaram por `ops/mutate-and-restore.sh`, todos morderam, e o
  arquivo foi restaurado byte a byte: sem a checagem, decidir pela mensagem, sem SEM-TETO, escopo
  ignorado e escrever antes do teto.

## O que muda ao trocar o armazenamento do writer pelo GitStore (PR seguinte, não este)

- O GitStore só enxerga o que está rastreado. Hoje o `kg_my_list` lista o diretório da área.
- `StoreError` significa não gravado, e tem de virar recusa nomeada, nunca `gravado: true`.
- Texto igual ao do HEAD devolve `unchanged` sem commit. Hoje é o `mudou: false` do `git status`, e o
  caso `reescrita-identica-sem-commit-novo` passa a cobrar o `unchanged`.
- `init=True` por usuário, ou seja, um repo por área, como o `_ensure_repo` faz hoje.
- Regravar um nome julga também os grafos que apontam para ele. Numa área com `external_edges` entre os
  próprios grafos, isso muda o que conta como `external_checked`, e o NAO JULGADO de hoje tem de ser
  revisto.

## Deploy (do maestro, depois do merge)

A unit publicada roda o servidor a partir da worktree de código `core-writer`. Basta atualizá-la para o
novo `origin/main` e reiniciar a unit. Medido em 2026-10-13: a unit `onion-vps-mcp-kg-writer` roda
`/usr/bin/python3`, e esse Python tem jsonschema 4.10.3 (que tem o Draft202012Validator) e PyYAML. Sem jsonschema, ou sem o `verdict.schema.json` no code root, o servidor recusa subir.
