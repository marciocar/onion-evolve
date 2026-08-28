---
title: "Revisão — mapeamento de harness adjacente (fato × barulho × não-verificável)"
date: 2026-08-28
branch: research/adjacent-harness-munder-difflin
reviewer: "agente de pesquisa dedicado lendo CÓDIGO e API (não a landing page) + verificação independente de trajetória via gh search/API + gates determinísticos"
reviewed_diff_sha256: 592cba8dbf31fb45fcc0426db15a3a976b38489f060bfcf2bf64312b0de26c3c
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 60000
duration_min: 26
---

# Resíduo — REGRA 56

Seis nós num grafo de pesquisa. **Zero lógica.** O risco desta classe é **repetir marketing alheio
como fato** — e a defesa foi medir no código e na API antes de escrever qualquer linha.

## Achados

1. **Trajetória medida, não declarada.** 5.219★ / 629 forks / 185 PRs fechados / criado 31/05/2026,
   via API do GitHub. Comunidade real (PRs de externos identificáveis), não repo de vitrine.
2. **O "#1 Trending" é pico de um dia** (18/08), exibido sem data; em 25/08 já era #8/#18 — fonte
   terceira (`trendshift.io`), não a landing deles.
3. **"12 providers" bate** — contados em `src/shared/agentProvider.ts`, não no marketing.
4. **"Determinístico, sem tokens" é verdade pela metade** — plumbing sim, julgamento do orquestrador
   não (é sessão de LLM cobrada). A comunicação deles não separa.
5. **"Publicamente auditável" não se sustentou** — 88 arquivos varridos, nenhuma lib de cripto no
   `package.json`, nenhum relay/sync/e2e. **Registrado como NÃO-VERIFICADO, nunca como ausência**: o
   recurso é do tier pago e o relay plausivelmente vive no SaaS fechado. O nó fica `open` com gatilho
   nomeado (*alguém apontar o arquivo, ou o projeto declarar que o relay é fechado*).

## Disciplinas aplicadas

- **Interesse da fonte anotado**: a landing page ganha se o leitor acreditar sem checar. Por isso a
  trajetória foi confirmada em fonte terceira e os números, no código.
- **Nada de "vitória competitiva"**: o nó de decisão declara explicitamente o que **não** vira
  exemplo — eles são multi-provider por desenho, nós apostamos no acoplamento seletivo; são teses
  opostas e ambas defensáveis. Comparar providers seria comparar eixos diferentes.
- **Sem afirmação de ausência** onde só houve não-localização.

## Verificação

`kg-radar --integrity --schema` **exit 0** (37 nós, 40 arestas) · `realign --check` **ALINHADO** ·
`lint` **0 HARD** · o grafo de pesquisa **não entra** em `docs/backlog.md` (segue 190).

## Teto declarado

Ler código de terceiro dentro de um orçamento é amostragem, não auditoria: **não localizar não é
não existir**, e o nó de criptografia foi escrito para dizer exatamente isso. Um segundo par de olhos
com mais orçamento poderia achar o arquivo e fechar o nó na direção oposta — o que seria resultado
bom, não derrota.
