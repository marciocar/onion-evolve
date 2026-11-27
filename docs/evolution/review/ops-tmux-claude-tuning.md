---
branch: ops/tmux-claude-tuning
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_blocking: 1
tokens: 80511
duration_min: 1
findings_fixed: 1
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "refutador isolado (subagente general-purpose sonnet, sem o contexto nem o raciocínio do autor, mandato de refutar), que carregou a config em servidores tmux de teste (-L)"
nota: "Ajuste da config do tmux da casa para o Claude Code pelo caminho medido do maestro (Windows Terminal → WSL → mosh 1.4 → tmux 3.4)."
---

# Passada adversarial: `ops/tmux-claude-tuning`

## O que muda

Em `ops/tmux/onion.tmux.conf`:
- `escape-time 10`, `focus-events on`, `extended-keys on`;
- `tmux-256color` com RGB;
- a borda de cada painel mostra o nome da sessão;
- o comentário do `automatic-rename` agora diz que a opção é de janela.

O `set-clipboard external` e o `allow-passthrough` desligado, decididos em 25/11, não mudam.

## Achados

1. **Real e bloqueante, curado.** Os dois `set -as terminal-features` novos empilhavam uma cópia a cada recarga. O refutador mediu 2 entradas e depois 4, e o instalador recarrega todo servidor vivo.

   Cura: índices fixos `[10]` para RGB e `[11]` para extkeys, a mesma convenção do `[9]` do clipboard.

   Medido depois da cura: duas cargas seguidas deixam uma entrada só em cada um dos índices 9, 10 e 11.

Também conferidos, sem achado:
- a sintaxe no tmux 3.4;
- o terminfo `tmux-256color` na VPS;
- a segurança de 25/11 intacta;
- o comentário do mosh.

## Mutantes

Não há bancada da config do tmux em `lint-selftest.sh`: nada pegaria a duplicação. O teste de idempotência foi feito à
mão (carregar duas vezes e contar). A bancada fica declarada como limite.

## Limites declarados

- Não há bancada de idempotência da config do tmux. Há uma candidata: carregar 2 vezes num servidor `-L` e comparar `terminal-features`.
- O Shift+Enter pelo mosh não foi medido no notebook do maestro.
- Num adotante sem o terminfo `tmux-256color`, o tmux avisa e a correção é `ncurses-term`. Isso não foi testado.
