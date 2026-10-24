---
branch: chore/kg-ssot-4-25
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: 1d863a42c22a0ee0b3ffddb8f71aebd8e114402ee10e45c391a2994f98f326c2
reviewed_code_sha256: 46b4c79777a47a63c22df7c31970fb3ece27957688b44c4b19ce0a044241b66e
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "agente de execução da sessão principal (claude-opus-5-5), passada própria sobre o próprio diff"
nota: "tokens não medidos pelo agente; o harness reporta o uso na notificação final"
---

# Passada adversarial: `chore/kg-ssot-4-25`

## O que muda

- `vendor/kg-ssot` 4.23.0 → 4.25.0 (`b5582deee07e`, 627 arquivos), `kg_vendor.py check` rc 0. Contrato v4.14 sem
  mudança. Entram o `update --ref` com o carimbo `unreleased` e o `--allow-unreleased` no check e no gate (4.24.0) e
  o `kg_trace.py` (`integrity.trace-target-missing`, 4.25.0). O resolvedor da REGRA 55 (O `trace:` de um nó APONTA
  para alvo que EXISTE) não foi trocado: o `kg_trace.py` fica só disponível, e a troca é outro PR.
- `ops/kg-gate-ci.sh`: `KG_GATE_ALLOW_UNRELEASED=1` acrescenta `--allow-unreleased` ao check E ao `kg_gate.py` (os
  dois recusam o vendor de bancada sem ela). Só o valor `1` vale; no GitHub Actions a variável setada sai rc 2.
- `.kg-ssot/gate/contract.json`: kit 4.23.0 → 4.25.0 pelo `kg-gate-ci.sh --update`. O mesmo `--update` gravou
  `.kg-ssot/gate/graphs/vocabulario-da-casa-2026-10.json`, que chegou à main sem base (nasce vazia, como o grafo mede).
- Bancada: família nova `kg_gate_ci` (casos a–e). Grafo: nó `E_KG_SSOT_425_ADOTADA_1024` em `sinais-de-campo-2026-09`.

## Achados

1. **REAL, curado** — "o CI e o pr-finalize nunca setam a variável" era declaração no comentário, não mecanismo. Um
   `env:` herdado num workflow (ou um export esquecido) deixaria verde, no CI, um vendor de bancada, o que a 4.24.0
   existe para impedir. Cura: com `GITHUB_ACTIONS=true` e a variável em 1, o wrapper sai rc 2. Como a própria bancada
   roda no CI, os casos (b)–(d) rodam com `env -u GITHUB_ACTIONS`; medido com `GITHUB_ACTIONS=true` exportado: 5/5.
2. **Não é defeito** — `kg-criterion-ci.sh` e `kg-vocab-ci.sh` não leem o carimbo, então não precisam da flag: o
   veredito sobre o vendor fica no check e no gate, e os dois a recebem.

Gate antes (4.25 sem `--update`) e depois do `--update`: saída idêntica linha a linha (186 grafos, 184 no MUST, 2 de
dívida herdada, contagens SHOULD iguais; critério 3/0; nomes 0 novos).

## Mutantes

Todos mortos pela família `kg_gate_ci`:

- flag só no check (tirada do `kg_gate.py`): (c) reprova, o gate recusa a bancada.
- flag só no gate (tirada do check): (c) reprova com `UNRELEASED VENDOR`.
- flag sempre ligada (`allow=(--allow-unreleased)`): (b) reprova, sem=0 e yes=0.
- recusa no GitHub Actions removida: (e) reprova, rc 0.

## Limites declarados

- Bancada rodada só nas famílias `kg_gate_ci`, `kg_vocab_ci` e `kg_criterion_ci`; a completa fica com o CI.
- A recusa no CI cobre o GitHub Actions (`GITHUB_ACTIONS=true`), o único CI do core; outro runner não é reconhecido.
- Com a base em kit 4.25.0, uma bancada `--ref` de um commit cujo `spec/release.json` declara versão anterior cai na
  regra do próprio `kg_gate.py` (kit mais antigo que a base). É comportamento do vendor, não do wrapper.
