# Inventário interno — acoplamento da maquinaria Onion a suposições de modelo

> **Escopo:** read-only sobre `/home/marcio/onion-evolve` (core), 2026-09-02. Mede **onde a maquinaria
> depende de suposições sobre modelo/tier/effort/capacidade**, para depois decidir o que o Fable 5.1
> supera. Exclui `.claude/worktrees/**` (cópias de worktree antiga) salvo nota explícita.
> **Método:** `grep`/`find` sobre o vivo; toda contagem re-medida com stderr visível (a guarda
> anti-fail-open do shell parou 2 medições minhas nesta passada).

---

## (A) Tabela agente → model

**Censo prévio do pedido (8 opus / 47 sonnet) está ERRADO no denominador.** Medido:

```
$ for f in $(find .claude/agents -name '*.md' ! -name 'README.md'); do awk '/^---/{n++;next} n==1&&/^model:/{print $2;exit}' "$f"; done | sort | uniq -c
      8 opus
     43 sonnet
total: 51
```

51 agentes (60 `.md` − 9 `README.md` de categoria). **8 opus + 43 sonnet = 51.** O "47" provavelmente
contou as 6 ocorrências extras de `model:` **no corpo** de
`.claude/agents/meta/agent-creator-specialist.md` (linhas 408, 624, 1061, 1077, 1093, 1108 — exemplos
de template, não frontmatter). `effort:` no frontmatter de agente: **ZERO ocorrências** (`grep -rniE
"^(effort|thinking|reasoning)" .claude/agents` = vazio).

### Os 8 em `opus`

| Agente | `arquivo:linha` |
|---|---|
| `branch-code-reviewer` | `.claude/agents/git/branch-code-reviewer.md:7` |
| `metaspec-gate-keeper` | `.claude/agents/meta/metaspec-gate-keeper.md:6` |
| `branding-positioning-specialist` | `.claude/agents/product/branding-positioning-specialist.md:9` |
| `pain-price-specialist` | `.claude/agents/product/pain-price-specialist.md:8` |
| `product-agent` | `.claude/agents/product/product-agent.md:6` |
| `storytelling-business-specialist` | `.claude/agents/product/storytelling-business-specialist.md:6` |
| `code-reviewer` | `.claude/agents/review/code-reviewer.md:7` |
| `corporate-compliance-specialist` | `.claude/agents/review/corporate-compliance-specialist.md:6` |

### Os 43 em `sonnet` (por categoria, com linha)

| Categoria | Agentes (`model: sonnet`) |
|---|---|
| `compliance/` (**5/5 — nenhum opus**) | `iso-22301-specialist.md:6`, `iso-27001-specialist.md:6`, `pmbok-specialist.md:6`, `security-information-master.md:6`, `soc2-specialist.md:6` |
| `deployment/` | `docker-specialist.md:7` |
| `development/` (20) | `brand-generator.md:11`, `c4-architecture-specialist.md:6`, `c4-documentation-specialist.md:6`, `claude-code-specialist.md:6`, `clickup-specialist.md:6`, `design-system-specialist.md:11`, `docs-reverse-engineer.md:6`, `gamma-api-specialist.md:6`, `jira-specialist.md:7`, `linux-security-specialist.md:6`, `mermaid-specialist.md:7`, `nodejs-specialist.md:6`, `nx-migration-specialist.md:6`, `nx-monorepo-specialist.md:6`, `postgres-specialist.md:6`, `react-developer.md:6`, `runflow-specialist.md:7`, `system-documentation-orchestrator.md:6`, `whisper-specialist.md:7`, `zen-engine-specialist.md:9` |
| `git/` (4 de 5) | `branch-documentation-writer.md:7`, `branch-metaspec-checker.md:7`, `branch-test-planner.md:7`, `gitflow-specialist.md:6` |
| `meta/` (4 de 5) | `agent-creator-specialist.md:6`, `agent-skills-specialist.md:10`, `command-creator-specialist.md:6`, `onion.md:7` |
| `product/` (5 de 9) | `extract-meeting-specialist.md:6`, `meeting-consolidator.md:7`, `presentation-orchestrator.md:6`, `story-points-framework-specialist.md:6`, `task-specialist.md:6` |
| `research/` | `research-agent.md:6` |
| `testing/` (3) | `test-agent.md:8`, `test-engineer.md:6`, `test-planner.md:7` |

### Trabalho "difícil" rodando em `sonnet` — a assimetria medida

A doutrina da casa (`onion-orchestration/SKILL.md:236`) manda **`opus`/`high` para "verify adversarial,
juiz/painel, síntese final, mudança irreversível/compliance"**. Contra isso:

| Agente em `sonnet` | Por que a doutrina pediria tier alto |
|---|---|
| `compliance/soc2-specialist`, `iso-27001`, `iso-22301`, `pmbok`, `security-information-master` | **A vertical inteira de compliance** — a própria tabela de tiering nomeia "compliance" na faixa difícil. **5/5 em sonnet.** |
| `git/branch-metaspec-checker` (`:7`) | É **gate pré-PR** de conformidade arquitetural — mas o seu par não-diff-scoped `metaspec-gate-keeper` está em `opus`. Assimetria dentro do mesmo papel. |
| `git/branch-test-planner`, `git/branch-documentation-writer` | Gates pré-PR (irmãos do `branch-code-reviewer`, que **está** em opus). |
| `research/research-agent` (`:6`) | Pesquisa multi-fonte + análise semântica — a casa roda juiz `opus/high` em research (`meta/radar.md:35`), mas o agente nomeado de research é sonnet. |
| `development/linux-security-specialist` (`:6`) | Hardening/forense/incidente = alto risco irreversível. |
| `meta/agent-creator-specialist`, `command-creator-specialist` | Meta-fábrica: erro se propaga por todo artefato gerado. |
| `testing/test-agent`, `test-planner` | Estratégia de cobertura (julgamento, não mecânica). |

**Contraponto honesto:** nenhum destes é *worker de fan-out* — são agentes invocáveis diretamente, e o
`model:` do frontmatter é **default**, sobrescritível por spawn. Ainda assim é declaração de tier, e é
a única declaração que existe: **`effort:` não aparece em nenhum dos 51**.

### Superfície ESPELHADA em `plugins/` (dobra o custo de qualquer troca)

```
$ grep -rh "^model:" plugins --include=*.md | sort | uniq -c
      2 model: haiku
     13 model: opus
    108 model: sonnet
      1 model: sonnet|opus|haiku
(123 arquivos)
```

Os agentes/comandos materializados nos plugins carregam **cópia** do `model:`. Qualquer re-tiering do
core precisa re-materializar os plugins, ou os dois divergem silenciosamente.

---

## (B) Inventário por `arquivo:linha`

### B.1 — Acoplamento a MODELO ESPECÍFICO (versão exata colada; envelhece sozinho)

| `arquivo:linha` | Trecho verbatim | Nota |
|---|---|---|
| `docs/knowledge-base/concepts/context-window-optimization.md:498` | `model: opus-4.8` | versão exata num exemplo YAML — a KB **manda não hardcodar** na linha 60 e hardcoda na 498 |
| `docs/knowledge-base/concepts/context-window-optimization.md:502` | `model: sonnet-4.6        # ou haiku-4.5 para tarefas mecânicas` | idem; **três** versões retiradas num comentário |
| `docs/knowledge-base/concepts/agent-orchestration.md:286` | `{ schema: VerdictSchema, model: "sonnet-4.6" })` | a **própria fonte única** do lineup tem um exemplo pinado em 4.6 |
| `.claude/validation/review-verdict.sh:178` | `{ "type": "system", "subtype": "init", "model": "claude-sonnet-5" }` | fixture/stub de stream — mas é **string de modelo dentro do gate** |
| `docs/knowledge-base/platforms/runflow.md:243,312` | `anthropic('claude-3-5-sonnet-20241022')` · `bedrock('anthropic.claude-3-5-sonnet-20241022-v2:0')` | **família Claude 3.x retirada** — exatamente o que `/meta:kb-freshness` cataloga como FALHA (`kb-freshness.md:68`) |
| `.claude/commands/meta/recover.md:370` | `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` | assinatura de commit com versão exata |

### B.2 — Acoplamento a TIER ABSTRATO (`opus`/`sonnet`/`haiku`/`fable` — o padrão SDAAL da casa)

**Frontmatter (declaração de tier por artefato):**

| Superfície | Distribuição medida |
|---|---|
| 51 agentes | 8 `opus` · 43 `sonnet` · 0 `haiku` · 0 `fable` |
| Comandos (`.claude/commands/**`) | 99 `sonnet` · 11 `opus` · 3 `haiku` · 0 `fable` · 2 no template (`sonnet   # sonnet \| opus \| haiku \| fable`) |
| 23 fragmentos `common/prompts/**` e `common/templates/**` | **sem `model:`** (não são invocáveis; isentos por desenho) |

Comandos `opus`: `meta/kg-freshness.md:11`, `meta/census.md:8`, `meta/analyze-complex-problem.md:7`,
`meta/orchestrate.md:7`, `design/generate.md:8`, `meta/kb-freshness.md:10`, `meta/drive.md:4`,
`meta/evolve.md:9`, `meta/radar.md:8`, `meta/context-freshness.md:10`,
`common/templates/agent-template.md:253` (exemplo).
Comandos `haiku`: `meta/inventory.md:4`, `meta/co-evolve.md:4`, `meta/backlog.md:4`.

**Doutrina de tiering (a tabela canônica):**

- `.claude/skills/onion-orchestration/SKILL.md:225` — `## Model tiering — PADRÃO OBRIGATÓRIO (tier por complexidade, sempre)`
- `:228` — *"Onion **atribui explicitamente `model` + `effort` por stage** … **Tiering não é opcional — é o default.**"*
- `:234-236` — a tabela de 3 faixas: mecânico→`haiku`/`low`; médio→`sonnet`/`medium`; **difícil/alto risco→`opus` (ou Mythos-class) / `high` (ou `xhigh`)**
- `:238-239` — *"**Opus orquestra** no nível principal … só o stage que **realmente** exige raciocínio profundo paga opus."*
- `:244-247` — *"Tiers disponíveis: **opus, sonnet, haiku** — sempre, e é o piso seguro. Acima de `opus` existe hoje um tier **Mythos-class** … use-o na faixa difícil/alto-risco **só se souber que a conta tem acesso confirmado**: GA de mercado **não** é sinônimo de liberado no plano/conta daqui. **Na dúvida, fique em `opus`.**"*

**Repetições da tabela (drift potencial — a doutrina está em 5 lugares):**

- `.claude/commands/meta/orchestrate.md:112-116, 128, 135, 146-147, 160, 237`
- `.claude/commands/meta/kb-freshness.md:149-152, 164, 194, 219` — *"Workers de leitura/classificação → **haiku** … Fan-in de síntese → **sonnet** … Verificação adversarial (se acionada) → **opus**."*
- `.claude/commands/meta/context-freshness.md:127-128, 140, 167` — *"workers → **haiku**; fan-in → **sonnet**; verificação adversarial (se acionada) → **opus**. Teto **16 workers**"*
- `.claude/commands/meta/kg.md:245, 263, 326-328` — *"um subagente `sonnet`/`medium` por documento"* · *"Um subagente `opus`/`high` por leva"*
- `.claude/commands/meta/radar.md:35, 47` — *"**Juiz-fixo por eixo** (`opus/high`, mandato REFUTAR, ABRE as fontes)"* · *"pipeline scan `sonnet/medium` → juiz `opus/high`"*
- `.claude/commands/meta/census.md:33` — *"(opus/high, calibração 2026-08-29) audita CONFIRMED e GATED-não-disparado"*
- `docs/knowledge-base/concepts/ai-agent-design-patterns.md:213-218`
- `docs/knowledge-base/concepts/context-window-optimization.md:60, 479`

**Gate mecânico do tier (a única guarda que existe):**

- `.claude/validation/lint-artifacts.sh:365-388` — **REGRA 3 (model allowlist) [HARD]**: `sonnet|opus|haiku|fable`; fora disso → `"campo model: fora da allowlist"`. Fixtures em `.claude/validation/fixtures/r3-model-allowlist/`.
- `.claude/validation/lint-artifacts.sh:3111` — HARD: `"frontmatter de comando sem model: — todo comando invocável declara o tier (achado D8-20, auditoria 2026-07-04)"`

**Drift já presente na doutrina escrita (a allowlist tem 4 valores; dois documentos dizem 3):**

| `arquivo:linha` | Diz | Deveria (REGRA 3) |
|---|---|---|
| `.claude/skills/onion-patterns/SKILL.md:98` | `model: sonnet\|opus\|haiku` | falta `fable` |
| `.claude/skills/onion-validation/SKILL.md:19` | `` `model` \| string \| `sonnet` \| `opus` \| `haiku` `` | falta `fable` |
| `.claude/commands/meta/create-agent.md:212` | *"Usar modelo `sonnet` como padrão"* | prescreve o piso, sem faixa |

**Contradição interna de doutrina:**

- `docs/knowledge-base/concepts/ai-agent-design-patterns.md:213` — *"**Lead (orquestrador)** → tier **opus** (**o modelo Claude mais capaz**)"*
- `…:218` (5 linhas abaixo) — *"Tiers no Claude Code, do topo para a base: **fable** (Mythos-class, **acima** de opus — não é par dele), **opus**, …"*

### B.3 — Acoplamento a CAPACIDADE (effort, contexto, harness, hooks)

**`effort` — doutrina obrigatória, execução quase-nula:**

| `arquivo:linha` | Trecho |
|---|---|
| `.claude/skills/onion-orchestration/SKILL.md:228` | *"atribui explicitamente `model` **+ `effort`** por stage"* — **obrigatório** |
| `.claude/utils/census/census-workflow.mjs:79` | `{ label: \`censo:${a.id}\`, phase: 'Medir', model: 'sonnet', effort: 'medium', budget: 35000, schema: WSchema }` |
| `.claude/utils/census/census-workflow.mjs:98` | `{ label: \`juiz:lote${ix+1}\`, phase: 'Juizo', model: 'opus', effort: 'high', budget: 70000, schema: JSchema }` |
| `.claude/skills/onion-orchestration/SKILL.md:176` | `{ schema: KgWriteSchema, model: "sonnet", effort: "medium" }` (exemplo) |
| `docs/knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md:63` | *"**Doutrina declarada ≠ praticada** \| `effort` obrigatório na skill de orquestração \| scripts Workflow que de fato **passam** `effort` \| **guarda a nomear — achado 2026-07-17 (~0 scripts passam hoje)**"* |

Medido hoje: **existe exatamente 1 script `.mjs` de Workflow versionado no core**
(`.claude/utils/census/census-workflow.mjs`) e ele **passa** `effort`. Ou seja o achado de 2026-07-17
("~0 scripts passam") foi corrigido no único script que sobreviveu — mas a base é N=1, e **o `effort`
não tem guarda mecânica nenhuma**: `grep -rn "effort" .claude/validation/` → **rc=1, ZERO ocorrências**.
Só `model:` é catraca (REGRA 3); `effort` é conselho.

Vocabulário de `effort` reconhecido pela casa: `docs/knowledge-base/tools/agent-skills.md:127` e `:193`
— `low | medium | high | xhigh | max` (também `${CLAUDE_EFFORT}`). A tabela de tiering da skill só
chega a `high (ou xhigh)` — **`max` nunca é prescrito em lugar nenhum da maquinaria.**

**Janela de contexto (suposições de capacidade):**

| `arquivo:linha` | Trecho |
|---|---|
| `docs/knowledge-base/concepts/context-window-optimization.md:51` | `\| Claude Fable 5 \| Orquestração de raciocínio profundo \| 1M tokens \| ~400K linhas \|` |
| `…:52` | `\| tier \`opus\` (hoje **Opus 5**) \| Orquestrador \| 1M tokens \| ~400K linhas \|` |
| `…:53` | `\| tier \`sonnet\` (hoje Sonnet 5) \| Worker de uso geral \| **200K–1M tokens** \| ~80K linhas \|` |
| `…:54` | `\| tier \`haiku\` (hoje Haiku 5) \| Worker barato/rápido \| **200K tokens** \| ~80K linhas \|` |

O KB inteiro de *context-window-optimization* é uma estratégia construída sobre escassez de janela — a
suposição mais exposta a um frontier de 1M ctx.

**Tetos de harness (não do modelo — SDAAL correto, mas anotar):**

- `.claude/skills/onion-orchestration/SKILL.md:19` e `docs/knowledge-base/concepts/agent-orchestration.md:255` — *"até **16 subagentes concorrentes** e **1.000 agregados por run** — teto do **Workflow** (o run)"*
- `agent-orchestration.md:262` — *"o fan-out de `agent()` de uma orquestração **NÃO consome o orçamento da sessão**"*

**Env que anula o tiering declarado (a descoberta do radar E3):**

- `.claude/skills/onion-orchestration/SKILL.md:106-109` — *"**Antes de declarar o tier, cheque o ambiente:** `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (Claude Code ≥ 2.1.257) aplica UM modelo a todo subagente **ignorando** `model` por spawn e por definição de agente — com ela setada, o tiering declarado no relatório é falso. Se `env | grep -c CLAUDE_CODE_SUBAGENT_MODEL` ≠ 0, imprima **AVISO: tiering declarado ≠ executado (env force)**"*
- **É conselho em prosa, não mecanismo.** Nenhum hook, nenhuma REGRA do lint lê essa env.

**Hooks / settings — resultado NEGATIVO (importante):**

- `.claude/settings.json` e `.claude/settings.local.json`: **nenhuma chave de modelo, nenhum `env` de modelo**. Hooks declarados: `SessionStart` (4), `UserPromptSubmit` (2), `SessionEnd`, `PreToolUse` (`:108`), `PostToolUse`.
- **Nenhum hook lê `model` do input JSON.** As 5 ocorrências de "model" em `.claude/hooks/*.sh` são a palavra portuguesa *modelo* em comentários (`bash-empty-result-guard.sh:25,383`; `co-evolution-inbox-check.sh:6,7,19`).
- **`PreModelSwitch`: ZERO ocorrências** em todo o repo.
- `CLAUDE_CODE_SUBAGENT_MODEL*` / `ANTHROPIC_MODEL` / `CLAUDE_MODEL`: nenhuma ocorrência **no repo** fora da prosa da skill.

**Medição do ambiente (feita, não deduzida):**

```
$ env | grep -c CLAUDE_CODE_SUBAGENT_MODEL
0                          ← a env force NÃO está setada; o censo (A) vale
$ env | grep -iE "CLAUDE_CODE_SUBAGENT|ANTHROPIC_MODEL|CLAUDE_MODEL|CLAUDE_EFFORT"
CLAUDE_EFFORT=high         ← única env de capacidade presente
```

→ **`CLAUDE_EFFORT=high` está setada no ambiente desta máquina.** Achado não-previsto: existe um
**default de effort vindo do ambiente**, invisível a toda a maquinaria (nenhum comando, skill, hook ou
REGRA o lê ou reporta). Combinado com C4 (a tabela para em `high (ou xhigh)`) e com a evidência de que
o ganho do 5.1 *"is widest at higher effort levels"* (`data/ext-oficial.md:62`), o efeito prático é que
**o piso e o teto de effort desta casa coincidem em `high`** — por env, não por decisão registrada.

**Baseline/radar (gatilho de re-medição de estratégia):**

- `docs/onion/radar-baselines.yaml:15-19` — eixo `E3-claude-code-delta`, `last_run: 2026-09-02`, `cc_version: "2.1.257"   # versão do Claude Code na rodada — instalada ≠ esta ⇒ SOFT "estratégia pode ter drift"`
- `.claude/validation/lint-artifacts.sh:3611-3619` — **REGRA 65 [SOFT]**, gatilho de versão: `"REGRA 65: Claude Code mudou de versão desde a última rodada de estratégia (rodada=${pinned_cc}, instalado=${installed_cc}) — adequação não re-medida; rode /meta:radar E3-claude-code-delta"`
- **Não existe eixo/baseline de LINEUP DE MODELO.** A REGRA 65 dispara por versão do **Claude Code**, nunca por lançamento de modelo. `E6-fronteira-modelos` existe (`radar-baselines.yaml:26-29`, `last_run: 2026-08-31`) mas é eixo de **pesquisa de mercado**, sem `cc_version`-equivalente e sem gatilho mecânico.
- `.claude/validation/kg-radar.sh`: **nenhuma menção a modelo/tier/effort** — o radar de grafo é 100% agnóstico (bom).

---

## (C) Suposições EXPLÍCITAS sobre limites de modelo que o Fable 5.1 pode invalidar

Ordenadas pelo tamanho do que cai se a suposição cair.

**C1 — "Na dúvida, fique em `opus`" (o piso conservador da faixa difícil).**
`onion-orchestration/SKILL.md:244-247`: *"Tiers disponíveis: **opus, sonnet, haiku** — sempre, e é o
piso seguro. Acima de `opus` existe hoje um tier **Mythos-class** … use-o na faixa difícil/alto-risco
**só se souber que a conta tem acesso confirmado**: GA de mercado **não** é sinônimo de liberado no
plano/conta daqui. **Na dúvida, fique em `opus`.**"*
→ O 2º degrau da régua de 3 **já foi satisfeito**: `E_FABLE_5_1_CONFIRMADO_NA_CONTA` (grafo do radar E3;
`SYNTHESIS.md:49` — *"FECHADA por testemunho (maestro, 2026-09-02)"*). A cláusula "só se souber que a
conta tem acesso" **passou a ser verdadeira**, e nada na maquinaria foi religado por isso. Toda a faixa
difícil/alto-risco (juízes, verify adversarial, síntese crítica, compliance) segue mandada para `opus`.

**C2 — "opus é o modelo Claude mais capaz".**
`ai-agent-design-patterns.md:213`: *"**Lead (orquestrador)** → tier **opus** (**o modelo Claude mais
capaz**)"*. Já contradito 5 linhas abaixo (`:218`) e falso desde jun/2026. Invalidado.

**C3 — o gap de runtime do alias `fable` (a suposição que ainda SEGURA tudo).**
`agent-orchestration.md:330`: *"⚠️ **Gap de runtime, o mesmo do `opus` acima:** o alias `fable` de
`Workflow`/`Agent` **segue resolvendo para Fable 5** em sessões via gateway ("for now"; 5.1 só por
`/model`) — logo "5.1 é o frontier" é declaração de catálogo, não execução observada"*.
→ **Lacuna 2 do radar E3, ainda ABERTA** (`SYNTHESIS.md:50`: *"Se o alias `fable` desta sessão
(não-gateway) resolve 5 ou 5.1 — lido, não medido em runtime"*). É a medição que falta e que decide se
o tiering pode escalar para 5.1 **por spawn** ou só pela sessão principal. Precedente exato de como se
fecha: o gap gêmeo do `opus` foi fechado por medição no mesmo dia — `agent-orchestration.md:321`,
*"o transcript do subagente `juiz-e3` spawnado com `model: opus` registra `claude-opus-5` em 39 turnos"*.

**C4 — a faixa de `effort` para no `high (ou xhigh)`.**
`onion-orchestration/SKILL.md:236`. O vocabulário reconhecido pela própria casa vai a `max`
(`agent-skills.md:127`), e a evidência externa já coletada nesta pesquisa diz que o ganho do 5.1 sobre
o 5 *"is widest at higher effort levels"* (`data/ext-oficial.md:62`). A maquinaria **nunca prescreve
`max`** e não tem guarda que verifique `effort` nenhum.

**C5 — escassez de janela como premissa de arquitetura.**
`context-window-optimization.md:53-54` (`sonnet` 200K–1M, `haiku` 200K). Se o frontier da faixa difícil
passa a 1M ctx com `max`, boa parte da estratégia de particionar-para-caber vira otimização prematura —
**mas** o worker `haiku` continua em 200K, então o teto de partição do fan-out **não** cai junto.

**C6 — "tiering declarado = tiering executado".**
`onion-orchestration/SKILL.md:106-109` já declara o contrário (env `..._MODEL_FORCE`), mas **em prosa**.
Enquanto for conselho, todo relatório de tier desta casa é declaração — a doutrina
`behavior-over-declaration` aplicada à própria maquinaria de tiering.

**C7 — o custo como catálogo, não medição.**
`agent-orchestration.md:319`: *"a régua tem **três** degraus, não dois: **GA de mercado ≠ liberado na sua
conta ≠ sem custo marginal**. Confirme antes de tierar a faixa difícil para cá; **na dúvida, `opus`**"*.
O 3º degrau segue não-medido (`SYNTHESIS.md:49`: *"custo segue catálogo"*). É o que sustenta C1 mesmo
depois do acesso confirmado — e a régua da casa é `efficiency-over-economy`, o que **enfraquece** o
custo como razão para não escalar.

---

## (D) SDAAL-abstraído vs hardcoded

**Bem abstraído (troca de modelo sem tocar doutrina) — o padrão da casa funciona:**

1. **Fonte única de lineup declarada e obedecida.** `agent-orchestration.md:313-315`: *"**Atualize o
   lineup SÓ aqui.** Os demais artefatos referenciam modelos por **tier** (evergreen), nunca por versão
   exata, e apontam para esta seção."* Cumprido por `context-window-optimization.md:60` e `:479`,
   `ai-agent-design-patterns.md:218`, `orchestrate.md:115-116`, `onion-orchestration/SKILL.md:247`.
2. **Referência por tier, não por versão**, em 100% do frontmatter de agentes e comandos (150+
   artefatos): trocar o que `opus`/`sonnet`/`haiku` significam é ato de **plataforma**, não de repo.
3. **REGRA 3 [HARD]** (`lint-artifacts.sh:365-388`) — allowlist fechada de 4 valores; nasceu justamente
   porque a guarda-lista-negra deixava `o3`/`claude-3-opus` passarem (`docs/onion/graph/pr-showcase-selection-2026-08.md:85`).
4. **`/meta:kb-freshness` audita o próprio lineup** — dimensão #1 (`kb-freshness.md:68`): *"Usa o lineup
   Claude vigente referenciado por **tier** … não fixa versão exata como única referência."*
5. **`kg-radar.sh` totalmente agnóstico** a modelo (ZERO menções).
6. **Hooks/settings sem acoplamento a modelo** (nenhuma env, nenhum `PreModelSwitch`).

**Hardcoded / não-abstraído (troca exige editar):**

1. **6 versões exatas coladas** — §B.1. Duas delas (`agent-orchestration.md:286`,
   `context-window-optimization.md:498,502`) estão **dentro dos próprios documentos que proíbem
   hardcodar**. `runflow.md:243,312` cita **família 3.x retirada** — falharia a dimensão #1 do
   `/meta:kb-freshness` se auditada hoje.
2. **`census-workflow.mjs:79,98`** — o único script de Workflow versionado tem `model`/`effort` literais
   no código. É o lugar certo (tiering **é** por stage), mas não há indireção: subir o juiz do censo
   para a Mythos-class exige editar `.mjs`.
3. **A tabela de tiering está replicada em ~8 documentos** (§B.2). Não é um `include` — é cópia. Mudar
   a faixa difícil de `opus` para `fable` significa editar 8 lugares, e 2 deles já driftaram na
   allowlist (`onion-patterns/SKILL.md:98`, `onion-validation/SKILL.md:19` esqueceram `fable`).
4. **`plugins/` carrega 123 cópias** do `model:` — re-tiering do core exige re-materializar.
5. **`effort` sem catraca.** `model:` é HARD no lint; `effort` não existe em `.claude/validation/`.
   Assimetria: metade da doutrina de tiering é mecanismo, a outra metade é conselho.
6. **Nenhum gatilho mecânico para lançamento de MODELO.** REGRA 65 dispara por `cc_version`; um Fable
   5.2 amanhã não acende luz nenhuma. O único caminho é `/meta:radar E6-fronteira-modelos`, manual, sem
   catraca.

---

## (E) Lacunas do inventário

1. **Não medi runtime.** Tudo aqui é leitura de arquivo. Se o alias `fable` desta sessão resolve 5 ou
   5.1 (C3) **continua não-medido** — é a lacuna 2 do radar E3, herdada. O teste é o do `juiz-e3`:
   spawnar com `model: fable` e ler a identidade de modelo no transcript.
2. ~~Não medi a força efetiva do `model:` de frontmatter.~~ **FECHADA nesta passada** (§B.3): a env
   force não está setada (`0`), logo o censo (A) não é declaração vazia. A medição rendeu o achado
   colateral `CLAUDE_EFFORT=high`. Continua **não** medido: se o `model:` de frontmatter de fato
   governa o spawn — provei só que nada o está sobrescrevendo por env.
3. **Não abri os 51 agentes.** Julguei "trabalho difícil" pela `description` do frontmatter e pela
   categoria, não pelo corpo. A lista de §A ("difícil em sonnet") é **hipótese ordenada**, não veredito
   — e `read-full-content-before-triage` diz exatamente para não triar por frontmatter.
4. **`docs/` fora de `knowledge-base/` e `evolution/research/` não foi varrido** para menções de modelo
   (`docs/analysis/`, `docs/meta-specs/`, `docs/onion/graph/`). Achei ocorrências ali por acidente
   (`onion-guardas-mapa-2026-08.md:403`, `pr-showcase-selection-2026-08.md:85`) — não por varredura.
5. **`.claude/worktrees/discuss+onion-pessoal-app/`** contém uma cópia inteira e mais velha da
   maquinaria (SKILL.md com a tabela **sem** a menção Mythos-class, `:118`). Excluí do inventário; se
   essa worktree ainda for viva, é superfície de drift não contabilizada.
6. **Nenhuma medição de custo.** O 3º degrau da régua (C7) segue sendo catálogo em todo lugar,
   inclusive aqui.
7. **`descartes:` por eixo e a semântica dos outros 5 eixos do radar** não foram examinados — só o E3.

---

## Emendas do juiz Elenxo `juiz-fable51` (fable, mandato REFUTAR — 2026-09-02)

Contagens re-medidas pelo juiz (texto original preservado acima):

| Contagem | Worker | Juiz (medido) | Veredito |
|---|---|---|---|
| agentes opus/sonnet/total | 8/43/51 | 8/43/51 | APROVADO |
| cópias de `model:` em `plugins/` | 123 | 123 | APROVADO |
| comandos `model:` | 99/11/3 (`^model:` cru) | **96/10/3 = 109** só no frontmatter (awk) | REPROVADO na precisão (l.109 conta exemplos de corpo) |
| `ModelSwitch` "ZERO em todo o repo" | 0 | **ZERO em `.claude/`**; 5+ arquivos em `docs/` (ex. `docs/analysis/pretooluse-proof-2026-08.md:68`) | REPROVADO: verdadeiro só para `.claude/` |
| versões coladas (§B.1) | 6 | **≥9**: + `claude-code-specialist.md:49` ("1M beta no Opus 4.7"), `:208` (`"claude-opus-4-7"`), e o drift `docs/onion/ci.md:10` (`sonnet-4-6`) vs `onion-review.yml:170,263` (`claude-sonnet-5`) | REPROVADO: subcontado |
| réplicas da tabela de tiering | "5 lugares" (l.126) e "~8" (l.309) | **9** (`onion-orchestration/SKILL.md:106-107,236,244-247`; `orchestrate.md:115`; `context-freshness.md:127`; `kg.md:245,263`; `ai-agent-design-patterns.md:213,218`; `context-window-optimization.md:60,479`; `onion-patterns/SKILL.md:98`; `onion-validation/SKILL.md:19`; `create-agent.md:212`; `agent-skills.md:127`; `census-workflow.mjs:79,98`) | REPROVADO: inconsistente internamente; a conclusão "doutrina replicada sem SSOT" sobrevive |
| `effort` em agentes / validation | 0 / 0 | 0 / rc=1 | APROVADO |
| `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` | unset | `env` rc=1 | APROVADO |

**§B.3/§D — o "achado" de `CLAUDE_EFFORT=high` (l.211-215) está ERRADO e é retirado.** O binário 2.1.257
contém *"Also exposed to hook commands and Bash as the CLAUDE_EFFORT env var"*; `~/.bashrc`, `~/.profile` e
`~/.claude/settings.json` não a definem (rc=1). **O Claude Code exporta o effort da sessão corrente para
Bash/hooks** — não é default de máquina escondido, é **sinal legível por hook**: a via para um gate de
effort, não um furo.

**PreModelSwitch/PostModelSwitch:** disponíveis no binário instalado (60/34 ocorrências; `from_model` 18,
`to_model` 22), **nenhum hook implementado em `.claude/`**, evento **nunca disparado** aqui. A baseline
`docs/onion/radar-baselines.yaml` E6/F7 ("sem sinal sobre hooks novos", 2026-08-31) está contradita pelo
CHANGELOG e pelo binário — re-carimbada nesta rodada.

**Omissão relatada pelo juiz:** o transcript da sessão principal tem 1868 campos `claude-fable-5`, 467
`claude-fable-5-1`, 1383 `claude-opus-5`; os últimos 15 são todos `claude-fable-5-1` — **a sessão migrou de
modelo no meio** e nenhum worker registrou quando; toda medição "de hoje" tem baseline ambígua.
