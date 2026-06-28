---
title: "Blind spots — o que ficou de fora e o usuário precisa saber"
date: 2026-06-17
local-datetime: "2026-06-17 15:18 -03 (America/Sao_Paulo)"
type: blindspots-note
status: active
authored-in: onion-evolve (sala de design)
audience: usuário (Marcio) + sala de obra
related:
  - ./onion-strategy-layer-adr-draft-2026-06-17.md
  - ./onion-strategy-layer-capability-draft-2026-06-17.md
  - ./onion-strategy-layer-handoff-2026-06-17.md
---

# Blind spots — o que ficou de fora (2026-06-17 15:18 -03)

> **Doc 4 de 4.** Coisas que não couberam nos outros três e que mudam decisões. Honestidade
> sobre limites, não polimento. Lê isto **antes** de aprovar os Docs 1 e 2.

## 1. O atrito que a doutrina não resolve, só administra

A doutrina (Doc 1) faz parecer que "deliberação genuína" é um botão que se liga em decisões
de alto risco. **É mais sujo que isso.** Mesmo com fan-out + juízes, a avaliação continua
**probabilística**: os juízes são o mesmo tipo de modelo que o gerador, e podem compartilhar
o mesmo viés. Verificação adversarial **reduz**, não elimina, o erro confiante. Isto é o
mesmo limite que o whitepaper do SDAAL admitiu ("simula consistentemente é probabilístico,
não determinístico"). A doutrina deve **dizer isso em voz alta**, senão vende garantia que
não tem — e o engenheiro sênior do cliente (público do reposicionamento) vai perceber.

## 2. Custo real, não estimado

`/meta:strategize` (Doc 2), se gerar N candidatos + painel de juízes + verificação adversarial
por bifurcação, **consome contexto e tokens de forma comparável a um `/meta:evolve`** (aquele
run gastou ~1.5M tokens / ~29 min). Isso é caríssimo para aplicar em qualquer decisão. Reforça
a regra de "altitude por risco": se aplicado largo, **destrói** a eficiência que o usuário
pediu. Não temos números medidos — só a analogia com o evolve. **Faltam benchmarks.**

## 3. A tensão com o trabalho que está REALMENTE quente

O fio estratégico vivo desta semana é o **reposicionamento como produto** (BSL, control plane
sobre Federação, ICP regulado, semver formal — ver `onion-repositioning-sdaal-session-2026-06-17.md`
e o backlog do `/meta:evolve` 2026-06-17 com 1 blocker + 12 recommended). A camada de
meta-estratégia **não está nesse caminho crítico**. Se ela consumir ciclos agora, atrasa
o que paga as contas. **Decisão de priorização que só você (Marcio) toma** — eu sinalizo o
conflito, não resolvo.

## 4. [RESOLVIDO] A ambiguidade do pedido — era catálogo do framework

Eu tinha levantado dúvida se você queria *doutrina do framework* ou *ajuste do meu
comportamento pessoal*. **O esclarecimento das 15:18 resolveu**: você quer **fluxos/casos
mapeados como padrões (catálogo de playbooks)** — é doutrina/capacidade do framework, não
regra de sessão. Docs 1-2 foram revisados para refletir isso (catálogo-first). ✅

> Sub-blind-spot remanescente: o catálogo só funciona se os playbooks forem **reconhecíveis**
> de forma confiável. "Reconhece-quando" mal escrito → match errado → aplica o fluxo errado
> com confiança (o mesmo modo de falha do contexto stale do ADR de ciclo de vida). Os gatilhos
> de reconhecimento são a parte difícil, não a lista de fluxos. **Investir na precisão do match.**

## 5. O blocker do backlog ainda está aberto

Independente desta sessão: o `/meta:evolve` de 2026-06-17 tem **1 blocker 🔴** vivo —
`agent-creator-specialist.md` guia listar ferramentas MCP sem steering SDAAL → novos agentes
nascem violando API-first. Isso é dívida ativa que **interage** com qualquer nova capacidade
(se `/meta:strategize` for criado por um agente mal-orientado, herda o vício). Fechar o
blocker é pré-requisito higiênico para qualquer expansão de orquestração.

## 6. O que eu não consigo saber daqui
- Se a sala de obra já começou algo nesta direção (instâncias isoladas — não vejo o trabalho dela).
- Se `analyze-complex-problem`/`fleet` no estado atual já cobrem o Doc 2 (descrevi de memória/doc,
  não reli os arquivos linha a linha nesta sessão).
- Sua prioridade real entre meta-estratégia e reposicionamento — só você tem essa ordenação.

---

## Resumo de uma linha para você
> Os Docs 1-2 (revisados para catálogo-first) miram um gap real, **mas**: (a) a parte difícil
> é a **precisão do reconhecimento** ("reconhece-quando"), não a lista de fluxos (item 4); (b) o
> reposicionamento provavelmente vem antes, embora o catálogo caiba em paralelo se incremental
> (item 3); (c) feche o blocker SDAAL antes de expandir a orquestração (item 5).
