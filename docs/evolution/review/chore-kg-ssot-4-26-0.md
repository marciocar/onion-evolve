---
branch: chore/kg-ssot-4-26-0
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: 686a482032e1153be908051fcda6b6d3732c31cd50d1512e151172b25a60b44f
reviewed_code_sha256: 9013dd662bffa117476802dd5b88049b62e2977d5f6e3a85156a0a0c7237ce9f
findings_total: 4
findings_real: 0
tokens: 0
duration_min: 4
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: "agente de execução kg426 (passada própria)"
nota: "tokens não medidos (0): a sessão não expõe o custo do agente. Os quatro achados foram suspeitas medidas e descartadas."
---

# Passada adversarial: `chore/kg-ssot-4-26-0`

## O que muda

- Vendor kg-ssot 4.25.1 → 4.26.0 (`kg-ssot-v4.26.0`, 42ae9832f588) pelo `kg_vendor.py update`: 629 arquivos, 2 novos (`tools/kg_vector.py`, `tools/requirements-vector.txt`), `kg_vendor.py check` intacto.
- `ops/kg-gate-ci.sh` rc 0 sem `--update` (contrato v4.14; 188 grafos, 186 passam o MUST, os 2 da dívida herdada de antes). `ops/kg-criterion-ci.sh` e `ops/kg-vocab-ci.sh` rc 0.
- Nó `E_KG_SSOT_426_ADOTADA_1025` em `sinais-de-campo-2026-09.kg.yaml`, com aresta SUPPORTS para `D_CANAL_CORE_KG_SSOT_FORMALIZADO_1023`; o índice de leitura ganha a linha dele.

## Achados

1. **Não procede.** O `--text` do `kg_query` poderia mudar de forma com o campo `semantic.text_matches`. Medido: a saída JSON de `--root . --text` é byte a byte igual à da 4.25.1 (`git archive` de origin/main) em 5 consultas.
2. **Não procede.** O `kg_query` poderia importar o `kg_vector` (e o onnxruntime) no topo e quebrar o caminho sem o extra. O import é tardio, dentro do ramo do `--semantic`; sem o extra o `--semantic` sai rc 3 com VECTOR UNAVAILABLE, sem cair calado no `--text`.
3. **Não procede.** Os consumidores diretos do vendor no core (`kg_store.py` do onion-kg-writer, `kg_validate.py`, `kg_trace.py` da REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) e da REGRA 84 (Índice de leitura do KG em sincronia com os traces)) não mudaram entre as duas tags (`git diff --quiet` rc 0).
4. **Não procede.** Os dois arquivos novos no perfil gate do `spec/release.json` poderiam exigir uma lista espelhada no core. Medido por grep: nenhum script ou doc do core repete a lista do perfil gate nem a contagem de arquivos do vendor; as citações da 4.25.1 fora do vendor são todas datadas ("desde a 4.25.1") e seguem verdadeiras.

## Mutantes

Nenhum: o PR não traz código do core, só o vendor regenerado pela ferramenta do produto e um nó de evidência.

## Limites declarados

- O `--semantic` com o extra instalado não foi exercitado (instalar pacote é vetado nesta tarefa). O `kg_vector.py` importa `urllib.request`, então com o extra ele pode baixar modelo; nada no core o chama hoje.
- A correção do UTF-8 no Windows não é exercitável neste Linux.
