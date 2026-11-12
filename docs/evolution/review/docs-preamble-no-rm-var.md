---
branch: docs/preamble-no-rm-var
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: "sessão principal (passada própria; mudança de uma linha no preâmbulo)"
nota: "tokens 0 = não medido; sem refutador independente: a mudança é uma cláusula de prosa que o agent-brief.sh já embute inteira"
---

# Passada adversarial: `docs/preamble-no-rm-var`

## O que muda

Uma cláusula no `execution-agent-preamble`: o agente de execução não faz nada que peça aprovação humana. O caso medido é o `rm -rf $var`. Como o `agent-brief.sh` embute o preâmbulo inteiro, todo brief novo leva a cláusula.

## Achados

1. **Limite.** A cláusula é prosa: ela muda o brief, não o harness. Uma checagem de segurança diferente, que também peça aprovação, continua pendurando o agente. A cura de mecanismo é o medidor acusar tool_use sem resultado há N minutos, proposta no SAC-421.

## Mutantes

Não se aplica: só prosa. A conferência é o `agent-brief.sh` gerar um brief que contém a cláusula.

## Limites declarados

- Ver o achado 1.
