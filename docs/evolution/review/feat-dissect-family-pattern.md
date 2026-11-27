---
branch: feat/dissect-family-pattern
pr: 1781
date: 2026-11-27
reviewed_diff_sha256: 3c3148842498c13b573c0696ef5e4f1bf7773e7280a0fa8b09a23f42648dae94
reviewed_code_sha256: 2bab0e88b9f1a4f6304a9a9bd6f293a8f5058547c608ed9391062a98d030dadb
findings_total: 8
findings_real: 8
findings_blocking: 0
tokens: 130830
duration_min: 5
findings_fixed: 8
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "subagente general-purpose isolado (não-fork), mandato REFUTAR, sem o raciocínio de quem escreveu"
nota: "Rodada sobre a revisão para níveis de maturidade (decisão do maestro de 2026-11-27 sobre Q_PATTERN_MATURITY_LEVELS). O refutador deu APROVA COM RESSALVAS: 0 bloqueante, 7 furos menores e 2 mutantes vivos (contados como o 8º achado); todos curados, cada um com caso na bancada (183 para 193 casos). A rodada anterior (catraca disjuntiva com piso de anos) tinha reprovado por 1 bloqueante e 7 menores, também curados; o piso de anos saiu por decisão do maestro. tokens = só o refutador desta rodada."
---

# Passada adversarial: `feat/dissect-family-pattern`

## O que muda

- Família `padrao` no registro, com `n2_proof` (C_OPTION_A_MATURITY_LEVELS, selo Q_PATTERN_MATURITY_LEVELS) e
  `n2_ratchet` {proto_min 2, established_min 3, established_min_derived 2, classic_by_longevity}; a contestação dos
  pisos é `C_PATTERN_THRESHOLD_CONTESTED` (CONSTRAINS).
- Item 13: níveis de maturidade declarados (`x_dissect_maturity`) e conferidos; entrada proto ≥ 2 fontes
  distintas; longevidade só promove a clássico, sem piso de anos. Item 12: forma dos pisos, contestação viva e
  catraca obrigatória para o `padrao`.
- Doutrina §6: tabela, regra dos níveis, ordem de predicados com `padrao` antes de `pratica`.

## Achados

1. Apagar o `n2_ratchet` desligava o item 13 com tudo verde. Curado: `RATCHET_FAMILIES` (par id → pref), código
   `catraca-n2-ausente`, caso novo.
2. Costurar sem N2 e usos em qualquer nível contavam. Curado: só uso em nó do N2 conta; caso novo.
3. A normalização tirava a query (dois `item?id=` do HN viravam um). Curado: a query fica; caso legítimo novo.
4. http/https, `www.` e `./arquivo` contavam como fontes distintas. Curado; dois casos.
5. Longevidade com data inválida passava. Curado com `datetime.date`; a idade mínima não conferida virou limite.
6. Rejeitar no N2 exigia esconder a evidência. Curado: parquear/rejeitar só conferem a maturidade se a declaram;
   absorver/costurar a exigem. Caso legítimo novo.
7. O pai do derivado contava como uso. Curado; caso novo.
8. Mutantes vivos (`not isinstance(bool)` e o filtro de status da contestação). Curado com dois casos.

## Mutantes

- Bancada: 193 casos + 6 de rc 3, cada código com o mutante calado.
- Pedidos: «1 uso só» reprova; «proto com 2» passa; «clássico sem longevidade» reprova.
- Tirar a prova N2 do `padrao` reprova; tirar o `n2_ratchet` também.

## Limites declarados

- As contagens (2, 3, derivado 2) não foram medidas; o proto está ancorado no piso de 2 domínios do GoF; a
  longevidade como promoção não tem âncora positiva direta (as 3 CONSTRAINS do nó da curadoria).
- Fontes distintas são forma normalizada, não independência real (Elenxo).
- A cura desta rodada não passou por 2ª refutação; os casos novos são a prova.
