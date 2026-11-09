---
branch: fix/doorbell-expired-core-half
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_blocking: 0
tokens: 0
duration_min: 25
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução (passada própria, não independente; o brief proibiu criar agentes)"
nota: "tokens 0 = não medido. Família mail_hook 24/0, com 5 mutantes mortos; hooks_python_isolated verde depois de tirar o shebang do leitor."
---

# Passada adversarial: `fix/doorbell-expired-core-half`

## O que muda

- Leitor `.claude/utils/co-evolution/doorbell-state.py`: acha o estado da campainha como o `server.ts` e conta o
  que está sem ack (expirado, retido), só para arquivo que segue na caixa.
- O hook de início de sessão marca os expirados (`🔕`). O arquivo segue no `📬`/`📥`: nada sai da contagem.
- `kg-radar.sh --doorbell` lista expirados e retidos, e diz NÃO VERIFICADO sem estado. No `--all` só fala quando há o que cobrar.

## Achados

| # | Achado | Veredito | Destino |
|---|---|---|---|
| 1 | shebang `python3` sem `-I` no leitor reprovava `hooks-python-isolated` | real | curado: sem shebang, invocado por `python3 -I -S -B` |
| 2 | o nome do sinal é escolhido por quem escreve, e o hook monta JSON com `printf` | real | curado por desenho: no hook só entram contagens; o radar imprime o caminho já filtrado pelo alfabeto do doorbell |
| 3 | o estado envelhece sem a campainha rodando: sinal já tratado seguiria cobrado | real | curado: só conta se o arquivo segue lá (caso e mutante) |
| 4 | retido nunca expira e por isso nunca seria cobrado | real | o radar cobra junto; o hook não, pois o retido já está no `📬` |
| 5 | o estado é por caminho de repo: numa worktree o leitor vê "sem estado" | limite | declarado; a campainha também é por caminho |

## Teto

- O prazo é o teto de avisos da própria campainha. Não há prazo calibrado além dele.
- Processo antigo da campainha não grava `expired_at`: no estado real deste repo, em 09/11, há um sinal com 4
  avisos e sem `expired_at` (leitor: `expired=0 unacked=1`). O sinal segue no `📬`.
- Não medido contra sinal realmente expirado na máquina: nenhum existe hoje. A bancada grava o estado no formato do `server.ts`.
