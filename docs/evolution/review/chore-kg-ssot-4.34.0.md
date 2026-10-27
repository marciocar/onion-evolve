---
branch: chore/kg-ssot-4.34.0
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 25
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "subagente de adoção (claude-opus-5-5), passada própria sobre o diff inteiro"
nota: "tokens não medidos; a passada mediu os consumidores do kg_query.py no core, os dois selos reais e o caso novo da bancada com o mutante"
---

# Passada adversarial: `chore/kg-ssot-4.34.0`

## O que muda

A adoção da kg-ssot 4.34.0 (contrato v4.16 sem mudança). Só muda o `kg_query --chain`, que passa a seguir o acordo
de transmissão: a cadeia segue primeiro o `provenance.source`; um source sem fragmento de grafo faz do nó a origem; a
TRACES_TO de um nó que tem provenance sai em `edges_not_followed`. Em `spec/` só muda o `release.json`, e o vendor
segue com 658 arquivos. Entram o nó de adoção `E_KG_SSOT_434_ADOTADA_1027` em `sinais-de-campo-2026-09`, o índice de
leitura regenerado, e um caso novo na família `decide` da bancada: o selo do maestro é a origem da própria cadeia.

## Achados

1. **A opção pedida no brief não existe** (real, corrigido): o pedido dizia `--chain <id> --json`. O `--help` do
   `kg_query.py` não tem `--json`; a saída de máquina é `--format json`. O caso usa `--format json`.
2. **O caso novo reprovava com rc 2 no sandbox** (real, corrigido): o grafo da bancada não estava commitado. Li o
   `kg_query.py`: com `--root` num repo git, o corpus é o `git ls-files` (`*.kg.yaml`), e o grafo não rastreado não
   existe para ele, então o id dá BROKEN INPUT. Fora de repo git a mesma chamada saiu rc 0. O caso passou a commitar
   o grafo antes do selo, o que também faz o lint de nomes do selador rodar, como em produção.

Conferido e sem defeito:

- **O diff do `kg_query.py`** só toca o código do `--chain` (`_source_ref`, `_steps`, `_link`, `_grade`, `chain`,
  `chain_human`). `--around` e o resto ficam iguais, e os leitores do core (`kg-trace.sh`, `peer-ref-check.sh`,
  `dissect-object-check.py`) leem o rc e outros modos, não o `--chain`.
- **A tag contra a bancada**: a ref `a0589dacd22a` da bancada pré-tag difere da tag só no teste, no manual, no
  `llms-full.txt` e no grafo do produto. O `kg_query.py` é o mesmo, e a saída humana do `--chain` nos dois selos
  reais é igual à da bancada (a bancada só tinha a linha `rc=0` a mais).
- **Os dois selos reais**: `D_A2A_PECA_RASCUNHO_CONSTRUIR_1027` e `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027` saem com um
  caminho completo, a origem no próprio selo, method `testimony`, e a pergunta respondida em `edges_not_followed`.
- **A identidade do contrato** não mudou: `ops/kg-gate-ci.sh --strict-identity` rc 0, sem a linha de identidade,
  então o `--update` não foi rodado. O gate saiu igual antes e depois (195 grafos, 193 passam o MUST, 2 da dívida).
- REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele): conferi os `confirmed` de maior impacto do
  grafo editado (`E_RADAR_IGNORAVA_O_SEGUNDO_MODO`, `C_O_CAMPO_ACHA_DECLARADO_MAIOR_QUE_MEDIDO`,
  `E_CENSO_EM_VOO_LE_NOME_DE_BRANCH`, `E_SPIKE_SOBREVIVENCIA_PREMIA_O_TRIVIAL_1012`). Nenhum trata da cadeia de
  transmissão, e o nó novo só registra a adoção, no molde do 4.33.0.

## Mutantes

- **O selador que grava o source com fragmento de grafo** (`docs/g.kg.yaml#Q_ALVO` no lugar de
  `maestro, na sessão do /meta:decide`), plantado com `ops/mutate-and-restore.sh` no `kg-decide-seal.sh`: o selo sai
  rc 0, o `--chain` sai rc 0, mas a pergunta vira a origem e o caso novo reprova (`cadeia-errada`). Os outros 36 casos
  da família passam com o mutante, e o selador voltou intacto (zero marcador `ONION_MUTANTE`).

## Limites declarados

- O caso lê a cadeia de um selo só, com uma aresta; a cadeia longa e os ciclos são da bancada da kg-ssot.
- A bancada rodou uma vez e só na família `decide`, sem paralelizar, pela carga da VPS; a completa é do CI.
