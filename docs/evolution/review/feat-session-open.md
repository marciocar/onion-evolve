---
branch: feat/session-open
pr: pendente
date: 2026-11-16
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 20
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: "Voz única do core, declarada; não houve revisor separado (o PR não toca guarda: guard-paths.sh rc 1). Dogfood contra a máquina real, em modo ensaio: --list, abrir sessão cuja sessão tmux existe (anexa), abrir sessão com claude vivo fora do tmux (recusa rc 3), nome sem repo (rc 2) e --all. Três defeitos achados no uso e curados: a mensagem de erro imprimia o código de saída no texto; a lista de concessões tinha apelidos que abririam sessão num clone alheio (limpa no estado local); e sessão tmux existente escondia uma cópia fora dela (agora avisa). Grafo de espiadas: kg-radar --integrity --schema rc 0 e kg-contract-check rc 0; o censo da espiada lista o registro sem inválido."
nota: "Sem caso de bancada no lint-selftest: declarado como dívida, com gatilho (o abridor entra na bancada junto do PR de guarda que sobe o teto de sessões e troca o texto de cura do pulso). O script só abre terminal: não mata processo, não lê .env e não decide permissão."
---

# Abridor único de sessão (`ops/session-open.sh`) e a espiada que o conferiu

## O que muda

- `ops/session-open.sh <nome>`: uma sessão tmux por repo, com o nome do repo, por `tmux new-session -A` (anexa se existe, cria se não). Recusa abrir quando já há um `claude` vivo naquela pasta fora do tmux; `--list`, `--all` (depois de reboot) e `--dry-run`.
- `E_PEEK_SESSION_OPENER_TMUX_1116` no grafo de espiadas: o que a comunidade usa em novembro de 2026.

## Achados

Três, do próprio uso, todos curados (ver `reviewer`).

## Limites declarados

- Sem caso de bancada ainda.
- `--continue` retoma a conversa mais recente da pasta; para garantir a sessão certa existe `--resume <id>`.
- A espiada passou do teto de chamadas do nível (13 de 10) e subiu um nível acima da tabela, com o motivo no registro.
