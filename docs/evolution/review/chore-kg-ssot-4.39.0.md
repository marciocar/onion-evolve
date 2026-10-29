---
branch: chore/kg-ssot-4.39.0
pr: pendente
date: 2026-10-29
reviewed_diff_sha256: a75385f99c4081a40e0b2232f890cd7aeb9b7b215053e54a33f500709d9ee8e1
reviewed_code_sha256: 7c96ebc1f8213c360bc0cf9af7118852176dfa8facf9059f012df719876d5473
findings_total: 1
findings_real: 0
tokens: 61676
duration_min: 3
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: revisor novo só-leitura (code-reviewer), sem o contexto da sessão
nota: "tokens do revisor medidos pelo harness (61676). O único achado é uma observação fora do escopo e não é defeito do PR."
---

# Passada adversarial: `chore/kg-ssot-4.39.0`

## O que muda

- `vendor/kg-ssot` 4.38.0 → 4.39.0, com o contrato v4.18 inalterado. O gate deu o mesmo resultado antes e depois (204 grafos, 202 passam no MUST, as 2 dívidas herdadas, SHOULD idêntico) e não houve aviso de identidade.
- O `/meta:backlog` ganha o passo «A minha fila» (`kg_query --open --where owner=<dono> --sort attention`).
- O `Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA` passa a trazer a medida da bancada 4.39 sobre os três buracos.
- O `meta:` do `radar-E3-2026-09-21-r5` recupera o `# kg-backlog-guard: on` e o `TETO: 15 NOS`, e o `docs/backlog.md` foi regenerado.

## Achados

O revisor conferiu sete pontos e não achou defeito real em nenhum deles:

- a coerência do `.kg-ssot-version` com o `release.json` e o `sha256` do `kg_query.py`;
- o comando da fila, que sai com rc 0 e, com um dono inexistente, devolve 0 nós sem erro;
- os donos listados;
- a renumeração dos passos (nenhuma referência ao 4 ou ao 5);
- o label, com 161 caracteres, e a sustentação dele na narrative;
- o teto 15 contra os 15 nós e o padrão do awk;
- o `--check` da projeção, em dia, e a ausência de caminho de máquina.

1. **Observação fora do escopo, não curada:** 13 dos 15 labels do r5 passam de 280 caracteres (de 281 a 955). Com o marcador religado, o `D_E3_R5_O_QUE_FICA_PARA_O_MAESTRO` aparece truncado no backlog. A dívida é anterior ao PR, cabe numa limpeza à parte, e o contrato a trata como SHOULD herdado sem piora.

## Mutantes

- O teto foi conferido pelo próprio `kg-backlog-check.sh`, que deu `OK BACKLOG 15/15`. Sem a linha de TETO, o marcador cairia em `SEM-TETO` HARD; é por isso que as duas linhas voltaram juntas.
