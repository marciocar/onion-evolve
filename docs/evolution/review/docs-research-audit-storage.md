---
branch: docs/research-audit-storage
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 8851d45b45c2f3324a645684f2a393d77781d7711026812cd8e65bff72da2894
reviewed_code_sha256: 736ac022c9e52d090808fd511ad90defaab47c225cc5a065723f43ca3193c476
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 15
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão principal (passada sobre o grafo do run e a síntese)
nota: "tokens 0 = não medido na passada da sessão; o Elenxo do run wf_1b66acda-ac8 é a passada adversarial do conteúdo"
---

# Passada adversarial: `docs/research-audit-storage`

## O que muda

O grafo da varredura de armazenamento (78 nós, decisão `D_AUDIT_STORAGE_SEAL_AFTER_VENDOR_SWEEP_1021`
OPEN), a `SYNTHESIS.md` e o retorno do run.

## Achados

1. **A recomendação do Elenxo chegou ao escritor cortada em 600 caracteres.** A causa é o `webText()`
   (`.claude/workflows/onion-research.js:97`, `slice(0, 600)`) aplicado na linha 690, cujo comentário
   promete o texto INTEIRO. Curado neste PR: a íntegra, de 2786 caracteres, foi restaurada no nó a partir
   do journal do run (resultado do agente, não de memória). A cura do MOTOR vai em PR próprio, com
   mutante.
2. **Caminho absoluto da máquina no retorno do run.** Curado com caminho relativo.

## Mutantes

Não se aplica a este PR, que só traz dado. O mutante do motor fica no PR da cura.

## Limites declarados

Não reli as fontes e confio no Verify 3/2 e no Elenxo do run. A varredura de nomes de cliente é limitada
à lista que conheço.
