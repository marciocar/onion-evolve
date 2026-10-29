---
title: "Sinal de campo: consumidores de business-context com nomes antigos, e o hooksPath absoluto recorrente"
date: 2026-10-29
type: signal
from: adotante sem registro (role: adopted, pin 6c4272252528), recebido por mensagem entre sessões
to: onion-evolve (core)
reviewed_for_public: true  # transcrito pelo core sem conteúdo do cliente nem nome do adotante
status: open
---

# Dois atritos que valem para qualquer adotante (2026-10-29)

O maestro pediu ao adotante que o core avalie estes dois pontos e, se decidir, propague a correção aos outros
adotantes.

1. **Nomes de arquivo divergentes.** O `/product:analyze-pain-price` e a referência do `@pain-price-specialist`
   leem `docs/business-context/` pelos nomes em caixa alta: `CUSTOMER_PERSONAS.md`, `CUSTOMER_JOURNEY.md`,
   `VOICE_OF_CUSTOMER.md`, `PRODUCT_STRATEGY.md`, `SALES_PROCESS.md` e `COMPETITIVE_LANDSCAPE.md`. Já o
   `/docs:build-business-docs`, que é o autoritativo dessa convenção, gera kebab-case em subpastas:
   `01-customer/personas.md`, `01-customer/journey.md`, `01-customer/voice-of-customer.md`,
   `02-product/strategy.md`, `03-market/competitive-landscape.md` e `04-operations/sales-process.md`. Num adotante
   que acabou de rodar o build, o analyze-pain-price não acha nenhum dos arquivos. **Pedido:** alinhar todos os
   consumidores aos nomes do build, ou resolver pelo `index.md`. O primeiro passo é um grep no core pelos nomes
   antigos.
2. **O `core.hooksPath` absoluto volta (recorrência do sinal de worktree).** O adotante corrigiu para relativo, e
   uma nova worktree criada pelo harness regravou o caminho absoluto. O `session-currency-check.sh` avisou de
   novo. A correção à mão não dura. **Pedido:** um conserto automático, como um hook que reescreve para relativo,
   e não só o aviso.

Orquestrado com 🧅 Onion Evolve
