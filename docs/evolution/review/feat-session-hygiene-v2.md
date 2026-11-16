---
branch: feat/session-hygiene-v2
pr: pendente
date: 2026-11-15
reviewed_diff_sha256: 996110c7d4e9ce025b1d910c0ed5e857dc13421e0b67aea6f1c8a6e427e7aec5
reviewed_code_sha256: d8716a8c9aeda902a219f8822c8c5b6a441a00bbc46ffe4c5a406980e874012a
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "recuperação do branch perdido feat/pulse-session-hygiene (2 commits sem PR) por cherry-pick sobre origin/main, decisão do maestro 2026-11-15. Dogfood determinístico: lint-selftest.sh --families baton_pulse = 94 passaram, 0 falharam, 0 pularam, todos os mutantes (MUT) pegos — os 8 casos novos sobre /proc falso (SESSION_STOPPED, SESSION_NOT_IN_TMUX, SESSION_SAME_CHECKOUT, SESSION_CAP, HYGIENE_UNMEASURED, aviso muda o sha) reagem e cada um reprova o seu mutante. backlog regenerado pelo projetor (não editado à mão). Nenhum código de guarda/hook tocado — a mudança é no medidor baton-pulse.sh (aviso, nunca bloqueio) + doutrina + bancada."
nota: "Recuperação sem mudança de conteúdo além do rebase: o commit de resíduo antigo (passada independente pendente) foi descartado e este o substitui. O conflito único do cherry-pick foi docs/backlog.md (projeção), resolvido por regeneração, não por merge manual. Sem radar/contrato aqui: o grafo forge-baton-2026-11 recebeu o nó D_SESSION_HYGIENE_TMUX_WORKTREE_1114 via o próprio commit do feat, já conforme na origem."
---

# Recuperação: higiene de sessão no pulso da batuta (session-hygiene)

## O que muda

`baton-pulse.sh` passa a medir, por processo interativo vivo dos peers, quatro condições de higiene e a imprimir a cura como texto, sempre como **aviso, nunca bloqueio**:
- **SESSION_STOPPED** — sessão suspensa (estado T, ex. Ctrl+Z fora do tmux) que o harness ainda lista como idle → cura `kill -CONT`.
- **SESSION_NOT_IN_TMUX** — processo claude sem a chave TMUX no ambiente → cura `tmux new -s … 'claude --resume …'`.
- **SESSION_SAME_CHECKOUT** — duas sessões no mesmo checkout → cura `claude --worktree`.
- **SESSION_CAP** — mais de 4 interativas.
- **HYGIENE_UNMEASURED** — árvore de processo ilegível é lacuna declarada, nunca «em tmux».

## Achados

Nenhum. Recuperação de trabalho já autorado e com bancada, rebaseado sobre a main atual; dogfood 94/94 com mutantes. Cláusula 9 da baton-doctrine + nó D_SESSION_HYGIENE_TMUX_WORKTREE_1114 no grafo forge-baton.

## Limites declarados

- Lê só o stat/comm dos processos interativos dos peers e, do processo claude, só a chave TMUX do ambiente — não lê conteúdo de transcript nem segredo.
- Aviso reversível: nenhuma sessão é morta ou movida pelo pulso.
