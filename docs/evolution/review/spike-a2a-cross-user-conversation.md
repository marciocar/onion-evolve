---
title: 'Resíduo — spike A2A cross-user: protocolo pré-registrado, cura do anti-replay e membro de teste pinado'
date: 2026-10-14
branch: spike/a2a-cross-user-conversation
reviewed_diff_sha256: 7cac171ff8fd48dee3ae2b7de013931e91fd565db2ba479c3686714341b9f318
reviewed_code_sha256: de360a1c96e03640be1b3775abcc384cd9a745492839d8dd307e7452b37f2886
findings_total: 11
findings_real: 8
findings_fixed: 8
tokens: 101127
duration_min: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Um refutador (code-reviewer) passou o diff inteiro antes do PR. Achou 11 coisas, 8 reais e todas
  curadas: a pior foi PRÉ-EXISTENTE e estava em produção (a corrida de replay do a2a-verify, medida
  depois em 8/8 envios simultâneos verificados com o gate de origin/main). As outras 7 eram do receptor
  do spike, que eu escrevi. Os 3 restantes eram confirmações (a bancada correta, o estado de produção
  gravável, o --dry-run gravando jti, pré-existente e sem consumidor afetado).
---

# O refutador achou no gate de produção o furo que o spike existia para medir

## O que entrou

- O **protocolo pré-registrado** do spike, em `docs/evolution/research/a2a-cross-user-spike-2026-10/SPIKE-PROTOCOL.md`,
  com os cenários A1–A8, os critérios fixados antes, os passos do maestro e o MOAT.
- Os **artefatos**: o remetente e a retirada do notebook, o receptor com amarração do corpo na VPS e o
  channel MCP de teste sem permission relay.
- O **membro de teste** `maestro-notebook-test`, com a pública pinada. Mergear este PR é o ato humano
  que estabelece a confiança.
- A **cura do anti-replay** no `a2a-verify.sh`, nos dois furos (veja abaixo).
- O **grafo do spike**, com a emenda à RFC-0004 como decisão aberta (`D_RFC0004_CONVERSA_POR_THREAD`),
  e um ponteiro na própria RFC.

## Os achados e o destino de cada um

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | corrida check→gravação do `jti` no `a2a-verify` (pré-existente) | importante → **o pior** | curado: contagem == 1 depois do append. Medido em `origin/main`: 8/8 verificados em 5/5 rodadas; com a cura, ≤ 1. Entrou um caso de corrida na bancada |
| 2 | corpo em caminho fixo no receptor (corpo de B com o meta de A) | importante | curado: `mktemp` por invocação + `flock` no dedupe/entrega |
| 3 | o lease filtrava por campo NÃO assinado e não repassava o filtro | importante | curado: `--expect-from`/`--expect-thread` conferidos contra os claims assinados |
| 4 | a re-verificação não conferia de quem é a chave, nem o `exp` | importante | curado: kid-binding por `members.yaml` + `exp` obrigatório. Ensaio: kid órfão RECUSADO, sem `exp` RECUSADO |
| 5 | `exp` ausente passava no `fetch-replies.sh` | menor | curado: `sem-exp` reprova |
| 6 | nome remoto virava caminho antes da validação; `for $(…)` | menor | curado |
| 7 | "8192 bytes", quando conta caracteres | menor | texto corrigido |
| 8 | a recusa de boot do channel é estática e o cabeçalho prometia mais | menor | cabeçalho corrigido; a prova dinâmica é o A8e |
| 9 | bancada nova correta | — | confirmação |
| 10 | produção gravável sob `ProtectHome` | — | confirmação: eu li o drop-in (`ReadWritePaths=/home/onion`) |
| 11 | `--dry-run` grava `jti` no sucesso | — | pré-existente, sem consumidor afetado; não mexi |

## O que a passada NÃO cobriu (declarado)

- O caminho vivo HTTP → gate → fila com o membro de teste **não rodou**: falta o token do pool (P2,
  maestro). Os negativos rodaram contra uma réplica byte-idêntica do gate servido (§8b do protocolo).
- O channel foi exercitado num smoke **offline** (eu no papel do Claude Code no stdio). A
  sessão interativa com a flag de dev não foi exercitada.
- Este resíduo é de **uma** passada, e o refutador do adotante de curadoria ainda não leu o
  protocolo. Esse é o gate antes do P1 vivo.
