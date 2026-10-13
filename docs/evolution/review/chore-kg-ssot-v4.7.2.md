---
branch: chore/kg-ssot-v4.7.2
date: 2026-10-13
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 25
verdict: APROVADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: kg_vendor check, veredito JSON nos 443 grafos antes × depois, kg_gate antes e depois do --update, famílias mcp_onion_kg_writer e kg_contract_check
---

# O vendor sobe para a kg-ssot-v4.7.2, a release para quem é de fora

## O que muda

- `vendor/kg-ssot` ← `kg-ssot-v4.7.2` (3e439479cdf0, 315 arquivos), por `kg_vendor.py update --tag`; chegam
  `llms.txt` e `llms-full.txt`.
- Os schemas v4 mudam só no texto das descrições; o sha256 muda e a base do gate (`.kg-ssot/gate.json`) é
  regravada com `kg_gate.py --update` e os mesmos `--exclude` do CI.
- `E_CONTRATO_V43_ADOTADO` recebe a medição; nasce `Q_PADRONIZAR_LLMS_TXT_NO_ONION` (nota do maestro), com
  gatilho, e o teto do grafo sobe de 27 para 28, declarado.

## Passada adversarial

1. **O veredito muda?** `--format json` nos 443 `.kg.yaml` rastreados, 4.7.1 × 4.7.2: veredito e resumo
   de códigos idênticos (0 divergentes). 66 arquivos diferem só no texto da dica de provenance, que a
   release reescreveu de propósito. Não real.
2. **O `--update` esconde piora?** Antes dele o gate saiu rc 1 só pela identidade do contrato (a mensagem
   nomeia o sha velho e o novo). A base nova tem 156 grafos e 16 na dívida herdada, a mesma contagem do
   gate com a 4.7.1; a única saída da lista de dívida é `review-gate-saldo-2026-09.kg.yaml`, que passou a
   cumprir o MUST quando o #1076 trocou as chaves `gatilho:` por `x_gatilho:`. Ganho travado, não piora.
3. **O writer muda?** As dicas que o writer repassa ao modelo mudam de texto (`unverifiable`). Famílias
   `mcp_onion_kg_writer` e `kg_contract_check` com `LC_ALL=C` (resultado no PR). Redeploy pelo
   `ops/update-kg-writer.sh` e probe ao vivo depois do merge.
4. **O `kg-contract-check` do core acusa a troca de sha?** Rodado num grafo do corpus: conforme ao
   contrato. Ele compara o SHOULD contra o HEAD e o MUST pelo schema atual; a identidade é cobrada pelo
   gate, que acusou e foi regravado. Não real.
