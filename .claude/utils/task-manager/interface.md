# 📐 Interface ITaskManager

## 🎯 Propósito

Define o contrato que todos os adapters de gerenciadores de tarefas devem implementar, garantindo consistência e permitindo troca transparente de provedores.

Desde a **Onda 2 da SDAAL do Task Manager** (SAC-63, 2026-10-11) o contrato tem duas metades:

1. **as assinaturas** — o vocabulário canônico e cada operação tipada (abaixo);
2. **a declaração de capacidades** — cada adapter diz, num arquivo irmão `adapters/<provedor>.capabilities.tsv`,
   o que implementa, o que não implementa e o que **ninguém verificou**, com a fonte de cada afirmação.

A segunda metade existe porque a primeira, sozinha, mentia por omissão: uma interface de 14 métodos
que todo adapter "implementa" não diz qual deles foi **medido** contra o provedor. A Onda 1 (pesquisa
de primárias de 2026-10-11, grafo `task-manager-vocabulario-2026-10`) mostrou o tamanho disso: das 12
capacidades pesquisadas, nenhuma fechou para todos os provedores, e a célula de **versão de API** não
fechou para nenhum.

---

## 🧭 Vocabulário canônico

Os conceitos que a interface fala. O adapter traduz cada um para o provedor; o consumidor nunca vê a
forma do provedor.

| Conceito | Forma canônica | Observação |
|---|---|---|
| **Item** | `TaskOutput` com `level: 'epic' \| 'task' \| 'subtask'` | `epic` é o agrupador acima da task (épico no Jira, milestone no Zoho); a profundidade máxima de subtask **não foi ancorada** para nenhum provedor |
| **Status** | `TaskStatus` (7 valores) + **transição** por `updateStatus` | o adapter resolve o nome do provedor; nunca inventa status que o projeto/lista não tem |
| **Prioridade** | `TaskPriority` (`urgent` \| `high` \| `normal` \| `low`) | normalizada; o mapa por provedor está em [Prioridade](#prioridade), com a fonte de cada coluna |
| **Estimativa** | `storyPoints?: number` (complexidade) e `timeEstimate?: number` (minutos) | duas grandezas, nunca uma: pontos não são tempo |
| **Comentário** | corpo canônico em **Markdown**; a conversão é do adapter | ADF no Jira Cloud, string no DC, `text`/`html_text` no Asana — a interface não vê o formato ([texto rico](#texto-rico-é-assunto-do-adapter)) |
| **Anexo** | `AttachmentInput { filename, contentType, bytes }` | |
| **Label** | `tags: string[]` | no ClickUp a escrita de tag **não** vai no corpo do update (medido em 2026-10-02) |
| **Iteração** | `Iteration { id, name, startDate?, endDate? }` | sprint (Jira, ClickUp) ou cycle (Linear) |
| **Vínculo** | `createLink(from, to, type: LinkType)` | `LinkType = 'blocks' \| 'blocked_by' \| 'relates' \| 'duplicates'` |
| **Busca** | `searchTasks` (1ª página) e `searchPage` (iterador opaco) | o consumidor nunca vê offset, índice nem cursor ([paginação](#paginação-é-iterador-opaco)) |
| **Lote** | `bulkCreate` / `bulkUpdate`, **declarados por operação** | o limite é do adapter e vai na declaração ([lote](#lote-é-por-operação)) |

### Paginação é iterador opaco

Herdado de `C_PAGINATION_AS_OPAQUE_ITERATOR` (Onda 1). Os cinco provedores lidos usam cinco
mecanismos: `nextPageToken` que **expira em 7 dias** (Jira Cloud `/search/jql`), `startAt` (Jira DC),
índice de página com 100 por página (ClickUp), offset opaco que expira (Asana) e cursor Relay (Linear).
A interface expõe só **próxima página ou fim**:

```typescript
type PageCursor = string & { readonly __opaque: unique symbol };   // o consumidor só repassa
interface Page<T> { items: T[]; next: PageCursor | null }          // null = fim
```

Restrições que a Onda 1 deixou e que esta interface respeita:

- o cursor **pode expirar** (Jira Cloud, Asana). O consumidor não guarda cursor entre sessões;
- a paginação do **search do Asana** e a do `/rest/api/2/search` do DC **não foram ancoradas**
  (a do DC veio de uma seção genérica da doc). As declarações dizem `unverified` onde é o caso.

### Texto rico é assunto do adapter

Herdado de `C_RICH_TEXT_FORMAT_IS_ADAPTER_CONCERN`. O corpo de comentário e de descrição entra e sai em
**Markdown**; o adapter converte. Onde o formato do provedor **não foi ancorado**, a capacidade fica
`unverified` na declaração, e não `implemented`:

- o comentário do **Jira Cloud** em ADF tem apoio só na nota de rejeição da Onda 1;
- o corpo do comentário do **ClickUp** não foi ancorado (a descrição, sim: `markdown_content`);
- o formato de **escrita** do comentário do **Linear** não foi ancorado (o de leitura é markdown
  derivado do ProseMirror, o que muda a ida e volta);
- no Jira **DC** o corpo é string, e o wiki markup **não** foi provado.

### Lote é por operação

Herdado de `C_BULK_IS_PER_OPERATION_NOT_UNIFORM`. Não existe "o provedor tem bulk": o Jira ancorou só
**criação** em lote (até 50 no Cloud), o Asana tem um **batch genérico** de 10 ações (não é bulk de
tasks) e o Linear tem `issueBatchCreate`/`issueBatchUpdate` sem limite nem atomicidade ancorados.
Por isso são duas capacidades (`bulk.create`, `bulk.update`), e o limite vai na coluna `note` da
declaração de cada adapter.

---

## 📋 Interface Completa

```typescript
/**
 * Interface abstrata para gerenciadores de tarefas.
 * Todos os adapters (ClickUp, Asana, Jira, Linear, Zoho Projects) devem implementar esta interface.
 * Os membros marcados com `?` são capacidades OPCIONAIS: o adapter que não as implementa as declara
 * `not_implemented` no seu .capabilities.tsv e o consumidor consulta a declaração antes de chamar.
 */
interface ITaskManager {
  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTIFICAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /** Nome do provedor: 'clickup' | 'asana' | 'jira' | 'linear' | 'zoho' | 'none' */
  readonly provider: TaskManagerProvider;

  /** Indica se o provedor está configurado corretamente */
  readonly isConfigured: boolean;

  // ═══════════════════════════════════════════════════════════════════════════
  // ITEM (CRUD)                                  capacidades item.*
  // ═══════════════════════════════════════════════════════════════════════════

  /** item.create — cria uma task (level 'task'). Descrição em Markdown; o adapter converte. */
  createTask(input: CreateTaskInput): Promise<TaskOutput>;

  /** item.read — detalhes de uma task existente. */
  getTask(taskId: string): Promise<TaskOutput>;

  /** item.update — atualização parcial. Campo que o provedor ignora em silêncio é OMITIDO com aviso. */
  updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput>;

  /** item.delete — remove (ou arquiva, onde o provedor só arquiva). */
  deleteTask?(taskId: string): Promise<boolean>;

  // ═══════════════════════════════════════════════════════════════════════════
  // HIERARQUIA                                   capacidades hierarchy.*
  // ═══════════════════════════════════════════════════════════════════════════

  /** hierarchy.subtask_create — cria uma subtask (level 'subtask') vinculada ao pai. */
  createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput>;

  /** hierarchy.subtask_list — subtasks de uma task. */
  getSubtasks(parentId: string): Promise<TaskOutput[]>;

  /** hierarchy.epic — cria o agrupador acima da task (épico, milestone). */
  createEpic?(input: CreateTaskInput): Promise<TaskOutput>;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS                                       capacidade status.transition
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * status.transition — move a task para o status canônico. O adapter resolve o nome/id do
   * provedor (transição no Jira, WorkflowState no Linear, status da List no ClickUp, objeto
   * {id} ou completion_percentage no Zoho). Sem equivalente: omite com aviso, nunca inventa.
   */
  updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput>;

  // ═══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS                                  capacidades comment.*
  // ═══════════════════════════════════════════════════════════════════════════

  /** comment.add — corpo canônico em Markdown; o adapter converte (ADF, string, html_text…). */
  addComment(taskId: string, comment: string): Promise<CommentOutput>;

  /** comment.list — comentários de uma task, corpo devolvido em Markdown. */
  getComments(taskId: string): Promise<CommentOutput[]>;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANEXO · ITERAÇÃO · VÍNCULO                   capacidades opcionais
  // ═══════════════════════════════════════════════════════════════════════════

  /** attachment.add — anexa um arquivo à task. */
  addAttachment?(taskId: string, file: AttachmentInput): Promise<AttachmentOutput>;

  /** iteration.assign — coloca a task numa sprint/cycle (lista as disponíveis com listIterations). */
  assignIteration?(taskId: string, iterationId: string): Promise<TaskOutput>;
  listIterations?(projectId: string): Promise<Iteration[]>;

  /** link.create — vínculo entre duas tasks. Tipo sem equivalente no provedor: erro, não aproximação. */
  createLink?(fromTaskId: string, toTaskId: string, type: LinkType): Promise<boolean>;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSCA                                        capacidades search.*
  // ═══════════════════════════════════════════════════════════════════════════

  /** search.query — 1ª página (até query.limit). Filtro que o provedor ignora é aplicado NO CLIENTE. */
  searchTasks(query: SearchQuery): Promise<TaskOutput[]>;

  /** search.paginate — iterador opaco: passe `next` de volta até vir null. */
  searchPage?(query: SearchQuery, cursor?: PageCursor): Promise<Page<TaskOutput>>;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOTE (por operação)                          capacidades bulk.*
  // ═══════════════════════════════════════════════════════════════════════════

  /** bulk.create — cria N tasks; o adapter fatia pelo limite declarado e devolve o resultado por item. */
  bulkCreate?(inputs: CreateTaskInput[]): Promise<BulkResult<TaskOutput>>;

  /** bulk.update — atualiza N tasks. */
  bulkUpdate?(updates: Array<{ taskId: string; updates: UpdateTaskInput }>): Promise<BulkResult<TaskOutput>>;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJETOS/LISTAS                              capacidades project.*
  // ═══════════════════════════════════════════════════════════════════════════

  /** project.list — projetos/listas disponíveis. */
  getProjectList(): Promise<ProjectOutput[]>;

  /** project.read — detalhes de um projeto. */
  getProject(projectId: string): Promise<ProjectOutput>;

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO (local, sem chamada ao provedor)    capacidade id.validate
  // ═══════════════════════════════════════════════════════════════════════════

  /** id.validate — o formato do id é válido para este provedor? */
  validateTaskId(taskId: string): boolean;

  /** Detecta o provedor de origem de um id (null quando o formato não identifica com certeza). */
  getProviderFromTaskId(taskId: string): TaskManagerProvider | null;
}
```

Os tipos novos (`ItemLevel`, `Page`, `PageCursor`, `AttachmentInput`, `AttachmentOutput`, `Iteration`,
`LinkType`, `BulkResult`) e os campos `level` e `storyPoints` estão em [`types.md`](./types.md).

---

## 🧾 Capacidades — o vocabulário que toda declaração usa

Bloco **lido por máquina** (a guarda do lint o parseia; não mude o formato sem mudar a guarda).
Colunas separadas por TAB:

- `capability` — id canônico;
- `requirement` — `required` (todo adapter tem de implementar; `not_implemented` aqui reprova) ou
  `optional`;
- `scope` — `remote` (fala com o provedor: exige fonte para virar `implemented`) ou `local` (sem
  chamada ao provedor: a fonte é `local`);
- `surface` — o que o adapter tem de conter para a declaração bater com o que ele faz: `método(` para
  operação, `field:<campo>` para campo dos tipos de entrada.

<!-- capabilities:begin -->
```tsv
capability	requirement	scope	surface
item.create	required	remote	createTask(
item.read	required	remote	getTask(
item.update	required	remote	updateTask(
item.delete	optional	remote	deleteTask(
hierarchy.subtask_create	required	remote	createSubtask(
hierarchy.subtask_list	required	remote	getSubtasks(
hierarchy.epic	optional	remote	createEpic(
status.transition	required	remote	updateStatus(
priority.set	optional	remote	field:priority
estimate.points	optional	remote	field:storyPoints
estimate.time	optional	remote	field:timeEstimate
comment.add	required	remote	addComment(
comment.list	required	remote	getComments(
attachment.add	optional	remote	addAttachment(
label.set	optional	remote	field:tags
iteration.assign	optional	remote	assignIteration(
link.create	optional	remote	createLink(
search.query	required	remote	searchTasks(
search.paginate	optional	remote	searchPage(
bulk.create	optional	remote	bulkCreate(
bulk.update	optional	remote	bulkUpdate(
project.list	required	remote	getProjectList(
project.read	required	remote	getProject(
id.validate	required	local	validateTaskId(
```
<!-- capabilities:end -->

### Formato da declaração por adapter

Cada provedor de `TaskManagerProvider` (em [`types.md`](./types.md), menos `none`, que é o Null Object)
tem um arquivo irmão do adapter: `adapters/<provedor>.capabilities.tsv`. Uma linha por capacidade do
bloco acima — **nenhuma faltando, nenhuma fora dele** —, separada por TAB, com cabeçalho:

```tsv
capability	requirement	status	api_version	source	note
```

| Coluna | Valores | Regra |
|---|---|---|
| `requirement` | `required` \| `optional` | igual à do bloco acima (a declaração não rebaixa o contrato) |
| `status` | `implemented` \| `not_implemented` \| `unverified` | ver abaixo |
| `api_version` | texto livre não vazio | a versão que **o adapter mira** — não a "vigente", que a Onda 1 não ancorou para nenhum provedor |
| `source` | refs separadas por `;`, ou `-` | `kg:<id-do-grafo>#<NÓ>` (evidência ancorada) · `adapter:<arquivo>§<trecho literal>` (medição datada registrada no adapter) · `local` (só para `scope: local`) |
| `note` | texto livre | limite de lote, restrição, a lacuna que deixou a célula aberta |

O que cada `status` afirma:

- **`implemented`** — o adapter tem a superfície **e** uma fonte mostra que ela funciona contra o
  provedor (evidência ancorada num grafo, ou medição ao vivo datada no próprio adapter). Exige `source`.
- **`unverified`** — o adapter tem a superfície, mas ninguém ancorou nem mediu o comportamento contra o
  provedor. É a marca honesta das células que a Onda 1 deixou abertas (`Q_TASK_MANAGER_VOCABULARY_MATRIX`,
  `Q_WAVE2_PRIMARIES_CELLS`). Não é defeito: é o que falta medir, à vista.
- **`not_implemented`** — o adapter não tem a superfície. O provedor pode suportar (a `note` e a `source`
  dizem quando a Onda 1 ancorou o suporte do lado do provedor); o adapter não chama.

**O consumidor consulta a declaração antes de chamar uma capacidade opcional.** Capacidade
`not_implemented` não se emula em silêncio no comando; ou o fluxo degrada declarando, ou o adapter
ganha a implementação, e a declaração muda no mesmo commit.

### A guarda que cobra a declaração (REGRA 103)

A REGRA 103 (Adapter do task-manager declara todas as capacidades da interface, com fonte) do lint do
Onion reprova (HARD):

- provedor sem `.capabilities.tsv`, ou `.capabilities.tsv` de provedor que não existe;
- capacidade da interface faltando, capacidade fora da interface, ou linha duplicada;
- `requirement` diferente do bloco acima; valor fora do enum; `api_version` vazia;
- `required` declarada `not_implemented`;
- `implemented` sem fonte, ou com fonte que não resolve (`kg:` aponta nó inexistente; `adapter:` cita
  trecho que não está no adapter);
- **declaração que não bate com o adapter**: `implemented`/`unverified` sem a superfície no adapter, ou
  `not_implemented` com o método presente.

Onde ela roda: no core e em todo repo que recebe o lint (adotante, porta `onion-core`, `onion-standalone`).
**Não roda na porta `onion-mini`**, que leva o task-manager mas não leva o lint — por desenho da allowlist
didática, não por esquecimento. Num repo derivado, a ref `kg:` cujo grafo não viajou **não é
conferida** (a pesquisa do core não viaja); o core a conferiu antes de publicar.

---

## 📊 Métodos por Categoria

| Categoria | Métodos | Capacidades |
|-----------|---------|-------------|
| **Identificação** | `provider`, `isConfigured` | — |
| **Item** | `createTask`, `getTask`, `updateTask`, `deleteTask?` | `item.*` |
| **Hierarquia** | `createSubtask`, `getSubtasks`, `createEpic?` | `hierarchy.*` |
| **Status** | `updateStatus` | `status.transition` |
| **Campos** | `priority`, `storyPoints`, `timeEstimate`, `tags` em Create/UpdateTaskInput | `priority.set`, `estimate.*`, `label.set` |
| **Comentários** | `addComment`, `getComments` | `comment.*` |
| **Anexo · Iteração · Vínculo** | `addAttachment?`, `assignIteration?`/`listIterations?`, `createLink?` | `attachment.add`, `iteration.assign`, `link.create` |
| **Busca** | `searchTasks`, `searchPage?` | `search.*` |
| **Lote** | `bulkCreate?`, `bulkUpdate?` | `bulk.*` |
| **Projetos** | `getProjectList`, `getProject` | `project.*` |
| **Validação** | `validateTaskId`, `getProviderFromTaskId` | `id.validate` |

---

## 🔄 Mapeamento por Provedor

### Status

| Interface | ClickUp | Asana | Jira | Linear | Zoho Projects |
|-----------|---------|-------|------|--------|---------------|
| `backlog` | "backlog" | - | "Backlog" | "Backlog" | "Open" |
| `todo` | "to do" | - | "To Do" | "Todo" | "Open" |
| `in_progress` | "in progress" | - | "In Progress" | "In Progress" | "In Progress" **se o mapa tiver**; senão `Open` + `completion_percentage` |
| `review` | "review" | - | "In Review" | "In Review" | ⚠️ sem nativo — status customizado do projeto (NÃO MEDIDO) |
| `done` | "done" | completed: true | "Done" | "Done" | o status com `is_closed_type: true` |
| `closed` | "closed" | completed: true | "Closed" | "Canceled" | idem (`is_closed_type: true`) |
| `canceled` | "closed" | completed: true | "Cancelled" | "Canceled" | idem (`is_closed_type: true`) |

⚠️ **Os nomes acima são o ponto de partida, não o contrato.** No ClickUp os status são da **List** (medido
em 2026-10-02: uma List real tinha `to do / in progress / complete`, sem `review`), e o adapter casa por
sinônimo. No Linear o status é `WorkflowState` do team (ancorado na Onda 1); se a transição entre estados
é livre **não** foi ancorado. No Jira a transição existe como endpoint, mas a **obrigatoriedade** dela
(que `PUT /issue` não mude status) segue sem âncora (`Q_JIRA_STATUS_BY_PUT_MEASURE`).

⚠️ **Zoho resolve status por NOME, não por id fixo.** Os ids são por projeto e **não existe endpoint que
os liste** (medido 2026-09-30: seis caminhos candidatos devolvem 400). O adapter lê uma task do projeto
para descobrir o mapa `{id, name, is_closed_type}`, e usa `is_closed_type` para saber qual é o terminal.
A escrita é `{"status":{"id":"…"}}` — objeto, não nome, e **não** `custom_status`.

⚠️ **O layout padrão do Zoho só tem `Open` e `Closed`** (medido por um adotante em 2026-10-07, num portal
só). Não há `In Progress` para resolver por nome, e ler uma task nunca acha o resto do mapa quando todas
estão `Open`. O caminho que funciona sem saber ids é o `completion_percentage`: `100` fecha a task e a
resposta traz o id de `Closed`. Detalhe em [`adapters/zoho.md`](adapters/zoho.md) §`updateStatus`.

### Prioridade

| Interface | ClickUp | Asana | Jira | Linear | Zoho Projects |
|-----------|---------|-------|------|--------|---------------|
| `urgent` | 1 | - | Highest | 1 | "High" ⚠️ |
| `high` | 2 | - | High | 2 | "High" ⚠️ |
| `normal` | 3 | - | Medium | 3 | "Medium" ⚠️ |
| `low` | 4 | - | Low | 4 | "Low" ⚠️ |
| **fonte** | medição ao vivo (2026-10-02): só inteiro 1–4; `"high"` → `400 Priority invalid` | não nativo (custom field ou tag); **não verificado** | nomes do esquema padrão; **não verificado** na Onda 1 | ancorado: `0` sem prioridade, `1` urgente … `4` baixa | da UI; **não medido** contra a API |

⚠️ O Zoho tem **quatro** níveis (`None`/`Low`/`Medium`/`High`), então `urgent` e `high` **colapsam** no
mesmo valor — perda de informação declarada, não escondida. E este mapeamento vem da UI: **não foi
medido contra a API**, por isso o adapter Zoho declara `priority.set` como `not_implemented` (ele não
envia prioridade) em vez de afirmar um mapa que ninguém conferiu.

---

## 🧪 Exemplo de Uso

```typescript
// Obter adapter
const taskManager = getTaskManager();

// Verificar configuração
if (!taskManager.isConfigured) {
  console.warn('⚠️ Provedor não configurado. Execute /meta/setup-integration');
  return;
}

// Criar task
const task = await taskManager.createTask({
  name: 'Implementar feature X',
  description: 'Descrição detalhada...',
  priority: 'high',
  tags: ['feature', 'v2']
});

console.log(`✅ Task criada: ${task.url}`);

// Criar subtask
const subtask = await taskManager.createSubtask(task.id, {
  name: 'Fase 1: Setup'
});

// Adicionar comentário (Markdown canônico; o adapter converte)
await taskManager.addComment(task.id, '🚀 Desenvolvimento iniciado!');

// Atualizar status
await taskManager.updateStatus(subtask.id, 'in_progress');

// Capacidade OPCIONAL: só chame o que o adapter declara implementar
if (taskManager.bulkCreate) {
  await taskManager.bulkCreate([{ name: 'A' }, { name: 'B' }]);
}
```

---

## 📚 Referências

- [Tipos Compartilhados](./types.md)
- [Factory](./factory.md)
- [Adapters](./adapters/) e suas declarações `adapters/*.capabilities.tsv`

---

**Versão**: 2.0.0 (Onda 2 — assinaturas e declaração de capacidades, SAC-63)
**Criado em**: 2025-11-24 · **Atualizado em**: 2026-10-11
