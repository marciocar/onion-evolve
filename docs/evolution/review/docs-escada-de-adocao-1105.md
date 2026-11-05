---
branch: docs/escada-de-adocao-1105
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: "kg-ssot e curadoria acharam os nós colhidos citados em outro repo, por kg_refs e git grep; sem outra passada adversarial neste diff"
nota: "tokens e duração 0 = não medido. Só registro: selos do maestro e arquivo de selos."
---

# Passada adversarial: `docs/escada-de-adocao-1105`

## O que muda

- Selos do maestro no grafo de identidade: a escada de adoção, o portão no forge, o censo retroativo, o A2A como primeiro caso, o refino que não rebaixa eliminatório, e a publicação depois do merge.
- `Q_COORD_BRAIN_SEGREDO_VERSIONADO_ALERTA` e `Q_COORD_MAESTRO_VITRINE_E_DIA_ZERO_KGSSOT` fechadas com a resposta do maestro.
- Novo grafo `coordenacao-selos-arquivo-2026-11`, para onde vão os selos colhidos, sem mudar o texto.

## Achados

1. A colheita de 2026-11-02 apagou três selos citados por outro repo. Curado trazendo-os ao arquivo.
2. A colheita de 2026-11-04 apagou dois. Curado do mesmo modo, e a regra agora é mover a decisão, não apagar.

## Mutantes

Não se aplica: só registro.

## Limites declarados

Citação com o caminho antigo só resolve no commit fixado, até o citador atualizar. O arquivo não confere quem cita: a consulta entre repos vem do kg-ssot. A varredura de outros nós colhidos em rodadas anteriores não foi feita.
