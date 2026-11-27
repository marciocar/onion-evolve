---
branch: ops/ticketai-vhost
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: ec7ef25f4b7fd2706fb6aa03a2b68a9332114213f859bf5774f46572ff0a3b01
reviewed_code_sha256: c996004462c7869edc791ff133e316ed20972952c6a706bc8bdab9b32f40d1b6
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 79622
duration_min: 2
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: true
reviewer: "refutador isolado (subagente general-purpose sonnet, sem o contexto nem o raciocínio do autor, mandato de refutar), que rodou o --plan e o --selftest do instalador"
nota: "Uma linha no ops/caddy/service-vhosts.tsv: o vhost do TicketAi. DNS e deploy autorizados pelo maestro em 27/11; a instalação espera a 1ª subida do app."
---

# Passada adversarial: `ops/ticketai-vhost`

## O que muda

Entra uma linha em `ops/caddy/service-vhosts.tsv`. O vhost `ticket.onionevolve.com` passa a vir de
`caddy/ticketai.caddy` do repo `marciocar/ticket-ai`, em `origin/main`, e o upstream fica limitado a `127.0.0.1:3070`.

## Achados

Nenhum. O refutador isolado conferiu cinco pontos:
- as 6 colunas, separadas por TAB, no molde do cabeçalho;
- o blob do repo usa só o host e o upstream permitidos;
- `install-caddy-config.sh --plan` deu rc 0 e criaria `conf.d/ticketai.caddy`, com o `caddy validate` do estágio verde e o vivo intacto;
- `--selftest` deu 68 pass e 0 fail;
- o vhost não expõe nada além do app: sem file_server, sem caminho admin, sem :2019.

## Mutantes

Não se aplica: a mudança é de dado. O instalador que a lê tem a bancada própria (`--selftest`, 68 casos).

## Limites declarados

O plano também mostra duas pendências anteriores a este PR, que entram na mesma instalação: o Caddyfile
«SUBSTITUÍDO» e o `hooks.caddy` «CRIAR». A instalação real fica para depois da 1ª subida do app e começa por
`git -C ~/ticket-ai fetch`, porque o script lê o blob do clone local.
