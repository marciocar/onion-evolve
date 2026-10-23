---
branch: chore/kg-ssot-4.20.0
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 30
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão)"
---

# Passada adversarial: `chore/kg-ssot-4.20.0`

## O que muda

- `vendor/kg-ssot` sobe de 4.19.1 para 4.20.0 (`6077142279a9`) pelo `kg_vendor.py update`; `check` rc 0. Contrato
  v4.11 sem mudança; o `--update` do gate só regravou `"kit": "4.20.0"` em `.kg-ssot/gate/contract.json`.
- `.claude/validation/kg-fixture-paths.sh`: a isenção fixa `(^|/)vendor/kg-ssot/` dá lugar à regra pública da 4.20.0
  — toda pasta com `.kg-ssot-version` rastreado é o vendor e sai do corpus; o carimbo na raiz do que se lê não conta.
  Uma chamada de `git ls-files` ao carregar o predicado (nunca por grafo). `--selftest` ganha um repo de mentira:
  vendor fora de `vendor/` isento, pasta sem carimbo e carimbo na raiz não isentam.

## Achados

1. A 1ª versão do caso novo chamava o próprio script por `${BASH_SOURCE[0]}` relativo depois de um `cd` para o repo
   de mentira: o `--filter` não rodava e a saída vinha vazia. Curado com o caminho absoluto do script.
2. O harness do kg-writer (`ops/mcp-onion-kg-writer/selftest.py`) tem um `judge()` falso com a assinatura antiga, e o
   `kg_store` da 4.20.0 chama `judge(..., cache=…)`: 4 casos da família `mcp_onion_kg_writer` caíram com TypeError
   ("NAO JULGADO"). Curado: o falso aceita `cache=None` e o ignora de propósito, porque ele conta as chamadas (modo
   raise-2nd) e cada uma tem de julgar. Família: 88 passaram, 0 falharam (com `mcp_onion_kg`).

## Mutantes

- Voltar o `KG_VENDOR_RE` ao caminho fixo `vendor/kg-ssot`: o `--selftest` reprova (1 falha), porque o vendor em
  `lib/terceiros/kgs/` deixa de ser isento. Restaurado: OK.

## Limites declarados

- O cache do veredito da 4.20.0 (`kg_validate.JudgeCache`) é em memória, dentro do processo do `kg_store`; não cria
  arquivo no repo, então nada a versionar nem a ignorar.
- Bancada: 41 famílias do kg, do door e do decide, 708 passaram e 1 caiu (o item 2), curado e re-rodado verde.
- O gate seguiu com 184 grafos, 182 cumprindo o MUST e 2 de dívida herdada, antes e depois.
