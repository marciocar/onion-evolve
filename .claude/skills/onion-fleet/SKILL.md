---
description: >
  Reconhece trabalho elegível a fan-out e autora/dispara um script da ferramenta
  nativa Workflow que codifica o padrão canônico certo. Use quando houver N
  subtarefas independentes, varreduras amplas (auditorias, migrações, edições
  multi-arquivo), review paralelo, ou o padrão decompor→delegar→sintetizar/verificar.
  Ative mesmo sem o usuário dizer "frota", "paralelo" ou "fleet". Orquestra sempre
  no contexto principal (skill/comando), nunca dentro de um subagente.
allowed-tools: Workflow Agent Read Grep Glob Bash(git worktree*)
---

# Onion Fleet — Orquestração de Frota

Cérebro operacional para fan-out paralelo no Sistema Onion. Reconhece quando
um trabalho se decompõe em subtarefas independentes e o codifica em um script
da ferramenta nativa **Workflow**, escolhendo o padrão canônico adequado.

A coordenação roda em JavaScript e custa **0 tokens de modelo**. O teto é de
16 subagentes concorrentes e 1.000 agregados por run.

## Instruções (passo a passo)

1. **Detectar elegibilidade de fan-out.** Há *independência real* entre as
   subtarefas? Cada uma produz seu resultado sem ler a saída da outra? Se há
   dependência de ordem ou estado compartilhado mutável, **não** paralelize —
   mantenha serial. Sinais de elegibilidade: "para cada arquivo/módulo/PR/fonte",
   varredura ampla, auditoria, migração mecânica, review multi-dimensão.
2. **Escolher 1 dos 6 padrões canônicos** (tabela abaixo) conforme a forma do
   trabalho: classificar antes de agir, fan-out→sintetizar, verificação
   adversarial, gerar→filtrar, torneio, ou loop até convergir.
3. **Autorar um script Workflow.** Use `parallel([...])` quando precisa de
   **barreira** (todos terminam antes do fan-in) e `pipeline(items, ...)` quando
   o fluxo corre **sem barreira** entre itens (estágios encadeados por item).
   Defina `schema` por worker para output estruturado e validado.
4. **Verificação adversarial / judge-panel quando alto risco.** Mudanças amplas,
   irreversíveis ou de compliance ganham uma etapa de verificação por um agente
   independente (ou painel de juízes) sobre a saída agregada.
5. **Fan-in / consolidação.** Todo fan-out termina em **um único resultado**
   consolidado — nunca N saídas soltas. Agregue, deduplique e ranqueie no
   contexto principal (custo 0 tokens).
6. **Relatório ao usuário** em pt-BR: padrão escolhido, nº de workers, tier de
   modelo, budget gasto e o resultado consolidado.

## Padrões → primitivas

| Padrão canônico | Primitiva | Forma | Mini-exemplo |
|---|---|---|---|
| **classify-and-act** | `agent()` → `parallel()` | classifica, depois roteia branches | 1 agente classifica o input; em seguida dispara o handler do bucket |
| **fan-out-and-synthesize** | `parallel()` + fan-in | barreira, depois síntese | N agentes auditam N arquivos; consolida num relatório |
| **adversarial verification** | `parallel()` (gerador + verificador) | gera e contesta | um agente propõe a fix, outro tenta refutá-la |
| **generate-and-filter** | `parallel()` → filtro JS | gera muitos, retém poucos | gera 10 candidatos; filtra por schema/critério |
| **tournament** | `parallel()` em rodadas | eliminação par-a-par | compara saídas 2-a-2 até 1 vencedor |
| **loop-until-done** | `loop` budget-gated | refina até convergir | refina output até passar no juízo ou estourar budget |

```javascript
// fan-out-and-synthesize: auditar N arquivos em paralelo (com barreira)
const findings = await parallel(
  files.map((f) => agent(
    `Audite ${f} contra a checklist de segurança. Liste vulnerabilidades.`,
    { schema: FindingSchema, model: "haiku" }
  ))
);
// fan-in no contexto principal (0 tokens): consolida num resultado único
return consolidate(findings);
```

```javascript
// pipeline: sem barreira entre itens — cada item flui estágio→estágio
await pipeline(
  modules,
  (m) => agent(`Extraia a API pública de ${m}.`, { schema: ApiSchema }),
  (api) => agent(`Gere os testes de contrato para esta API.`, { schema: TestSchema })
);
```

## Model tiering & budget

- **Opus orquestra** no nível principal (decisão, roteamento, síntese);
  **Sonnet/Haiku são os workers** — tier por dificuldade da subtarefa.
  Workers mecânicos (extração, classificação, varredura) → Haiku 4.5;
  raciocínio de média complexidade → Sonnet 4.6; reservar Opus 4.8 para
  orquestração e juízes adversariais críticos.
- **Loops budget-gated**: `loop-until-done` sempre com teto via `budget`
  (tokens) — sem teto não há loop.
- **Prompt caching**: instruções/contexto comuns aos workers entram no prefixo
  cacheável, cortando custo no fan-out.
- Lineup válido: **Fable 5, Opus 4.8, Sonnet 4.6, Haiku 4.5**. Nunca ofereça
  modelo de outro provider como worker.

## Gotchas

- **Fan-out só com independência real.** Dependência de ordem ou estado
  compartilhado mutável → mantenha serial. Paralelizar trabalho dependente
  corrompe resultado e desperdiça budget.
- **Mutação concorrente de arquivos exige `isolation:'worktree'`.** Quando
  múltiplos workers escrevem no repositório, isole cada um em seu git worktree;
  consolide os diffs no fan-in. Sem isolamento, há corrida de escrita.
- **Fleet é OPT-IN, nunca default.** Fan-out é decisão explícita. Trabalho
  serial e os workflows faseados canônicos (`engineer/*`, `product/*`)
  permanecem sequenciais — a frota paraleliza *dentro* de uma fase, não funde
  fases.
- **Nunca orqueste dentro de um subagente.** A orquestração mora no **nível
  principal** (skill/comando). Subagentes não disparam a frota — fan-out aninhado
  dentro de worker é mais caro e turvo. Por
  [architecture.md §4.2](../../../docs/meta-specs/architecture.md), `agents/* →
  commands/*` é proibido; logo **não existe** agente "fleet-orchestrator".
- **Coordenação JS custa 0 tokens.** Filtros, agregação, ranqueamento e
  roteamento entre etapas rodam em JavaScript — não gaste chamadas de modelo no
  que é determinístico.
- **Fan-in obrigatório.** Todo fan-out converge num único resultado consolidado.

## Resiliência (versão confiável)

- **Passo 0 — health-check do substrato.** Antes de autorar o script, confirme que a ferramenta `Workflow` está disponível. Se não estiver, acione o **fallback serial** de `/meta:fleet` de forma determinística — não dependa de o modelo "perceber".
- **Falha parcial de worker.** `parallel()` pode retornar `null` (worker morto, timeout, ou output que falhou no `schema`). **Sempre** `.filter(Boolean)` antes do fan-in e **reporte** quantos foram descartados (`SKIP — <motivo>`). Um worker morto nunca deve silenciar nem corromper o relatório.
- **Timeout por worker.** `budget` limita tokens, não tempo. Para workers que tocam I/O externo, aplique um teto de tempo (campo nativo quando existir; senão `Promise.race` com timer) e trate o estouro como SKIP.
- **Budget em todo fan-out.** Exija `budget` por worker também em `parallel()`/`pipeline()`, não só em `loop-until-done`.
- **Run-id + trace.** Gere um identificador por run (custo 0 tokens) e inclua no relatório junto à referência do **Agent View**, para reprodutibilidade e inspeção.

## Referências

- KB de doutrina e mapeamento de padrões: `docs/knowledge-base/concepts/agent-fleet-orchestration.md`
- Comando faceta: `/meta:fleet`
- Meta-spec de comandos (§10 Orquestração em fleet): `docs/meta-specs/commands.md`
- Meta-spec de arquitetura (§4.2 dependências): `docs/meta-specs/architecture.md`
- Skill relacionada: `onion-patterns` (estrutura e nomenclatura)
