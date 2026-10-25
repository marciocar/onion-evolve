---
branch: fix/door-empty-read-index
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: 6216f662ddbe1436a6a0efcc3d8e4d7b2e8590da7c5aafec988a7505d5461f6c
reviewed_code_sha256: 823770192299cefeb679f44efa346f800e1128038a33916a0d5e75266897cd88
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/door-empty-read-index`

## O que muda

- `ops/materialize-door.sh`: a conferência final das 5 projeções SSOT aceita o `docs/onion/kg-read-index.tsv`
  vazio só quando o produto o declara, ou seja, quando `kg-trace.sh <porta> --emit-index` sai rc 3 (nenhum nó com
  trace de arquivo). Vazio sem a declaração (rc 2: vendor ausente ou ilegível) segue abortando com rc 3.
- `.claude/validation/lint-selftest.sh`, família `door`, caso (f): a mesma regra na contagem das projeções do
  papel standalone.

## Causa medida

Desde o #1340 o índice de leitura nasce do `resolved_targets` do `kg_trace.py` (kg-ssot 4.25.1), que exclui
fixtures e vendor por padrão. A porta não leva a biografia do core: dos 447 grafos materializados, 446 são
fixtures e 1 é exemplo do vendor, então o índice sai vazio com rc 3. O `[ -s ]` da conferência tratava isso
como projeção ausente e abortava a porta. Na main (cf744d98) a família `door` reprovava em (c), (e) e (f), e
o `/meta:publish` de qualquer porta com lint abortaria. O CI não pegou porque a faixa dele não selecionou a
família `door` nos PRs do índice; quem pegou foi a bancada local do #1341.

## Achados

1. REAL, corrigido: o caso (f) da bancada repetia o `[ -s ]` e seguia reprovando depois da cura do script.
2. NÃO É DEFEITO: a conferência chama o `kg-trace.sh` da porta. Num papel que não o levasse, o rc seria 127 e
   a porta abortaria (fail-closed), que é o comportamento certo.

## Mutantes

- `ONION_KG_TRACE=/nonexistent/kg_trace.py bash ops/materialize-door.sh <dest>`: o gerador sai rc 2, o índice
  fica vazio sem declaração e a porta aborta com "a porta ficaria SEM projeção SSOT: docs/onion/kg-read-index.tsv"
  (rc 3). A cura não abre o vazio sem declaração.
- Família `door` antes da cura: 10/13 (falham c, e, f); depois: 13/13.

## Limites declarados

- A REGRA 84 (Índice de leitura do KG em sincronia com os traces) no lint da porta segue dizendo
  CORPUS-SEM-TRACE-DE-ARQUIVO (SOFT): é o estado real da porta, não muda aqui.
