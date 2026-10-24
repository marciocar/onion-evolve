---
branch: ci/review-pin-v1-0-261
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: pendente
findings_total: 2
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

## Re-revisão (2026-10-24): a v1.0.262 saiu durante o CI deste PR

O hook de versão defasada (`session-currency-check.sh`) acusou a v1.0.262, publicada às 18:57:30Z, com o PR ainda no
CI. Ficar na v1.0.261 seria nascer uma versão atrás, então o PR sobe direto para a v1.0.262. A tag anotada é
`70f88a9f` e o commit, `925afb53`.

2. **O compare `v1.0.261...v1.0.262` tem 1 commit, o #1916, que só sobe o Bun do runner de 1.3.14 para 1.4.4.**
   Ele mexe no `setup-bun` do `action.yml` e do `base-action/action.yml`, e no `@types/bun` dos `package.json` e locks.
   A versão do CLI não muda (continua 2.1.310), e nenhum input nem output usado pelo revisor muda. O risco é de
   runtime (Bun 1.4 sob a action), e só se mede com o revisor rodando, o mesmo limite já declarado.

Conferido de novo: os dois `uses:` foram para `925afb53`, sem SHA velho sobrando. A evidência do grafo foi renomeada
para `…_V1_0_262_1024`, com o `verified_against` e a fonte apontando o compare até a v1.0.262. Radar rc 0.
