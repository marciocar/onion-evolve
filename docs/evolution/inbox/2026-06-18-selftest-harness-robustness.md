---
title: 'Robustez do harness de validação: pre-commit sem self-test + fixture acoplada à SSOT'
date: 2026-06-18
from: sessão-core (emergiu ao construir o trio de co-evolução, PR #93)
to: onion-evolve (core)
type: field-signal / framework-gap
severity: low
flow: C (in-repo / qualidade do harness)
status: aberto (2 itens; ação = sessão-core futura)
---

# Dois furos no harness de validação (pegos ao construir o trio, PR #93)

Contexto: o PR #93 (comando novo `/meta:co-evolve`) passou no **pre-commit local** mas **falhou no CI**.
Causa imediata já corrigida (fixture stale); abaixo as duas melhorias estruturais que isso expôs.

## 1. Pre-commit local não roda o self-test → falhas só aparecem no CI

- **Sintoma:** o pre-commit (`.githooks/pre-commit`) roda só `lint-artifacts.sh`. O CI roda
  `lint-artifacts.sh` **+** `lint-selftest.sh`. Logo, uma quebra de fixture/self-test **não é pega
  localmente** — só estoura no CI (loop de feedback lento).
- **Proposta:** o pre-commit rodar o self-test também (ou um modo rápido dele). Cuidado: o self-test
  copia a árvore (sandbox) e é mais lento (~1min) — talvez rodar só quando `.claude/validation/**` ou
  `fixtures/**` mudarem (pre-commit condicional), pra não penalizar todo commit.

## 2. Fixture `r16-count-drift/good-cmd-count` é acoplada à SSOT (quebra a cada comando novo)

- **Sintoma:** a fixture GOOD da Regra 16 **hardcoda** o total atual ("N comandos invocáveis"). Cada
  comando adicionado/removido a torna stale → o self-test falha até alguém atualizar o número à mão
  (foi o que quebrou o #93: 84→85).
- **Proposta:** derivar o número da SSOT em tempo de teste (ler `inventory.sh`/`inventory.md` e injetar
  na fixture no sandbox), em vez de hardcodar. Aí a fixture GOOD acompanha a SSOT sozinha. (A própria
  nota da fixture já reconhece o acoplamento — é candidato a automatizar.)

## Próximo passo
Item de backlog do core (baixa prioridade — o CI já protege; é melhoria de feedback-loop/manutenção).
Avaliar custo do pre-commit condicional vs. o ganho.
