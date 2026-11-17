---
branch: docs/decide-seals-1116b
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: "Um selo gravado pelo kg-decide-seal.sh (saiu 0: radar --integrity --schema exit 0, contrato rc 0, lint de nomes sem achado novo). Voz única do core; só grafo. Achado, curado antes do commit: a 1ª versão do selo dizia que a autorização cobria também a execução; a curadoria confirmou direto com o maestro que ela vale só para abrir o documento, e o selo foi refeito com esse alcance."
nota: "O selo registra a resposta do maestro de 2026-11-16 e o esclarecimento dele à curadoria no mesmo dia. A execução da Fase 2 não está selada aqui: espera o sim dele, serviço a serviço."
---

# Selo da abertura da Emenda da Fase 2

## O que muda

`D_ISOLATION_PHASE2_AMENDMENT_AUTHORIZED_1116` no grafo de arquivo de selos: a Emenda da Fase 2 da bancada de isolamento entre inquilinos está autorizada a abrir como documento, com as quatro cláusulas propostas pela sessão de operações da VPS; a execução contra cópia sintética de cada serviço espera o sim do maestro, serviço a serviço.

## Achados

Um, curado: o alcance do selo (ver `reviewer`).

## Limites declarados

- Nenhuma execução está autorizada por este selo.
