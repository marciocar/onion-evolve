---
branch: research/radar-e3-r19
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: fced7806df08f54ca611efc2e80b7cd95c11dddc6b4da23cd559e5b1a5e68c01
reviewed_code_sha256: 5464927843353a0d3ee511cf7f4c63bc2af2fc63416453136e19b020dbe52ea9
findings_total: 7
findings_real: 7
tokens: 213361
duration_min: 30
findings_fixed: 7
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente general-purpose opus independente (não-fork, effort high), mandato REFUTAR"
nota: "tokens = só o juiz (medidos pelo harness); os da rodada não ficaram expostos. Os 7 achados são 3 vereditos negativos sobre nós e 4 omissões. Os 3 nós foram reescritos; das omissões, 2 viraram nó (InstructionsLoaded e extensão do VS Code, esta com pergunta e issue) e 2 foram absorvidas em nós existentes; cada superação virou nó C_SUPERACAO_20261026_*"
---

# Passada adversarial: `research/radar-e3-r19`

## O que muda

- Rodada 19 do radar do Claude Code: grafo `radar-E3-2026-10-26-r19.kg.yaml` (24 nós), `data/2.1.311.txt`,
  `data/judge-verdicts.json`, `SYNTHESIS.md` e a baseline do E3 em `docs/onion/radar-baselines.yaml`.

## Achados

1. EXAGERA: a prova do `resume` do bridge vinha do clone de desenvolvimento (SDK 0.3.232, `src/chat.ts` linha 491).
   Reescrito com a âncora do servido (`src/chat-query-options.ts` linha 84), re-medida como a conta do serviço.
2. EXAGERA: o maior item de lista do CLAUDE.md foi contado sem o aninhamento (1.391 caracteres). Reescrito com as
   duas contagens (1.391 e 4.969).
3. EXAGERA: eram dois agentes com MCP declarado no frontmatter, não três. Reescrito, com o general-purpose como a
   superfície mais exercitada.
4. Omissão: o InstructionsLoaded registra `load_reason=compact` e é o instrumento da linha 10. Virou nó.
5. Omissão: a extensão do VS Code do host roda 2.1.306 e o censo não a mede. Virou nó, pergunta e a SAC-260.
6. Omissão: Remote Control ligado no host (linhas 20 a 22). Absorvida no nó de agent teams.
7. Omissão: a sonda `background-task-probe.sh` lê o mesmo texto da linha 58. Absorvida no nó do timeout.

## Mutantes

- CU1: o juiz fez `cmp` da cópia contra o CHANGELOG baixado, sem diferença.
- Guarda de modelo: o mesmo hook, com o mesmo JSON, decide `allow` para claude-opus-5-5 e `block` para
  claude-sonnet-5-5 e claude-haiku-5-5, com e sem `[1m]`: o caso que reprova existe, e o sufixo não o muda.
- Timeout do Bash: o comando de 9 s sob teto de 3 s foi ao fundo com a saída parcial; o PostToolUse calou.

## Limites declarados

- Nada foi subido: SDK do bridge e pin do revisor ficam para a SAC-259 (deploy do maestro, repo alheio).
- Os tokens da rodada não foram medidos; só os do juiz.
- Nenhuma compactação foi registrada na 2.1.311, então a linha 10 segue sem efeito medido.
