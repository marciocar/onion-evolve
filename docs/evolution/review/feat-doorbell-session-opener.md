---
branch: feat/doorbell-session-opener
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 0
tokens: 0
duration_min: 40
findings_fixed: 9
verdict: FIXED
elenxo: true
reviewer: refutador da sessão do core (aprovou com cinco ressalvas, relatadas pelo condutor) e o agente de execução, por comando e dogfood
nota: "tokens 0 = não medido. Os quatro primeiros achados são da passada do autor; os cinco seguintes, do refutador, que o autor recebeu por relato e não leu no original."
---

# Passada adversarial: `feat/doorbell-session-opener`

## O que muda

Aviso único de início de sessão quando o repo tem a campainha e a sessão abriu sem o canal; abridor versionado de
lista fechada; contagem de sinais sem ack no `UserPromptSubmit`. Cabe tudo no hook e no diretório co-evolution, que
já viajam para adotados e ficam fora das portas. Em repo sem `doorbell` no `.mcp.json`, nada fala.

## Achados

1. Registro do hook no `settings.json` caiu dentro do bloco errado e ainda era JSON válido. O caso (w) pegou; refeito.
2. Interpretador na frente do argv (`node cli.js`) tiraria `bg-spare` da primeira posição. Corrigido com `own_args`,
   e a fixture usa um script real com o nome `claude`, que tem o mesmo desenho.
3. A bancada do abridor passava `''` quando chamada sem argumentos, e os casos (o) e (p) passavam pelo motivo errado.
   O mutante denunciou; corrigida a montagem dos argumentos.
4. Array vazio sob `set -u` quebra no bash 3.2 do macOS. O `exec` passou a usar a forma com `+`.
5. Refutador: no rebase sobre o #1563, o `exit 0` de um modo `prompt` mataria o outro. Agora é um bloco só, um JSON e uma
   entrada no `settings.json`. Caso (t7). O mutante Q-M12 do #1563 mudou de âncora com o bloco.
6. Refutador: a contagem aparecia também em sessão com canal, e o sinal expirado voltava em todo prompt. Casos (t4) e (t2).
7. Refutador: estado morto contava sinal cujo arquivo já saiu. Caso (t3).
8. Refutador: mutantes vivos em `st_uid != me`, `state.repo == target` e `-I -S`. Casos (j2), (t6) e (t8).
9. Refutador: `-cp x` e `--print=x` passavam por interativos, e `session_id: null` sugeria `--resume None`. Casos (d2), (d3) e (g2).

## Mutantes

Cada caso, exceto o (w) do registro, tem mutante que reprova, inclusive as doze flags recusadas. Rodados
`channel_session`, `mail_hook` e `corelay_spool`.

Dogfood: sessão real sem a flag mostra o aviso; pelo abridor a tela de confirmação aparece e, depois dela, a sessão abre
com o canal e sem aviso; `claude -p` recebeu a contagem no contexto; 30 ms contra o estado real.

## Limites declarados

- Só Linux: sem procfs o aviso cala.
- Só o servidor chamado `doorbell`; canal novo entra na lista do `channel-session.py`.
- A contagem é por repo, não por sessão, e não inclui a dead-letter da fila.
- O `/resume` dentro da sessão repete o aviso, por ser outra sessão.
- Sinal retido (held) e sinal da fila aparecem a cada prompt enquanto a sessão não tiver canal.
- A checagem de terminal do abridor é conformidade, não fronteira de segurança: um pty a satisfaz.
