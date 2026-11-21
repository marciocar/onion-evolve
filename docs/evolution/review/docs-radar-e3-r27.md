---
branch: docs/radar-e3-r27
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: b72f7a599b9206c6b92222106164f6080b1661f5e7d5ebd901ca2803ca352f78
reviewed_code_sha256: 9c9702c90cd01608794a73d003690f1e88a0fd417c0148cb7724598330253432
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 174460
duration_min: 10
findings_fixed: 3
verdict: FIXED
elenxo: true
reviewer: "subagente general-purpose opus independente (não-fork), mandato REFUTAR"
nota: "tokens = só o juiz. Os 3 achados são o EXAGERA do nó do que a casa não usa (aplicado com a superação) e duas omissões que viraram nó (sonda do agent_id e nomes de modelo). Nenhum código mudou: o diff é o grafo, os dados da rodada, a SYNTHESIS, o selo do eixo E3 e as projeções."
---

# Passada adversarial: `docs/radar-e3-r27`

## O que muda

A rodada 27 do radar do Claude Code (versão 2.1.330) e o selo da baseline do eixo E3.

## Achados

Os vereditos estão em `docs/evolution/research/radar-E3-2026-11-21-r27/data/judge-verdicts.json`: 11 SUSTENTA, 1 EXAGERA e 0 REPROVA, com `judge-verdict-check.sh` rc 0 e 0 recusados.

- O EXAGERA: o nó do que a casa não usa contava o `claude -p` em disco cheio como fora de uso, mas a bancada do deny o roda com a saída num arquivo. A razão da volta do retry de `max_tokens` também estava errada. Aplicado com a superação `C_SUPERACAO_20261121_CLAUDE_P_DA_BANCADA_DO_DENY`.
- A omissão da re-sonda do `agent_id` foi medida pelo juiz e virou nó. É a 2ª rodada seguida com essa omissão.
- A omissão dos nomes de modelo (l.108) foi medida pelo juiz e virou nó.

## Mutantes

Não se aplica: nenhum código mudou.

## Limites declarados

- O Code Mode segue desligado neste host, e o efeito das correções dele não foi medido. Ele está ligado à tarefa da sonda dos vetos no Code Mode (SAC-492).
- O que ficou sem medida está em NÃO-VERIFICADOS na SYNTHESIS.
