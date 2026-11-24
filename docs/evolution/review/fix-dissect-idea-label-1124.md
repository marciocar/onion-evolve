---
branch: fix/dissect-idea-label-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
findings_blocking: 0
tokens: 104000
duration_min: 11
findings_fixed: 1
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "refutador INDEPENDENTE (agente separado, brief sem a conclusão do condutor; comparou o checador antes e depois nos grafos reais do core e da curadoria, mutou um clone da curadoria na pasta dele, rodou a bancada) não achou bloqueante: 0 falso positivo, corte por data respeitado, label não-string pego, ordem do continue certa, bancada discrimina"
nota: "tokens e duração são os do refutador; a passada do condutor não foi medida"
---

# Passada adversarial: `fix/dissect-idea-label-1124`

## O que muda

- `dissect-object-check.py`, item 9: código novo `ideia-sem-label` quando o nó com `x_dissect_idea` não tem `label`
  string preenchida. Fica dentro do `ideas_check`, então herda o corte por data (`IDEAS_SINCE`): estudo anterior sai aviso.
- `dissect-object-bench.py`: dois casos (label ausente no nó 0, label em branco no nó 1), cada um contra o mutante.
- `dissect-doctrine.md`: o código entra na lista de quem cobra.

## Achados

1. **Real, não bloqueante, curado.** A mensagem do commit sugeria que os 6 nós sem label da curadoria passariam a
   reprovar; eles estão em estudos anteriores ao corte, onde o código só avisa. A mensagem foi reescrita para dizer isso.
2. **Não defeito.** Ideia mal-formada e sem label mostra só a mal-formação primeiro (uma causa raiz por vez, como os
   outros códigos do item 9).
