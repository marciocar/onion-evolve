---
branch: fix/decide-seal-local-contract
date: 2026-10-12
reviewed_diff_sha256: 4cf5aa85f0f6fdc350bf09e066e8abdfcce827c13b44d18625e8ce04e90aa835
reviewed_code_sha256: 8286c53e081aa3a25aae1a01052ed78baa43eafffda74ae1da42fe3343be40bc
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 25
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutante executado (sem subagente) — gate mecânico: família decide
---

# O selador do /meta:decide confere o contrato também no repo do produto KG-SSOT

## Sinal de campo (onion-kg-ssot, 1º dogfood do /meta:decide, 2026-10-12)

1. **Selo sem contrato.** O `kg-decide-seal.sh` só conhecia o contrato vendorizado (`vendor/kg-ssot`). No
   repo do produto, o leitor de referência é o próprio `tools/kg_validate.py`, e o selador selava com o
   radar como único gate. Curado: sem vendor e com `tools/kg_validate.py`, o leitor local passa a ser o
   2º gate. O julgamento é absoluto (rc 0 passa, 1 reprova). O passo 0 já recusa um grafo que reprovava
   antes, então a reprovação depois do selo é culpa dele, e a escrita é desfeita com rc 3. A linha final
   nomeia o leitor usado.
2. **Mensagem que juntava dois casos.** "fora de repo git ou contrato não vendorizado" descrevia um repo
   git como se não fosse. Agora são duas mensagens.

A prosa do `/meta:decide` também foi corrigida: ele não viaja para as **portas**, mas o adotante de corte
completo (carimbo `adopted`) o recebe.

## Prova

- Família decide **24/0**. Casos novos:
  - (s12): o leitor local que reprova o grafo selado → rc 3, desfeito byte a byte; o que passa → rc 0,
    nomeando o leitor;
  - (s13): repo git sem leitor → mensagem própria.
- Com o selador de `origin/main` (o mutante), s12 e s13 reprovam.

## O que NÃO cobre

- O leitor local julga o grafo inteiro, não a piora contra o HEAD como o `kg-contract-check`. Isso é seguro
  por causa do passo 0, mas a mensagem de reprovação vem do leitor do produto, na forma dele.
