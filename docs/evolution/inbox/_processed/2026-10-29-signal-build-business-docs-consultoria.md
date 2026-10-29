---
title: "Sinal de campo: atritos do /docs:build-business-docs num repositório de consultoria"
date: 2026-10-29
type: signal
from: adotante sem registro (role: adopted, pin 6c4272252528), recebido por mensagem entre sessões
to: onion-evolve (core)
reviewed_for_public: true  # transcrito pelo core sem conteúdo do cliente nem nome do adotante
status: open
---

# O /docs:build-business-docs no dogfood de uma consultoria (2026-10-29)

1. **O comando supõe produto próprio.** O comando e o template partem de que o repositório é o produto de
   quem o usa. Personas são os clientes do produto, e o sales-process é o do produto. Numa consultoria, o
   negócio é o de um cliente, e as camadas tiveram de ser reinterpretadas: personas do engajamento e clientes
   do cliente, com a oferta no lugar do "produto". **Pedido:** um modo ou seção "engajamento de consultoria".
2. **A REGRA 15 (carimbo de frescor) barra o 1º commit, com 15 HARD.** O comando não manda carimbar
   "Última Atualização" em cada arquivo gerado. **Pedido:** a Fase 3 grava o carimbo no cabeçalho de cada um.
3. **A REGRA 8 (inventário sincronizado com o filesystem) barra o commit.** O inventário conta os arquivos de
   business-context/, e o comando não lista o `/meta:inventory` nos próximos passos. **Pedido:** incluir o passo,
   como faz o fragmento `inventory-sync-after-create`.
4. **A pesquisa corre fora da maquinaria.** A Fase 1.2 manda pesquisar "via WebSearch" e não aponta a skill
   `onion-research`, que injeta o corpus, os eixos e o `.kg.yaml` com tier. A sessão usou um agente de pesquisa
   avulso e montou o grafo à mão. O maestro notou a ausência. **Pedido:** a 1.2 rotear para o `onion-research`.

**O que funcionou:** o modo infer-from-evidence. O maestro pediu uma 3ª marca, além de `[INFERIDO]` e
`[TO BE COMPLETED]`: o **`[DECISÃO PENDENTE]`**, para a decisão do cliente que não foi aferida e não pode ser
inferida. Vale levar ao template.

Orquestrado com 🧅 Onion Evolve
