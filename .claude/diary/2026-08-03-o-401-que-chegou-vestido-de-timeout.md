---
date: 2026-08-03
instance: onion-evolve
type: error
classification: collective
tags: [causa-raiz, inferencia-vs-medicao, behavior-over-declaration, ci, onion-review]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-01
conflict_class: static
significance: "Três rodadas de diagnóstico em três semanas descartaram 'credencial' pelo MESMO raciocínio correto-mas-inválido — e a causa era a credencial: a action entregava um 401 vestido de timeout de 180s."
---

## Signal

**Medir certo e inferir errado é um modo de falha distinto de medir errado** — e mais perigoso,
porque a medição dá confiança à conclusão. Descartei "credencial" raciocinando: *"401 volta
instantâneo, isto pendura 180s, logo não é auth"*. Cada premissa era verdadeira **e verificada**.
A conclusão dependia de uma terceira premissa que eu **nunca testei**: que a action repassaria o
401. Ela não repassa. Ao raciocinar sobre um componente, pergunte qual comportamento dele você
está assumindo — e se você o **observou**.

## Evidence

- Sintoma estável de 2026-07-14 a 08-03: `is_error: true`, `num_turns: 1`, `total_cost_usd: 0`,
  ~180s, **sem mensagem de erro**.
- **Causa real:** o secret `ANTHROPIC_API_KEY` não autenticava. Medido de dentro do runner:
  `GET /v1/models` → **401 `authentication_error` "API key is invalid" em 0,07s**, com a rede
  impecável (DNS 3,5ms · TCP 5,6ms · TLS 27ms).
- A chave era **bem formada** — 108 chars, prefixo `sk-ant-`, mesmo comprimento antes e depois de
  normalizar. Logo revogada/expirada, não mal-colada. O teste que separa as duas existe porque o
  conserto difere (re-colar × gravar nova).
- **Três rodadas erraram pelo mesmo motivo** (07-18 e duas em 08-03): um erro de auth chegando com
  cara de timeout. A investigação de 07-18 fechou numa **coincidência de data** — o revisor começou
  a falhar em 07-14 e a action lançou v1.0.172/173/174 em 07-14 — e escreveu "o pin v1.0.171 cura"
  no comentário do workflow. Não curava: testado nas duas pontas em 08-03 (v1.0.171 e v1.0.183),
  falha idêntica.
- **Confirmação:** com a chave trocada, o mesmo diagnóstico devolveu **HTTP 200 em 2,2s**.
- Custo do engano: **11 PRs** mergearam num único dia sem revisão semântica, com o CI verde.

## Next crumb

O **pré-voo** em `onion-review.yml` converte a próxima ocorrência de 6 minutos de mistério em 1
segundo de causa dita: checa `/v1/models` (não consome tokens) antes de invocar o revisor e, se não
autenticar, nomeia a credencial no aviso do PR em vez de deixar `sem-arquivo`.

Re-teste (`static` — conclusão que fonte melhor pode corrigir): se a action passar a **repassar**
erro de auth em versão futura, o pré-voo vira redundante e pode encolher. Verifique rodando
`.github/workflows/onion-review-diagnose.yml`, que separa rede × credencial × chave mal-colada.

E a armadilha que peguei **duas vezes** no mesmo dia: a action **se auto-pula** quando o PR altera
o próprio `onion-review.yml`. Um PR que mexe no revisor **não consegue medir o revisor**. Quem mede
é sempre o PR seguinte.
