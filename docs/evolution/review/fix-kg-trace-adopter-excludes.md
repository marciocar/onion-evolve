---
branch: fix/kg-trace-adopter-excludes
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 0
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/kg-trace-adopter-excludes`

## O que muda

- `.claude/validation/kg-trace.sh` lê o arquivo `<repo_root>/.kg-ssot/trace-excludes.txt`, quando ele existe. O
  arquivo traz um glob por linha, e `#` comenta até o fim da linha. Cada glob vira `--exclude` nas três chamadas
  de `kg_trace.py check`: humano, TSV e índice.
- A família `kg_trace_root_file` ganha o caso (h). Ele cobre três situações:
  - grafo quebrado fora de fixture: reprova (rc 1);
  - arquivo só com comentário: segue reprovando;
  - com o glob: sai do julgamento (rc 0).

## Causa medida

Desde o #1338, a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) é julgada pelo `kg_trace.py`, que
julga todo `.kg.yaml` e `.kg.json` rastreado fora das pastas de fixture. O onion-kg-ssot guarda 8 casos inválidos
de propósito em `docs/onion/measurements/option-b-json-reader/cases/`, e o CI dele os exclui com
`--exclude 'docs/onion/measurements/*'` (`conformance.yml:158`). No `--update` do Onion para o kg-ssot, o
remeasure-hard foi de 0 na integração para 8 no WORK, todos `[trace-resolve/ILEGIVEL]`, e o gate recusou o commit
durável.

## Achados

1. Suspeita descartada: vazio no array de excludes sob `set -u`. A expansão `${_KT_EXCL[@]+"${_KT_EXCL[@]}"}` não
   quebra no bash 4 nem no 5, e a família roda sem o arquivo em todos os casos de (a) a (g).
2. Suspeita descartada: o glob com espaço em volta e o comentário no fim da linha. O caso (h) usa
   `docs/medidas/*   # o dogfood`, e o arquivo é aparado antes de virar argumento.

## Mutantes

- Sem o arquivo, o grafo quebrado reprova (rc 1). Só com comentário, segue rc 1, então o leitor não exclui por
  engano. Com o glob, rc 0.
- Famílias `kg_trace_root_file` e `kg_trace_resolve`: 23 de 23.

## Limites declarados

- O arquivo é do adotante, e o core não o cria nem o escreve. Para o kg-ssot, a linha é
  `docs/onion/measurements/*`, igual à que o CI dele já usa.
