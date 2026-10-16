---
branch: fix/cc-census-measures-bridge-sdk
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 14
findings_real: 14
tokens: 284140
duration_min: 10
findings_fixed: 14
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: general-purpose opus, 2 passadas (mandato REFUTAR)
nota: "13 achados do refutador (9 na passada 1, 4 na passada 2) e 1 do dogfood (override cego ao _ de SDK_TARGETS). tokens e duração são a soma das duas passadas, lidas do uso do subagente. As curas da passada 2 não passaram por uma 3ª passada."
---

# Passada adversarial: `fix/cc-census-measures-bridge-sdk`

## O que muda

SAC-155. O medidor do `/meta:cc-update` (`.claude/validation/cc-delta-census.sh`) media só o CLI do host. Na r12,
o host estava em 2.1.301 e o bridge e o runner do /chat rodavam o 2.1.232 do Agent SDK 0.3.232, sem que nenhuma
linha mostrasse isso. Agora o censo lê **alvos declarados por configuração**: `CC_DELTA_SDK_TARGETS`, ou no core o
`ops/cc-sdk-targets.tsv` (core-only). Para cada alvo:

- mede o `--version` do binário do SDK como a conta dona, cruzando com o `claudeCodeVersion` do package.json, que é lido como arquivo;
- imprime uma linha na tabela de versões;
- avisa quando o CLI do SDK está N versões publicadas atrás do host, ou à frente dele;
- marca NÃO MEDIDO, com rc e motivo, quando não alcança o alvo; o rc do censo continua 0.

Sem arquivo de alvos, a linha diz "nenhum alvo declarado".

**Medido: o medidor VIAJA.** O `vendor-manifest.sh --list` lista `cc-delta-census.sh` e `cc-update.md` em
adopted, hub, standalone, plugins e source; o mini é a exceção. Isso vale mesmo com o comando se declarando Core-only.
Por isso o caminho da VPS mora no `ops/`, seguindo o precedente do `ops/moat-targets.tsv`, e o código só o testa
por presença. A REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) segue com HARD=0.

**Linha nova medida ao vivo na VPS:** `| SDK `bridge` (CLI embutido, binário --version) | 2.1.301 (SDK 0.3.301) |`,
ao lado de disco 2.1.302 e processo 2.1.301, com o aviso "está 1 versão(ões) publicada(s) atrás do host (2.1.302)".

## Achados

Dogfood:
0. O regex de override `CC_DELTA_[A-Z]+` não declarava `CC_DELTA_SDK_TARGETS`. Curado para `[A-Z_]+`, coberto pelo caso (n).

Passada 1:
1. (média) Com a forma aberta, qualquer binário rodava como qualquer conta, inclusive root (medido lendo o arquivo de senhas como uid 0). Curado: conta root e uid 0 recusados, caminho preso ao layout do SDK. Caso (o).
2. (média) Meias-falhas sumiam: binário com rc 0 sem versão, pacote ausente e binário com rc≠0 não davam aviso. Curado: cada perna que falha tem aviso próprio. Caso (p).
3. (média) 12 mutantes sobreviviam. Curado com os casos (o) a (s); ver a seção Mutantes.
4. (baixa-média) O rótulo malformado entrava cru no YAML do esqueleto. Curado: vira `(linha N)`. Caso (s).
5. (baixa) A leitura do pacote não tinha teto; um FIFO travava o censo. Curado com `timeout 30 head -c 1048576`. Caso (v).
6. (baixa) Tabs seguidos deslocavam colunas, e CRLF e comentário indentado também quebravam a leitura. Curado com split por TAB literal, remoção do CR e skip depois de aparar. Casos (j), (q) e (o).
7. (baixa) Sufixo de pré-release sumia. Curado: agora é avisado. Caso (r).
8. (baixa) O nó omitia os plugins e os dois binários-irmãos (glibc e musl). Curado: o nó e o arquivo de alvos declaram a suposição do glibc.
9. (cosmético) Um arquivo só de comentários ficava sem aviso próprio. Curado: avisa "não declara nenhum alvo". Caso (r).

Passada 2:
10. (alta) A conta `-` com o censo rodando como root executava como uid 0. Curado: sob root, a perna do SDK é recusada inteira. Caso (t), e dogfood sob `sudo -n`.
11. (alta/média) Só o NOME do caminho era fechado: um `claude` em qualquer `node_modules` rodava e, com sudo, escalava. Curado: os caminhos são resolvidos como a conta; o binário real tem de ficar na mesma árvore real, ser da conta declarada e não ser gravável por outros, e executa-se o caminho resolvido. A fronteira de confiança está no cabeçalho: o arquivo de alvos é código. Caso (u).
12. (média) 8 mutantes sobreviviam além dos declarados. Curado com os casos (u), (v) e (j) endurecidos.
13. (média) O nó afirmava mais do que tinha sido medido. Curado: o nó lista os sobreviventes reais e a fronteira de confiança.

## Mutantes

Foram 37 mutantes, todos por `ops/mutate-and-restore.sh` com `LC_ALL=C`, rodados contra o **código final**:
32 reprovaram e 5 sobreviveram, todos declarados abaixo. Quatro mutantes da 1ª rodada tinham quebrado a sintaxe do
script e reprovavam tudo; foram refeitos com sintaxe válida, e a contagem usa só os refeitos.

Os 5 sobreviventes:
- a recusa por nome `root` sozinha e a recusa por uid 0 sozinha, porque uma cobre a outra; as duas juntas (M25) reprovam o caso (o);
- o `timeout 30` do binário, porque testá-lo exigiria um binário que trava 30 s;
- executar o caminho resolvido em vez do declarado, porque só pesa na janela entre a checagem e a execução;
- a checagem textual de `/../`, que é equivalente porque o caminho real é conferido depois.

Bancada `run_cc_delta_census_selftests`: 24/24 com `LC_ALL=C`; os casos novos são de (j) a (v).

## Limites declarados

- O ramo `sudo -n -u <conta>` não é exercido pela bancada, que não tem outra conta. Ele é medido só no dogfood na VPS, com a conta `onion`.
- A bancada também não exercita o motivo "teto de 30 s" da leitura do pacote.
- Janela TOCTOU entre a checagem e a execução: só a conta dona ou o root conseguem usá-la.
- O grupo pode escrever no binário. A instalação do bridge é 775/664, com o grupo da própria conta (medido).
- Com a conta `-`, o binário tem o poder de quem roda o censo.
- Bancada rodando como root reprovaria os casos SDK, porque o censo recusa root. O CI roda como `runner`, que não é root.
- O comando continua se declarando "Core-only", mas viaja. A inconsistência fica medida e declarada no nó e não foi corrigida aqui: tirar o "Core-only" muda a isenção (c) da REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) sobre o `cc-update.md`.
- Não medido: um host em que o SDK resolva o binário musl.
