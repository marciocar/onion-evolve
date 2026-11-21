---
branch: feat/house-gloss-commit-and-signals-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: 51de902cf5e53730a825eda40a557cd4d922ff4d9b1ac3a47cf664ce6eb2716d
reviewed_code_sha256: af06be4129392d60899964b13ab91c98bb3ad641d77c48928f84793e383a0e70
findings_total: 5
findings_real: 5
findings_blocking: 2
tokens: 93289
duration_min: 7
findings_fixed: 2
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: code-reviewer (agente separado e isolado; brief com o código, sem a conclusão do autor)
nota: >-
  Um refutador isolado rodou a bancada, montou commits reais (repo de teste, worktree com hooksPath
  absoluto, porta simulada) e varreu 150 commits da origin/main (12 lembretes, todos siglas reais sem
  glosa; nenhum falso positivo visto). Achou 2 bloqueios, ambos de contrato e curados: o caso de registro
  reprovava na porta onion-core (papel source, sem .githooks/), e o cabeçalho prometia "sai 0 sempre"
  ignorando a falha fechada do trampolim comum. Os 3 limites são do git e ficaram declarados no
  cabeçalho do .githooks/commit-msg.
---

# Passada adversarial: a glosa de sigla chega ao commit e aos sinais entre sessões

## O que muda

- `.githooks/commit-msg` novo chama `.claude/hooks/house-code-gloss.sh commit-msg <arquivo>`: julga a
  prosa do assunto e do corpo (sem comentário do git, sem o diff da tesoura, sem o prefixo Conventional,
  sem o bloco final de trailers e a assinatura) e lembra a glosa no stderr. Nunca barra.
- O modo `tool` do mesmo hook passa a ler o `.md` escrito por Write/Edit em `docs/evolution/inbox/` e
  `docs/evolution/federation/outbox/` (menos o README).
- A bancada do hook ganha t12, t13 e c1 a c6; a lint-selftest ganha o caso (reg-commit).
- Origem: item C1 da régua de Linguagem Simples por superfície, decisão `D_PLAIN_LANGUAGE_STITCH_1121`.

## Achados

| # | achado | triagem | destino |
|---|---|---|---|
| 1 | (reg-commit) reprovava na porta onion-core, que tem papel `source` e não leva `.githooks/` | bloqueia | curado: pula quando não há `.githooks/` |
| 2 | cabeçalho dizia "sai 0 sempre", mas o trampolim comum falha fechado com bit perdido e hooksPath absoluto | bloqueia | curado: o cabeçalho declara a exceção |
| 3 | no `-m`/`-F` a linha com `#` entra no commit e o hook não a julga | limite | declarado no cabeçalho |
| 4 | parágrafo final todo em `Chave: valor` vira trailer e sai do julgamento | limite | declarado no cabeçalho |
| 5 | com commentChar `auto` ou de vários caracteres, o hook usa `#` | limite | declarado no cabeçalho |

Também curado, das melhorias opcionais: a bancada e o (reg-commit) passam `</dev/null` ao motor (um
mutante que perde o modo commit-msg travava lendo o stdin) e o caso binário da c6 grava os bytes por
`printf`, sem o corte do bash no NUL.

## Mutantes

Harness numa cópia de `.claude/hooks` + glossário, com a cópia limpa provada antes (rc 0, 0 falhas).
**11 de 11 mortos**, cada um pelo caso-alvo: M1 sem o SIGNAL (t12) · M2 comentário do git vira prosa
(c3) · M3 tesoura ignorada (c3) · M4 trailer mantido (c3) · M5 trailer por `any` (c4) · M6 prefixo
Conventional mantido (c3) · M7 commentChar ignorado (c5) · M8 README da caixa lido (t12) · M9 caixa por
prefixo `inboxes/` (t13) · M10 modo commit nunca lembra (c1) · M11 dispatch do commit-msg some (c1).

## Limites declarados

- Sinal escrito por Bash (o carteiro co-relay/co-deliver copia o arquivo) não é lido pelo modo tool.
- Os três limites do git da tabela acima (itens 3 a 5).
- O lembrete do commit chega depois de o commit existir; a cura é o `--amend`, e um `--no-verify` pula o
  hook junto com o pre-commit.
