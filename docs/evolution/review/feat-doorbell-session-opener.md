---
branch: feat/doorbell-session-opener
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 40
findings_fixed: 4
verdict: FIXED
elenxo: false
reviewer: agente de execução da sessão do core, por comando e dogfood, sem revisor independente (o brief proibiu criar agentes)
nota: "tokens 0 = não medido. A passada é do próprio autor, contra bancada com mutantes e sessões reais do Claude Code 2.1.319 no tmux."
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

## Mutantes

Cada caso, exceto o (w) do registro, tem mutante que reprova: 33 dos 34 casos, inclusive as doze
flags recusadas. Rodados `channel_session` (67 casos), `mail_hook` e `corelay_spool`.

Dogfood: sessão real sem a flag mostra o aviso; pelo abridor a tela de confirmação aparece e, depois dela, a sessão abre
com o canal e sem aviso; `claude -p` recebeu a contagem no contexto; 30 ms contra o estado real.

## Limites declarados

- Só Linux: sem procfs o aviso cala.
- Só o servidor chamado `doorbell`; canal novo entra na lista do `channel-session.py`.
- A contagem é por repo, não por sessão, e não inclui a dead-letter da fila.
- O `/resume` dentro da sessão repete o aviso, por ser outra sessão.
- A checagem de terminal do abridor é conformidade, não fronteira de segurança: um pty a satisfaz.
