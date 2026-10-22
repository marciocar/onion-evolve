---
branch: fix/a2a-spike-fetch-replies-member
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 8
tokens: 80480
duration_min: 5
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: code-reviewer
nota: >-
  Um refutador (code-reviewer, contexto limpo) leu o diff inteiro, rodou o selftest e conferiu as
  citações de linha em origin/main. Achou 11 itens: 8 reais (4 importantes, 2 menores, 2 cosméticos) e
  3 confirmações. O mais grave era de segurança: o --sent-tsv novo expunha entre usuários uma injeção
  já existente no $(( )) do rtt. Todos os 8 foram curados no código ou na Emenda 12.14.
---

# Passada adversarial: `fix/a2a-spike-fetch-replies-member`

## O que muda

- `notebook/fetch-replies.sh` ganha `--me ID` (env `A2A_SPIKE_ME`) e `--sent-tsv F`, com os defaults
  de antes (`maestro-notebook-test` e o `sent.tsv` da própria home). Flag de valor sem o valor sai com
  rc 2. O `t_send` lido do `sent.tsv` só passa se for só dígitos.
- `notebook/fetch-replies.selftest.sh` (NOVO, offline): chave RSA descartável, ack e reply sintéticos
  assinados como o `signedEnvelope` do channel, e uma HOME nova por caso. Resultado: 15/15.
- `SPIKE-PROTOCOL.md` §12.14 (degrau B, 2026-10-22), com o que o maestro selou e o critério do A7-C1
  pré-registrado.
- No grafo do spike: `D_DEGRAU_B_A7_ANTES_DO_A8_COM_FOTO_LIMPA_1022` e
  `D_DEGRAU_B_SEM_B0_NEM_C2_HOJE_1022`, as duas pelo `kg-decide-seal.sh`, e
  `E_DEGRAU_B_VOLTA_TINHA_DOIS_BLOQUEIOS_1022`. O radar `--integrity --schema` sai 0 e o contrato
  sai conforme.

## Achados

| # | sev. | achado | destino |
|---|---|---|---|
| 1 | importante (segurança) | o `t_send` do `sent.tsv` entrava cru em `$(( t_recv - t_send ))`. Com `--sent-tsv` apontando para o arquivo do `a2a-peer`, quem escreve esse arquivo executava código como `marciocar`. Medido aqui em bash 5.2.21: `t_recv[$(touch X)]` cria X. O `a[$(…)]` do refutador morre no `set -u` antes do índice, mas um nome definido executa | curado: `case "${t_send}" in *[!0-9]*) t_send="" ;; esac` vira `in_reply_to-desconhecido`; caso no selftest e mutante |
| 2 | importante | a 12.14 não dizia onde a receptora roda. No checkout do core, o `--assert-clean --strict` sai sempre CONTAMINADO (Read/Grep/Glob sem escopo) | curado na emenda: sandbox (§12.2, §12.11), fotos com `--project <sandbox>`, `--plant` antes da 1ª réplica do A7-C1, `--restore` só depois do A8 |
| 3 | importante | o "legível por permissão" se desfaz: o `send-a2a.sh` dá `chmod 700` no diretório de estado a cada envio (l.84) | curado na emenda: só cópia, depois de cada envio |
| 4 | importante | o `recv.tsv` só acresce e guarda o ensaio de 14/10. Um envelope antigo no outbox faria rc 1 na réplica 1 | curado na emenda: mediana filtrada pelos 5 jtis, e um fetch sem `--watch` drena o outbox antes da réplica 1 |
| 5 | menor | `--me` ou `--sent-tsv` como último argumento dava "unbound variable" (rc 1, que se confunde com "envelope reprovou") | curado: checagem de valor antes do `case` (rc 2); caso no selftest |
| 6 | menor | "sem ack em 300 s" não batia com o `--timeout`, que espera pela reply | curado na emenda: rc 3 sem ack = perda; rc 3 com ack = NÃO PASSOU |
| 7 | cosmético | ordem `--assert-clean` antes do `--label` (o `--assert-clean L` lê a foto L) | curado na emenda: `--label …-before` e depois `--assert-clean …-before --strict` |
| 8 | cosmético | o caso "sem --sent-tsv" testava arquivo ausente, não um `sent.tsv` existente com outro jti | curado: a HOME de cada caso nasce com um `sent.tsv` de outro jti; o caso de arquivo ilegível ficou separado |
| 9 | confirmação | o sintético bate campo a campo com o `signedEnvelope` (`a2a-channel.ts` l.93-100). O fetch não confere o nome do arquivo nem o prefixo do jti | — |
| 10 | confirmação | as citações batem em `origin/main` 46f733b5: l.26, l.87, `send-a2a.sh` l.132, 0 `sent.tsv` no `a2a-send.sh`, as saídas `http=`, `push http`, `DADO` e `TIMEOUT=300` | — |
| 11 | confirmação | grafo íntegro (radar e contrato) | — |

## Mutantes

O selftest faz mutate-and-restore no próprio `fetch-replies.sh`, e um sha256 conferido no fim prova a
restauração (`trap` também restaura em qualquer saída):

- **`--me` ignorado** (`--me) shift 2 ;;`): o caso ok reprova com rc 1 e `[aud-errado] reply`. Prova
  que o caso ok morde o `--me`;
- **`--sent-tsv` ignorado**: o caso ok reprova com rc 1 e `[in_reply_to-desconhecido] reply`, porque
  a HOME tem um `sent.tsv` com outro jti;
- **`t_send` sem validação**: o `sent.tsv` com `t_recv[$(touch PWNED)]` **cria** o arquivo-prova.
  Prova que o caso da injeção morde. A 1ª versão do caso usava `a[$(…)]` e o mutante não executou,
  porque o `set -u` mata antes do índice. O mutante achou o caso fraco, e o caso foi corrigido.

## Limites declarados

- NÃO MEDIDO: o fetch vivo por ssh contra o outbox real da VPS com as flags novas; a cópia do
  `sent.tsv` entre os dois usuários do notebook; o desvio N−V de hoje.
- Achado fora do diff, declarado na 12.14 e não curado aqui: `vps/accept-to-channel.selftest.sh` dá
  9/12 em `origin/main`. O registro sintético dele não tem `receivedAt`, e o `a2a-accept.sh` passou a
  reverificar contra a raiz de confiança do repo (e97fe410). Acrescentar o `receivedAt` troca o veto
  para `trust-denied`. Isso bloqueia o P3b (12/12) do §12.11.
- O selftest não está na bancada (`lint-selftest.sh`). Não há família do spike lá: o único ponto é o
  caso (k) da família `a2a_verify`, que exercita o `send-a2a.sh`. Os outros dois selftests do spike
  também ficam fora dela.
