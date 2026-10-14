---
title: 'Resíduo — o corpo entra na assinatura do a2a-verify e o exp fica obrigatório'
date: 2026-10-14
branch: fix/a2a-body-signed-and-exp-required
reviewed_diff_sha256: 9885a8e929ae1923c1102c4b7d530b08d7297aaac16b1e588404e20ea11e73a1
reviewed_code_sha256: 451d0b569450ffb480187a873d26b31bbc8e3f959cbb312b73a09130bccbce19
findings_total: 19
findings_real: 15
findings_fixed: 12
tokens: 153344
duration_min: 13
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Um refutador (code-reviewer) passou o diff inteiro antes do PR, com harness próprio em sandbox (chave
  RSA gerada ali, o bridge simulado com JSON.parse/stringify do node). Achou 11 coisas: nenhum
  bloqueador, 7 reais (2 importantes, 5 menores) e 4 confirmações. 5 curadas neste PR; a maleabilidade
  com surrogate solitário foi declarada; o trust-log gravado antes do veto é anterior ao PR e ficou
  declarado.
---

# O corpo assinado fecha o conteúdo, e o refutador mostrou que a etiqueta ainda estava aberta

## O que entrou

- **Corpo na assinatura.** O claim `body_sha256` passa a ser obrigatório no payload do JWS e é conferido
  contra o sha256 dos bytes UTF-8 da string `signal.body` já decodificada (ausente = vazio). Remetente sem
  o claim é recusado (`jws-missing-body-sha256`), sem modo legado.
- **`exp` e `iat` obrigatórios**, inteiros, com teto de vida de 3600 s nas duas formas (`exp − iat` e
  `exp − now`).
- `body_path` e `thread` do signal têm de bater com os claims. Chave JSON duplicada veta.
- Bancada: casos e mutantes na família `a2a_verify` (50/50), incluindo o envelope real do
  `send-a2a.sh` do spike.

## As três perguntas obrigatórias

1. **Canonicalização divergente entre remetente e gate gera falso `body-mismatch`?** Não. O refutador
   testou 17 corpos, direto e via bridge simulado, e todos verificaram: ascii, `\n` final, CRLF, `é`
   escapado e literal, NFD, emoji por par de surrogates e literal, BOM dentro do corpo, U+2028, NUL,
   caracteres de controle, `\/`, 8 KB e 200 KB. O canônico é a string decodificada, então a forma de
   escape não entra no hash. A exceção é um surrogate alto solitário, que vira `malformed-envelope`:
   é veto, não falso mismatch.
2. **Corpo vazio passa?** Sim, quando o remetente assinou o vazio (claim = sha256 de ""), com `body`
   ausente ou `""`. Não é furo: acrescentar corpo depois dá `body-mismatch` (caso da bancada), e tirar
   um corpo não-vazio muda o hash. O furo que sobrava estava nos campos NÃO assinados (achado 1, curado).
3. **Um `body_sha256` duplicado no payload engana o gate?** Não. Os bytes assinados chegam intactos ao
   python, que veta `duplicate-key:jws-payload` (caso e mutante). No envelope, o python também veta
   quando o duplicado chega direto ao gate. Via bridge, o `JSON.parse` fica com o último valor e o jq
   também, e o registro que o bridge grava tem o mesmo corpo cujo hash foi conferido.

## Os achados e o destino de cada um

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | `kind`/`id`/`classification` não assinados chegavam ao frontmatter do inbox pelo `a2a-accept` (injeção de YAML num sinal verificado) | importante (anterior ao PR) | curado: forma fechada 1–128 de `[A-Za-z0-9._:-]` (`signal-field-unsafe`) e chave desconhecida no signal veta (`signal-unknown-key`). Caso e mutante |
| 2 | 4 linhas load-bearing sem caso (`exp-not-after-iat`, `signal-body-sha256-mismatch`, `claim-thread-mismatch`, `body-not-string`) | importante | curado: caso e mutante para as quatro |
| 3 | `body_sha256` com `\n` final era aceito (`$(...)` + `grep -x`) | menor | curado: a forma é julgada no jq por `explode`; e `iss/aud/jti` com caractere de controle vetam |
| 4 | surrogate baixo solitário e U+FFFD são intercambiáveis sob a mesma assinatura | menor | declarado (sem injeção possível; ver limitações) |
| 5 | envelope com dois documentos JSON passava a camada 0; rótulo `duplicate-key:unparseable-*` enganava | menor | curado: `jq -es 'length==1'`; o rótulo virou `unparseable:<onde>` |
| 6 | o trust-check grava o trust-log antes de qualquer veto de corpo/assinatura | menor (anterior ao PR) | declarado; não mexi |
| 7 | `send-a2a.sh --body-file` perdia os `\n` finais | menor | curado: leitura com sentinela |
| 8–11 | canonicalização, duplicatas, tipos/ordem das camadas, sem regressão | — | confirmações |

## 2ª passada (depois das curas e do rebase sobre o #1109)

O rebase trouxe o #1109, que mudou o ATC (`iat`, vida ≤ 900 s, inteiros JSON, raiz de confiança no clone
servido) e o §12 do protocolo. O conflito no ATC foi resolvido mantendo o bloco do main e trocando só a
mensagem do `refuse` de exp. O mesmo refutador passou de novo sobre o gate curado e o delta do conflito: 12
itens, 8 reais (todos menores), 4 confirmações (SIGF e DUP sem fail-open; forma do hash fechada; o ATC
preservou o main; chave extra no topo do envelope sem consumidor hoje).

| # | achado | destino |
|---|---|---|
| 1 | `jti` objeto/array passava as camadas e sujava o `jti.state` | curado: `jws-bad-claim-type` (jti/iss string, aud string se houver) |
| 2 | controle só `< 32` (U+0085, U+2028 passavam) | curado: C0, DEL, C1, U+2028/9 |
| 3 | `signal.from`/`to` com `\n` final passavam (comparação por `$()`) | curado: entram na forma fechada |
| 4 | `thread`/`body_path` assinados, mas texto livre até o inbox | curado: `thread` na forma fechada; `body_path` 1–256 de `[A-Za-z0-9._/-]` sem `..` |
| 5 | 3 curas sem mutante | 2 ganharam mutante (chave desconhecida, forma do hash); o envelope de dois documentos tem defesa em profundidade (o python veta `unparseable:envelope`), então um mutante seria "não exercido" — declarado |
| 6 | a nota do A5d não dizia o offset nem que o teto é inclusivo | curado: `--exp-offset 7200` → 403; 3600 é inclusivo; os 900 s do ATC não contam |
| 7 | a L8 mudava a condição do bloqueio do §12.7 fora do §12 | curado: marcada como interpretação do §12.7 pelo §12.6 (P5b) |
| 8 | `send-a2a.sh` não valida a forma de `--thread`/`--kind`/`--jti` | declarado: o gate recusa com motivo nomeado; os valores do protocolo cabem |

Bancada depois das curas: `a2a_verify` + `a2a_accept` 59/59, `accept-to-channel.selftest.sh` 12/12.

## O que a passada NÃO cobriu (declarado)

- O `a2a-accept.sh` não foi executado pelo refutador (o sandbox recusou); a injeção no inbox foi lida no código.
- O caminho vivo HTTP → bridge → gate não rodou: o deploy é da sessão principal (`ops/update-bridge.sh`).
- Os campos `id`/`kind`/`classification` continuam **não assinados**: o gate fecha a forma, não a autoria.
- As curas da 2ª passada foram medidas pela bancada, sem 3ª refutação.
