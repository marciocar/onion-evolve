---
branch: research/librechat-kg-runtime
pr: 642
date: 2026-08-20
reviewed_diff_sha256: d19c5635a3082faf5ddb090cb67b368a1a74f218a3a937692d9242fc98e58c47
findings_total: 2
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME-PESQUISA-FUNDADA-EM-EVIDENCIA-DE-CAMPO
reviewer: passada adversarial manual; sem subagentes
REVISOU: true
---

# Resíduo — `research/librechat-kg-runtime`

**Origem:** o gatilho REAL da F4b — a alucinação do agente da PoC, nomeada pelo maestro.

## Achado 1 — proveniência-invertida de novo (REAL, curado pelo gate)

Segunda ocorrência da MESMA classe em pesquisas desta semana (a 1ª foi no librechat-2026-08):
criei grafo+síntese e o grafo não citava a síntese em trace:. O gate bloqueou o commit; curado.
⚠️ 2 ocorrências = à beira da régua de recorrência da casa (3 vira mecanismo/lembrete no
template de pesquisa) — registro para a contagem.

## O ataque que vale (contra a validade da própria pesquisa)

A pesquisa afirma o desenho SEM fan-out de exploração — é válido? Sim, e o motivo é declarado
no frontmatter: a evidência central veio DO CAMPO (transcript real da PoC), não de hipótese; e
as decisões reusam padrões já provados na casa (skillSync vivo, pipeline da PoC com radar rc=0,
o padrão federação p/ write-como-proposta). Pesquisa de gabinete seria mais fraca que a
evidência que já existia.

## Ressalva declarada

O write-leg como proposta está DESENHADO, não construído — a fila de proposta que o core sela
não existe como mecanismo; vira parte do MCP onion-kg (F6.3) quando o maestro ordenar.
