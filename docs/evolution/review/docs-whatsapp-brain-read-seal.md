---
branch: docs/whatsapp-brain-read-seal
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 9069b299703d82e603676619148247f2c938edf14f09277f110ddee3b6601571
reviewed_code_sha256: f086690db46ab9b310b7168e8f9fa77cdd4b5819bfd1eca39945f20ec5f94c9c
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: sessão do core (passada própria, sem subagente)
nota: "tokens 0 = não medido: passada feita na própria sessão, sem run separado"
---

# Passada adversarial: `docs/whatsapp-brain-read-seal`

## O que muda

Três nós de decisão do maestro, selados pelo `kg-decide-seal.sh` no grafo do estudo do Brain: leitura do WhatsApp por dois números, as condições do número pessoal e o aviso nos grupos com piloto gradual.

## Achados

1. **Nome comercial do adotante no grafo público** (real, corrigido). A primeira passada dos selos escreveu o nome da empresa no `label` de um nó. O core é público. Corrigido antes do commit: o arquivo voltou ao estado da `origin/main` e os três selos foram refeitos com «a empresa» e «um contato escolhido pelo maestro». Conferência: `grep -ci` do nome da empresa e do contato no grafo devolve 0.
2. **Delimitador do selo no texto do aviso** (real, corrigido). O selador recusou (rc 2) o texto com «», que é o delimitador dele na narrative. Reescrito com aspas simples.

## Limites declarados

- A execução (sessão no WAHA, QR, aviso no grupo) não é deste repo. Este PR só registra a decisão.
