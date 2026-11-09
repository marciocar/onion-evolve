---
branch: fix/doorbell-expired-core-half
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: 2fa132b8a6b9cd2ef17011ddb3d7d6294f22e1b1f830b7332c28aeb0a7ebf49a
reviewed_code_sha256: 529396dfb1d52c8615544a1577dfa338d9d51fb2c04c95cd274ad9aba4a38fd5
findings_total: 6
findings_real: 6
findings_blocking: 0
tokens: 0
duration_min: 25
findings_fixed: 4
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução (passada própria, não independente; o brief proibiu criar agentes)"
nota: "tokens 0 = não medido. Famílias mail_hook e assemble_plugin 38/0, com 5 mutantes mortos; hooks_python_isolated verde depois de tirar o shebang do leitor."
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
| 6 | o `kg-radar.sh` viaja no plugin de design, e o caminho `.claude/utils/` dentro dele reprovava `assemble_plugin` no CI (13/1 local) | real | curado: o leitor é achado a partir do próprio radar; no plugin, NÃO VERIFICADO. Re-revisado a cada rebase: o hook da main ganhou o modo `prompt` e o aviso do canal, e o marcador 🔕 segue no mesmo `msg` (mail_hook 24/0) |

## Teto

- O prazo é o teto de avisos da própria campainha. Não há prazo calibrado além dele.
- Processo antigo da campainha não grava `expired_at`: no estado real deste repo, em 09/11, há um sinal com 4
  avisos e sem `expired_at` (leitor: `expired=0 unacked=1`). O sinal segue no `📬`.
- Não medido contra sinal realmente expirado na máquina: nenhum existe hoje. A bancada grava o estado no formato do `server.ts`.
