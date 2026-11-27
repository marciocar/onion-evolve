---
branch: chore/ticket-ai-remote-marciocar
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 85009
duration_min: 1
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "subagente general-purpose isolado (sonnet), só leitura, sem o contexto da conversa, com mandato de refutar"
nota: "Uma linha do members.yaml: o remote do ticket-ai segue a transferência do repo para marciocar, decidida pelo maestro em 27/11."
---

# Passada adversarial: `chore/ticket-ai-remote-marciocar`

## O que muda

Muda uma linha de `docs/evolution/federation/members.yaml`: o `remote:` do membro `ticket-ai` passa a ser
`github.com/marciocar/ticket-ai`. O repo foi transferido de `marcio-granaai` em 27/11, por decisão do maestro. A
decisão evita uma exceção na guarda: a sessão dona faz os próprios merges pelo caminho verificado.

## Achados

Nenhum bloqueante. O revisor isolado conferiu cinco pontos:
- a transferência é real (`gh repo view marciocar/ticket-ai`: privado, com esse nome);
- `members-validate.sh` dá rc 0, com 42 membros;
- o `ops/pr-merge-verified.sh` casa o repo por slug exato com o `remote:` e exige o mesmo dono do core, então passa a aceitar o merge da sessão dona `ticket-ai`;
- a mudança não abre permissão além desse repo: só um membro tem essa `owner_session`, e o `kind` segue `adopter`;
- o diff não traz dado privado novo.

## Mutantes

Não se aplica: o diff é de dado de registro. A catraca que o lê (`pr-merge-verified.sh`) não muda e já tem bancada
própria (`pr_merge_verified`).

## Limites declarados

O repo só vira alvo aceito do caminho verificado depois que este PR entrar em `origin/main`, porque a catraca lê o
registro de lá.
