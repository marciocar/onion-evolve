---
branch: fix/tm-comment-body-file
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 3
tokens: 95535
duration_min: 4
findings_fixed: 3
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR
nota: "tokens e duração do refutador lidos do retorno do subagente; achados (1)(4) e (2)/(3) reais e curados; (5) falso"
---

# Passada adversarial: `fix/tm-comment-body-file`


## O que muda

`tm.sh comment.add` (adapters/linear.py): o 2º posicional era o corpo, e `comment.add <ID> --body-file <arq>` publicou o
texto literal "--body-file" em 4 issues reais (SAC-146, 149, 150, 153) com rc 0. Agora: `--body-file <arq>`,
`--body-file=<arq>`, `-` (entrada padrão) e `--` (fim das opções); flag desconhecida, posicional extra, corpo vazio e
arquivo ilegível saem rc 2 antes da rede. Junto, o nó `E_DEGRAU1_EM_PRODUCAO_1016` no grafo do isolamento do /chat
(o --apply do degrau 1 medido em produção), para não abrir PR de registro em paralelo.

## Achados

1. REAL, curado: texto que começa com `--` (`--- régua`) passou a ser recusado como flag. O parse próprio do
   comment.add só trata `^--[a-z][a-z-]*(=.*)?$` como opção e aceita `--`. Caso (n5).
2. REAL, curado: a pendura de 20 s da bancada (o servidor esperava requisição que não vinha). O `_cmt` mata o PID
   do servidor; a família caiu de 33 s para 14 s.
3. REAL, curado: o mutante mordia pela guarda nova, não pelo defeito. (mn1) restaura o parse antigo e EXIGE o literal
   "--body-file" no corpo enviado; (mn2) separado para a guarda de posicional extra (n4).
4. REAL (anterior), curado: `comment.add <ID> -` publicava "-". Agora lê a entrada padrão. Caso (n6).
5. FALSO: o log opcional no srv.py compartilhado não muda (f)(g)(h)(m) (só grava com o 3º argumento).

## Mutantes

(mn1) parse antigo → o (n2) reprova publicando o literal; (mn2) sem a guarda de posicional extra → o (n4) reprova (rc 1, rede).

## Limites declarados

Os outros verbos com texto longo (`item.create --description`, `item.update`) não ganharam `--*-file` (paridade
opcional, sem defeito medido). O adapter segue sem `comment.delete`: os 4 comentários espúrios ficam com o maestro.
Dogfood real: SAC-154 recebeu um comentário por `--body-file`, relido idêntico com acento; os modos de falha rodaram
com o ambiente real e saíram rc 2 sem rede.
