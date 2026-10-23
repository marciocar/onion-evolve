---
branch: docs/radar-e3-r17
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: e9eda3348a50d063d66f4362e7995ba17a396b67a8d703d229038fe449c1325e
reviewed_code_sha256: c1bf51ebef6f7ffaef45a1fafee5ee2723e940debe163a50d6acd1a2cd0c47fe
findings_total: 9
findings_real: 9
tokens: 139178
duration_min: 35
findings_fixed: 9
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente general-purpose opus independente (não-fork), mandato REFUTAR"
nota: "tokens = só o juiz (medidos pelo harness); os da rodada não ficaram expostos. Os 9 achados são 3 vereditos negativos e 6 omissões. Os negativos foram reescritos; 3 omissões viraram nó ou reescrita, 1 foi absorvida por nó reescrito e 2 ficaram como NÃO-VERIFICADOS declarados na SYNTHESIS (linha 15 e os itens de plataforma alheia)"
---

# Passada adversarial: `docs/radar-e3-r17`

## O que muda

- Rodada r17 do radar E3: grafo `radar-E3-2026-10-23-r17.kg.yaml` (18 nós), `data/2.1.309.txt`,
  `data/judge-verdicts.json`, `SYNTHESIS.md` e a baseline do E3 em `docs/onion/radar-baselines.yaml`.

## Achados

1. REPROVA: o nó de worktree negava uma superfície que a doutrina prescreve (`isolation: worktree` em três
   artefatos). Foi reescrito, com `C_SUPERACAO_20261023_WORKTREE_ISOLADA_E_PRESCRITA` e com a pergunta SAC-241.
2. EXAGERA: o nó do `sed -i` dizia que a perna de leitura do grafo dispara. A rodada re-mediu: o Edit dá 988
   bytes de aviso e o `sed -i` dá 0. O nó foi reescrito, com `C_SUPERACAO_20261023_PERNA_DE_LEITURA_SURDA_AO_SED_I`
   e com a pergunta SAC-240.
3. EXAGERA: o nó de permissões dizia que o core não usa deny, mas `ops/chat-runner.sh` usa (linhas 618 a 625).
   O nó foi reescrito, com `C_SUPERACAO_20261023_DENY_MORA_NO_RUNNER_DO_CONVIDADO`.
4. Omissão da linha 41 (menções): o revisor do CI posta o texto do modelo sem sanitizar `@`. Virou nó e reforça a
   SAC-239.
5. Omissão da linha 29 (`/add-dir` com skill homônima): virou nó, com impacto 1.
6. Omissão das linhas 10 a 12 e 58 (worktree): absorvida pelo achado 1.
7. Omissão da linha 9 (deny no runner): absorvida pelo achado 3.
8. Omissão da linha 54 (`sed -i` e a perna de leitura): absorvida pelo achado 2.
9. Omissão da linha 15 (ctrl+enter re-executando hooks): ficou declarada em NÃO-VERIFICADOS, sem ação.

Forma: o juiz deu às superações classes livres, e o `judge-verdict-check.sh` recusou as três (rc 1). A rodada
normalizou a classe para `entrega` e manteve o rótulo do juiz no `o_que`. Depois disso, rc 0.

## Mutantes

- CU1: o juiz fez `diff` e `cmp` da cópia contra o CHANGELOG baixado, os dois vazios; com uma linha alterada, o
  diff acusaria.
- Perna de leitura: o mesmo arquivo rastreado foi passado por Edit e por `sed -i`. O Edit dá 988 bytes e o
  `sed -i` dá 0, então o contraste distingue os dois casos.
- env-guard: o alvo (arquivo de segredos) dá rc 2 e o controle (arquivo temporário) dá rc 0.

## Limites declarados

- A guarda de isolamento endurecida não foi medida dentro de um agente isolado, porque criar a worktree de agente
  regrava o `core.hooksPath` compartilhado (SAC-241).
- Os tokens da rodada não foram medidos; só os do juiz.
