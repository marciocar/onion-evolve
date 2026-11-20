---
branch: docs/cc-update-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: pendente
findings_total: 13
findings_real: 13
tokens: 182619
duration_min: 12
findings_fixed: 13
verdict: FIXED
elenxo: true
reviewer: "subagente general-purpose opus independente (não-fork, effort high), mandato REFUTAR, critérios pré-registrados CU1 a CU7"
nota: "tokens = só o juiz (medidos pelo harness). Os 13 achados são 4 vereditos EXAGERA sobre nós e 9 omissões. Os 4 nós foram corrigidos com a superação de cada um (C_SUPERACAO_20261120_*); das omissões, 4 viraram nó (sonda do agent_id, origem do prompt, bancada do deny, effort do juiz, este com a afirmação do juiz refutada pela rodada), 1 foi declarada sem superfície (/code-review embutido) e 4 foram para NÃO-VERIFICADOS na SYNTHESIS"
---

# Passada adversarial: `docs/cc-update-1120`

## O que muda

- Rodada 26 do radar do Claude Code (2.1.327 → 2.1.329). Entram o grafo `radar-E3-2026-11-20-r26.kg.yaml` (20 nós),
  `data/2.1.328.txt`, `data/2.1.329.txt`, `data/judge-verdicts.json`, a `SYNTHESIS.md` e a baseline do E3 em
  `docs/onion/radar-baselines.yaml`.

## Achados

1. EXAGERA: a pergunta do delta fechava antes das omissões e citava uma SYNTHESIS que ainda não existia. Agora
   ela fecha com as omissões medidas como nós e com a SYNTHESIS gravada.
2. EXAGERA: a defasagem de quem serve misturava duas réguas (npm e CHANGELOG). Ficou só a régua do CHANGELOG:
   bridge de 3 para 5 versões, revisor de 4 para 6.
3. EXAGERA: o locator da sonda de fundo citava l.5 para o `/tasks` com uma contagem só. A linha certa é l.113.
4. EXAGERA: o nó da configuração não usada citava 2.1.328 l.6 no lugar de l.7 e deixava sem citação as linhas de
   sandbox, de `allowManagedModsOnly` e de `max_tokens`. As linhas foram corrigidas e completadas.
5. Omissão: a re-sonda do `agent_id` que o cabeçalho da guarda de espera em fundo pede. O juiz mediu a metade do
   subagente, que está verde, e ela virou nó.
6. Omissão: os campos de origem do prompt na 2.1.329 (2.1.328 l.136). Seguem iguais, sem `promptSource` novo.
   Virou nó.
7. Omissão: a bancada do `permissions.deny` na 2.1.329 (75 regras, 362 casos, 0 divergentes). Virou nó.
8. Omissão: o `effort` do Agent tool (2.1.329 l.45). Virou nó, e a afirmação do juiz de que o `effort` não sai na
   chamada foi refutada pelo transcript do coordenador (`"effort":"high"`).
9. Omissão: as tarefas agendadas que precisam ser re-agendadas (2.1.329 l.97, l.101). Foi para NÃO-VERIFICADOS.
10. Omissão: os painéis de teammate por `/bin/sh` e o lock dos teammates (2.1.329 l.102; 2.1.328 l.118). Foi para
    NÃO-VERIFICADOS.
11. Omissão: a compactação automática que reconstrói o system prompt (2.1.328 l.17). Foi para NÃO-VERIFICADOS.
12. Omissão: o diálogo de confiança que aponta onde ficam os hooks (2.1.329 l.3). Foi para NÃO-VERIFICADOS.
13. Omissão: o `/code-review` embutido. Declarada sem superfície, porque a casa usa o `/git:code-review` e o
    revisor do CI usa prompt próprio.

## Mutantes

- CU1: o juiz conferiu as duas cópias byte a byte contra o CHANGELOG oficial, sem diferença, e conferiu as linhas
  l.N citadas.
- CU2: o juiz repetiu as medições de versão, as duas famílias de deriva de binário, a contagem do settings e a do
  transcript, e os números reproduziram.
