---
branch: feat/session-hygiene-v2
pr: pendente
date: 2026-11-15
reviewed_diff_sha256: e1d00e6cfb79a81d5ef9c8324de375a7e725aa455d747422b03fb8d88f208fbc
reviewed_code_sha256: a1e07887ed1c920ca7a10c2a4267d1b5175a67bfd5250881e1c5132c98f59c7c
findings_total: 4
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 4
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "recuperação do branch perdido feat/pulse-session-hygiene (2 commits sem PR) por cherry-pick sobre origin/main, decisão do maestro 2026-11-15. Dogfood determinístico: lint-selftest.sh --families baton_pulse = 94 passaram, 0 falharam, 0 pularam, todos os mutantes (MUT) pegos — os 8 casos novos sobre /proc falso (SESSION_STOPPED, SESSION_NOT_IN_TMUX, SESSION_SAME_CHECKOUT, SESSION_CAP, HYGIENE_UNMEASURED, aviso muda o sha) reagem e cada um reprova o seu mutante. backlog regenerado pelo projetor (não editado à mão). Nenhum código de guarda/hook tocado — a mudança é no medidor baton-pulse.sh (aviso, nunca bloqueio) + doutrina + bancada. ── 2ª passada independente (revisor externo, 2026-11-16): 4 achados NÃO bloqueantes no baton-pulse.sh, todos procedentes e CURADOS neste mesmo PR: (1) SESSION_CAP contava PROCESSOS e falava «sessões» — agora dedupe por sid (retomada em dois terminais conta uma), a mensagem nomeia a grandeza, e a contagem por processo fica onde é intencional (SESSION_SAME_CHECKOUT). (2) redação de SESSION_NOT_IN_TMUX dizia «morre com o terminal (mosh, ssh)», impreciso para mosh — reescrita: fora do tmux não há como reanexar nem sobreviver a reboot/fim do processo do terminal; ssh puro cai com a conexão, mosh não. (3) o git rev-parse --show-toplevel por cwd não tinha timeout e penduraria o pulso inteiro num mount travado — teto curto (BATON_TOPLEVEL_TIMEOUT_S, padrão 5s) só nessa chamada; estouro vira LACUNA nomeada (HYGIENE_UNMEASURED), nunca «mesmo/diferente checkout» por palpite. (4) fora de repo git, duas sessões no mesmo diretório saíam SESSION_SAME_CHECKOUT com a cura --worktree inaplicável — agora não se classifica fora de git (o aviso protege a colisão de worktree git, cujo remédio é git). As três curas que mudam comportamento (1,3,4) ganharam caso novo com mutante que morde — (av) dedupe do teto, (aw) rev-parse pendurado→lacuna, (ax) fora-de-git sem mesmo-checkout; (as) atualizado para a nova mensagem/âncora. A 2 é redação. Dogfood: lint-selftest --families baton_pulse = 100 passaram, 0 falharam, 0 pularam, todos os MUT pegos."
nota: "Recuperação sem mudança de conteúdo além do rebase: o commit de resíduo antigo (passada independente pendente) foi descartado e este o substitui. O conflito único do cherry-pick foi docs/backlog.md (projeção), resolvido por regeneração, não por merge manual. Sem radar/contrato aqui: o grafo forge-baton-2026-11 recebeu o nó D_SESSION_HYGIENE_TMUX_WORKTREE_1114 via o próprio commit do feat, já conforme na origem."
---

# Recuperação: higiene de sessão no pulso da batuta (session-hygiene)

## O que muda

`baton-pulse.sh` passa a medir, por processo interativo vivo dos peers, quatro condições de higiene e a imprimir a cura como texto, sempre como **aviso, nunca bloqueio**:
- **SESSION_STOPPED** — sessão suspensa (estado T, ex. Ctrl+Z fora do tmux) que o harness ainda lista como idle → cura `kill -CONT`.
- **SESSION_NOT_IN_TMUX** — processo claude sem a chave TMUX no ambiente → cura `tmux new -s … 'claude --resume …'`.
- **SESSION_SAME_CHECKOUT** — duas sessões no mesmo checkout **git** → cura `claude --worktree`. Fora de repo git não se classifica (o remédio é git). O `rev-parse` por cwd tem teto curto; estouro vira lacuna, não palpite.
- **SESSION_CAP** — mais de 4 **sessões** interativas distintas (dedupe por sid; a retomada em dois terminais conta uma).
- **HYGIENE_UNMEASURED** — árvore de processo ilegível, ou `rev-parse` do cwd pendurado, é lacuna declarada, nunca «em tmux» nem «mesmo checkout».

## Achados

1ª passada (recuperação, 2026-11-15): nenhum — trabalho já autorado e com bancada, rebaseado sobre a main atual.

2ª passada independente (revisor externo, 2026-11-16): **4 achados não bloqueantes, todos procedentes e curados neste PR** (ver o campo `reviewer:` do frontmatter para o detalhe de cada um): dedupe do teto por sessão (1), redação do mosh (2), timeout do `rev-parse` por cwd (3) e fora-de-git sem mesmo-checkout (4). Três mudam comportamento (1,3,4) e ganharam caso novo com mutante (av, aw, ax); (as) foi atualizado. Dogfood: `lint-selftest --families baton_pulse` = 100/100, 0 falhas, todos os mutantes pegos. Cláusula 9 da baton-doctrine + nó D_SESSION_HYGIENE_TMUX_WORKTREE_1114 no grafo forge-baton.

## Limites declarados

- Lê só o stat/comm dos processos interativos dos peers e, do processo claude, só a chave TMUX do ambiente — não lê conteúdo de transcript nem segredo.
- Aviso reversível: nenhuma sessão é morta ou movida pelo pulso.
