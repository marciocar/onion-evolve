---
title: "Auditoria de frescor dos contextos de domínio do core"
date: 2026-08-12
category: analysis
status: reference
kg: docs/onion/graph/context-freshness-2026-08-12.kg.yaml
run_id: wf_23de8ab6-81b
tokens: 1065019
agents: 19
duration_min: 2
---

# Auditoria de frescor — `docs/business-context/` e `docs/technical-context/`

> **Projeção do grafo, não fonte paralela.** Os achados vivem no `.kg.yaml` acima; este documento
> é a leitura humana do run. Divergindo os dois, o grafo vence.

## O run

| | |
|---|---|
| Comando | `/meta:context-freshness` (fase *Manage* do ciclo CRUD+) |
| Escopo | 19 arquivos — 13 business · 6 technical · 0 compliance (template puro) |
| Padrão | fan-out-and-synthesize · 19 workers `sonnet`/`medium` · 0 descartados |
| Custo | 1.065.019 tokens · 102 tool-calls · 2min19s |
| Juiz | 1 × `opus`, acionado pela regra dos >30% (taxa medida: 42%) |
| Revisão | 2 revisores adversariais `opus` sobre o PR resultante |

**Desvio declarado:** o comando especifica `haiku` nos workers; usei `sonnet`/`medium`. O item #4
da régua (aderência à realidade) exige cruzar `members.yaml`, `inventory.md` e `decisions.md`
contra prosa — raciocínio, não varredura. Acrescentei ao schema o campo `checked_against_live`,
que obriga cada worker a declarar **o que mediu**, com `nao-medi` como valor legal que **proíbe**
acusar falha de #4. Resultado: 19 de 19 mediram.

## Vereditos

**11 CURRENT · 8 STALE · 0 HISTORICAL** — e o juiz derrubou 1 dos 8, levando o denominador real a
**7**. Nada descreve realidade extinta: a doutrina viva (`.onion/` abandonado, CORE ≠ FAMÍLIA, três
dimensões peer) está respeitada nos 19.

### STALE confirmados

| arquivo | o que drifta |
|---|---|
| `technical/codebase-guide.md` | 99→**102** comandos (3 formas), 33→35 meta, 2→3 design, 10→11 skills |
| `technical/contributing.md` | `timeout-minutes` 15→**25**, lint 2261→**3191** linhas (+41%) |
| `technical/ai-development-guide.md` | regras até 60; REGRA 4 removida em 03/08 |
| `technical/business-logic.md` | contagens de contextos |
| `business/voice-of-customer.md` | "4 adotantes" → **8** |
| `business/metrics.md` | "4 adotantes" → **8** (auto-declarado "contagem manual") |
| `business/customer-communication.md` | rótulo trata D3 como pendente; **conteúdo correto** |

### Refutado pelo juiz

`business/competitive-landscape.md` — o acusador leu "hipótese a validar" como se qualificasse a
decisão D6 (ratificada) quando qualifica o **whitespace de mercado**. E o próprio D6 ratificado
registra *"Falta: 1-2 entrevistas P4"*. O arquivo concorda com D6.

## Os dois achados que a auditoria não procurava

**Citação fabricada com endereço.** `codebase-guide.md:111` cita entre aspas *"conhecimento
completo de 51 agentes e 99 comandos"* ancorado em `.claude/agents/meta/onion.md:4` — a linha viva
diz **102**. Número velho o leitor desconfia; citação com `arquivo:linha` ele **confere**, e ao
conferir conclui que a **fonte** está errada. O aparato de rastreabilidade vira veículo do erro.

**Nota de frescor que blinda o número errado.** Uma *"Nota de frescor (re-testada 2026-08-05)"* mora
a **nove linhas** de um cabeçalho `## 4. Skills — 10` quando são 11. A nota fala de **outro
arquivo** (`docs/onion/index.md`), mas quem lê não percebe o salto de referente. Carimbo genérico
perto de conteúdo não-medido é pior que carimbo nenhum.

## Por que o lint não pegava

A REGRA 16 sempre varreu `docs/` — a hipótese "os contextos estão fora do escopo" foi medida e
**caiu**. A cegueira era de **vocabulário**: as três formas do `99` (travessão invertendo
número/substantivo; rótulo `Total` fora dos canônicos; prosa conjuntiva atravessando quebra de
linha) não casavam nenhum feeder. É a terceira vez que essa regra falha por esse eixo — o próprio
cabeçalho dela já registra a classe do PR #517: *"causa: forma de frase, não ausência de guarda"*.

Curado nesta mesma branch, com 6 fixtures e a invariante do pré-filtro honrada (e seu limite
declarado, onde ela estruturalmente não fecha).

## O que a revisão adversarial derrubou desta auditoria

Registrado porque é o valor do Elenxo, e porque parte era afirmação minha:

1. **A "contradição cross-domínio" não existia.** Acusei `business-logic.md` de dizer "11 membros";
   ele diz **"8 membros hoje"** — o valor **certo**. Listei como divergente o arquivo correto,
   casando o numeral com `11 skills`/`11 arquivos`. É o mesmo defeito que este relatório celebra
   ter pego num worker.
2. **A receita publicada não reproduzia.** `grep -c 'kind: adopter'` devolve **9** (a 9ª é legenda
   comentada); o correto é `grep -c '^ *kind: adopter'` = 8. O número estava certo, o comando não.
3. **A tese central estava esticada.** Dos cinco sítios que listei como "número copiado de SSOT
   gerada", **um** encaixa: `inventory.md` cobre quatro totais e não cobre linhas do lint, regras
   numeradas nem `timeout-minutes`; `members.yaml` é mantido à mão. A cura prescrita não existe
   para quatro dos cinco.
4. **Uma aresta era álibi por proximidade** — desfeita, e a analogia que a motivava virou claim
   própria.

## Teto declarado

- O comando **não modifica contextos** por desenho; nenhum dos 7 STALE foi corrigido aqui.
- O refresh só faz sentido **depois** de decidir a régua canônica de "adotante" e fazer a prosa
  apontar para `members.yaml` — senão drifta de novo no próximo adotante.
- A auditoria não cobre `compliance-context/` (template puro, só `README.md`).
