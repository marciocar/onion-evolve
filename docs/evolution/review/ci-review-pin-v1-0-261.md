---
branch: ci/review-pin-v1-0-261
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: bf3108bcf9897da725888ce1dfb92ff608f0493159f07762e6ae5475106bc95d
reviewed_code_sha256: 4a179eac3874b4c2be61861a29de40a9af7c8a65fa2609baf91c2fa3bb1f9fb8
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `ci/review-pin-v1-0-261`

## O que muda

- `.github/workflows/onion-review.yml`: os dois `uses:` da `anthropics/claude-code-action` saem de `8d70a0dd`
  (v1.0.260) e vão para `16f9f71a` (v1.0.261). O comentário de cada um ganha a medição do compare e guarda a
  linha anterior como "Antes:".
- `radar-E3-2026-10-24-r18.kg.yaml`: entra a evidência `E_SDK_DO_BRIDGE_NA_0_3_310_E_PIN_DO_REVISOR_EM_V1_0_261_1024`,
  com uma aresta SUPPORTS para `Q_SUBIR_SDK_DO_BRIDGE_E_PIN_DO_REVISOR_PARA_2_1_310_1024`. O teto do grafo vai a 17 de 25.

## Achados

1. **A tag é anotada, então o SHA do `ref` não é o commit. Conferido, sem defeito.** O `git/ref/tags/v1.0.261`
   devolve `af7730b4` com `type: tag`. O `git/tags/af7730b4` aponta o commit `16f9f71a`, que é o que entra no `uses:`.
   É o mesmo cuidado da subida anterior (tag `1c5885c4` → commit `8d70a0dd`).

Também conferido:
- O compare `v1.0.260...v1.0.261` tem 1 commit em 6 arquivos, lidos patch a patch. Só mudam versões:
  `CLAUDE_CODE_VERSION` e `claudeCodeVersion` vão a 2.1.310, e o `claude-agent-sdk` vai a `^0.3.310`, com os locks.
  Nenhum input, output nem modo da action muda, então o contrato que o `review-verdict.sh` lê (`execution_file`, `prompt`,
  `anthropic_api_key`, `claude_args`) fica igual.
- O `grep -n claude-code-action@` mostra as duas ocorrências trocadas e nenhuma que tenha sobrado no SHA velho.
- A evidência do bridge foi medida agora, não herdada: o censo dá o binário servido em `2.1.310 (SDK 0.3.310)`.
- A pergunta `Q_…_2_1_310_1024` **fica aberta** de propósito. A metade do revisor só se prova com ele rodando,
  e hoje ele está desligado (sem a label `review:ia`). É a mesma pendência da SAC-239, que a rodada 18 registrou.

## Mutantes

Não se aplica: o diff não tem código executável, só o pin e um nó de grafo. O radar `--integrity --schema` e o
contrato deram rc 0 no grafo tocado.

## Limites declarados

- O PR que edita o workflow do revisor pode fazer a action se auto-pular, então a execução do CLI 2.1.310 no
  revisor não é provada aqui. Isso fica para um PR seguinte com a label `review:ia`.
