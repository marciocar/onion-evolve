---
branch: docs/kg-f5-praca
pr: 601
date: 2026-08-14
reviewed_diff_sha256: 8fe4f9aefacf925532eaebd86ed0cf101397224f87102eaa8a586fb91f199b2b
findings_total: 12
findings_real: 12
findings_fixed: 12
tokens: 90000
duration_min: 25
verdict: CORRIGIDO
reviewer: elenxo16 (agente adversarial em background, 16º Elenxo da linha) + verificação claim→medição do carimbo
---

# Passada adversarial — `docs/kg-f5-praca`

Este PR é o carimbo da F5 no KG do programa BRIDGE-EVOLVE. A substância revisada não é o
YAML — é a pilha F5 do bridge que o carimbo AFIRMA (PRs 22/23/24 + curas, `74bc794..28f3ad9`),
revisada pelo **16º Elenxo** (agente adversarial dedicado, nada foi editado por ele). O diff
do core foi então conferido claim a claim contra o medido.

## O 16º Elenxo sobre a pilha carimbada: 11 achados, todos endereçados

O CRÍTICO: `shares.json` era ler→mutar→escrever com `catch → {}` na leitura e write
não-atômico — **uma** leitura falha substituía o índice global de links de TODOS os usuários,
sem recuperação (medido com prova executada: 2 shares → corrupção simulada → 1 share
sobrevivente, link órfão permanente). Os ALTOS: `threadId "__proto__"` poluía
`Object.prototype` do processo inteiro cruzando usuários (medido, inclusive percent-encoded);
`/shared` era a única rota pública com I/O síncrono e sem balde (17ms/req com 20k shares);
o botão 🔗 revogava o link no caminho de **Cancelar/Esc** e não tinha `.catch`.

**A lei da linha, no grau mais literal até aqui:** as três classes tinham cura já escrita
*no mesmo arquivo* — o tmp+rename comentado 120 linhas acima do `writeShares` que não o
usava; o balde de I/O síncrono comentado 50 linhas acima da rota pública sem ele; o
`__proto__` do 13º. A cura ficou no caso, não no mecanismo. Desta vez virou mecanismo:
`share-selftest.mts` (16 asserts comportamentais, incluindo "índice corrompido segue
INTACTO no disco") entrou na bancada `bench.sh`.

Duas hipóteses do meu próprio briefing o Elenxo **refutou com evidência** (o valor da
adversarialidade correndo nos dois sentidos): o guard `use("/threads/*")` cobre o subpath
do share (testado com Hono real — não há IDOR), e o denylist do SW não quebra a página
compartilhada (`NavigationRoute` só intercepta navegações; lido no `sw.js` compilado).

## Conferência claim→medição do carimbo (este diff)

- `verified_against` cita deploy `28f3ad96` — é o clone servido (`update-bridge` OK, health
  200 local+público) ✓
- Provas vivas citadas = exatamente as medidas em produção: `/shared` 404 + `x-robots-tag:
  noindex, nofollow` + `cache-control: no-store`; POST share anônimo 401; `/s/*` 200 com
  noindex; 31º hit 429 ✓
- Selftest 16/16 e bench verde (gzip 259 KiB, folga 593 bytes) ✓
- **1 achado neste diff, corrigido antes do PR:** o label contava "10 curados + 1 refutado"
  — a contagem real é 11 achados endereçados com 2 hipóteses do *briefing* refutadas (a
  refutação foi das minhas suspeitas, não de achados do revisor). Corrigido no próprio label.
- `Q_G5_DOGFOOD_GO_LIVE`: gate honesto — declara que NÃO fecha no dia do deploy por
  definição, relógio 08-14→~08-21, e fecha só com o go do maestro. Aresta `CONSTRAINS`
  (dissent que limita), não `REFUTES` — conforme a gramática.
- Radar exit 0: 26 nós, 30 arestas, sem contradições, frescor 25/25.
