---
title: 'kg-corpus-grep.sh: o último nó do grafo absorve o label de todas as arestas'
date: 2026-09-24
from: sge (adotante, role adopted, pin ba0d2d423c17)
to: core (onion-evolve)
type: bug
severity: medium
flow: upstream
---

# `kg-corpus-grep.sh` — o último nó absorve os labels da seção `edges:`

## O que acontece

O parser de `.claude/validation/kg-corpus-grep.sh` (loop por linha, ~l. 42–55) abre um nó a cada
`- id:` e atribui a ele toda linha `status|verified_at|source_tier|label:` que vier depois. Ele
**não para na seção `edges:`**. O último nó da lista `nodes:` recebe, portanto, o `label:` de **cada
aresta** do arquivo, e termina com o label da última aresta.

Dois efeitos:

1. **Label errado** na saída do corpus: o nó aparece com o texto de uma aresta.
2. **Falso positivo de busca**: qualquer termo presente no label de **qualquer aresta** marca `_hit`
   no último nó, que entra no corpus injetado na pesquisa sem ter a ver com o termo.

## Reprodução (medida no SGE em 2026-09-24)

```bash
bash .claude/validation/kg-corpus-grep.sh PROPOSE
# Q_PROPOSE_CLOSE_PASS2_QUESTIONS  open  a proposta de fechamento ou manutenção se apoia nesta
#                                        pergunta e nas evidências ligadas a ela   ← label de ARESTA
bash .claude/validation/kg-radar.sh <grafo> --open-tsv | grep PROPOSE
# ... Q_PROPOSE_CLOSE_PASS2_QUESTIONS ... PROPOSTA ao maestro (est...        ← label real do NÓ
```

O mesmo aconteceu antes com `Q_PROPOSE_RECONCILE_REPO_DOMAIN`, quando ele era o último nó. **Os dois
leitores do corpus discordam** sobre o mesmo nó, que é a classe que a REGRA 82 existe para pegar. A
REGRA 82 não pegou porque compara **quem é nó** (ids), não os campos.

## Cura sugerida

Encerrar o nó corrente ao entrar em `edges:` (ou em qualquer chave de topo sem indentação):

```python
if re.match(r'^\S', line):          # chave de topo (edges:, meta:, ...) encerra o nó
    if node and node.get("_hit"): hits.append(node)
    node = None
    continue
```

E estender a paridade da REGRA 82 para comparar também `status` e `label` entre os dois leitores.

**Testada no SGE** (cópia no scratchpad, sem tocar o vendorizado):

| Consulta | Original | Com a cura |
|---|---|---|
| `PROPOSE` — label do último nó | label de aresta | label real do nó ✓ |
| `manutenção` (termo só num label de aresta) | 3 nós, incluindo o último **por falso positivo** | 2 nós ✓ |
| `lote item 191` — conjunto de ids | 38 nós | 38 nós, idênticos (sem regressão) ✓ |

A cópia precisa de `kg-fixture-paths.sh` ao lado (dependência do script), senão aborta.

## Impacto no adotante

Baixo e contornável: o corpus é contexto de pesquisa, não gate. Mas ele é o **passo 1** da skill
`onion-research` ("corpus primeiro"). Um label trocado ali já entra no Scope, no Elenxo e no write(KG).
