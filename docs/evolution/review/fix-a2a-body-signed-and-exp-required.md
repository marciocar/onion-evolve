---
title: 'Resíduo — o corpo entra na assinatura do a2a-verify e o exp fica obrigatório'
date: 2026-10-14
branch: fix/a2a-body-signed-and-exp-required
reviewed_diff_sha256: d29251f4a2c3cfd0c0abdc5196ac7c9a37394c43041f68e8fce3965f91bf3916
reviewed_code_sha256: cc735ae89b3e57cec8553164029eedf9ea53ed57bc40bc9bb6c8362f41b6ec06
findings_total: 11
findings_real: 7
findings_fixed: 5
tokens: 111997
duration_min: 8
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

## O que a passada NÃO cobriu (declarado)

- O `a2a-accept.sh` não foi executado pelo refutador (o sandbox recusou); a injeção no inbox foi lida no código.
- O caminho vivo HTTP → bridge → gate não rodou: o deploy é da sessão principal (`ops/update-bridge.sh`).
- Os campos `id`/`kind`/`classification` continuam **não assinados**: o gate fecha a forma, não a autoria.
- Uma passada só, sobre o diff antes das curas; as curas foram medidas pela bancada, não re-refutadas.
