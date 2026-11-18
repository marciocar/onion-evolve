---
branch: fix/hookspath-auto-revert-1118
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: de04c59b48ac5a0915c25dc9b9963fd2b109eb348f9f1d6db34134b98fc34dcd
reviewed_code_sha256: 145edd58728418a18b07e80659363923891d46ca3257c36da7c3b87ce784d421
findings_total: 5
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 25
findings_fixed: 1
verdict: APPROVED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, teto de 25 minutos, mandato de refutar: JSON do PostToolUse, nome do matcher, reversão contra configuração legítima e bancada. Veredito APPROVED. Uma 1ª revisão separada foi encerrada pela sessão do core por silêncio; o transcript mostrou depois que ela tinha entregado e a mensagem se perdeu no caminho."
nota: "tokens 0 = não medido (o harness não devolveu o custo do revisor); duration_min é o teto da revisão."
---

# Passada adversarial: `fix/hookspath-auto-revert-1118`

## O que muda

O Claude Code grava `core.hooksPath` em forma absoluta no `.git/config` comum ao criar worktree de agente
(anthropics/claude-code#85039 e #88747, abertas). A guarda `session-currency-check.sh` só avisava; agora reverte
sozinha para `.githooks` quando o valor é exatamente `<raiz do checkout principal>/.githooks` em escopo local, relê o
valor e, se não ficou relativo, volta ao aviso. O mesmo reparo roda num PostToolUse com matcher `Agent`
(`--hookspath-only`, 5 s). Qualquer outro absoluto segue só avisando ou em silêncio. Bancada `hookspath_reminder`
reescrita (21 casos, mutante da reversão morto).

## A passada

Medido pelo revisor, em `mktemp -d`: worktree com o absoluto exato reverte e devolve JSON válido; raiz por link
simbólico não reverte e avisa; `core.hooksPath` global não é tocado; `config.lock` de outra sessão faz a escrita
falhar, sai o aviso e o valor fica intacto; stdin vazio reverte com rc 0. A família `hookspath_reminder` passou
21 de 21, sem pular, com a árvore intacta. O matcher `Agent` é o nome atual da ferramenta (o binário do 2.1.326 traz
`Agent` e o legado `Task`); o formato `hookSpecificOutput`/`additionalContext` é o dos outros hooks da casa; o rc é
sempre 0, então nunca bloqueia a chamada de Agent.

## Achados e destino

- **(médio, limite de desenho, curado na doc):** o PostToolUse dispara quando a ferramenta RETORNA; com agente em
  primeiro plano isso só acontece ao fim dele, e até lá o pre-commit da worktree dele ainda roda o `.githooks` do
  checkout principal. Declarado no comentário do hook.
- **(baixo, declarado):** o escape do JSON trata `\`, `"`, `\n` e `\t`; outro caractere de controle num valor exótico
  geraria JSON inválido, que o harness descarta sem travar. A casa já usa `json.dumps` noutro hook; fica para
  alinhar depois.
- **(baixo, declarado):** com `config.lock` de outra sessão sai o aviso «ABSOLUTO» mesmo que a outra já tenha
  revertido em seguida.
- **(info):** primeiro matcher `Agent` da casa; formato e rc conferidos.
- **(info, não medido):** `include.path` não foi testado (a guarda de pré-uso da casa barrou o teste do revisor); pela
  leitura, a releitura do valor depois de gravar pega o caso em que o incluído vence.
