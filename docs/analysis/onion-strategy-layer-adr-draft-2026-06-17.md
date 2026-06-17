---
title: "ADR (RASCUNHO) — Camada de Meta-Estratégia: deliberar vs executar"
date: 2026-06-17
local-datetime: "2026-06-17 15:18 -03 (America/Sao_Paulo)"
type: adr-draft
status: proposed
decision-scope: orchestration / meta-strategy
supersedes: none
authored-in: onion-evolve (sala de design)
for-instance: sala de obra (.claude/ implementação)
related:
  - ./onion-repositioning-sdaal-session-2026-06-17.md
  - ../meta-specs/architecture.md
  - ../sdaal/sdaal.md
  - ../knowledge-base/concepts/onion-modernization-doctrine.md
---

# ADR (RASCUNHO) — Camada de Meta-Estratégia: deliberar vs executar

> **Doc 1 de 4** do handoff de 2026-06-17 15:18 -03. Rascunho de **proposta** — não é
> decisão aceita. A sala de obra deve reconciliar com o que já evoluiu antes de mexer
> em `.claude/`. Ver Doc 3 (handoff) para o porquê e Doc 4 (blind spots) para o que falta.

| Campo | Valor |
|-------|-------|
| **Decisão proposta** | Criar um **catálogo de padrões de estratégia (playbooks)** — mapeamento `situação reconhecida → fluxo nomeado → grupo de ferramentas → sequência` — de forma que a seleção de caminho vire **reconhecimento** (match contra catálogo), não **composição do zero** (raciocinar tool por tool toda vez). A deliberação cara (fan-out, juízes) passa a ser **fallback** para o resíduo que nenhum padrão cobre. |
| **Escopo** | Meta-estratégia de orquestração. Regra L0 que se senta acima de `commands.md`/`agents.md` e que prioriza **catálogo-first**: o agente primeiro reconhece o caso e aplica o playbook; só delibera quando não há match. |
| **Status** | 🟡 **Proposto** em 2026-06-17 15:18 -03 (refinado às 15:18 após esclarecimento do usuário: catálogo-first, não deliberação-first). Aguarda reconciliação na sala de obra. |
| **Origem** | Sessão de design 2026-06-17. Esclarecimento decisivo do usuário: *"em vez de ter que orquestrar e pensar no uso de ferramenta tool por tool, já ter fluxos/casos mapeados — padrões."* Isto é **recognition-primed decision making**: reconhecer a situação como típica e aplicar o padrão validado, em vez de reavaliar tudo. O Onion tem peças de orquestração (Workflow/fleet) mas **não um catálogo de playbooks por caso de uso**. |

---

## Contexto

### O gap: regimes de orquestração sem doutrina de transição

Um agente Claude Code opera num laço: recebe contexto → produz texto/tool calls → resultados
voltam → repete. Não há módulo planejador separado — **planejar é texto de raciocínio gerado
antes da ação**. Disso decorre que há dois regimes de orquestração, e o Onion usa ambos sem
nomear a fronteira:

1. **Dirigido por modelo** (emergente, flexível, in-context). O agente decide na hora.
   Bom para o ambíguo/novo. Custo: não-determinismo, deriva, sem garantia de cobertura.
   → É o default da maioria dos comandos `/product:*`, `/engineer:*`.
2. **Dirigido por código** (orquestração determinística — ferramenta `Workflow`). A *estrutura*
   (laços, fan-out, condicionais) é fixa no script; o modelo só preenche as folhas. Bom para
   formas conhecidas (auditoria, migração, review paralelo). Custo: rígido — exige saber a forma.
   → É o que `/meta:evolve`, `/meta:fleet`, `onion-fleet` materializam.

**O ponto cego**: não existe um **catálogo de playbooks por caso de uso** que o agente
possa reconhecer e aplicar. O que existe (`onion-fleet`, padrões canônicos do Workflow) é
catálogo de **forma de orquestração** (fan-out, judge panel, pipeline…), não de **`caso de
uso → fluxo → grupo de ferramentas`**. Sem esse catálogo, o agente recompõe a estratégia
do zero, tool por tool, a cada tarefa — implícito no julgamento de quem invoca. É o mesmo
tipo de decisão ad-hoc que o SDAAL eliminou para integrações.

### O atrito a fixar: amostragem ≠ avaliação

Por padrão o modelo **não avalia o melhor caminho entre caminhos possíveis — ele amostra o
mais provável**. "Melhor caminho" e "continuação mais plausível" parecem iguais de dentro,
mas a amostra é *confiante, não necessariamente correta*. Avaliação **genuína** exige
externalizar a escolha (candidatos paralelos + critério fora do gerador + verificação
adversarial) — e isso custa tokens. A doutrina precisa dizer **onde gastar essa deliberação**.

---

## Decisão (proposta)

### Princípio 0 — Catálogo-first: reconhecer antes de compor (o coração)

A ordem padrão de operação é **reconhecimento, não composição**:

1. **Reconhecer** — dado o objetivo, casar a situação contra o **catálogo de playbooks**
   (`situação → fluxo → grupo de ferramentas → sequência`).
2. **Aplicar** — se houver match, executar o playbook. Barato: é *match*, não raciocínio
   tool-por-tool. É aqui que vivem ~90% dos casos.
3. **Deliberar (fallback)** — só quando **nenhum** padrão encaixa, subir para a maquinaria
   cara (fan-out de candidatos + juízes). O resíduo que delibera **vira candidato a novo
   playbook** (o catálogo aprende).

> Isto inverte o instinto de "pensar do zero a cada tarefa". O custo de decisão cai de
> *O(raciocinar sobre cada ferramenta)* para *O(casar contra catálogo)*. É a alavanca central
> da eficiência que o usuário pediu.

### Princípio 1 — A deliberação cara é fallback, alocada por risco

Quando não há playbook (e **só então**), a deliberação genuína é alocada por **risco da
bifurcação**, não uniformemente:

- **Bifurcação de alto risco** (difícil de reverter, alto custo de erro, espaço amplo) →
  fan-out multi-candidato + painel de juízes + verificação adversarial.
- **Passo mecânico / reversível** → execução barata dirigida por modelo.

Os **níveis de abstração existentes são o botão de volume** desse gasto: SDAAL (liga provider
tarde), skills (carrega conhecimento sob demanda), L0→L3 (liga especificidade tarde). Eles não
eliminam o trade-off eficiência↔deliberação — dão o controle fino sobre ele.

### Princípio 2 — Critério vive no domínio, não no gerador

A "escolha assertiva de caminho" só é tão boa quanto o domínio em que se apoia. Os critérios
de seleção de estratégia devem **referenciar** os contextos peer (`business-context/`,
`technical-context/`, `compliance-context/`) — não residir no julgamento momentâneo do modelo.
Isto reusa a doutrina já aceita do ADR de ciclo de vida de contexto (SSOT viva).

### Princípio 3 — O fio condutor é externalizado, sempre

Dentro de um contexto, o fio condutor **degrada** (context window enche, sumariza). Logo:

- O objetivo maior vive escrito numa sessão/spec; cada fase **re-lê antes de agir**.
- Redirecionamento é barato **quando o ponto de divergência e a meta estão ambos escritos**.
- Por isso os workflows faseados retomáveis são invariantes — a retomabilidade *é* a
  preservação do fio através de fronteiras de contexto. Esta doutrina os generaliza:
  *qualquer* estratégia composta deve registrar seu ponto de reroute.

### Princípio 4 — Coerência intenção↔resultado exige verificação independente

O modelo que produz o resultado é o pior juiz dele. Para fechar o gap intenção↔resultado,
estratégias de alto risco **devem** terminar com verificação de contexto fresco / prompt
adversarial contra o objetivo declarado. "Coerência" auto-relatada não conta.

---

## Consequências

- **Positivas**: torna auditável uma decisão hoje ad-hoc (qual regime, quanto deliberar);
  alinha-se ao ativo de venda "auditabilidade" do reposicionamento; dá aos autores de
  comando uma regra L0 para consultar em vez de improvisar.
- **Custo**: mais um nível doutrinário a manter; risco de virar ritual se a regra for vaga
  (mitigar com exemplos concretos por regime, não prosa).
- **Aberto** (ver Doc 4): formato exato (meta-spec nova vs seção em `architecture.md`?),
  e se isto vira *capacidade* executável (Doc 2) ou fica como doutrina lida pelo autor.

---

## Alternativas consideradas

1. **Não fazer nada** — manter implícito. Rejeitado: é o mesmo baseline ad-hoc que o SDAAL
   superou para integrações; reaparece como deriva silenciosa de qualidade entre comandos.
2. **Só capacidade, sem doutrina** — criar um comando de seleção de estratégia sem L0.
   Rejeitado: capacidade sem doutrina não tem critério de quando usá-la (recursão do mesmo gap).
3. **Doutrina + capacidade** (recomendado) — este ADR + Doc 2. A doutrina dá o critério; a
   capacidade dá o atuador. Ordem: ADR primeiro (barato, reversível), capacidade depois.
