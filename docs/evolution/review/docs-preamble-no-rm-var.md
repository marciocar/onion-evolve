---
branch: docs/preamble-no-rm-var
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: "sessão principal (passada própria; mudança de uma linha no preâmbulo)"
nota: "tokens 0 = não medido; sem refutador independente: a mudança é uma cláusula de prosa que o agent-brief.sh já embute inteira"
---

# Passada adversarial: `docs/preamble-no-rm-var`

## O que muda

Uma cláusula no `execution-agent-preamble`: o agente de execução não faz nada que peça aprovação humana. O caso medido é o `rm -rf $var`. O `agent-brief.sh` manda ler o preâmbulo e copia, por âncora, a linha da espera; agora copia também a desta cláusula, e acusa rc 2 se a âncora sumir. A passada achou isso: a primeira versão supunha que o ajudante embutia o preâmbulo inteiro.

## Achados

1. **Limite.** A cláusula é prosa: ela muda o brief, não o harness. Uma checagem de segurança diferente, que também peça aprovação, continua pendurando o agente. A cura de mecanismo é o medidor acusar tool_use sem resultado há N minutos, proposta no SAC-421.

2. **Curado.** O `agent-brief.sh` não embute o preâmbulo inteiro: copia uma linha por âncora. Sem a cópia, a cláusula só chegava se o agente lesse o arquivo, e foi justo a falta de leitura que criou o ajudante. Cura: a segunda âncora, copiada e conferida.

## Mutantes

`--families agent_brief`: 12 casos, 0 falhas. O caso novo (f) reprova contra o mutante que tira a linha copiada, e o (b) foi reancorado na linha nova do `printf`.

## Limites declarados

- Ver o achado 1.
