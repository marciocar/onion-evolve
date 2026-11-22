---
branch: feat/sessions-statusline-1121
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 10
findings_blocking: 1
findings_fixed: 10
tokens: 0
duration_min: 60
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), somente leitura, com mandato de refutar, lançado pela sessão sobre o diff sem receber as conclusões do autor. Fez três passadas. 1ª: 1 achado bloqueante (cache plantável no tmp, que trunca arquivo e forja dados), 6 não bloqueantes e 2 de baixa prioridade. 2ª, sobre o fix: 4 corrigidos, 3 parciais e 1 novo. 3ª, sobre o fix final: NO_FINDINGS. Ficou uma observação de texto, não corrigida e declarada no corpo."
nota: "tokens 0 = não medido. Medido: a bancada sessions_statusline deu 52 passaram e 0 falharam (casos com mutantes via _prove_mutation); a guarda-da-guarda pegou dois mutantes com âncora caduca, e ambos foram corrigidos. A linha rodou ao vivo contra claude agents --json (CC 2.1.330), rc 0. A oferta rodou ao vivo no core: resolveu o checkout principal a partir da worktree. Depois da 3ª passada, só a FORMA de duas linhas do adopt.md mudou (a cópia do settings e o passo 6c viraram uma linha cada), para caber nas 800 linhas da REGRA 5 (Limites de linhas); a semântica é idêntica e o bloco if/else passa no bash -n."
---

# Passada adversarial: `feat/sessions-statusline-1121`

O que este PR leva ao framework: a linha de status `sessões: N trabalhando · M esperam você · ← claude agents`
(`.claude/utils/statusline/onion-sessions-line`), a oferta somente leitura do `/meta:adopt`
(`.claude/utils/adopt/offer-statusline.sh`, passo 6c) e o aviso no `merge-onion-hooks.sh` quando o alvo já tem
statusLine. Ele vem acompanhado da família de bancada `sessions_statusline`.

## Decisão do core que o revisor recebeu como requisito

O adopt **nunca escreve** statusLine no projeto. Os motivos estão abaixo e os detalhes no cabeçalho do helper.
- A statusLine não se mescla entre camadas: a do projeto substitui, sem aviso, a que cada pessoa usa.
- A oferta é para o settings do **usuário**, com o caminho absoluto do checkout principal resolvido pelo git.
- Projeto que já tem statusLine é detectado e recebe um aviso.

## Achados e destino

| # | Achado | Severidade | Destino |
|---|---|---|---|
| 1 | Pasta do cache com nome fixo no tmp: outro usuário planta a pasta, trunca arquivo por symlink na trava e forja a contagem | bloqueante | corrigido: uid no nome, `lstat` (diretório, dono, 0700), trava com `O_NOFOLLOW` e sem truncar; casos (r) e (s) |
| 2 | Mtime no futuro congelava a contagem sem aviso | não bloqueante | corrigido em duas passadas: com claude, relê (t); sem claude, sai o rótulo «data no futuro» (t2) |
| 3 | Estado desconhecido sumia num zero, e um campo conhecido mascarava o outro | não bloqueante | corrigido: `N em estado desconhecido`, contado por `status` OU `state`; casos (u) e (u2) |
| 4 | A oferta dizia «já ligada» para um caminho que não existia mais | não bloqueante | corrigido: confere o arquivo; caso (n2) |
| 5 | Sem HOME a oferta morria em `unbound variable`; em repo bare ela não avisava | não bloqueante | corrigido: aviso «NÃO medi» (n3) e NOTE de repo bare |
| 6 | O caso (i) passava por vacuidade | não bloqueante | corrigido: mutante com fallback de home |
| 7 | A cópia do settings no adopt levaria a statusLine da fonte | não bloqueante | corrigido: `jq del(.statusLine)` e, sem jq, aviso no stderr. Segue latente, porque o core não tem statusLine |
| 8 | Contas diferentes (`CLAUDE_CONFIG_DIR`) dividiam o cache | baixa | corrigido: hash da conta no nome da pasta |
| 9 | Locale sem UTF-8 podia fazer o tratador de erro lançar exceção | baixa | corrigido no código (`reconfigure(errors="replace")` e print protegido); não medido, porque a máquina não tem locale sem UTF-8 |
| 10 | Caminho relativo dado como «já ligada» | não bloqueante (2ª passada) | corrigido: aviso «caminho RELATIVO» e nova oferta; caso (n4) |
| 11 | Um command com `~/…` cai no aviso de caminho relativo (o shell expande o til) | observação de texto | **não corrigido, declarado**: o bloco é oferecido de novo e não há dano. Cura de uma linha (`os.path.expanduser`) para um PR seguinte |

## O que não foi verificado

- Locale sem UTF-8 e Python anterior ao 3.15.
- Pasta plantada por outro uid de verdade: foi simulada com o modo e com symlink.
- Trava sob concorrência real.
- Sessão background que estivesse trabalhando de fato, cujo formato de `state` não foi visto.
