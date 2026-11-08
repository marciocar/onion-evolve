---
branch: docs/degrau2-slack-proven-1108
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: a99ff5dec2e8cb9187e8349fc6b41afdce9aeaa4448c5dd131c62c53cd732f7d
reviewed_code_sha256: 0b52e5227be0e2e3da3efe509a34be6d72e26b9446275703579c54d0a9b0b61b
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: passada própria sobre o próprio diff (sem subagente); gate mecânico kg-radar --integrity --schema e kg-contract-check
nota: "tokens 0 = não medido. Lote de grafo: a passada é a releitura do fecho contra os rascunhos e o journal medidos no mesmo turno."
---

# Passada adversarial: `docs/degrau2-slack-proven-1108`

## O que muda

`Q_CS_DEGRAU2_SLACK_RASCUNHO_1109` (o Slack como evento, com a persona respondendo em rascunho) passa de `open`
para `done`, com `verified_against` apontando os rascunhos medidos. O checkpoint do lote nomeia o flip.

## Achados

1. **O primeiro sinal que eu ia usar não provava o critério (REAL, curado).** O último rascunho aprovado
   (`d_650e344d09432b78`) respondia "modo livre" e saiu com `sources` vazio. Fechar por ele afirmaria "com fonte no
   Company Brain" sem fonte. A cura foi ler os metadados dos 13 rascunhos: 9 dos 10 postados têm fonte do Company
   Brain, e esse rascunho serve como prova de outra coisa, a sobrevivência ao restart.
2. **As 7 condições do `D_PERSONA_RUNTIME_2026_11` não foram re-medidas uma a uma (REAL, não curado aqui).** Vai em
   Limites e está escrito na narrativa do nó.

## Mutantes

Não se aplica: o diff é dado de grafo, sem lógica. O gate é o radar (exit 0) e o contrato (rc 0).

## Limites declarados

- Fecho por medida de produção (metadados dos rascunhos e journal), não por bancada nova.
- 3 rascunhos de 07/11 ficaram pendentes sem aprovação. É o comportamento esperado (nada sai sem o maestro), não
  defeito.
