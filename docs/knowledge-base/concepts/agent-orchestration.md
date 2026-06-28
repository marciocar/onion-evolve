# Agent Orchestration

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.3.0 |
| **Data de Criação** | 2026-06-13 |
| **Última Atualização** | 2026-06-20 |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Camada de Orquestração de Agentes |

### Fontes

**Substrato nativo (Claude Code, 2026):**

- [Introducing Dynamic Workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) — ferramenta Workflow (`agent`/`parallel`/`pipeline`/`schema`/`isolation`/`budget`), research preview (28/mai/2026)
- [Claude Code Release Notes — v2.1.172](https://docs.claude.com/en/docs/claude-code/release-notes) — nesting de subagentes até 5 níveis (10/jun/2026)
- [Agent View — General Availability](https://docs.claude.com/en/docs/claude-code/agent-view) — observabilidade de orquestração (GA, mai/2026)
- [Building Effective Agents — Anthropic](https://www.anthropic.com/engineering/building-effective-agents) — padrões canônicos de orquestração (2026)
- [The State of Agentic Coding 2026 — Context Studios](https://contextstudios.ai/) — doutrina da "era da orquestração"
- [Claude Code — Agent Teams](https://code.claude.com/docs/en/agent-teams) — substrato experimental de peers persistentes (`TeamCreate`/`SendMessage`/task list compartilhada), atrás de `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

**Relacionados no Onion:**

- [`ai-agent-design-patterns.md`](ai-agent-design-patterns.md) — KB irmã (design de agentes)
- [`docs/analysis/onion-agent-teams-evaluation-2026-06.md`](../../analysis/onion-agent-teams-evaluation-2026-06.md) — decisão de framework sobre Agent Teams (opt-in, não padrão)

---

## 🎯 Visão Geral

Uma **orquestração de subagentes** é a **execução paralela coordenada de subagentes especializados** sob um único orquestrador. Em vez de um agente único processar uma tarefa de ponta a ponta de forma serial, a orquestração **decompõe** o trabalho, **despacha** N subagentes em paralelo (fan-out), aguarda (ou não) sua conclusão e **consolida** os resultados (fan-in).

A partir de jun/2026, no Claude Code, a orquestração deixou de ser "promptware" e passou a assentar sobre a ferramenta nativa **Workflow** (research preview, 28/mai/2026). A coordenação roda em **JavaScript** e custa **0 tokens de modelo** — apenas os subagentes consomem tokens. O orquestrador descreve o **grafo de execução** em código, não em prosa.

As cinco propriedades que definem uma orquestração madura:

| Propriedade | O que significa |
|-------------|-----------------|
| **Paralelismo coordenado** | Fan-out de subagentes + fan-in de resultados sob barreira (`parallel`) ou esteira (`pipeline`). |
| **Isolamento** | Cada worker pode rodar em sua própria git worktree (`isolation: 'worktree'`), sem colisão de estado. |
| **Verificação** | Geradores são contestados por críticos/juízes antes de o resultado ser aceito. |
| **Budget** | Teto de tokens por agente e por run, contendo custo de execuções longas. |
| **Observabilidade** | Cada subagente é inspecionável em tempo real via Agent View. |

> A camada de orquestração é o nível operacional acima do design de agente individual. Para o design do agente em si (identidade, ferramentas, especialização), veja a KB irmã [`ai-agent-design-patterns.md`](ai-agent-design-patterns.md).

---

## ⚖️ Orquestração vs. Agente Único

Orquestração **não é default**. Ela paga overhead de coordenação, multiplica custo de tokens e introduz pontos de falha paralelos. Use o teste abaixo antes de despachar uma orquestração.

### Quando a orquestração vence

- **Subtarefas independentes** — o trabalho se decompõe em unidades que não dependem umas das outras (ex.: auditar 4 módulos distintos). O fan-out converte tempo serial em tempo paralelo.
- **Varredura ampla** — cobrir muitas fontes/arquivos/hipóteses (ex.: pesquisar 12 fontes web, varrer um monorepo). Workers Haiku/Sonnet baratos cobrem a largura.
- **Verificação adversarial** — quando a qualidade exige que um resultado seja contestado por múltiplos céticos antes de aceito.
- **Geração de candidatos** — produzir muitas alternativas e filtrar/rankear (generate-and-filter, tournament).

### Quando NÃO compensa

- **Trabalho serial dependente** — cada passo precisa do resultado do anterior. Fan-out aqui só adiciona barreiras vazias; use um `pipeline` linear ou um único agente.
- **Custo/overhead desproporcional** — a tarefa é pequena o bastante para um agente único resolver mais barato do que o custo de decompor + coordenar + sintetizar.
- **Fan-out sem independência real** — se os "workers" compartilham estado mutável ou um depende do output do outro, a paralelização produz corrida de dados ou retrabalho.
- **Contexto profundamente compartilhado** — quando todos os subagentes precisariam do mesmo contexto grande, replicá-lo por worker desperdiça tokens; um agente único com bom context boundary pode ganhar.

**Regra de bolso:** a orquestração se justifica quando `largura × independência` é alta o suficiente para amortizar o custo de coordenação e síntese.

---

## 🔀 Dois Substratos de Orquestração: Workflow vs Agent Teams

> **Status (jun/2026):** Agent Teams é **experimental**, atrás da flag `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (off por default). O substrato **default e portável** da orquestração Onion é a ferramenta **Workflow**. Esta seção fixa a fronteira; a decisão de framework está registrada em [`docs/analysis/onion-agent-teams-evaluation-2026-06.md`](../../analysis/onion-agent-teams-evaluation-2026-06.md).

Decididos a usar uma orquestração (acima), restam **dois substratos** com modelos de coordenação opostos. Não competem — cobrem **shapes de trabalho diferentes**:

| | **Workflow** (default) | **Agent Teams** (opt-in, experimental) |
|---|---|---|
| Modelo | Fan-out de workers **stateless** | Peers **persistentes** + mailbox |
| Coordenação | **Determinística** — script JS controla o grafo (loop/cond/`parallel`/`pipeline`) | **Emergente** — agentes negociam em runtime via `SendMessage` |
| Estado | Efêmero; resultados retornam ao script | Idle entre turnos; **task list compartilhada** (`owner`/`blockedBy`) |
| Retomável | Sim (journal de run) | Parcial (sem resumption de teammate in-process) |
| Custo de coordenação | **0 tokens** (roda em JS) | Tokens (cada turno de teammate + lead) |
| Auditável | Alto (grafo explícito, determinístico) | Menor (coordenação emergente) |
| Substrato | ferramenta `Workflow` | `TeamCreate` / `SendMessage` / task list nativa |

### Decisão: qual substrato

```
A forma do trabalho é CONHECIDA antes de começar (decompõe-se num grafo)?
├── SIM → Workflow. Determinístico, 0-token de coordenação, retomável, auditável.
│         (auditoria, migração, review, pesquisa, generate-and-filter, tournament…)
└── NÃO → o trabalho exige NEGOCIAÇÃO VIVA entre sub-streams, ou redirecionamento
          humano no meio do voo?
          ├── SIM → Agent Teams — SE a flag estiver on; senão degrade p/ Workflow/serial.
          │         (ex.: agente de front e de back acertando um contrato de API em tempo real)
          └── NÃO → Workflow.
```

**Regra de bolso:** Workflow é o **default**. Agent Teams só ganha quando a coordenação **não pode ser pré-desenhada** como grafo — quando os agentes precisam *conversar* para decidir o próximo passo. Se você consegue escrever o grafo, Workflow é mais barato, mais auditável e portável.

> **Sessões faseadas ≠ orquestração.** Lembre que os workflows faseados retomáveis (`.claude/sessions/`, p.ex. `engineer/plan→pr-update`) são o **backbone** de trabalho single-thread com humano no loop — outra camada, que **nenhum** dos dois substratos de orquestração substitui. A orquestração (Workflow ou Agent Teams) paraleliza *dentro* de uma fase, não funde fases.

### Postura no Onion: capacidade opt-in com fallback gracioso

Agent Teams entra como **terceiro modo opt-in**, nunca requisito duro — mesmo espírito **SDAAL** dos adapters de forge/task-manager:

- **Detecção de capacidade:** `onion-orchestration` verifica `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` antes de preferir Agent Teams.
- **Fallback gracioso:** flag off → degrade para Workflow (ou serial), avisando em pt-BR; **nunca** assumir a flag ligada.
- **Portabilidade preservada:** o Onion é template instalável em **qualquer** projeto; não pode depender de feature experimental gated → o default permanece Workflow.
- **Mesma invariante arquitetural:** orquestre no **nível principal** (skill/comando) — o "lead" do time é a própria sessão principal. **Nunca** dentro de um agente (§4.2; ver [Aplicação no Onion](#-aplicação-no-onion)).
- **Escopo é DENTRO de um repo, nunca cross-repo.** Agent Teams coordena dentro de **uma sessão/worktree** — **não há suporte multi-repo nativo** (limitação oficial, jun/2026). Coordenação multi-repo na prática se faz por **git + file-lock** (o próprio caso do compilador C da Anthropic — *Building a C compiler with a team of parallel Claudes*), não por Agent Teams. Logo, **Agent Teams ≠ co-evolução entre repos** — esta vive na camada git-async (ledger + doc-bridge), com a linha vermelha do A2A-runtime cross-repo intacta. Ver [`onion-adr-comms-transport-vs-execution-2026-06.md`](../../analysis/onion-adr-comms-transport-vs-execution-2026-06.md).

> **Postura da Anthropic (fonte oficial):** autonomia **com salvaguardas**, não launch-and-forget —
> *stopping conditions*, sandbox + guardrails, e gates por **classificador de risco** (Claude Code
> *auto mode*) que escala ao humano após N bloqueios. Para Agent Teams, recomenda **hooks**
> (`TeammateIdle`/`TaskCompleted`) como quality gates. Alinha-se ao §7.5 abaixo.

> Reavaliar quando Agent Teams sair de experimental: a ressalva de portabilidade cai e a fronteira pode ser revista.

---

## 🧩 Os 6 Padrões Canônicos da Anthropic (2026)

Seis padrões de referência, cada um mapeado a uma primitiva nativa da ferramenta Workflow. Sinônimos históricos entre parênteses.

> **Nota sobre "Map-Reduce":** "Map-Reduce" **não** é um padrão canônico nomeado no léxico Anthropic 2026. Ele é, na prática, **fan-out-and-synthesize** (o "map" é o `parallel`, o "reduce" é o `agent` de síntese). Use o nome canônico.

### 1. classify-and-act (Router)

**Definição:** classifica a entrada e roteia para o handler especializado correto.
**Quando usar:** entrada heterogênea com handlers distintos (ex.: triagem de issue → bug vs. feature vs. docs).

```javascript
const kind = await agent("Classifique este ticket: bug | feature | docs", { schema: KindSchema });
const handlers = { bug: triageBug, feature: planFeature, docs: writeDocs };
const result = await agent(handlers[kind.label], { schema: ResultSchema });
```

### 2. fan-out-and-synthesize (Fan-out/Fan-in; Map-Reduce informal)

**Definição:** dispara N workers em paralelo e consolida os resultados em um output único.
**Quando usar:** subtarefas independentes que precisam de uma síntese final (ex.: auditoria multi-dimensão).

```javascript
const findings = await parallel([
  () => agent("Audite segurança do módulo de auth", { schema: FindingSchema }),
  () => agent("Audite performance das queries", { schema: FindingSchema }),
  () => agent("Audite cobertura de testes", { schema: FindingSchema }),
]);
// Barreira liberada: todos retornaram. Consolida.
const report = await agent(`Sintetize: ${JSON.stringify(findings)}`, { schema: ReportSchema });
```

### 3. adversarial verification (Generator-Critic; Peer Review)

**Definição:** um agente produz, outro contesta — reduz erro e alucinação.
**Quando usar:** qualidade crítica, onde uma segunda opinião cética vale o custo extra.

```javascript
let draft = await agent("Escreva a migração SQL", { schema: SqlSchema });
const critique = await agent(`Conteste esta migração buscando falhas: ${draft.sql}`, { schema: CritiqueSchema });
if (!critique.approved) draft = await agent(`Corrija conforme: ${critique.issues}`, { schema: SqlSchema });
```

### 4. generate-and-filter

**Definição:** gera muitos candidatos e filtra os que passam no critério.
**Quando usar:** espaço de soluções amplo, com critério de aceitação objetivo (ex.: gerar variações e manter as que compilam).

```javascript
const candidates = await parallel(
  Array.from({ length: 8 }, (_, i) => () => agent(`Gere abordagem #${i}`, { schema: CandidateSchema }))
);
const passing = candidates.filter((c) => c.compiles && c.testsPass); // filtro em JS = 0 tokens
```

### 5. tournament

**Definição:** compara candidatos em rodadas eliminatórias até eleger o melhor.
**Quando usar:** muitos candidatos viáveis sem critério booleano simples — a comparação relativa decide.

```javascript
// Rodadas eliminatórias com BARREIRA entre rodadas (a próxima depende dos
// vencedores). Cada rodada usa parallel() (confrontos independentes ENTRE SI);
// a redução do campo acontece em JS (0 tokens) antes da rodada seguinte.
let field = candidates;
while (field.length > 1) {
  const pairs = chunk(field, 2);
  field = (await parallel(
    pairs.map(([a, b]) => () => agent(`Escolha o melhor entre A e B`, { schema: WinnerSchema }))
  )).filter(Boolean);                       // redução: N → N/2
}
const winner = field[0];
```

> **Primitivo:** `parallel()` **por rodada** (com barreira entre rodadas), **não**
> `pipeline()`. As rodadas são **dependentes** (a Final precisa dos vencedores), o
> que exige barreira; `pipeline` é sem barreira e serve a itens independentes. A
> redução N→N/2 entre rodadas roda em JS.

### 6. loop-until-done (loop-until-dry)

**Definição:** itera um agente até satisfazer uma condição de parada.
**Quando usar:** trabalho de exaustão (ex.: corrigir até zero erros de lint), sempre com guarda de `budget`.

```javascript
let state = await agent("Corrija o próximo lote de erros de lint", { schema: StateSchema });
while (!state.done && tokensUsed < budget) {
  state = await agent(`Continue a partir de: ${state.cursor}`, { schema: StateSchema });
}
```

### Tabela-resumo

| Padrão | Sinônimos | Primitiva nativa |
|--------|-----------|------------------|
| classify-and-act | Router | `agent` (classificador) → `agent` (handler) |
| fan-out-and-synthesize | Fan-out/Fan-in, Supervisor/Orchestrator-Worker, Map-Reduce (informal) | `parallel([...])` + `agent` de síntese |
| adversarial verification | Generator-Critic, Peer Review | `agent` (gerador) + `agent` (crítico) |
| generate-and-filter | — | `parallel([...])` + filtro JS/`agent` |
| tournament | Bracket | `parallel()` por rodada (barreira entre rodadas) + redução JS |
| loop-until-done | loop-until-dry | `agent` em loop JS + guarda de `budget` |

---

## 🛠️ Primitivas Nativas (Workflow / Agent)

A ferramenta **Workflow** é o substrato de orquestração. A ferramenta **Agent** dispara 1 subagente especializado.

| Primitiva | Papel | Semântica |
|-----------|-------|-----------|
| `agent(prompt, opts)` | Dispara **1 subagente** | Unidade de trabalho; aceita `model`, `schema`, `budget`, `isolation`. |
| `parallel([thunks])` | **Fan-out com barreira** | Aguarda **todos** terminarem antes de prosseguir. |
| `pipeline(items, stage1, stage2, ...)` | Esteira por itens | **Sem barreira** entre itens — cada item flui pelos estágios independentemente. |
| `schema` | Structured output validado | Garante o shape do retorno de cada agente. |
| `isolation: 'worktree'` | Isolamento por git worktree | Cada agente em sua própria árvore de trabalho. |
| `budget` | Teto de tokens | Limite de custo por agente/run. |

**Barreira vs. sem barreira:** `parallel` é a escolha quando há um passo de fan-in que precisa de **todos** os resultados (síntese). `pipeline` é a escolha quando cada item pode percorrer os estágios no seu próprio ritmo, sem esperar os demais (maior throughput).

**Limites operacionais (jun/2026):** até **16 subagentes concorrentes** e **1.000 agregados por run**.

**Coordenação = 0 tokens:** a lógica de fan-out/fan-in/filtro/loop roda em JavaScript no orquestrador. Não há custo de modelo na coordenação — só os subagentes pagam tokens. Isso muda o eixo econômico: vale a pena empurrar o máximo de lógica determinística para o JS.

**Nesting (5 níveis):** desde **10/jun/2026 (v2.1.172)**, subagentes podem aninhar **até 5 níveis** de profundidade. Antes, o fan-out era de nível único. Mesmo com nesting disponível, a recomendação permanece: **orquestrar no nível principal** (skill/comando), não dentro de um subagente — é mais barato e respeita a regra arquitetural do Onion.

---

## 🛡️ Verificação Adversarial / Judge-Panel

O caso mais forte de verificação é o **judge-panel**: N céticos avaliam o mesmo artefato em `parallel`, e a decisão sai por **voto** (maioria, unanimidade, ou média ponderada). É a aplicação direta de *adversarial verification* em escala de orquestração.

```javascript
const verdicts = await parallel(
  Array.from({ length: 3 }, () => () =>
    agent(`Você é um revisor cético. Aprove ou rejeite, com justificativa: ${JSON.stringify(artifact)}`,
      { schema: VerdictSchema, model: "sonnet-4.6" })
  )
);
const approved = verdicts.filter((v) => v.approve).length > verdicts.length / 2; // voto em JS
```

**Quando exigir judge-panel:**

- Saída irreversível ou de alto custo de erro (migração de schema, deploy, mudança regulada).
- Risco de alucinação relevante (claims factuais, números, citações).
- Decisões onde uma única opinião é frágil — diversidade de céticos reduz viés correlacionado.

**Quando um único crítico basta:** revisões de baixo risco, onde o overhead de um painel não se justifica.

---

## ⚙️ Autonomia e Eficiência

### Hierarchical model tiers

Padrão de custo-eficiência: **modelos diferentes por papel** no grafo.

- **Lead (orquestrador)** → tier **opus**: raciocínio sobre o grafo, decomposição, síntese final.
- **Workers** → tiers **sonnet** / **haiku**: trabalho paralelo de alto volume, onde o tier mais barato basta.

A ferramenta Workflow permite fixar o `model` por chamada de `agent(...)`, então o lead opus despacha dezenas de workers sonnet/haiku sob `budget`, mantendo a qualidade da coordenação sem pagar opus em cada folha.

### Disponibilidade de modelos (fonte única)

> **Atualize o lineup SÓ aqui.** Os demais artefatos referenciam modelos por **tier** (evergreen), nunca por versão exata, e apontam para esta seção. Quando um modelo é adicionado, deprecado ou **bloqueado** (regional/política), basta atualizar esta nota — o resto continua válido.

| Tier | Uso típico | Disponibilidade (jun/2026) |
|---|---|---|
| `opus` | orquestrador, juízes adversariais | geral |
| `sonnet` | raciocínio de média complexidade | geral |
| `haiku` | workers mecânicos, alto volume | geral |
| `fable` | — | **restrita** — bloqueio do governo dos EUA (jun/2026); verificar antes de usar |

Tiers de **worker** recomendados (uso geral): **opus / sonnet / haiku**. Snapshot de versões à época (jun/2026, apenas referência histórica, não normativa): Opus 4.8 / Sonnet 4.6 / Haiku 4.5 / Fable 5. Não existe "gpt-4" nem qualquer modelo de outro provider como opção de modelo de agente no Claude Code.

### Outras alavancas de eficiência

- **Prompt caching** — para runs longos e workers que compartilham um preâmbulo grande, o cache de prompt corta custo e latência repetidos.
- **Budget-gated loops** — todo loop (`loop-until-done`) deve ter guarda de `budget` para não divergir.
- **loop-until-dry** — itere até a fonte de trabalho "secar" (zero erros restantes), não por contagem fixa.
- **Completeness critic** — antes de declarar pronto, um agente crítico verifica se a orquestração cobriu todo o escopo (evita fan-out que deixa lacunas silenciosas).

---

## 🔒 Orquestração Mutante: Isolamento, Consolidação e Autonomia

Até aqui os padrões foram **read-only** (auditar, pesquisar, verificar). Quando a
orquestração **muta** o repositório em paralelo, há corrida de escrita — e a forma de
evitá-la **com eficiência** é a parte que distingue uma orquestração mutante operacional
de um blueprint. Regra-mãe: **particione primeiro; isole por worktree só quando
precisar; consolide numa única branch.**

### 7.1 Decisão: partição-primeiro vs. worktree

```
Os workers tocam conjuntos de arquivos DISJUNTOS?
├── SIM → particione por arquivo/módulo. Sem corrida → NÃO use worktree.
│         (mais barato: sem custo de setup de worktree; consolidação trivial)
└── NÃO → há sobreposição real OU são branches independentes a fundir?
          └── SIM → isolation: 'worktree' por worker; orquestrador funde após a barreira.
```

**Por que partição primeiro:** criar uma git worktree custa **~200-500 ms + disco
por agente**. Se o orquestrador consegue dividir o trabalho em conjuntos de
arquivos disjuntos (ex.: "adicione `version:` em cada um destes 40 comandos"),
**não há colisão** e o worktree é desperdício. Worktree só ganha quando os workers
inevitavelmente tocam o mesmo arquivo, ou quando cada um produz uma **branch
independente** (ex.: duas implementações concorrentes da mesma feature a comparar).

> **Regra de break-even:** use `isolation: 'worktree'` apenas quando a corrida de
> escrita é **inevitável** por partição. Caso contrário, partição-primeiro é mais
> rápido e mais simples de consolidar.

### 7.2 `DiffSchema` (output estruturado do worker mutante)

Todo worker mutante retorna seu resultado neste shape — o fan-in opera sobre ele
em JS (0 tokens):

```javascript
const DiffSchema = {
  worker: "string",            // id/rótulo do worker
  files: [                     // arquivos que o worker alterou
    { path: "string", action: "create|edit|delete", summary: "string" }
  ],
  branch: "string|null",       // nome da worktree/branch efêmera (quando isolation='worktree')
  status: "done|skipped|failed",
  notes: "string"              // contexto p/ o gate humano, se houver
};
```

### 7.3 Playbook de consolidação (o "merge" que faltava)

O fan-in de uma orquestração mutante roda no orquestrador (JS, 0 tokens):

1. **Coletar** — `results.filter(Boolean)` (worker morto → `null`; reporte os SKIP).
2. **Detectar sobreposição** — em JS, cruze os `files[].path` de todos os workers.
   - **Partição limpa** (nenhum path repetido) → aplicar todos os diffs na branch
     de consolidação; sem conflito possível.
   - **Sobreposição** (2+ workers no mesmo path) → **não** auto-mesclar às cegas:
     - geração-e-seleção (abordagens concorrentes) → **judge-panel** escolhe/funde;
     - mutação que deveria ser disjunta mas colidiu → **gate humano** (a partição
       falhou; o humano decide).
3. **Aplicar numa única branch de consolidação** — uma branch (ex.:
   `orchestration/<tarefa>-<data>`), não N branches soltas.
4. **Verificação adversarial** em alto risco — um crítico contesta o diff agregado
   (lint, testes, coerência) antes de aceitar.
5. **Gate humano** para irreversível/conflito (ver 7.5).

```javascript
// Partição-primeiro: workers em conjuntos disjuntos → SEM worktree
const results = (await parallel(
  partitions.map((files) => agent(
    `Aplique a transformação X SOMENTE nestes arquivos: ${files.join(", ")}. Retorne DiffSchema.`,
    { schema: DiffSchema, model: "haiku" }
  ))
)).filter(Boolean);

// fan-in em JS (0 tokens): detectar colisão entre partições
const seen = new Map();
const collisions = [];
for (const r of results) for (const f of r.files) {
  if (seen.has(f.path)) collisions.push(f.path);
  seen.set(f.path, r.worker);
}
if (collisions.length) {
  // partição falhou → gate humano, NÃO auto-merge
  return reportConflict(collisions, results);
}
// partição limpa → tudo numa branch de consolidação → fluxo normal de PR
```

### 7.4 Worktree efêmero → 1 branch (ciclo de vida + saída)

- **Ciclo de vida automático:** o param `isolation: 'worktree'` da ferramenta
  Workflow **cria e limpa** a worktree por agente (auto-removida se inalterada).
  **Não** se usa `EnterWorktree`/`ExitWorktree` manual — a ferramenta gerencia.
- **Worker morto** → o `agent()` retorna `null`; `.filter(Boolean)` antes do fan-in.
- **Saída = uma branch consolidada**, nunca N branches persistentes. Essa branch
  entra no **fluxo normal**: `/git:flow feature finish` ou `/engineer:pr` (via
  forge adapter, `.claude/utils/forge/`) → **gate de PR**. A orquestração paraleliza
  *dentro* da fase de implementação; **não** funde fases nem cria branches que
  contornem o gate (invariante — `commands.md §10.3`).

```javascript
// Worktree só quando há sobreposição/branches independentes a comparar:
const branches = (await parallel([
  () => agent("Implemente a abordagem A da feature", { isolation: "worktree", schema: DiffSchema }),
  () => agent("Implemente a abordagem B da feature", { isolation: "worktree", schema: DiffSchema }),
])).filter(Boolean);
// judge-panel escolhe a melhor; orquestrador consolida UMA branch → /git:flow / /engineer:pr
```

### 7.5 Autonomia e gates (control before autonomy)

> **O eixo de risco é o ATO, não a conversa.** O que exige gate não é agentes se
> coordenarem (mailbox, `SendMessage`) — é o ato de **ler+interpretar+executar** algo
> irreversível. **Transportar** e **notificar** (mover resultado, avisar) são
> determinísticos e automatizáveis; **executar** o passo crítico é gate humano. A2A é
> ortogonal ao risco. Eixo completo (co-evolução e orquestração) em
> [`onion-adr-comms-transport-vs-execution-2026-06.md`](../../analysis/onion-adr-comms-transport-vs-execution-2026-06.md).

A orquestração **propõe**; o humano **confirma** o passo crítico. Exija **gate humano**
quando:

- a operação é **irreversível** (deploy, merge em produção, mudança regulada);
- a consolidação detectou **conflito** de partição (7.3, passo 2);
- o raio de alcance excede um limiar (ex.: > N arquivos mutados, ou toca
  `engineer/*`/`product/*`).

Doutrina da era da orquestração:

- **Control before autonomy** — gates e limites antes de delegar trabalho amplo.
- **Gates humanos** — irreversível passa por aprovação, mesmo em orquestração autônoma.
- **Delegation gap** — a lacuna entre a intenção do orquestrador e o que os
  workers executam cresce com a profundidade; verificação adversarial a fecha.

---

## 👁️ Observabilidade

Cada subagente de uma orquestração é inspecionável via **Agent View** (GA, mai/2026): estado, prompt, tokens consumidos e output estruturado de cada worker em tempo real. Sem essa visibilidade, uma orquestração é uma caixa-preta — um worker travado ou divergente passa despercebido até o fan-in.

Superfícies relacionadas (jun/2026): **Managed Agents** (beta, abr/2026) e **Routines** (research preview, mai/2026).

---

## ⚠️ Armadilhas

| Armadilha | Sintoma | Mitigação |
|-----------|---------|-----------|
| **Custo de token** | Orquestração custa mais que o valor entregue. | Use tiers (Haiku/Sonnet workers), `budget`, prompt caching; reavalie se a orquestração se justifica. |
| **Overhead de coordenação** | Decompor + sintetizar custa mais que resolver direto. | Para tarefas pequenas, prefira agente único. |
| **Verificação insuficiente** | Output aceito sem contestação; alucinação passa. | Adicione crítico ou judge-panel em saídas de alto risco. |
| **Fan-out sem independência real** | Workers competem por estado ou um depende do outro → corrida/retrabalho. | Garanta independência; use `pipeline` serial ou `isolation: 'worktree'`. |
| **Orquestração dentro de um agente** | Orquestração escondida num subagente, mais cara e fora da regra arquitetural. | Orquestre no nível principal (skill/comando). |
| **Lacunas silenciosas** | Fan-out deixa parte do escopo sem cobertura. | Use um completeness critic antes do fan-in final. |

---

## 🧅 Aplicação no Onion

No Onion (port do Claude Code), a orquestração tem **endereço fixo** ditado pela arquitetura:

- A regra de dependência de `architecture.md` §4.2 **proíbe** `agents/* → commands/*` — um agente **sugere**, não invoca comando nem orquestra subagentes.
- Skills **podem** orquestrar: `skills/* → commands/*, agents/*, docs/*`.

Logo, a camada de orquestração mora em **skill + comando**, **nunca** num agente:

- **Skill** `.claude/skills/onion-orchestration/` — cérebro de orquestração: descreve o grafo (qual padrão canônico, quais primitivas, quais tiers).
- **Comando** `/meta:orchestrate` — ponto de invocação no nível principal, onde a coordenação JS roda a 0 tokens.

> **Nunca crie um agente `worker-orchestrator`.** Isso violaria §4.2 e esconderia a orquestração no lugar mais caro. A orquestração é responsabilidade do nível principal.

> **Locus ≠ forma — hierarquia NÃO é proibida.** O que se proíbe é o **locus** (orquestração *dentro* de um agente). A **forma do grafo** é livre: plano (default) ou **árvore** (workers agrupados sob nós sumarizadores — *aggregator/sub-synthesizer*) é **legítima**, desde que **composta no nível principal** (`parallel`/`pipeline` aninhados), nunca por um agente que orquestra. Não infira "hierarquia = proibida" do silêncio: o proibido é a inversão de controle (worker dirigindo a orquestração), não a topologia. Quando usar árvore (síntese por LLM que estoura 1 agente) é caso-limite estreito — ver [ADR de topologia](../../analysis/onion-orchestration-topology-adr-2026-06-21.md). É a mesma lógica da [economia de motores](onion-engine-economy.md): o fan-in determinístico em JS vence por default; o motor LLM (nó sumarizador) entra só por necessidade.

### Cross-links

- [`docs/meta-specs/commands.md`](../../meta-specs/commands.md) — constituição L0 dos comandos (categoria `meta/` abriga `/meta:orchestrate`; o grafo de orquestração não é um workflow faseado retomável, e sim coordenação efêmera intra-run).
- [`ai-agent-design-patterns.md`](ai-agent-design-patterns.md) — KB irmã: design do agente individual e os mesmos padrões sob a ótica de design.

---

**Próxima Atualização Planejada**: Dezembro 2026
**Responsável**: Sistema Onion
