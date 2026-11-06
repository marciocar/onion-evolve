---
branch: docs/decide-seals-1106
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: edc0a749b19fd2c68798e5badae58b53a8275867508cea4c096b7c018cb5e368
reviewed_code_sha256: e66a3ba76485f95d02b6f68f8db5a3ebf75e843cbbfeed7ecc9ddd0f3cd66700
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal do core (passada própria, não independente)
nota: "tokens 0 = não medido. Diff só de grafo, staging de resposta e sinal processado, sem código nem regra; a passada é da própria sessão e se declara como tal."
---

# Passada adversarial: `docs/decide-seals-1106`

## O que muda

- O teto `C_TETO_BANG_NA_VERSAO_ATUAL` fecha com a medida do maestro na 2.1.319, e `E_BANG_NAO_PASSA_PELOS_HOOKS` ganha o carimbo novo.
- O selo `D_LINHA_CORE_DO_ADOPTER_GUARD_PELO_UPDATE_1106` (REGRA 118 (Veto de repo alheio do adotante registrado e com lista) arma pelo update), pelo `kg-decide-seal.sh`.
- O grafo novo `persona-servico-2026-11` dá nó, dono, data e critério de pronto aos 4 compromissos cobrados pelo hub.
- A resposta ao hub entra na staging do outbox, e o sinal da cobrança vai para `_processed/`.

## Achados

1. **Real, curado:** o `provenance.method` dos dois nós com proveniência no grafo novo não seguia a forma `<classe>: <detalhe>` (aviso SHOULD `form.pattern.node.provenance.method` do contrato). Reescrito em `leitura:` e `testemunho:`; o `kg-contract-check` voltou conforme.
2. **Real, curado:** o selo novo no grafo das vetos do adotante estourava o teto declarado de 15 nós; o selador recusou e nada foi escrito. O teto subiu para 16 com o motivo escrito na linha do `meta:`, e o selo passou com radar e contrato verdes.
3. **Descartado:** o nome do hub no frontmatter da resposta (`to:`) é o id de membro do `members.yaml`, como nas respostas anteriores já versionadas; o corpo não traz nome de cliente nem de pessoa.

## Mutantes

Nenhum: o diff não tem código.

## Limites declarados

- A passada não é independente.
- A confirmação ao hub saiu depois do prazo de 30 min pedido; o nó `E_PS_COBRANCA_DO_HUB_1106` e a resposta dizem isso.
- A cópia untracked do sinal no checkout da main sai depois do merge (é byte-idêntica à de `_processed/`).
