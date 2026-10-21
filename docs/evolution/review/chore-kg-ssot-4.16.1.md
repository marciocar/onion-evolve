---
branch: chore/kg-ssot-4.16.1
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 4
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; vendor por kg_vendor.py"
---

# Passada adversarial: `chore/kg-ssot-4.16.1`

## O que muda

O vendor vai da 4.16.0 para a 4.16.1, que traz o contrato v4.10. A identidade da base é regravada e o
comentário do pin é alinhado.

## Achados

Nenhum. Pelo caminho do CI, são 182 grafos e os mesmos 16 na dívida herdada. O gate saiu rc 0 com a
identidade nova mesmo antes do `--update`, que é a cura da 4.16.0 medida no core. O vendor está íntegro
(495 arquivos).

## Mutantes

Não se aplica.

## Limites declarados

Os três pontos do perfil YAML não aparecem nos grafos do core. O ADOPTING diz isso dos grafos medidos por
eles, e o gate do core confirma: nenhum veredito trocou.
