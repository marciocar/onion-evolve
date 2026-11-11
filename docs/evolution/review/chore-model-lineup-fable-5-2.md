---
branch: chore/model-lineup-fable-5-2
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: passada própria da sessão do core sobre o diff, sem revisor independente
nota: "tokens 0 = não medido. O diff é um degrau do lineup, uma cláusula de doutrina, o estudo e os selos; sem código. Os números do estudo vêm de dois juízes às cegas, registrados em data/runs.tsv."
---

# Passada adversarial: `chore/model-lineup-fable-5-2`

## O que muda

O Fable 5.2 entra em `session_models` no lugar do 5.1, por selo do maestro; a doutrina da batuta ganha a cláusula do dono do resultado; o estudo da comparação de modelos nasce com os selos e as perguntas da fila.

## Achados

Nenhum. Conferi: a guarda de modelo passa o `claude-fable-5-2` e passa a vetar o `claude-fable-5-1`, como decidido; o `fallbackModel` não muda, porque a escada dele começa no segundo degrau; `data/runs.tsv` não traz texto de resposta nem caminho de máquina.

## Mutantes

Não se aplica: nenhum código mudou.

## Limites declarados

- Sem revisor independente: o diff não tem código, e o estudo já passou por dois juízes às cegas.
- Quem tiver `claude-fable-5-1` fixado pelo nome passa a ser vetado; voltar é editar uma linha.
